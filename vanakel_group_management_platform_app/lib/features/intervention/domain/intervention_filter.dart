import '../domain/intervention.dart';

class InterventionFilter {
  final String searchQuery;
  final String? sectorId;
  final String? urgency;
  final String? buildingId;
  final DateTime? scheduledDate;

  const InterventionFilter({
    this.searchQuery = '',
    this.sectorId,
    this.urgency,
    this.buildingId,
    this.scheduledDate,
  });

  InterventionFilter copyWith({
    String? searchQuery,
    String? sectorId,
    String? urgency,
    String? buildingId,
    DateTime? scheduledDate,
    bool clearSector = false,
    bool clearUrgency = false,
    bool clearBuilding = false,
    bool clearDate = false,
  }) {
    return InterventionFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      sectorId: clearSector ? null : (sectorId ?? this.sectorId),
      urgency: clearUrgency ? null : (urgency ?? this.urgency),
      buildingId: clearBuilding ? null : (buildingId ?? this.buildingId),
      scheduledDate: clearDate ? null : (scheduledDate ?? this.scheduledDate),
    );
  }

  bool get isActive =>
      searchQuery.isNotEmpty ||
      sectorId != null ||
      urgency != null ||
      buildingId != null ||
      scheduledDate != null;

  bool matches(Intervention i) {
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
