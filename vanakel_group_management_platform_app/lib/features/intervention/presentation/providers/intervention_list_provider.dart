import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/intervention.dart';
import 'intervention_provider.dart';

class InterventionListNotifier extends AsyncNotifier<List<Intervention>> {
  @override
  Future<List<Intervention>> build() async {
    return ref.watch(interventionRepositoryProvider).getInterventions();
  }

  Future<void> updateStatus(String id, InterventionStatus status) async {
    final repository = ref.read(interventionRepositoryProvider);
    try {
      await repository.updateIntervention(id, {'status': status.name});
      // Refresh the list
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
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
