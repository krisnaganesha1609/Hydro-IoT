import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydro_iot/src/dashboard/application/controllers/crop_cycle_controller.dart';
import 'package:hydro_iot/src/dashboard/data/models/edit_session_data.dart';
import 'package:hydro_iot/utils/pill_shape_rangeslider_thumb_shape.dart';
import 'package:vector_graphics/vector_graphics.dart';
import '../../../../pkg.dart';
import '../../domain/entities/plant_entity.dart';

class EditSessionModal extends ConsumerStatefulWidget {
  final String cropCycleId;
  final String device;
  final String plant;
  final String sessionName;
  final RangeValues phRange;
  final RangeValues ppmRange;
  final int expectedEnd;

  const EditSessionModal({
    super.key,
    required this.cropCycleId,
    required this.device,
    required this.plant,
    required this.sessionName,
    required this.phRange,
    required this.ppmRange,
    required this.expectedEnd,
  });

  @override
  ConsumerState<EditSessionModal> createState() => _EditSessionModalState();
}

class _EditSessionModalState extends ConsumerState<EditSessionModal> {
  late TextEditingController _nameController;
  late TextEditingController _expectedEndController;
  late TextEditingController plants;
  late TextEditingController devices;

  bool isEdited = false;

  late RangeValues _phRange;
  late RangeValues _ppmRange;

  late TextEditingController phMinController;
  late TextEditingController phMaxController;

  late TextEditingController ppmMinController;
  late TextEditingController ppmMaxController;

  ThresholdInputMode phMode = ThresholdInputMode.slider;
  ThresholdInputMode ppmMode = ThresholdInputMode.slider;

  void _saveDevice() {
    if (_nameController.text.isEmpty) {
      Toast().showErrorToast(context: context, title: 'Error', description: 'Please enter session name');
      return;
    }

    String name = _nameController.text;
    double minPH = _phRange.start;
    double maxPH = _phRange.end;
    double minPPM = _ppmRange.start;
    double maxPPM = _ppmRange.end;

    EditSessionData editedSession = EditSessionData(name: name, phMin: minPH, phMax: maxPH, ppmMin: minPPM, ppmMax: maxPPM);

    ref.read(cropCycleControllerProvider.notifier).updateCropCycleSession(widget.cropCycleId, editedSession);
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.sessionName);
    _expectedEndController = TextEditingController(text: widget.expectedEnd.toString());
    plants = TextEditingController(text: widget.plant);
    devices = TextEditingController(text: widget.device);
    _phRange = widget.phRange;
    _ppmRange = widget.ppmRange;
    phMinController = TextEditingController(text: widget.phRange.start.toStringAsFixed(1));

    phMaxController = TextEditingController(text: widget.phRange.end.toStringAsFixed(1));

    ppmMinController = TextEditingController(text: widget.ppmRange.start.round().toString());

    ppmMaxController = TextEditingController(text: widget.ppmRange.end.round().toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expectedEndController.dispose();
    plants.dispose();
    devices.dispose();
    phMinController.dispose();
    phMaxController.dispose();
    ppmMinController.dispose();
    ppmMaxController.dispose();
    super.dispose();
  }

