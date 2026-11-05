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

/// How many interventions each status tab shows (the other filters applied, the status itself ignored), like the website.
class InterventionStatusCounts {
  final int all;
  final int pending;
  final int delayed;
  final int completed;
  const InterventionStatusCounts({this.all = 0, this.pending = 0, this.delayed = 0, this.completed = 0});

  int of(InterventionStatus? status) => switch (status) {
        null => all,
        InterventionStatus.pending => pending,
        InterventionStatus.delayed => delayed,
        InterventionStatus.completed => completed,
      };
}

final filteredInterventionListProvider = Provider<AsyncValue<List<Intervention>>>((ref) {
  final interventionsAsync = ref.watch(interventionListProvider);
  final filter = ref.watch(interventionFilterProvider);

  // Like the website: a technician only sees the interventions that are still to do
  final onlyOpen = ref.watch(authStateProvider).user?.seesOnlyOpenInterventions ?? false;

  return interventionsAsync.whenData((interventions) {
    return interventions
        .where((i) => !onlyOpen || i.status == InterventionStatus.pending)
        .where((i) => filter.matches(i))
        .toList()
      // newest scheduled date first, as on the website
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
  });
});

final interventionStatusCountsProvider = Provider<InterventionStatusCounts>((ref) {
  final interventions = ref.watch(interventionListProvider).value ?? const <Intervention>[];
  final filter = ref.watch(interventionFilterProvider);
  final onlyOpen = ref.watch(authStateProvider).user?.seesOnlyOpenInterventions ?? false;

  final base = interventions
      .where((i) => !onlyOpen || i.status == InterventionStatus.pending)
      .where(filter.matchesIgnoringStatus)
      .toList();
  int count(InterventionStatus status) => base.where((i) => i.status == status).length;

  return InterventionStatusCounts(
    all: base.length,
    pending: count(InterventionStatus.pending),
    delayed: count(InterventionStatus.delayed),
    completed: count(InterventionStatus.completed),
  );
});
