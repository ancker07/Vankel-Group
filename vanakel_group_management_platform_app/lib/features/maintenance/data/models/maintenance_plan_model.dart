import '../../domain/entities/maintenance_plan.dart';

class MaintenancePlanModel extends MaintenancePlan {
  const MaintenancePlanModel({
    required super.id,
    required super.buildingId,
    required super.title,
    required super.description,
    required super.frequency,
    required super.interval,
    required super.startDate,
    required super.endDate,
    required super.status,
    super.syndicId,
    required super.createdAt,
  });

  factory MaintenancePlanModel.fromJson(Map<String, dynamic> json) {
    // Recurrence logic from backend
    final recurrence = json['recurrence'] as Map<String, dynamic>?;

    return MaintenancePlanModel(
      id: json['id'].toString(),
      buildingId: json['building_id']?.toString() ?? '',
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? '',
      frequency: recurrence?['frequency'] as String? ?? 'MONTHLY',
      interval: recurrence?['interval'] as int? ?? 1,
      startDate: DateTime.tryParse(recurrence?['startDate'] ?? recurrence?['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(recurrence?['endDate'] ?? recurrence?['end_date'] ?? '') ?? DateTime.now().add(const Duration(days: 365)),
      status: json['status'] as String? ?? 'ACTIVE',
      syndicId: json['syndic_id']?.toString(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  factory MaintenancePlanModel.fromEntity(MaintenancePlan entity) {
    return MaintenancePlanModel(
      id: entity.id,
      buildingId: entity.buildingId,
      title: entity.title,
      description: entity.description,
      frequency: entity.frequency,
      interval: entity.interval,
      startDate: entity.startDate,
      endDate: entity.endDate,
      status: entity.status,
      syndicId: entity.syndicId,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'building_id': buildingId,
      'title': title,
      'description': description,
      'status': status,
      'syndic_id': syndicId,
      'created_at': createdAt.toIso8601String(),
      'recurrence': {
        'frequency': frequency,
        'interval': interval,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    };
  }

  MaintenancePlan toEntity() => this;
}