  bool isCustomizingThreshold = false;
  bool isCustomizingPH = false;
  bool isCustomizingPPM = false;

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

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
              onPressed: isEdited
                  ? () async {
                      await showAdaptiveDialog(
                        context: context,
                        builder: (_) {
                          return alertDialog(
                            context: context,
                            title: local.discardYourChanges,
                            content: local.anyUnsavedChangesWillBeLost,
                            confirmText: local.discardChanges,
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
          title: Text(local.editSession, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
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
                          TextFormFieldComponent(
                            label: '',
                            controller: plants,
                            hintText: local.selectPlant,
                            obscureText: false,
                            readOnly: true,
                            suffixIcon: const Icon(Icons.keyboard_arrow_down_outlined),
                          ),

                          const SizedBox(height: 8),
                          TextFormFieldComponent(
                            label: local.sessionName,
                            controller: _nameController,
                            hintText: local.nameYourSession,
                            obscureText: false,
                            onChanged: (str) {
                              if (str != widget.sessionName) {
                                setState(() {
                                  isEdited = true;
                                });
                              } else {
                                setState(() {
                                  isEdited = false;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormFieldComponent(
                            label: '',
                            controller: devices,
                            hintText: local.selectDevice,
                            obscureText: false,
                            readOnly: true,
                            suffixIcon: const Icon(Icons.keyboard_arrow_down_outlined),
                          ),
                          const SizedBox(height: 8),
                          TextFormFieldComponent(
                            label: '',
                            controller: _expectedEndController,
                            hintText: local.expectedHarvestDuration,
                            obscureText: false,
                            readOnly: true,
                            suffixIcon: Padding(
                              padding: EdgeInsets.only(right: 14.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    local.days,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(color: ColorValues.neutral500, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                          Text(local.autoSetBasedOnPlantType, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColorValues.neutral500)),
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
                                                        if (widget.phRange != values) {
                                                          setState(() {
                                                            _phRange = values;
                                                            phMinController.text = values.start.toStringAsFixed(1);
                                                            phMaxController.text = values.end.toStringAsFixed(1);
                                                            isEdited = true;
                                                          });
                                                        } else {
                                                          setState(() {
                                                            _phRange = values;
                                                            phMinController.text = values.start.toStringAsFixed(1);
                                                            phMaxController.text = values.end.toStringAsFixed(1);
                                                            isEdited = false;
                                                          });
                                                        }
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
                                                phMode = phMode == ThresholdInputMode.slider ? ThresholdInputMode.manual : ThresholdInputMode.slider;
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
                                                _phRange = widget.phRange;
                                                _ppmRange = widget.ppmRange;
                                                isEdited = false;
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
                                                      min: 400,
                                                      max: 2500,
                                                      divisions: 100,
                                                      labels: RangeLabels(_ppmRange.start.round().toString(), _ppmRange.end.round().toString()),
                                                      onChanged: (RangeValues values) {
                                                        if (widget.ppmRange != values) {
                                                          setState(() {
                                                            _ppmRange = values;
                                                            ppmMinController.text = values.start.round().toString();
                                                            ppmMaxController.text = values.end.round().toString();
                                                            isEdited = true;
                                                          });
                                                        } else {
                                                          setState(() {
                                                            _ppmRange = values;
                                                            ppmMinController.text = values.start.round().toString();
                                                            ppmMaxController.text = values.end.round().toString();
                                                            isEdited = false;
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  const VectorGraphic(loader: AssetBytesLoader(IconAssets.ppmMax), width: 24, height: 24),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Text('${local.rangeAvailable}: 400 - 2500 PPM', style: Theme.of(context).textTheme.bodySmall),
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
                                                _phRange = widget.phRange;
                                                _ppmRange = widget.ppmRange;
                                                isEdited = false;
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
                                                  'Revert to auto values',
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
                          child: secondaryButton(
                            context: context,
                            onPressed: isEdited
                                ? () async {
                                    await showAdaptiveDialog(
                                      context: context,
                                      builder: (_) {
                                        return alertDialog(
                                          context: context,
                                          title: local.discardYourChanges,
                                          content: local.anyUnsavedChangesWillBeLost,
                                          confirmText: local.discardChanges,
                                          onConfirm: () {
                                            context.pop();
                                          },
                                        );
                                      },
                                    );
                                  }
                                : () {
                                    context.pop();
                                  },
                            text: local.cancel,
                            color: ColorValues.neutral200,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: primaryButton(
                            text: local.save,
                            onPressed: isEdited
                                ? () {
                                    _saveDevice();
                                  }
                                : () {},
                            context: context,
                            color: isEdited ? ColorValues.green500 : ColorValues.neutral400,
                          ),
                        ),
                      ],
                    ),
                  ),

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
