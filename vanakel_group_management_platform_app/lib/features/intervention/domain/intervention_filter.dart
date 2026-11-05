import '../domain/intervention.dart';

class InterventionFilter {
  final String searchQuery;
  final String? sectorId;
  final String? urgency;
  final String? buildingId;
  final DateTime? scheduledDate;
  final InterventionStatus? status;

  const InterventionFilter({
    this.searchQuery = '',
    this.sectorId,
    this.urgency,
    this.buildingId,
    this.scheduledDate,
    this.status,
  });

  InterventionFilter copyWith({
    String? searchQuery,
    String? sectorId,
    String? urgency,
    String? buildingId,
    DateTime? scheduledDate,
    InterventionStatus? status,
    bool clearSector = false,
    bool clearUrgency = false,
    bool clearBuilding = false,
    bool clearDate = false,
    bool clearStatus = false,
  }) {
    return InterventionFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      sectorId: clearSector ? null : (sectorId ?? this.sectorId),
      urgency: clearUrgency ? null : (urgency ?? this.urgency),
      buildingId: clearBuilding ? null : (buildingId ?? this.buildingId),
      scheduledDate: clearDate ? null : (scheduledDate ?? this.scheduledDate),
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  /// The filters set with the chips and the search box. The status is chosen with the tabs (All / Ongoing /
  /// Delayed / Completed), so it is not counted here.
  bool get isActive =>
      searchQuery.isNotEmpty ||
      sectorId != null ||
      urgency != null ||
      buildingId != null ||
      scheduledDate != null;

  /// Like the website: the selected status tab (null = All, every status) and all the other filters.
  bool matches(Intervention i) {
    if (status != null && i.status != status) return false;
    return matchesIgnoringStatus(i);
  }

  /// Everything except the status: what the counts on the status tabs are based on.
  bool matchesIgnoringStatus(Intervention i) {
    // Search query match
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final titleMatch = (i.title).toLowerCase().contains(query);
      final descMatch = (i.description).toLowerCase().contains(query);
      if (!titleMatch && !descMatch) return false;
    }

    // Sector match
    if (sectorId != null && i.sector != sectorId) return false;

    // Urgency match
    if (urgency != null && i.urgency != urgency) return false;

    // Building match
    if (buildingId != null && i.buildingId != buildingId) return false;

    // Date match
    if (scheduledDate != null) {
      final filterDateStr = "${scheduledDate!.year}-${scheduledDate!.month}-${scheduledDate!.day}";
      final interventionDate = i.scheduledDate;
      final interventionDateStr = "${interventionDate.year}-${interventionDate.month}-${interventionDate.day}";
      if (filterDateStr != interventionDateStr) return false;
    }

    return true;
  }
}
