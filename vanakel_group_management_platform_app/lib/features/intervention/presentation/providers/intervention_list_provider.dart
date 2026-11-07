import 'package:flutter/foundation.dart';
import '../../domain/intervention_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/intervention.dart';
import 'intervention_provider.dart';
import '../../data/intervention_submitter.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

/// The intervention as it is after this save, so the phone shows it before (or without) the server's answer.
Intervention withSavedFields(Intervention i, Map<String, String> fields, DateTime savedAt) {
  final status = InterventionStatus.values.where((s) => s.name.toUpperCase() == fields['status']).firstOrNull;
  return i.copyWith(
    status: status,
    adminFeedback: fields['admin_feedback'],
    delayReason: fields['delay_reason'],
    delayDetails: fields['delay_details'],
    delayedRescheduleDate: DateTime.tryParse(fields['delayed_reschedule_date'] ?? ''),
    completedAt: status == InterventionStatus.completed ? savedAt : null,
    submittedAt: fields['save_mode'] == 'SUBMIT' ? savedAt : null,
    updatedAt: savedAt,
  );
}

class InterventionListNotifier extends AsyncNotifier<List<Intervention>> {
  int _newestLoad = 0; // an older answer that arrives late must not overwrite newer data

  @override
  Future<List<Intervention>> build() => _load(ref.watch(interventionRepositoryProvider));

  /// What the server says, with the work still waiting on this phone on top: until it is delivered the server does
  /// not know about it, and a task the technician finished must not come back in the list.
  Future<List<Intervention>> _load(InterventionRepository repository) async {
    final userId = ref.read(authStateProvider).user?.id;
    final submitter = userId == null ? null : ref.read(interventionSubmitterProvider);
    final list = await repository.getInterventions();
    if (submitter == null) return list;

    for (final work in await submitter.waitingFor(userId!)) {
      final index = list.indexWhere((i) => i.id == work.interventionId);
      if (index != -1) list[index] = withSavedFields(list[index], work.fields, work.createdAt);
    }
    return list;
  }

  /// The save is done (or safe on the phone): every screen shows it now, without waiting for the network.
  void markSaved(String id, Map<String, String> fields) {
    final current = state.value;
    if (current == null) return;
    _newestLoad++; // anything still on its way was asked for before this save
    final now = DateTime.now();
    state = AsyncData([
      for (final i in current) i.id == id ? withSavedFields(i, fields, now) : i,
    ]);
  }

  /// Fetches the latest data while the list stays on screen; when it fails the list simply stays as it is.
  Future<void> refreshQuietly() async {
    if (state.isLoading) {
      ref.invalidateSelf(); // a fetch from before this moment is running: start again, its answer is out of date
      return;
    }
    final load = ++_newestLoad;
    try {
      final fresh = await _load(ref.read(interventionRepositoryProvider));
      if (ref.mounted && load == _newestLoad) state = AsyncData(fresh);
    } catch (e) {
      debugPrint('Interventions not refreshed: $e');
    }
  }

  Future<void> updateIntervention(String id, Map<String, dynamic> data) async {
    final repository = ref.read(interventionRepositoryProvider);
    try {
      await repository.updateIntervention(id, data);
      _refreshAfterUpdate(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<RegisterResult> registerIntervention(String id, dynamic data) async {
    final repository = ref.read(interventionRepositoryProvider);
    try {
      final result = await repository.registerIntervention(id, data);
      _refreshAfterUpdate(id);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  void _refreshAfterUpdate(String id) {
    // Refresh the list
    ref.invalidateSelf();
    // Also invalidate the detail provider for this specific ID if it exists
    ref.invalidate(interventionDetailProvider(id));
  }

  // Helper for simple status updates (backward compatibility)
  Future<void> updateStatus(String id, InterventionStatus status) async {
    return updateIntervention(id, {'status': status.name.toUpperCase()});
  }

  Future<void> sendReport(String id, String type) async {
    final repository = ref.read(interventionRepositoryProvider);
    try {
      await repository.sendReport(id, {'type': type});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<String> improveNote(String text) async {
    return ref.read(interventionRepositoryProvider).improveNote(text);
  }

  Future<void> createMaintenancePlan(Map<String, dynamic> data) async {
    return ref.read(interventionRepositoryProvider).createMaintenancePlan(data);
  }
}

final interventionListProvider = AsyncNotifierProvider<InterventionListNotifier, List<Intervention>>(
  InterventionListNotifier.new,
);

final interventionDetailProvider = FutureProvider.family<Intervention, String>((ref, id) async {
  final cachedInterventions = ref.watch(interventionListProvider).asData?.value;
  if (cachedInterventions != null) {
    for (final intervention in cachedInterventions) {
      if (intervention.id == id) return intervention;
    }
  }

  return ref.watch(interventionRepositoryProvider).getInterventionById(id);
});
