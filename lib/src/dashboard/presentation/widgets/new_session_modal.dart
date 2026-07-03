import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydro_iot/core/components/fancy_loading.dart';
import 'package:hydro_iot/pkg.dart';
import 'package:hydro_iot/src/dashboard/application/controllers/crop_cycle_controller.dart';
import 'package:hydro_iot/src/dashboard/application/controllers/plant_controller.dart';
import 'package:hydro_iot/src/dashboard/data/models/session_data.dart';
import 'package:hydro_iot/src/dashboard/domain/entities/plant_entity.dart';
import 'package:hydro_iot/src/devices/application/controllers/devices_controller.dart';
import 'package:hydro_iot/src/devices/domain/entities/device_entity.dart';
import 'package:hydro_iot/utils/pill_shape_rangeslider_thumb_shape.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:vector_graphics/vector_graphics.dart';

class SessionModal extends ConsumerStatefulWidget {
  final Function(SessionData) onSessionAdded;

  const SessionModal({super.key, required this.onSessionAdded});

  @override
  ConsumerState<SessionModal> createState() => _SessionModalState();
}

class _SessionModalState extends ConsumerState<SessionModal> {
  late TextEditingController _nameController;

  late RangeValues _phRange;
  late RangeValues _ppmRange;

  late TextEditingController phMinController;
  late TextEditingController phMaxController;

  late TextEditingController ppmMinController;
  late TextEditingController ppmMaxController;

  ThresholdInputMode phMode = ThresholdInputMode.slider;
  ThresholdInputMode ppmMode = ThresholdInputMode.slider;

  AsyncValue<List<PlantEntity>> get plantTypes => ref.watch(plantControllerProvider);
  AsyncValue<List<DeviceEntity>> get devices => ref.watch(devicesControllerProvider);

  bool isEntriesValid() {
    return _nameController.text.isNotEmpty && devicesController.selectedItems.isNotEmpty && plantsController.selectedItems.isNotEmpty;
  }

  bool isFilled() {
    return _nameController.text.isNotEmpty || devicesController.selectedItems.isNotEmpty || plantsController.selectedItems.isNotEmpty;
  }

