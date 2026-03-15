import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/intervention.dart';
import 'intervention_provider.dart';

class InterventionListNotifier extends AsyncNotifier<List<Intervention>> {
  @override
  Future<List<Intervention>> build() async {
    return ref.watch(interventionRepositoryProvider).getInterventions();
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

  Future<void> registerIntervention(String id, dynamic data) async {
    final repository = ref.read(interventionRepositoryProvider);
    try {
      await repository.registerIntervention(id, data);
      _refreshAfterUpdate(id);
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
}

final interventionListProvider = AsyncNotifierProvider<InterventionListNotifier, List<Intervention>>(
  InterventionListNotifier.new,
);

final interventionDetailProvider = FutureProvider.family<Intervention, String>((ref, id) async {
  return ref.watch(interventionRepositoryProvider).getInterventionById(id);
});
