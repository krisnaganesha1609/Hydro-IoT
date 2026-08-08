import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydro_iot/core/components/crop_cycle_card.dart';
import 'package:hydro_iot/core/core.dart';
import 'package:hydro_iot/l10n/app_localizations.dart';
import 'package:hydro_iot/res/res.dart';
import 'package:hydro_iot/src/auth/application/controllers/user_controller.dart';
import 'package:hydro_iot/src/dashboard/application/controllers/crop_cycle_controller.dart';
import 'package:hydro_iot/src/dashboard/application/providers/filter_devices_providers.dart';
import 'package:hydro_iot/src/dashboard/presentation/screens/search_crop_cycle_screen.dart';
import 'package:hydro_iot/core/components/screen_header.dart';
import 'package:hydro_iot/src/dashboard/presentation/widgets/edit_session_modal.dart';
import 'package:hydro_iot/src/dashboard/presentation/widgets/new_session_modal.dart';
import 'package:hydro_iot/core/components/animated_refresh_button_widget.dart';
import 'package:hydro_iot/utils/utils.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../devices/application/controllers/devices_controller.dart';
import '../../application/providers/crop_cycle_providers.dart';
import '../../application/state/crop_cycle_state.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  static const String path = 'dashboard';

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final ScrollController _scrollController;

  PlantStatus? get filterPlants => ref.watch(filterCropCycleProvider);

  static const _status = 'ongoing';
  static const _active = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cropCycleNotifierProvider.notifier).fetchCropCycles(_status, _active);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(cropCycleNotifierProvider.notifier).loadMore(_status, _active);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userControllerProvider, (previous, next) {
      final wasLoggedIn = previous?.asData?.value != null;
      final isNowNull = next.asData?.value == null && !next.isLoading;

      if (wasLoggedIn && isNowNull) {
        infoDialog(
          context: context,
          title: 'Session Expired',
          content: 'Your session has expired. Please log in again.',
          onConfirm: () => context.pushReplacement('/${AuthScreen.path}'),
          confirmText: 'Go to Login',
        );
      }
    });

    final local = AppLocalizations.of(context)!;
    final cropCycleState = ref.watch(cropCycleNotifierProvider);
    final userProvider = ref.watch(userControllerProvider);

    ref.listen(cropCycleControllerProvider, (previous, next) {
      final action = ref.watch(cropCycleControllerProvider.notifier).action;
      next.whenOrNull(
        error: (err, _) {
          context.pop();
          final errorMessage = (err as Exception).toString().replaceAll('Exception: ', '');
          if (context.mounted) {
            context.pop();
            Toast().showErrorToast(context: context, title: local.error, description: errorMessage);
          }
        },
        loading: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => FancyLoadingDialog(
              title: action == CropCycleAction.add
                  ? local.addingCropCycleSession
                  : action == CropCycleAction.update
                  ? local.updatingCropCycleSession
                  : action == CropCycleAction.end
                  ? local.harvested
                  : local.loadingCropCycles,
            ),
          );
        },
        data: (u) {
          if (action != CropCycleAction.none && context.mounted) {
            context.pop();
            if (action == CropCycleAction.add || action == CropCycleAction.update) {
              if (context.mounted) context.pop();
            }
            Toast().showSuccessToast(
              context: context,
              title: local.success,
              description: action == CropCycleAction.add
                  ? local.cropCycleAdded
                  : action == CropCycleAction.update
                  ? local.cropCycleUpdated
                  : action == CropCycleAction.end
                  ? local.harvested
                  : local.loadingCropCycles,
            );

            ref.read(cropCycleNotifierProvider.notifier).fetchCropCycles(_status, _active);

            ref.read(devicesControllerProvider.notifier).fetchDevices();
          }
        },
      );
    });

    return Skeletonizer(
      enabled: cropCycleState.isLoading || userProvider.isLoading,
      child: RefreshIndicator.adaptive(
        onRefresh: () async {
          await ref.read(cropCycleNotifierProvider.notifier).fetchCropCycles(_status, _active);
        },
        child: CustomScrollView(
          controller: _scrollController,
          shrinkWrap: true,
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverToBoxAdapter(
                child: userProvider.when(
                  data: (user) =>
                      ScreenHeader(username: user!.name.split(' ')[0], plantAsset: IconAssets.plant, line1: local.letsgrow, line2: local.amazing),
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) => Center(child: Text('${local.error}: $err')),
                ),
              ),
            ),
            SliverAppBar(
              pinned: true,
              floating: false,
              automaticallyImplyLeading: false,
              backgroundColor: ColorValues.whiteColor,
              forceMaterialTransparency: true,
              toolbarHeight: 42.h,
              collapsedHeight: 42.h,
              title: Skeleton.shade(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: searchButton(
                        onPressed: () => context.push('/dashboard/${SearchCropCycleScreen.path}'),
                        context: context,
                        text: '${local.searchSessionOrPlants}...',
                      ),
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: SizedBox(
                        width: 40.w,
                        height: 40.h,
                        child: addButton(
                          context: context,
                          onPressed: () {
                            showModalBottomSheet(
                              useRootNavigator: true,
                              isScrollControlled: true,
                              useSafeArea: true,
                              context: context,
                              builder: (context) => const SessionModal(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Skeleton.leaf(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      _buildContent(cropCycleState, local),
                      SizedBox(height: heightQuery(context) * 0.15),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CropCycleState state, AppLocalizations local) {
    if (state.isLoading) return const SizedBox.shrink();

    if (state.error != null && state.items.isEmpty) {
      return _buildError(state.error.toString(), local);
    }

    if (state.isEmpty) return _buildEmpty(local);

    return _buildList(state, local);
  }

  Widget _buildList(CropCycleState state, AppLocalizations local) {
    final filtered = state.items.where((e) {
      if (filterPlants != null) return e.status == getPlantStatusText(filterPlants!);
      return true;
    }).toList();

    return Column(
      children: [
        ...filtered.map(
          (cropCycle) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: CropCycleCard(
              deviceName: cropCycle.device.name,
              onEditPressed: () {
                showModalBottomSheet(
                  useRootNavigator: true,
                  isScrollControlled: true,
                  useSafeArea: true,
                  context: context,
                  builder: (context) => EditSessionModal(
                    cropCycleId: cropCycle.id,
                    device: cropCycle.device.name,
                    plant: cropCycle.plant.name,
                    sessionName: cropCycle.name,
                    phRange: RangeValues(cropCycle.phMin, cropCycle.phMax),
                    ppmRange: RangeValues(cropCycle.ppmMin.toDouble(), cropCycle.ppmMax.toDouble()),
                    expectedEnd: cropCycle.expectedEnd != null ? cropCycle.expectedEnd!.difference(cropCycle.startedAt).inDays : 30,
                  ),
                );
              },
              deviceSerialNumber: cropCycle.device.serialNumber,
              cropCycleName: cropCycle.name,
              cropCycleType: cropCycle.plant.name,
              plantedAt: cropCycle.startedAt,
              phValue: 14.toStringAsFixed(2),
              ppmValue: 1000.toStringAsFixed(0),
              phRangeValue: '${cropCycle.phMin.toStringAsFixed(1)}-${cropCycle.phMax.toStringAsFixed(1)}',
              ppmRangeValue: '${cropCycle.ppmMin.toStringAsFixed(0)}-${cropCycle.ppmMax.toStringAsFixed(0)}',
              deviceStatus: cropCycle.device.status,
              progressDay: DateTime.now().difference(cropCycle.startedAt).inDays,
              totalDay: cropCycle.expectedEnd != null ? cropCycle.expectedEnd!.difference(cropCycle.startedAt).inDays : 30,
              onHistoryPressed: () {
                context.push('/sensor-history', extra: {'cropCycleId': cropCycle.id});
              },
              onHarvestPressed: () {
                showAdaptiveDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (context) => alertDialog(
                    context: context,
                    title: local.harvest,
                    content: local.confirmHarvest,
                    confirmText: local.yes,
                    cancelText: local.no,
                    onConfirm: () {
                      ref.read(cropCycleControllerProvider.notifier).endCropCycleSession(cropCycle.id);
                    },
                  ),
                );
              },
            ),
          ),
        ),

        // Loading indicator saat load more
        if (state.isLoadingMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const Center(child: CircularProgressIndicator.adaptive()),
          ),

        // Tanda sudah sampai data terakhir
        if (!state.hasMore && filtered.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text(
              local.allCropCyclesLoaded,
              style: dmSansSmallText(size: 13, weight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildError(String message, AppLocalizations local) {
    final errorMessage = message.replaceAll('Exception: ', '');
    return Column(
      children: [
        const Icon(Icons.error_outline_outlined, color: ColorValues.danger600, size: 50),
        Text(
          local.error,
          style: jetBrainsMonoHeadText(color: ColorValues.danger600, size: 20),
          textAlign: TextAlign.center,
        ),
        Text(
          errorMessage,
          style: dmSansSmallText(size: 14, weight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        AnimatedRefreshButton(
          onRefresh: () async {
            await ref.read(cropCycleNotifierProvider.notifier).fetchCropCycles(_status, _active);
          },
          loading: false,
        ),
      ],
    );
  }

  Widget _buildEmpty(AppLocalizations local) {
    return SizedBox(
      height: heightQuery(context) * 0.65,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, color: ColorValues.warning600, size: 50),
            Text(
              local.warning,
              style: jetBrainsMonoHeadText(color: ColorValues.warning600, size: 20),
              textAlign: TextAlign.center,
            ),
            Text(
              local.noCropCyclesFound,
              style: dmSansSmallText(size: 14, weight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