  void _saveDevice() {
    if (!isEntriesValid()) {
      Toast().showErrorToast(context: context, title: 'Error', description: 'Please fill all fields');
      return;
    }

    String deviceId = devicesController.selectedItems.first.value.id;
    String name = _nameController.text;
    String plantId = plantsController.selectedItems.first.value.id;
    double minPH = _phRange.start;
    double maxPH = _phRange.end;
    double minPPM = _ppmRange.start;
    double maxPPM = _ppmRange.end;

    SessionData newSession = SessionData(
      deviceId: deviceId,
      plantId: plantId,
      name: name,
      phMin: minPH,
      phMax: maxPH,
      ppmMin: minPPM,
      ppmMax: maxPPM,
      expectedEnd: 30,
    );

    ref.read(cropCycleControllerProvider.notifier).addCropCycleSession(newSession);
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phRange = const RangeValues(0, 0);
    _ppmRange = const RangeValues(0, 0);
    phMinController = TextEditingController(text: _phRange.start.toStringAsFixed(1));

    phMaxController = TextEditingController(text: _phRange.end.toStringAsFixed(1));

    ppmMinController = TextEditingController(text: _ppmRange.start.round().toString());

    ppmMaxController = TextEditingController(text: _ppmRange.end.round().toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    plantsController.dispose();
    devicesController.dispose();
    phMinController.dispose();
    phMaxController.dispose();
    ppmMinController.dispose();
    ppmMaxController.dispose();
    super.dispose();
  }

  final plantsController = MultiSelectController<PlantEntity>();
  final devicesController = MultiSelectController<DeviceEntity>();

  bool isCustomizingThreshold = false;
  bool isCustomizingPH = false;
  bool isCustomizingPPM = false;

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final action = ref.watch(cropCycleControllerProvider.notifier).action;
    ref.listen<AsyncValue<void>>(cropCycleControllerProvider, (previous, next) {
      next.whenOrNull(
        loading: () {
          if (action == CropCycleAction.add) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => FancyLoadingDialog(title: local.addingCropCycleSession),
            );
          }
        },
        error: (error, stackTrace) {
          context.pop();
          Toast().showErrorToast(context: context, title: 'Error', description: error.toString().replaceAll('Exception: ', ''));
        },
        data: (_) {
          if (action == CropCycleAction.add) {
            context.pop();
            Toast().showSuccessToast(context: context, title: local.success, description: local.cropCycleAdded);
            SessionData sessionData = SessionData(
              deviceId: devicesController.selectedItems.first.value.id,
              plantId: plantsController.selectedItems.first.value.id,
              name: _nameController.text,
              phMin: _phRange.start,
              phMax: _phRange.end,
              ppmMin: _ppmRange.start,
              ppmMax: _ppmRange.end,
              expectedEnd: plantsController.selectedItems.first.value.expectedDurationDays ?? 30,
            );
            widget.onSessionAdded(sessionData);
            context.pop();
          }
        },
      );
    });
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
              onPressed: isFilled()
                  ? () async {
                      await showAdaptiveDialog(
                        context: context,
                        builder: (_) {
                          return alertDialog(
                            context: context,
                            title: local.discardYourEntries,
                            content: local.anyUnsavedEntriesWillBeLost,
                            confirmText: local.discardEntries,
                            onConfirm: () {
                              context.pop();
                            },
                          );
                        },
                      );
                    }
                  : context.pop,
            ),
          ),
          title: Text(local.newSession, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: devices.isLoading || plantTypes.isLoading
            ? Center(child: FancyLoading(title: local.loadingDevice.split(' ')[0]))
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: ColorValues.blueProgress,
                      inactiveTrackColor: ColorValues.neutral200,
                      thumbColor: ColorValues.blueProgress.withValues(alpha: 0.5),
                      valueIndicatorColor: ColorValues.whiteColor,
                      valueIndicatorTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ColorValues.blackColor),
                      rangeThumbShape: PillRangeThumbShape(width: 35, height: 15),
                      rangeTickMarkShape: const RoundRangeSliderTickMarkShape(tickMarkRadius: 0),
                      rangeValueIndicatorShape: const RectangularRangeSliderValueIndicatorShape(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(33),
                            side: const BorderSide(color: ColorValues.neutral100, width: 1),
                          ),
                          color: ColorValues.whiteColor,
                          elevation: 0,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                            child: Column(
                              children: [
                                devices.when(
                                  data: (data) {
                                    return MultiDropdown<DeviceEntity>(
                                      items: data.map((device) => DropdownItem(label: device.name, value: device)).toList(),
                                      controller: devicesController,
                                      enabled: true,
                                      singleSelect: true,
                                      itemSeparator: null,
                                      onSelectionChange: (selectedItems) => setState(() {}),
                                      fieldDecoration: FieldDecoration(
                                        hintText: local.selectDevice,
                                        hintStyle: Theme.of(context).textTheme.bodyMedium,
                                        showClearIcon: false,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(40),
                                          borderSide: const BorderSide(color: ColorValues.neutral400),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(40),
                                          borderSide: const BorderSide(color: ColorValues.neutral400),
                                        ),
                                        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                                      ),
                                      dropdownDecoration: DropdownDecoration(
                                        marginTop: 2,
                                        maxHeight: heightQuery(context) * 0.3,
                                        backgroundColor: ColorValues.whiteColor,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      dropdownItemDecoration: const DropdownItemDecoration(
                                        selectedIcon: null,
                                        textColor: ColorValues.blackColor,
                                        selectedTextColor: ColorValues.blackColor,
                                        selectedBackgroundColor: ColorValues.green100,
                                      ),
                                    );
                                  },
                                  error: (error, stackTrace) {
                                    return Text('Error: $error');
                                  },
                                  loading: () {
                                    return const SizedBox.shrink();
                                  },
                                ),
                                const SizedBox(height: 8),
                                TextFormFieldComponent(
                                  label: local.sessionName,
                                  controller: _nameController,
                                  hintText: local.nameYourSession,
                                  obscureText: false,
                                ),
                                const SizedBox(height: 8),
                                plantTypes.when(
                                  data: (data) {
                                    debugPrint('Plant types loaded: $data');
                                    debugPrint('Test plants: ${data.map((plant) => DropdownItem(label: plant.name, value: plant)).toList()}');
                                    return MultiDropdown<PlantEntity>(
                                      items: data.map((plant) => DropdownItem(label: plant.name, value: plant)).toList(),
                                      controller: plantsController,
                                      enabled: true,
                                      singleSelect: true,
                                      itemSeparator: null,
                                      onSelectionChange: (selectedItems) {
                                        setState(() {
                                          // Update UI based on selected plant
                                          if (selectedItems.isNotEmpty) {
                                            final selectedPlant = selectedItems.first;
                                            _phRange = RangeValues(selectedPlant.phMin ?? 0.0, selectedPlant.phMax ?? 14.0);
                                            _ppmRange = RangeValues(
                                              selectedPlant.ppmMin?.toDouble() ?? 500,
                                              selectedPlant.ppmMax?.toDouble() ?? 2500,
                                            );
                                            phMinController.text = _phRange.start.toStringAsFixed(1);

                                            phMaxController.text = _phRange.end.toStringAsFixed(1);

                                            ppmMinController.text = _ppmRange.start.round().toString();

                                            ppmMaxController.text = _ppmRange.end.round().toString();
                                          } else {
                                            _phRange = const RangeValues(0, 0);
                                            _ppmRange = const RangeValues(500, 2500);
                                          }
                                        });
                                      },
                                      fieldDecoration: FieldDecoration(
                                        hintText: local.selectPlant,
                                        hintStyle: Theme.of(context).textTheme.bodyMedium,
                                        showClearIcon: false,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(40),
                                          borderSide: const BorderSide(color: ColorValues.neutral400),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(40),
                                          borderSide: const BorderSide(color: ColorValues.neutral400),
                                        ),
                                        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                                      ),
                                      dropdownDecoration: DropdownDecoration(
                                        marginTop: 2,
                                        maxHeight: heightQuery(context) * 0.3,
                                        backgroundColor: ColorValues.whiteColor,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      dropdownItemDecoration: const DropdownItemDecoration(
                                        selectedIcon: null,
                                        textColor: ColorValues.blackColor,
                                        selectedTextColor: ColorValues.blackColor,
                                        selectedBackgroundColor: ColorValues.green100,
                                      ),
                                    );
                                  },
                                  error: (error, stackTrace) {
                                    return Text('Error: $error');
                                  },
                                  loading: () {
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (devicesController.selectedItems.isNotEmpty && plantsController.selectedItems.isNotEmpty) ...[
                          Card(
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
                                  Text(local.thresholdSettings, style: Theme.of(context).textTheme.titleMedium),
                                  Text(
                                    local.autoSetBasedOnPlantType,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColorValues.neutral500),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _SensorCard(
                                          'pH',
                                          '${_phRange.start.toStringAsFixed(1)} - ${_phRange.end.toStringAsFixed(1)}',
                                          !isCustomizingThreshold ? null : isCustomizingPH,
                                          () {
                                            setState(() {
                                              isCustomizingThreshold = true;
                                              isCustomizingPH = true;
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: _SensorCard(
                                          'PPM',
                                          '${_ppmRange.start.toStringAsFixed(0)} - ${_ppmRange.end.toStringAsFixed(0)}',
                                          !isCustomizingThreshold ? null : !isCustomizingPH,
                                          () {
                                            setState(() {
                                              isCustomizingThreshold = true;
                                              isCustomizingPH = false;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  isCustomizingThreshold
                                      ? isCustomizingPH
                                            ? Column(
                                                children: [
                                                  Card(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(43),
                                                      side: const BorderSide(color: ColorValues.neutral100, width: 1),
                                                    ),
                                                    elevation: 0,
                                                    color: ColorValues.whiteColor,
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          const VectorGraphic(loader: AssetBytesLoader(IconAssets.phMin), width: 18, height: 18),
                                                          Expanded(
                                                            child: RangeSlider(
                                                              values: _phRange,
                                                              min: 0.0,
                                                              max: 14.0,
                                                              divisions: 28,
                                                              labels: RangeLabels(_phRange.start.toStringAsFixed(1), _phRange.end.toStringAsFixed(1)),
                                                              onChanged: (RangeValues values) {
                                                                setState(() {
                                                                  _phRange = values;

                                                                  phMinController.text = values.start.toStringAsFixed(1);

                                                                  phMaxController.text = values.end.toStringAsFixed(1);
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          const VectorGraphic(loader: AssetBytesLoader(IconAssets.phMax), width: 18, height: 18),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Text('${local.rangeAvailable}: 0.0 - 14.0 pH', style: Theme.of(context).textTheme.bodySmall),
                                                  const SizedBox(height: 8),

                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        phMode = phMode == ThresholdInputMode.slider
                                                            ? ThresholdInputMode.manual
                                                            : ThresholdInputMode.slider;
                                                      });
                                                    },
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          phMode == ThresholdInputMode.manual ? Icons.keyboard_arrow_up : Icons.edit_outlined,
                                                          color: ColorValues.blueLink,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          phMode == ThresholdInputMode.manual ? local.hideManualInput : local.manualInput,
                                                          style: Theme.of(
                                                            context,
                                                          ).textTheme.bodySmall?.copyWith(color: ColorValues.blueLink, fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  AnimatedSwitcher(
                                                    duration: const Duration(milliseconds: 250),
                                                    child: phMode != ThresholdInputMode.manual
                                                        ? const SizedBox.shrink()
                                                        : Padding(
                                                            padding: const EdgeInsets.only(top: 12),
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child: TextFormFieldComponent(
                                                                    label: 'Min pH',
                                                                    controller: phMinController,
                                                                    hintText: '0.0',
                                                                    obscureText: false,
                                                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),

                                                                    onChanged: (value) {
                                                                      final min = double.tryParse(value);

                                                                      if (min == null) return;

                                                                      if (min >= 0 && min <= _phRange.end && min <= 14) {
                                                                        setState(() {
                                                                          _phRange = RangeValues(min, _phRange.end);
                                                                        });
                                                                      }
                                                                    },
                                                                  ),
                                                                ),

                                                                SizedBox(width: 12.w),

                                                                Expanded(
                                                                  child: TextFormFieldComponent(
                                                                    label: 'Max pH',
                                                                    controller: phMaxController,
                                                                    hintText: '14.0',
                                                                    obscureText: false,
                                                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),

                                                                    onChanged: (value) {
                                                                      final max = double.tryParse(value);

                                                                      if (max == null) return;

                                                                      if (max <= 14 && max >= _phRange.start) {
                                                                        setState(() {
                                                                          _phRange = RangeValues(_phRange.start, max);
                                                                        });
                                                                      }
                                                                    },
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        isCustomizingThreshold = false;
                                                        isCustomizingPH = false;
                                                      });
                                                    },
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const RotationTransition(
                                                          turns: AlwaysStoppedAnimation(180 / 360),
                                                          child: VectorGraphic(
                                                            loader: AssetBytesLoader(IconAssets.moreInfo),
                                                            width: 16,
                                                            height: 16,
                                                            colorFilter: ColorFilter.mode(ColorValues.blueLink, BlendMode.srcIn),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 5),
                                                        Text(
                                                          local.revertToAutoValues,
                                                          style: Theme.of(
                                                            context,
                                                          ).textTheme.bodySmall?.copyWith(color: ColorValues.blueLink, fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Column(
                                                children: [
                                                  Card(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(43),
                                                      side: const BorderSide(color: ColorValues.neutral100, width: 1),
                                                    ),
                                                    elevation: 0,
                                                    color: ColorValues.whiteColor,
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          const VectorGraphic(loader: AssetBytesLoader(IconAssets.ppmMin), width: 24, height: 24),
                                                          Expanded(
                                                            child: RangeSlider(
                                                              values: _ppmRange,
                                                              min: 500,
                                                              max: 2500,
                                                              divisions: 100,
                                                              labels: RangeLabels(
                                                                _ppmRange.start.round().toString(),
                                                                _ppmRange.end.round().toString(),
                                                              ),
                                                              onChanged: (RangeValues values) {
                                                                setState(() {
                                                                  _ppmRange = values;

                                                                  ppmMinController.text = values.start.round().toString();

                                                                  ppmMaxController.text = values.end.round().toString();
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          const VectorGraphic(loader: AssetBytesLoader(IconAssets.ppmMax), width: 24, height: 24),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Text('${local.rangeAvailable}: 500 - 2500 PPM', style: Theme.of(context).textTheme.bodySmall),
                                                  const SizedBox(height: 8),

                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        ppmMode = ppmMode == ThresholdInputMode.slider
                                                            ? ThresholdInputMode.manual
                                                            : ThresholdInputMode.slider;
                                                      });
                                                    },
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          ppmMode == ThresholdInputMode.manual ? Icons.keyboard_arrow_up : Icons.edit_outlined,
                                                          color: ColorValues.blueLink,
                                                          size: 18,
                                                        ),

                                                        const SizedBox(width: 4),

                                                        Text(
                                                          ppmMode == ThresholdInputMode.manual ? local.hideManualInput : local.manualInput,
                                                          style: Theme.of(
                                                            context,
                                                          ).textTheme.bodySmall?.copyWith(color: ColorValues.blueLink, fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  AnimatedSwitcher(
                                                    duration: const Duration(milliseconds: 250),

                                                    child: ppmMode != ThresholdInputMode.manual
                                                        ? const SizedBox.shrink()
                                                        : Padding(
                                                            padding: const EdgeInsets.only(top: 12),

                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child: TextFormFieldComponent(
                                                                    label: 'Min PPM',
                                                                    controller: ppmMinController,
                                                                    hintText: '500',
                                                                    obscureText: false,
                                                                    keyboardType: TextInputType.number,

                                                                    onChanged: (value) {
                                                                      final min = double.tryParse(value);

                                                                      if (min == null) return;

                                                                      if (min >= 500 && min <= _ppmRange.end && min <= 2500) {
                                                                        setState(() {
                                                                          _ppmRange = RangeValues(min, _ppmRange.end);
                                                                        });
                                                                      }
                                                                    },
                                                                  ),
                                                                ),

                                                                SizedBox(width: 12.w),

                                                                Expanded(
                                                                  child: TextFormFieldComponent(
                                                                    label: 'Max PPM',
                                                                    controller: ppmMaxController,
                                                                    hintText: '2500',
                                                                    obscureText: false,
                                                                    keyboardType: TextInputType.number,

                                                                    onChanged: (value) {
                                                                      final max = double.tryParse(value);

                                                                      if (max == null) return;

                                                                      if (max <= 2500 && max >= _ppmRange.start) {
                                                                        setState(() {
                                                                          _ppmRange = RangeValues(_ppmRange.start, max);
                                                                        });
                                                                      }
                                                                    },
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        isCustomizingThreshold = false;
                                                        isCustomizingPH = false;

                                                        if (plantsController.selectedItems.isNotEmpty) {
                                                          final selectedPlant = plantsController.selectedItems.first.value;
                                                          _phRange = RangeValues(selectedPlant.phMin ?? 0.0, selectedPlant.phMax ?? 14.0);
                                                          _ppmRange = RangeValues(
                                                            selectedPlant.ppmMin?.toDouble() ?? 500,
                                                            selectedPlant.ppmMax?.toDouble() ?? 2500,
                                                          );
                                                        } else {
                                                          _phRange = const RangeValues(0, 0);
                                                          _ppmRange = const RangeValues(500, 2500);
                                                        }
                                                      });
                                                    },
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const RotationTransition(
                                                          turns: AlwaysStoppedAnimation(180 / 360),
                                                          child: VectorGraphic(
                                                            loader: AssetBytesLoader(IconAssets.moreInfo),
                                                            width: 16,
                                                            height: 16,
                                                            colorFilter: ColorFilter.mode(ColorValues.blueLink, BlendMode.srcIn),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 5),
                                                        Text(
                                                          local.revertToAutoValues,
                                                          style: Theme.of(
                                                            context,
                                                          ).textTheme.bodySmall?.copyWith(color: ColorValues.blueLink, fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )
                                      : GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              isCustomizingThreshold = true;
                                              isCustomizingPH = true;
                                            });
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                local.customizeValues,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(color: ColorValues.blueLink, fontWeight: FontWeight.w600),
                                              ),
                                              const VectorGraphic(
                                                loader: AssetBytesLoader(IconAssets.moreInfo),
                                                width: 16,
                                                height: 16,
                                                colorFilter: ColorFilter.mode(ColorValues.blueLink, BlendMode.srcIn),
                                              ),
                                            ],
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: cancelButton(
                                    context: context,
                                    onPressed: () async {
                                      await showAdaptiveDialog(
                                        context: context,
                                        builder: (_) {
                                          return alertDialog(
                                            context: context,
                                            title: local.discardYourEntries,
                                            content: local.anyUnsavedEntriesWillBeLost,
                                            confirmText: local.discardEntries,
                                            onConfirm: () {
                                              context.pop();
                                            },
                                          );
                                        },
                                      );
                                    },
                                    textColor: ColorValues.green900,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  flex: 2,
                                  child: primaryButton(
                                    text: local.save,
                                    onPressed: () {
                                      _saveDevice();
                                    },
                                    context: context,
                                    color: ColorValues.green500,
                                    textColor: ColorValues.green900,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Add Session Button
                        ] else
                          const SizedBox.shrink(),

                        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard(this.sensorType, this.sensorRange, this.isActive, this.onTap);

  final String sensorType;
  final String sensorRange;
  final bool? isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isActive == true ? ColorValues.blueProgress : Colors.transparent, width: 2),
        ),
        color: ColorValues.green50,
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sensorType, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(sensorRange, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
