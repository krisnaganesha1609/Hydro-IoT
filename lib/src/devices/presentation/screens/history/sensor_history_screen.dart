import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydro_iot/src/devices/application/controllers/history_controller.dart';
import 'package:hydro_iot/src/devices/presentation/widgets/export_bottom_sheet_widget.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:vector_graphics/vector_graphics.dart';
import '../../../../../pkg.dart';
import '../../../domain/entities/history_entity.dart';

enum ChartType { ph, ppm }

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

class SensorHistoryScreen extends ConsumerStatefulWidget {
  const SensorHistoryScreen({super.key, required this.cropCycleId});

  final String cropCycleId;

  static const String path = 'sensor-history';

  @override
  ConsumerState<SensorHistoryScreen> createState() => _SensorHistoryScreenState();
}

class _SensorHistoryScreenState extends ConsumerState<SensorHistoryScreen> {
  DateTimeRange? _selectedRange;
  final ReceivePort _port = ReceivePort();
  String? _downloadTaskId;

  // Controller untuk transformasi Zoom & Pan chart
  final TransformationController _phTransformController = TransformationController();
  final TransformationController _ppmTransformController = TransformationController();

  bool _isZoomMode = false;
  int _currentChartPage = 0; // 0 = pH, 1 = PPM

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      log('Download progress: $data');
      _downloadTaskId = data[0];
      setState(() {});
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    _phTransformController.dispose();
    _ppmTransformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _phTransformController.value = Matrix4.identity();
    _ppmTransformController.value = Matrix4.identity();
    setState(() => _isZoomMode = false);
  }

  void onExportCsv(BuildContext context) async {
    final local = AppLocalizations.of(context)!;
    final cropCycleId = widget.cropCycleId;
    String url = '${EndpointStrings.cropcycle}/$cropCycleId/export?format=csv';
    if (_selectedRange != null) {
      final start = DateFormat('yyyy-MM-dd').format(_selectedRange!.start);
      final end = DateFormat('yyyy-MM-dd').format(_selectedRange!.end);
      url += '&start=$start&end=$end';
    }
    try {
      final access = await Storage().readAccessToken;
      if (context.mounted) {
        Toast().showSuccessToast(context: context, title: local.success, description: local.fileIsBeingDownloaded);
      }
      await FileDownloader.download(
        url: url,
        filename: 'CropCycleHistory_${widget.cropCycleId}.csv',
        headers: {'Authorization': 'Bearer $access'},
      ).then((_) {
        log('Download completed');
        setState(() {});
        if (_downloadTaskId != null) FlutterDownloader.open(taskId: _downloadTaskId!);
      });
    } catch (e) {
      if (context.mounted) Toast().showErrorToast(context: context, title: local.error, description: e.toString());
    }
  }

  void onExportXlsx(BuildContext context) async {
    final local = AppLocalizations.of(context)!;
    final cropCycleId = widget.cropCycleId;
    String url = '${EndpointStrings.cropcycle}/$cropCycleId/export?format=xlsx';
    if (_selectedRange != null) {
      final start = DateFormat('yyyy-MM-dd').format(_selectedRange!.start);
      final end = DateFormat('yyyy-MM-dd').format(_selectedRange!.end);
      url += '&start=$start&end=$end';
    }
    try {
      final access = await Storage().readAccessToken;
      if (context.mounted) {
        Toast().showSuccessToast(context: context, title: local.success, description: local.fileIsBeingDownloaded);
      }
      await FileDownloader.download(
        url: url,
        filename: 'CropCycleHistory_${widget.cropCycleId}.xlsx',
        headers: {'Authorization': 'Bearer $access'},
      ).then((_) {
        log('Download completed');
        setState(() {});
        if (_downloadTaskId != null) FlutterDownloader.open(taskId: _downloadTaskId!);
      });
    } catch (e) {
      if (context.mounted) Toast().showErrorToast(context: context, title: local.error, description: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(historyControllerProvider(widget.cropCycleId));

    return Scaffold(
      backgroundColor: ColorValues.whiteColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          decoration: BoxDecoration(
            color: ColorValues.whiteColor,
            shape: BoxShape.circle,
            border: Border.all(color: ColorValues.neutral200),
          ),
          margin: EdgeInsets.only(left: 16.w),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: ColorValues.blackColor),
            onPressed: context.pop,
          ),
        ),
        title: Text(local.sensorHistory, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Container(
            decoration: BoxDecoration(
              color: ColorValues.green50,
              shape: BoxShape.circle,
              border: Border.all(color: ColorValues.green200),
            ),
            margin: EdgeInsets.only(right: 16.w),
            child: IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => ExportBottomSheet(onExportCsv: () => onExportCsv(ctx), onExportXlsx: () => onExportXlsx(ctx)),
                );
              },
              icon: const Icon(Icons.cloud_download_outlined, color: ColorValues.green900, size: 20),
            ),
          ),
        ],
      ),
      body: Skeletonizer(
        enabled: historyAsync.isLoading || historyAsync.isRefreshing,
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, st) => _buildErrorState(e.toString(), local),
          data: (raw) {
            final entries = raw.history ?? [];
            if (entries.isEmpty) {
              return _buildEmptyState(local);
            }

            final start = raw.dateRange['start'];
            final end = raw.dateRange['end'];
            final dateRangeStr = (start != null && end != null)
                ? '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}'
                : '-';

            Future<void> pickDateRange() async {
              final picked = await showDateRangePicker(
                context: context,
                initialDateRange: _selectedRange ?? DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now()),
                firstDate: DateTime(2023, 1, 1),
                lastDate: DateTime.now(),
                helpText: local.selectDateRange,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: ColorValues.green600,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: ColorValues.blackColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null && mounted) {
                setState(() => _selectedRange = picked);
                await ref
                    .read(historyControllerProvider(widget.cropCycleId).notifier)
                    .fetchHistory(cropCycleId: widget.cropCycleId, start: picked.start, end: picked.end);
              }
            }

            return RefreshIndicator.adaptive(
              notificationPredicate: (_) => !_isZoomMode,
              onRefresh: () async {
                await ref
                    .read(historyControllerProvider(widget.cropCycleId).notifier)
                    .fetchHistory(cropCycleId: widget.cropCycleId, start: _selectedRange?.start, end: _selectedRange?.end);
              },
              child: CustomScrollView(
                physics: _isZoomMode ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header Info & Date Filter Section
                  SliverToBoxAdapter(
                    child: _buildScrollLockWarning(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(color: ColorValues.neutral100, width: 1),
                          ),
                          color: ColorValues.green50,
                          elevation: 0,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_filled, size: 16, color: ColorValues.green700),
                                        const SizedBox(width: 6),
                                        Text(
                                          raw.timezone,
                                          style: dmSansSmallText(size: 12, weight: FontWeight.w700).copyWith(color: ColorValues.green900),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: pickDateRange,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                        decoration: BoxDecoration(
                                          color: ColorValues.whiteColor,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: ColorValues.green200),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.date_range_rounded, size: 14, color: ColorValues.green700),
                                            const SizedBox(width: 4),
                                            Text(
                                              local.selectDateRange,
                                              style: dmSansSmallText(size: 11, weight: FontWeight.w700).copyWith(color: ColorValues.green700),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  dateRangeStr,
                                  style: dmSansSmallText(size: 13, weight: FontWeight.w600).copyWith(color: ColorValues.neutral600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Chart Section
                  SliverToBoxAdapter(child: _buildChartSection(context, entries, local)),

                  // History Data Cards Title
                  SliverToBoxAdapter(
                    child: _buildScrollLockWarning(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(22.w, 16.h, 22.w, 8.h),
                        child: Text(local.sensorData, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),

                  // History Data Cards List
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildScrollLockWarning(child: _buildHistoryCard(entries[index])),
                        childCount: entries.length,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: heightQuery(context) * 0.08)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, List<HistoryEntity> entries, AppLocalizations local) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(33),
          side: const BorderSide(color: ColorValues.neutral100, width: 1),
        ),
        color: ColorValues.whiteColor,
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Toggle Indikator Page & Mode Zoom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tab Switcher pH & PPM
                  Row(
                    children: [
                      _buildTabButton('pH Chart', 0, ColorValues.blueProgress),
                      const SizedBox(width: 8),
                      _buildTabButton('PPM Chart', 1, ColorValues.green600),
                    ],
                  ),

                  // Tombol Zoom Toggle
                  GestureDetector(
                    onTap: () {
                      if (_isZoomMode) {
                        _resetZoom();
                      } else {
                        setState(() => _isZoomMode = true);
                        Toast().showWarningToast(
                          context: context,
                          title: 'Zoom Mode Activated',
                          description: 'Use two fingers to scale & drag to slide chart horizontally.',
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: _isZoomMode ? ColorValues.green600 : ColorValues.neutral100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isZoomMode ? Icons.zoom_in_map_rounded : Icons.zoom_out_map_rounded,
                            size: 14,
                            color: _isZoomMode ? Colors.white : ColorValues.neutral600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isZoomMode ? 'Zooming' : 'Zoom',
                            style: dmSansSmallText(
                              size: 11,
                              weight: FontWeight.w700,
                            ).copyWith(color: _isZoomMode ? Colors.white : ColorValues.neutral600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Chart Container dengan height konsisten
              SizedBox(
                height: 240.h,
                child: PageView(
                  physics: _isZoomMode ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                  onPageChanged: (idx) {
                    setState(() => _currentChartPage = idx);
                  },
                  children: [
                    _buildInteractiveChart(entries, ChartType.ph, _phTransformController),
                    _buildInteractiveChart(entries, ChartType.ppm, _ppmTransformController),
                  ],
                ),
              ),
              if (_isZoomMode)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: Text(
                      'Pinch to zoom chart horizontal • Swipe page disabled',
                      style: dmSansSmallText(size: 11, weight: FontWeight.w500).copyWith(color: ColorValues.neutral500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int pageIdx, Color activeColor) {
    final isActive = _currentChartPage == pageIdx;
    return GestureDetector(
      onTap: () {
        if (_isZoomMode) return;
        setState(() => _currentChartPage = pageIdx);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? activeColor : ColorValues.neutral200),
        ),
        child: Text(
          title,
          style: dmSansSmallText(
            size: 12,
            weight: isActive ? FontWeight.w700 : FontWeight.w500,
          ).copyWith(color: isActive ? activeColor : ColorValues.neutral600),
        ),
      ),
    );
  }

  Widget _buildInteractiveChart(List<HistoryEntity> entries, ChartType chartType, TransformationController transformCtrl) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final values = entries.map((e) => chartType == ChartType.ph ? e.phAvg : e.ppmAvg).toList();
    final spots = List<FlSpot>.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));

    final minX = 0.0;
    final maxX = (entries.length - 1).toDouble();

    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);

    if ((maxY - minY).abs() < 0.0001) {
      minY -= 1;
      maxY += 1;
    } else {
      final padding = (maxY - minY) * 0.2;
      minY -= padding;
      maxY += padding;
    }

    final yInterval = ((maxY - minY) / 4).clamp(0.1, double.infinity);
    final color = chartType == ChartType.ph ? ColorValues.blueProgress : ColorValues.green600;

    return Column(
      children: [
        // Chart Area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12, left: 2, top: 12),
            child: LineChart(
              transformationConfig: FlTransformationConfig(
                panEnabled: _isZoomMode,
                scaleEnabled: _isZoomMode,
                scaleAxis: FlScaleAxis.horizontal,
                transformationController: transformCtrl,
              ),
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (_) => const FlLine(strokeWidth: 0.8, color: ColorValues.neutral100),
                  getDrawingVerticalLine: (_) => const FlLine(strokeWidth: 0.8, color: ColorValues.neutral100),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: ColorValues.neutral300, width: 1),
                    left: BorderSide(color: ColorValues.neutral300, width: 1),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      reservedSize: 36,
                      getTitlesWidget: (val, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            val.toStringAsFixed(chartType == ChartType.ph ? 1 : 0),
                            style: dmSansSmallText(size: 10, weight: FontWeight.w600).copyWith(color: ColorValues.neutral500),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      // FIXED BUG: Kalkulasi interval label X yang tidak tumpang tindih
                      interval: (entries.length > 6 ? (entries.length / 5).floorToDouble() : 1.0).clamp(1.0, double.infinity),
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final idx = value.round();
                        if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                        if (value != idx.toDouble()) return const SizedBox.shrink();

                        return SideTitleWidget(
                          meta: meta,
                          space: 6,
                          child: Text(
                            DateFormat('dd/MM').format(entries[idx].date),
                            style: dmSansSmallText(size: 10, weight: FontWeight.w600).copyWith(color: ColorValues.neutral500),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => ColorValues.blackColor.withValues(alpha: 0.85),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final idx = s.spotIndex.clamp(0, entries.length - 1);
                        final e = entries[idx];
                        return LineTooltipItem(
                          '${DateFormat('dd MMM yyyy').format(e.date)}\nAvg: ${s.y.toStringAsFixed(2)}',
                          dmSansSmallText(size: 11, weight: FontWeight.w700).copyWith(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: entries.length <= 15 || _isZoomMode, // Munculkan titik saat di-zoom agar mudah di-tap
                      getDotPainter: (spot, dbl, barData, it) =>
                          FlDotCirclePainter(radius: 3.5, color: color, strokeWidth: 1.5, strokeColor: Colors.white),
                    ),
                    belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.1)),
                  ),
                ],
                clipData: const FlClipData.all(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollLockWarning({required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _isZoomMode
          ? (_) {
              Toast().showWarningToast(
                context: context,
                title: 'Zoom Mode Aktif!',
                description: "Scroll terkunci. Matikan mode 'Zooming' terlebih dahulu untuk scroll halaman.",
              );
            }
          : null,
      child: child,
    );
  }

  Widget _buildHistoryCard(HistoryEntity e) {
    final df = DateFormat('EEEE, dd MMM yyyy', '${ref.watch(localeProvider).languageCode}_${ref.watch(localeProvider).countryCode ?? ''}');

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: ColorValues.neutral100, width: 1),
        ),
        color: ColorValues.whiteColor,
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(df.format(e.date), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(color: ColorValues.green50, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      'Daily Log',
                      style: dmSansSmallText(size: 10, weight: FontWeight.w700).copyWith(color: ColorValues.green700),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(color: ColorValues.neutral100, height: 1),
              ),

              // Sensor Details Box
              Row(
                children: [
                  // pH Box
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: ColorValues.blueProgress.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ColorValues.blueProgress.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const VectorGraphic(loader: AssetBytesLoader(IconAssets.phMin), width: 14, height: 14),
                              const SizedBox(width: 4),
                              Text('pH Level', style: dmSansSmallText(size: 11, weight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(e.phAvg.toStringAsFixed(2), style: jetBrainsMonoHeadText(size: 18, color: ColorValues.blackColor)),
                          const SizedBox(height: 4),
                          Text(
                            'Min ${e.phMin.toStringAsFixed(1)} • Max ${e.phMax.toStringAsFixed(1)}',
                            style: dmSansSmallText(size: 10, weight: FontWeight.w600).copyWith(color: ColorValues.neutral500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // PPM Box
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: ColorValues.green50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ColorValues.green200.withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const VectorGraphic(loader: AssetBytesLoader(IconAssets.ppmMin), width: 16, height: 16),
                              const SizedBox(width: 4),
                              Text('PPM Level', style: dmSansSmallText(size: 11, weight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(e.ppmAvg.toStringAsFixed(0), style: jetBrainsMonoHeadText(size: 18, color: ColorValues.blackColor)),
                          const SizedBox(height: 4),
                          Text(
                            'Min ${e.ppmMin.toStringAsFixed(0)} • Max ${e.ppmMax.toStringAsFixed(0)}',
                            style: dmSansSmallText(size: 10, weight: FontWeight.w600).copyWith(color: ColorValues.neutral500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations local) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_toggle_off_rounded, color: ColorValues.warning600, size: 52),
          const SizedBox(height: 12),
          Text(local.noSensorDataFound, style: jetBrainsMonoHeadText(color: ColorValues.warning600, size: 18)),
          const SizedBox(height: 4),
          Text(
            'Try selecting a wider date range filter above.',
            style: dmSansSmallText(size: 13, weight: FontWeight.w600).copyWith(color: ColorValues.neutral500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, AppLocalizations local) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: ColorValues.danger600, size: 52),
            const SizedBox(height: 12),
            Text(local.error, style: jetBrainsMonoHeadText(color: ColorValues.danger600, size: 20)),
            const SizedBox(height: 4),
            Text(
              message.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: dmSansSmallText(size: 13, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
