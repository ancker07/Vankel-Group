import '../../../auth/presentation/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/mission.dart';
import 'mission_provider.dart';
import '../../../intervention/presentation/providers/intervention_list_provider.dart';

class MissionListNotifier extends AsyncNotifier<List<Mission>> {
  @override
  Future<List<Mission>> build() async {
    // A role without the mission permission (e.g. a technician) has no missions at all: do not
    // ask the server (it would answer 403 and every screen reading this list would show an error).
    final user = ref.watch(authStateProvider).user;
    if (user != null && !user.can('missions.view')) return const [];
    return ref.watch(missionRepositoryProvider).getMissions();
  }

  Future<void> approveMission(String id, {String? scheduledDate}) async {
    final repository = ref.read(missionRepositoryProvider);
    try {
      await repository.approveMission(id, scheduledDate: scheduledDate);
      ref.invalidateSelf();
      // Also refresh interventions as an approved mission creates one
      ref.invalidate(interventionListProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectMission(String id) async {
    final repository = ref.read(missionRepositoryProvider);
    try {
      await repository.rejectMission(id);
      ref.invalidateSelf();
      ref.invalidate(interventionListProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMission(String id) async {
    await ref.read(missionRepositoryProvider).deleteMission(id);
    ref.invalidateSelf();
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
