import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/mission.dart';
import 'mission_provider.dart';

class MissionListNotifier extends AsyncNotifier<List<Mission>> {
  @override
  Future<List<Mission>> build() async {
    return ref.watch(missionRepositoryProvider).getMissions();
  }

  Future<void> approveMission(String id, {String? scheduledDate}) async {
    final repository = ref.read(missionRepositoryProvider);
    try {
      await repository.approveMission(id, scheduledDate: scheduledDate);
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectMission(String id) async {
    final repository = ref.read(missionRepositoryProvider);
    try {
      await repository.rejectMission(id);
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final missionListProvider = AsyncNotifierProvider<MissionListNotifier, List<Mission>>(
  MissionListNotifier.new,
);

final missionDetailProvider = FutureProvider.family<Mission, String>((ref, id) async {
  return ref.watch(missionRepositoryProvider).getMissionById(id);
});
