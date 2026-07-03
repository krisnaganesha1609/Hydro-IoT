import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydro_iot/core/components/blinking_dot.dart';
import 'package:hydro_iot/core/components/pulsing_harvest_button_widget.dart' show PulsingHarvestButton;
import 'package:hydro_iot/core/components/rolling_text.dart';
import 'package:hydro_iot/src/websocket/application/controller/sensor_websocket_controller.dart';
import 'package:hydro_iot/src/websocket/domain/entities/sensor_socket_entity.dart';
import 'package:hydro_iot/utils/border_progress_paint.dart';
import 'package:intl/intl.dart';
import 'package:vector_graphics/vector_graphics.dart';

import '../../../../../pkg.dart';

// ignore: must_be_immutable
class CropCycleCard extends ConsumerWidget {
  CropCycleCard({
    super.key,
    required this.deviceSerialNumber,
    required this.onEditPressed,
    required this.cropCycleName,
    required this.cropCycleType,
    required this.plantedAt,
    required this.phValue,
    required this.ppmValue,
    required this.phRangeValue,
    required this.ppmRangeValue,
    required this.deviceStatus,
    required this.deviceName,
    required this.progressDay,
    required this.totalDay,
    required this.onHistoryPressed,
    required this.onHarvestPressed,
  });
  final VoidCallback onEditPressed;
  final VoidCallback onHistoryPressed;
  final VoidCallback onHarvestPressed;
  final String cropCycleName;
  final String cropCycleType;
  final DateTime plantedAt;
  final String phValue;
  final String ppmValue;
  final String phRangeValue;
  final String ppmRangeValue;
  final String deviceStatus;
  final String deviceName;
  final int progressDay;
  final int totalDay;
  final String deviceSerialNumber;

  bool isViewDayProgress = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = AppLocalizations.of(context)!;
    final String plantedAtFormatted = DateFormat.yMMMd().format(plantedAt);
    AsyncValue<SensorSocketEntity> websocket = ref.watch(sensorWebsocketControllerProvider(deviceSerialNumber)).sensorData;

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
            Row(
              children: [
                Expanded(
                  child: Text(cropCycleName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: editButton(context: context, onPressed: onEditPressed),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(cropCycleType, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(width: 15, height: 3, child: VectorGraphic(loader: AssetBytesLoader(IconAssets.dot))),
                Text(
                  '${local.plantedAt} $plantedAtFormatted',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ColorValues.neutral500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      websocket.when(
                        data: (data) {
                          log('Received pH data: $data');
                          return SensorCard(
                            sensorType: 'pH',
                            icon: IconAssets.ph,
                            value: data.ph.toStringAsFixed(2),
                            rangeValue: phRangeValue,
                            decimalCount: 2,
                          );
                        },
                        error: (error, stackTrace) {
                          log('Error fetching pH value: $error');
                          return SensorCard(sensorType: 'pH', icon: IconAssets.ph, value: 'Error', rangeValue: phRangeValue, decimalCount: 2);
                        },
                        loading: () {
                          return SensorCard(sensorType: 'pH', icon: IconAssets.ph, value: 'Loading...', rangeValue: phRangeValue, decimalCount: 2);
                        },
                      ),
                      const SizedBox(height: 6),
                      websocket.when(
                        data: (data) {
                          log('Received PPM data: $data');
                          return SensorCard(
                            sensorType: 'PPM',
                            icon: IconAssets.ppm,
                            value: data.ppm.toStringAsFixed(0),
                            rangeValue: ppmRangeValue,
                            decimalCount: 0,
                          );
                        },
                        error: (error, stackTrace) {
                          log('Error fetching PPM value: $error');
                          return SensorCard(sensorType: 'PPM', icon: IconAssets.ppm, value: 'Error', rangeValue: ppmRangeValue, decimalCount: 0);
                        },
                        loading: () {
                          return SensorCard(sensorType: 'PPM', icon: IconAssets.ppm, value: 'Loading...', rangeValue: ppmRangeValue, decimalCount: 0);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StatefulBuilder(
                        builder: (context, setState) {
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            child: isViewDayProgress
                                ? GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isViewDayProgress = !isViewDayProgress;
                                      });
                                    },
                                    child: DayProgressBorder(currentDay: progressDay, totalDays: totalDay),
                                  )
                                : GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isViewDayProgress = !isViewDayProgress;
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(flex: 3, child: PlantDayCounter(progressDay: progressDay.toString())),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          flex: 5,
                                          child: websocket.when(
                                            data: (data) {
                                              return WaterTemp(temp: data.temperature.toStringAsFixed(0));
                                            },
                                            error: (error, stacktrace) {
                                              return const WaterTemp(temp: 'Error');
                                            },
                                            loading: () {
                                              return const WaterTemp(temp: '0');
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      DeviceStatusCard(status: deviceStatus, deviceName: deviceName, isViewDayProgress: isViewDayProgress),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 4,
                            child: historyButton(context: context, onPressed: onHistoryPressed),
                          ),
                          const Spacer(),
                          Expanded(
                            flex: 10,
                            child: PulsingHarvestButton(
                              isReadyToHarvest: progressDay >= totalDay,
                              tooltipMessage: 'Tanaman sudah mencapai $progressDay hari & siap dipanen! 🌱',
                              child: harvestButton(context: context, onPressed: onHarvestPressed),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.sensorType,
    required this.icon,
    required this.value,
    required this.rangeValue,
    required this.decimalCount,
  });
  final String sensorType;
  final String icon;
  final String value;
  final String rangeValue;
  final int decimalCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: ColorValues.neutral100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(sensorType, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: VectorGraphic(loader: AssetBytesLoader(icon), width: 16, height: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            RollingNumberText(
              value: double.tryParse(value) ?? 0.0,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              duration: const Duration(milliseconds: 1000),
              decimalCount: decimalCount,
            ),
            const SizedBox(height: 4),
            Text('Ideal: $rangeValue', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ColorValues.neutral500)),
          ],
        ),
      ),
    );
  }
}

class PlantDayCounter extends StatelessWidget {
  const PlantDayCounter({super.key, required this.progressDay});

  final String progressDay;

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
      decoration: BoxDecoration(color: ColorValues.neutral100, borderRadius: BorderRadius.circular(15)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            local.day,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: ColorValues.green900),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              progressDay,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: ColorValues.green900),
            ),
          ),
        ],
      ),
    );
  }
}

