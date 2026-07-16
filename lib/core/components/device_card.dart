import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_graphics/vector_graphics.dart';
import '../../pkg.dart';
import '../../src/devices/application/providers/calibration_provider.dart';
import '../../src/devices/domain/entities/calibration_timer_entity.dart';
import '../../src/devices/presentation/screens/calibration/calibration_steps_screen.dart';
import '../../src/devices/presentation/screens/start_calibration_screen.dart';
import 'blinking_dot.dart';
import 'tooltip_shape_border.dart';

class DeviceCard extends ConsumerStatefulWidget {
  final String deviceName;
  final String serialNumber;
  final String status;
  final String ssid;
  final VoidCallback onSettingPressed;
  final bool needCalibration;

  const DeviceCard({
    super.key,
    required this.deviceName,
    required this.serialNumber,
    required this.ssid,
    required this.onSettingPressed,
    required this.status,
    required this.needCalibration,
  });

  @override
  ConsumerState<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends ConsumerState<DeviceCard> {
  bool get _isCalibrating => widget.status == getDeviceStatusText(DeviceStatus.calibrating);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(DeviceCard old) {
    super.didUpdateWidget(old);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: ColorValues.whiteColor,
        borderRadius: BorderRadius.circular(31),
        border: Border.all(color: ColorValues.neutral100),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.deviceName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Ikon warning kuning jika needsCalibration tapi belum sedang kalibrasi
                      if (widget.needCalibration && !_isCalibrating) ...[const SizedBox(width: 6), _CalibrationWarningTooltip(local: local)],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: settingButton(context: context, onPressed: widget.onSettingPressed),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Text('Serial : ${widget.serialNumber}', style: Theme.of(context).textTheme.labelSmall),
            ),
            SizedBox(height: 12.h),

            // ─── Info Row ─────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InfoCard(info: widget.ssid, withBlinkingDot: false, iconPath: IconAssets.wifi, title: 'SSID'),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: InfoCard(info: widget.status, withBlinkingDot: true, iconPath: IconAssets.device, title: local.device),
                ),
              ],
            ),

            // ─── Bottom section: kondisional berdasarkan status ───────────
            if (_isCalibrating)
              _CalibrationProgressSection(serial: widget.serialNumber)
            else if (widget.needCalibration || widget.status == getDeviceStatusText(DeviceStatus.idle))
              _CalibrateButtonSection(serialNumber: widget.serialNumber, local: local),
          ],
        ),
      ),
    );
  }
}

// ─── Tooltip ikon peringatan "Calibration Required" ─────────────────────────

class _CalibrationWarningTooltip extends StatefulWidget {
  final AppLocalizations local;
  const _CalibrationWarningTooltip({required this.local});

  @override
  State<_CalibrationWarningTooltip> createState() => _CalibrationWarningTooltipState();
}

