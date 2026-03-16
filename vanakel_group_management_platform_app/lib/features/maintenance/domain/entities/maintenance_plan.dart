class MaintenancePlan {
  final String id;
  final String buildingId;
  final String title;
  final String description;
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
    required this.description,
    required this.frequency,
    required this.interval,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.syndicId,
    required this.createdAt,
  });
}
