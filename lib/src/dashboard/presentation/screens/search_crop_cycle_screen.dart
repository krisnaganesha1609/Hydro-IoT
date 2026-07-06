import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydro_iot/core/components/crop_cycle_card.dart';
import 'package:hydro_iot/core/components/fancy_loading.dart';
import 'package:hydro_iot/src/dashboard/application/providers/filter_devices_providers.dart';
import 'package:hydro_iot/src/dashboard/presentation/widgets/edit_session_modal.dart';
import 'package:vector_graphics/vector_graphics.dart';
import '../../../../pkg.dart';
import '../../application/providers/crop_cycle_providers.dart';
import '../../application/state/crop_cycle_state.dart';
import 'dart:async';

class SearchCropCycleScreen extends ConsumerStatefulWidget {
  const SearchCropCycleScreen({super.key});

  static const String path = 'search-crop-cycle';

  @override
  ConsumerState<SearchCropCycleScreen> createState() => _SearchCropCycleScreenState();
}

class _SearchCropCycleScreenState extends ConsumerState<SearchCropCycleScreen> {
  PlantStatus? get filterPlants => ref.watch(filterCropCycleProvider);
  final TextEditingController searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = searchController.text.trim();
      if (query.isNotEmpty) {
        ref.read(searchCropCycleNotifierProvider.notifier).searchCropCycles(query);
      } else {
        ref.read(searchCropCycleNotifierProvider.notifier).clearSearch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final searchState = ref.watch(searchCropCycleNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: heightQuery(context) * 0.1,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: ColorValues.green500,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        automaticallyImplyLeading: false,
        actionsPadding: EdgeInsets.symmetric(horizontal: 18.w),
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: searchButton(
                    onPressed: () {},
                    context: context,
                    enabled: true,
                    controller: searchController,
                    text: local.searchSessionOrPlants,
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: cancelButton(
                    context: context,
                    onPressed: () {
                      searchController.clear();
                      context.pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(searchState, local),
    );
  }

  Widget _buildBody(CropCycleState state, AppLocalizations local) {
    // Belum ada query — tampilkan placeholder awal
    if (!state.isLoading && state.error == null && state.items.isEmpty) {
      return _buildPlaceholder(local);
    }

    if (state.isLoading) {
      return const Center(child: FancyLoading(title: 'Searching crop cycles...'));
    }

    if (state.error != null) {
      return _buildError(state.error.toString(), local);
    }

    if (state.items.isEmpty) {
      return _buildNotFound(local);
    }

    return _buildResults(state, local);
  }

  Widget _buildPlaceholder(AppLocalizations local) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const VectorGraphic(loader: AssetBytesLoader(IconAssets.searchPlant), width: 40, height: 40),
          const SizedBox(height: 16),
          Text(
            local.searchSessionOrPlants,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            local.findAndManage,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ColorValues.neutral500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(AppLocalizations local) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const VectorGraphic(loader: AssetBytesLoader(IconAssets.notfoundSearch), width: 40, height: 40),
          const SizedBox(height: 16),
          Text(
            local.noResultsFound,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            local.tryAnotherName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ColorValues.neutral500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message, AppLocalizations local) {
    final errorMessage = message.replaceAll('Exception: ', '');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
        ],
      ),
    );
  }

  Widget _buildResults(CropCycleState state, AppLocalizations local) {
    final filtered = state.items.where((e) {
      if (filterPlants != null) return e.status == getPlantStatusText(filterPlants!);
      return true;
    }).toList();

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, index) {
        final cropCycle = filtered[index];
        return CropCycleCard(
          deviceSerialNumber: cropCycle.device.serialNumber,
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
          cropCycleName: cropCycle.name,
          cropCycleType: cropCycle.plant.name,
          plantedAt: cropCycle.startedAt,
          phValue: 4.5.toString(),
          ppmValue: 900.toString(),
          phRangeValue: '${cropCycle.phMin.toStringAsFixed(1)}-${cropCycle.phMax.toStringAsFixed(1)}',
          ppmRangeValue: '${cropCycle.ppmMin.toStringAsFixed(0)}-${cropCycle.ppmMax.toStringAsFixed(0)}',
          deviceStatus: cropCycle.status,
          progressDay: DateTime.now().difference(cropCycle.startedAt).inDays,
          totalDay: cropCycle.expectedEnd != null ? cropCycle.expectedEnd!.difference(cropCycle.startedAt).inDays : 30,
          onHistoryPressed: () {
            context.push('/sensor-history', extra: {'cropCycleId': cropCycle.id});
          },
          onHarvestPressed: () {
            showAdaptiveDialog(
              barrierDismissible: true,
              context: context,
              builder: (context) =>
                  alertDialog(context: context, title: local.harvest, content: local.confirmHarvest, onConfirm: () => Navigator.of(context).pop()),
            );
          },
        );
      },
    );
  }
}
