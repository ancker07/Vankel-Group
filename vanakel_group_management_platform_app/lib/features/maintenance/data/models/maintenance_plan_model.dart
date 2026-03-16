import '../../domain/entities/maintenance_plan.dart';

class MaintenancePlanModel extends MaintenancePlan {
  const MaintenancePlanModel({
    required super.id,
    required super.buildingId,
    required super.title,
    super.titleEn,
    super.titleFr,
    super.titleNl,
    required super.description,
    super.descriptionEn,
    super.descriptionFr,
    super.descriptionNl,
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
      titleEn: json['title_en'] as String?,
      titleFr: json['title_fr'] as String?,
      titleNl: json['title_nl'] as String?,
      description: json['description'] as String? ?? '',
      descriptionEn: json['description_en'] as String?,
      descriptionFr: json['description_fr'] as String?,
      descriptionNl: json['description_nl'] as String?,
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
      titleEn: entity.titleEn,
      titleFr: entity.titleFr,
      titleNl: entity.titleNl,
      description: entity.description,
      descriptionEn: entity.descriptionEn,
      descriptionFr: entity.descriptionFr,
      descriptionNl: entity.descriptionNl,
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
      'title_en': titleEn,
      'title_fr': titleFr,
      'title_nl': titleNl,
      'description': description,
      'description_en': descriptionEn,
      'description_fr': descriptionFr,
      'description_nl': descriptionNl,
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
