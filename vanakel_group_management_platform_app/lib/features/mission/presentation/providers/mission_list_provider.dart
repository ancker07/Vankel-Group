import '../../../auth/presentation/providers/auth_state_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/mission.dart';
import 'mission_provider.dart';
import '../../../intervention/presentation/providers/intervention_list_provider.dart';

class MissionListNotifier extends AsyncNotifier<List<Mission>> {
  int _newestLoad = 0;

  @override
  Future<List<Mission>> build() async {
    // A role without the mission permission (e.g. a technician) has no missions at all: do not
    // ask the server (it would answer 403 and every screen reading this list would show an error).
    final user = ref.watch(authStateProvider).user;
    if (user != null && !user.can('missions.view')) return const [];
    return ref.watch(missionRepositoryProvider).getMissions();
  }

  Future<void> approveMission(String id, {String? scheduledDate, int? assignedUserId}) async {
    final repository = ref.read(missionRepositoryProvider);
    try {
      await repository.approveMission(id, scheduledDate: scheduledDate, assignedUserId: assignedUserId);
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

  /// The refresh button: what is on screen goes and the spinner shows until the server's answer (the data, or the
  /// error with its retry button) is in. Fetched here rather than by rebuilding: a rebuild would keep the old data on
  /// screen and, on an error, retry by itself without end. A quiet refresh still on its way cannot land after it.
  Future<void> reloadFromServer() async {
    final user = ref.read(authStateProvider).user;
    if (user != null && !user.can('missions.view')) return; // no missions for this role: nothing to ask
    final load = ++_newestLoad;
    state = const AsyncLoading();
    try {
      final fresh = await ref.read(missionRepositoryProvider).getMissions();
      if (ref.mounted && load == _newestLoad) state = AsyncData(fresh);
    } catch (e, st) {
      if (ref.mounted && load == _newestLoad) state = AsyncError(e, st);
    }
  }

  /// Fetches the latest data while the list stays on screen; when it fails the list simply stays as it is.
  Future<void> refreshQuietly() async {
    if (state.isLoading) {
      ref.invalidateSelf();
      return;
    }
    final user = ref.read(authStateProvider).user;
    if (user != null && !user.can('missions.view')) return;
    final load = ++_newestLoad;
    try {
      final fresh = await ref.read(missionRepositoryProvider).getMissions();
      if (ref.mounted && load == _newestLoad) state = AsyncData(fresh);
    } catch (e) {
      debugPrint('Missions not refreshed: $e');
    }
  }
}

final missionListProvider = AsyncNotifierProvider<MissionListNotifier, List<Mission>>(
  MissionListNotifier.new,
);

final missionDetailProvider = FutureProvider.family<Mission, String>((ref, id) async {
  return ref.watch(missionRepositoryProvider).getMissionById(id);
});