class _CalibrationWarningTooltipState extends State<_CalibrationWarningTooltip> {
  final _tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      key: _tooltipKey,
      message: widget.local.calibrationRequired,
      triggerMode: TooltipTriggerMode.manual,
      preferBelow: false,
      decoration: const ShapeDecoration(
        shape: TooltipShapeBorder(arrowHeight: 8, arrowWidth: 16, radius: 25),
        color: ColorValues.whiteColor,
        shadows: [BoxShadow(color: ColorValues.neutral400, blurRadius: 4, offset: Offset(0, 2))],
      ),
      textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(color: ColorValues.blackColor, fontWeight: FontWeight.w600),
      child: GestureDetector(
        onTap: () => _tooltipKey.currentState?.ensureTooltipVisible(),
        child: Container(
          width: 23,
          height: 23,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(BorderSide(color: ColorValues.warning500, width: 2)),
            color: Colors.transparent,
          ),
          child: Center(
            child: Text(
              '!',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: ColorValues.warning500),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bagian progress kalibrasi aktif (tampil saat status CALIBRATING) ────────

class _CalibrationProgressSection extends ConsumerStatefulWidget {
  final String serial;
  const _CalibrationProgressSection({required this.serial});

  @override
  ConsumerState<_CalibrationProgressSection> createState() => _CalibrationProgressSectionState();
}

class _CalibrationProgressSectionState extends ConsumerState<_CalibrationProgressSection> {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    // Tick tiap detik untuk update countdown tanpa polling BE
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final sessionAsync = ref.watch(activeCalibrationSessionProvider(widget.serial));

    return Column(
      children: [
        SizedBox(height: 12.h),
        sessionAsync.when(
          loading: () => const SizedBox(height: 52, child: Center(child: CircularProgressIndicator.adaptive())),
          error: (_, __) => _buildActionRequired(local),
          data: (session) {
            final timer = session?.timer;
            if (session == null || timer == null || timer.endsAt.isBefore(DateTime.now())) {
              return _buildActionRequired(local);
            }

            final currentStep = session.timer!.step;
            final stepLabel = _stepLabel(currentStep);

            return _buildCalibrationRow(context, local, stepLabel, timer);
          },
        ),
      ],
    );
  }

  Widget _buildCalibrationRow(BuildContext context, AppLocalizations local, String stepLabel, CalibrationTimerEntity? timer) {
    final remaining = timer != null ? timer.endsAt.difference(DateTime.now()) : Duration.zero;
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    final m = clamped.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = clamped.inSeconds.remainder(60).toString().padLeft(2, '0');
    final timeText = '$m:$s';
    final isSoaking = timer != null && !remaining.isNegative;

    return Row(
      children: [
        // Step label + countdown pill
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: ColorValues.green400, width: 2),
              color: ColorValues.green50,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  stepLabel.split(' ').first,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: ColorValues.green700),
                ),
                SizedBox(width: 4.w),
                Text(stepLabel.split(' ').last, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                if (isSoaking) ...[
                  SizedBox(width: 12.w),
                  const Baseline(
                    baseline: 22,
                    baselineType: TextBaseline.alphabetic,
                    child: VectorGraphic(loader: AssetBytesLoader(IconAssets.timer), width: 12, height: 12),
                  ),
                  SizedBox(width: 4.w),
                  Text(timeText, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: 8.w),
        // View button → resume langsung ke CalibrationStepsScreen
        SizedBox(
          child: primaryButton(
            text: local.view,
            context: context,
            color: ColorValues.green600,
            onPressed: () async {
              await context.push('/${CalibrationStepsScreen.path}', extra: {'serialNumber': widget.serial});
              // Setelah kembali dari halaman kalibrasi, invalidate provider
              // supaya card ini refetch status session terbaru
              if (mounted) {
                ref.invalidate(activeCalibrationSessionProvider(widget.serial));
              }
            },
          ),
        ),
      ],
    );
  }

  /// Fallback saat session null atau error — tampilkan "Action Required" + View button
  /// seperti di mockup Case 2.
  Widget _buildActionRequired(AppLocalizations local) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: ColorValues.green400, width: 2),
              color: ColorValues.green50,
            ),
            child: Text(
              local.actionRequired,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        SizedBox(
          width: widthQuery(context) * 0.23,
          child: primaryButton(
            text: local.view,
            context: context,
            buttonType: ButtonType.large,
            color: ColorValues.green600,
            onPressed: () async {
              await context.push('/${CalibrationStepsScreen.path}', extra: {'serialNumber': widget.serial});
              if (mounted) ref.invalidate(activeCalibrationSessionProvider(widget.serial));
            },
          ),
        ),
      ],
    );
  }

  String _stepLabel(String action) {
    return switch (action) {
      'cal7' || 'enter_cal' => 'pH 7.0',
      'cal4' => 'pH 4.0',
      'calc' => 'Saving pH',
      'cal500' => 'PPM 500',
      'cal1000' => 'PPM 1000',
      'cal1382' => 'PPM 1382',
      'calctds' => 'Saving PPM',
      _ => action,
    };
  }
}

// ─── Tombol Calibrate Device (tampil saat idle/needsCalibration tapi tidak calibrating) ──

class _CalibrateButtonSection extends StatelessWidget {
  final String serialNumber;
  final AppLocalizations local;
  const _CalibrateButtonSection({required this.serialNumber, required this.local});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: primaryButton(
            text: local.calibrateDevice,
            buttonType: ButtonType.large,
            context: context,
            onPressed: () {
              context.push('/${StartCalibrationScreen.path}', extra: {'serialNumber': serialNumber});
            },
            color: ColorValues.green600,
          ),
        ),
      ],
    );
  }
}

// ─── InfoCard (tidak ada perubahan, + tambahan warna CALIBRATING) ────────────

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.info, required this.withBlinkingDot, required this.iconPath, required this.title});

  final String title;
  final String info;
  final bool withBlinkingDot;
  final String iconPath;

  Color _statusColor() {
    if (info == getDeviceStatusText(DeviceStatus.active)) return ColorValues.success700;
    if (info == getDeviceStatusText(DeviceStatus.idle)) return ColorValues.blueProgress;
    if (info == getDeviceStatusText(DeviceStatus.calibrating)) return ColorValues.blueProgress;
    return ColorValues.danger700;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: ColorValues.neutral100, borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: ColorValues.green400, width: 2),
                  ),
                  child: Center(
                    child: withBlinkingDot
                        ? Stack(
                            children: [
                              VectorGraphic(loader: AssetBytesLoader(iconPath), width: 16, height: 16),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: BlinkingDot(size: 5, color: _statusColor(), duration: const Duration(milliseconds: 800)),
                              ),
                            ],
                          )
                        : VectorGraphic(loader: AssetBytesLoader(iconPath), width: 16, height: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              info,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: withBlinkingDot ? _statusColor() : ColorValues.blackColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