class WaterTemp extends StatelessWidget {
  const WaterTemp({super.key, required this.temp});

  final String temp;

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
      decoration: BoxDecoration(color: ColorValues.neutral100, borderRadius: BorderRadius.circular(15)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            local.waterTemp,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: ColorValues.green900),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '$temp°C',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: ColorValues.green900),
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceStatusCard extends StatelessWidget {
  const DeviceStatusCard({super.key, required this.status, required this.deviceName, required this.isViewDayProgress});
  final String status;
  final String deviceName;
  final bool isViewDayProgress;

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      color: ColorValues.neutral100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(local.device, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: status == getDeviceStatusText(DeviceStatus.active)
                              ? ColorValues.success700
                              : status == getDeviceStatusText(DeviceStatus.idle)
                              ? ColorValues.blueProgress
                              : ColorValues.danger700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
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
                    child: Stack(
                      children: [
                        const VectorGraphic(loader: AssetBytesLoader(IconAssets.device), width: 16, height: 16),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: BlinkingDot(
                            size: 5,
                            color: status == getDeviceStatusText(DeviceStatus.active)
                                ? ColorValues.success700
                                : status == getDeviceStatusText(DeviceStatus.idle)
                                ? ColorValues.blueProgress
                                : ColorValues.danger700,
                            duration: const Duration(milliseconds: 800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isViewDayProgress ? heightQuery(context) * 0.06 : heightQuery(context) * 0.04),
            Text(deviceName, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class DayProgressBorder extends StatefulWidget {
  final int currentDay;
  final int totalDays;

  const DayProgressBorder({super.key, required this.currentDay, required this.totalDays});

  @override
  State<DayProgressBorder> createState() => _DayProgressBorderState();
}

class _DayProgressBorderState extends State<DayProgressBorder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    final targetProgress = widget.currentDay / widget.totalDays;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (targetProgress * 6000).toInt()),
    );

    _progressAnimation = Tween<double>(begin: 0, end: targetProgress).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          painter: FluidProgressPainter(
            progress: _progressAnimation.value,
            waveOffset: _waveAnimation.value,
            isFinished: _progressAnimation.value >= widget.currentDay / widget.totalDays,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
            decoration: BoxDecoration(color: ColorValues.neutral100, borderRadius: BorderRadius.circular(21)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('${local.day} ${widget.currentDay}', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text('${local.oof} ${widget.totalDays}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: ColorValues.neutral500)),
              ],
            ),
          ),
        );
      },
    );
  }
}
