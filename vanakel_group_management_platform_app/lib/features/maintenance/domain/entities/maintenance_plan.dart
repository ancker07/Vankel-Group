class MaintenancePlan {
  final String id;
  final String buildingId;
  final String title;
  final String? titleEn;
  final String? titleFr;
  final String? titleNl;
  final String description;
  final String? descriptionEn;
  final String? descriptionFr;
  final String? descriptionNl;
  final String frequency; // YEARLY, MONTHLY, QUARTERLY
  final int interval;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // ACTIVE, CANCELLED
  final String? syndicId;
  final DateTime createdAt;

  const MaintenancePlan({
    required this.id,
    required this.buildingId,
    required this.title,
    this.titleEn,
    this.titleFr,
    this.titleNl,
    required this.description,
    this.descriptionEn,
    this.descriptionFr,
    this.descriptionNl,
    required this.frequency,
    required this.interval,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.syndicId,
    required this.createdAt,
  });
}
