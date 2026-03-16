import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/mission.dart';
import 'mission_list_provider.dart';

class MissionFilter {
  final String searchQuery;
  final MissionStatus? status;
  final MissionUrgency? urgency;
  final String? sector;
  final String? buildingId;
  final DateTime? date;

  const MissionFilter({
    this.searchQuery = '',
    this.status,
    this.urgency,
    this.sector,
    this.buildingId,
    this.date,
  });

  bool get isActive =>
      searchQuery.isNotEmpty ||
      status != null ||
      urgency != null ||
      sector != null ||
      buildingId != null ||
      date != null;

  MissionFilter copyWith({
    String? searchQuery,
    MissionStatus? status,
    bool clearStatus = false,
    MissionUrgency? urgency,
    bool clearUrgency = false,
    String? sector,
    bool clearSector = false,
    String? buildingId,
    bool clearBuilding = false,
    DateTime? date,
    bool clearDate = false,
  }) {
    return MissionFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      status: clearStatus ? null : (status ?? this.status),
      urgency: clearUrgency ? null : (urgency ?? this.urgency),
      sector: clearSector ? null : (sector ?? this.sector),
      buildingId: clearBuilding ? null : (buildingId ?? this.buildingId),
      date: clearDate ? null : (date ?? this.date),
    );
  }

  bool matches(Mission mission) {
    final matchesSearch = mission.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
        mission.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
        mission.address.toLowerCase().contains(searchQuery.toLowerCase());

    final matchesStatus = status != null 
        ? mission.status == status 
        : (mission.status != MissionStatus.completed && mission.status != MissionStatus.rejected);
    final matchesUrgency = urgency == null || mission.urgency == urgency;
    final matchesSector = sector == null || mission.sector == sector;
    final matchesBuilding = buildingId == null || mission.buildingId == buildingId;

    final missionDate = DateTime(mission.createdAt.year, mission.createdAt.month, mission.createdAt.day);
    final matchesDate = date == null || missionDate.isAtSameMomentAs(date!);

    return matchesSearch && matchesStatus && matchesUrgency && matchesSector && matchesBuilding && matchesDate;
  }
}

class MissionFilterNotifier extends Notifier<MissionFilter> {
  @override
  MissionFilter build() {
    return const MissionFilter();
  }

  void updateSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void updateStatus(MissionStatus? status) => state = state.copyWith(status: status, clearStatus: status == null);
  void updateUrgency(MissionUrgency? urgency) => state = state.copyWith(urgency: urgency, clearUrgency: urgency == null);
  void updateSector(String? sector) => state = state.copyWith(sector: sector, clearSector: sector == null);
  void updateBuilding(String? buildingId) => state = state.copyWith(buildingId: buildingId, clearBuilding: buildingId == null);
  void updateDate(DateTime? date) => state = state.copyWith(date: date, clearDate: date == null);
  void reset() => state = const MissionFilter();
}

final missionFilterProvider = NotifierProvider<MissionFilterNotifier, MissionFilter>(
  MissionFilterNotifier.new,
);

final filteredMissionListProvider = Provider<AsyncValue<List<Mission>>>((ref) {
  final missionsAsync = ref.watch(missionListProvider);
  final filter = ref.watch(missionFilterProvider);

  return missionsAsync.whenData((missions) {
    return missions.where((m) => filter.matches(m)).toList();
  });
});
