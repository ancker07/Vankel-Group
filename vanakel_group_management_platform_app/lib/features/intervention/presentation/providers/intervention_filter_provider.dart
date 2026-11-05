import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/intervention_filter.dart';
import '../../domain/intervention.dart';
import 'intervention_list_provider.dart';
import '../../../../core/router/mobile_access.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

class InterventionFilterNotifier extends Notifier<InterventionFilter> {
  @override
  InterventionFilter build() {
    return const InterventionFilter();
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateSector(String? sectorId) {
    if (sectorId == null) {
      state = state.copyWith(clearSector: true);
    } else {
      state = state.copyWith(sectorId: sectorId);
    }
  }

  void updateUrgency(String? urgency) {
    if (urgency == null) {
      state = state.copyWith(clearUrgency: true);
    } else {
      state = state.copyWith(urgency: urgency);
    }
  }

  void updateBuilding(String? buildingId) {
    if (buildingId == null) {
      state = state.copyWith(clearBuilding: true);
    } else {
      state = state.copyWith(buildingId: buildingId);
    }
  }

  void updateDate(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearDate: true);
    } else {
      state = state.copyWith(scheduledDate: date);
    }
  }

  void updateStatus(InterventionStatus? status) {
    if (status == null) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(status: status);
    }
  }

  void reset() {
    state = const InterventionFilter();
  }
}

final interventionFilterProvider = NotifierProvider<InterventionFilterNotifier, InterventionFilter>(
  InterventionFilterNotifier.new,
);

final filteredInterventionListProvider = Provider<AsyncValue<List<Intervention>>>((ref) {
  final interventionsAsync = ref.watch(interventionListProvider);
  final filter = ref.watch(interventionFilterProvider);

  // Like the website: a technician only sees the interventions that are still to do
  final onlyOpen = ref.watch(authStateProvider).user?.seesOnlyOpenInterventions ?? false;

  return interventionsAsync.whenData((interventions) {
    return interventions
        .where((i) => !onlyOpen || i.status == InterventionStatus.pending)
        .where((i) => filter.matches(i))
        .toList();
  });
});
