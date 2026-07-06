import 'package:hydro_iot/src/dashboard/application/providers/crop_cycle_providers.dart';
import 'package:hydro_iot/src/dashboard/data/models/edit_session_data.dart';
import 'package:hydro_iot/src/dashboard/data/models/session_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'crop_cycle_controller.g.dart';

enum CropCycleAction { add, update, end, delete, none }

@riverpod
class CropCycleController extends _$CropCycleController {
  CropCycleAction action = CropCycleAction.none;
  @override
  FutureOr<void> build() async {}

  Future<void> addCropCycleSession(SessionData sessionData) async {
    action = CropCycleAction.add;
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      await ref.read(cropCycleRepositoryProvider).addCropCycle(sessionData);
    });
    state = result;
  }

  Future<void> updateCropCycleSession(String id, EditSessionData sessionData) async {
    action = CropCycleAction.update;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(cropCycleRepositoryProvider).updateCropCycle(id, sessionData);
    });
  }

  Future<void> deleteCropCycleSession(String id) async {
    action = CropCycleAction.delete;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(cropCycleRepositoryProvider).deleteCropCycle(id);
    });
  }

  Future<void> endCropCycleSession(String id) async {
    action = CropCycleAction.end;
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      await ref.read(cropCycleRepositoryProvider).endCropCycle(id);
    });
    state = result;
  }
}
