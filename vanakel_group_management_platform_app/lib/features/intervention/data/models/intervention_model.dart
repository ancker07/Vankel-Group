import '../../domain/intervention.dart';
import '../../domain/document.dart';

class InterventionModel extends Intervention {
  const InterventionModel({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.scheduledDate,
    required super.address,
    super.buildingId,
    super.buildingSyndicId,
    super.city,
    super.syndicId,
    super.proId,
    super.syndicName,
    super.professionalName,
    super.onSiteContactName,
    super.onSiteContactPhone,
    super.onSiteContactEmail,
    super.adminFeedback,
    super.urgency,
    super.sector,
    super.category,
    super.delayReason,
    super.delayDetails,
    super.delayedRescheduleDate,
    super.completedAt,
    super.interventionNumber,
    super.isMaintenance = false,
    super.documents = const [],
  });

  factory InterventionModel.fromJson(Map<String, dynamic> json) {
    // Building info — may come as nested object or flat fields
    final building = json['building'] as Map<String, dynamic>?;
    final buildingAddress = building?['address'] as String? ??
        json['address'] as String? ??
        'No Address';
    final buildingCity = building?['city'] as String? ?? json['city'] as String?;

    // Syndic info
    final syndic = json['syndic'] as Map<String, dynamic>?;
    final syndicName = syndic != null
        ? ((syndic['company_name'] ?? syndic['companyName']) as String?)
        : null;

    // Professional info
    final professional = json['professional'] as Map<String, dynamic>?;
    final proName = professional != null
        ? ((professional['company_name'] ?? professional['companyName']) as String?)
        : null;

    return InterventionModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      // Backend uses 'scheduled_date', not 'scheduled_at'
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.tryParse(json['scheduled_date'] as String) ?? DateTime.now()
          : json['scheduled_at'] != null
              ? DateTime.tryParse(json['scheduled_at'] as String) ?? DateTime.now()
              : DateTime.now(),
      address: buildingAddress,
      city: buildingCity,
      buildingId: json['building_id']?.toString(),
      buildingSyndicId: building?['syndic_id']?.toString(),
      syndicId: json['syndic_id']?.toString(),
      proId: json['pro_id']?.toString(),
      syndicName: syndicName,
      professionalName: proName,
      onSiteContactName: json['on_site_contact_name'] as String?,
      onSiteContactPhone: json['on_site_contact_phone'] as String?,
      onSiteContactEmail: json['on_site_contact_email'] as String?,
      adminFeedback: json['admin_feedback'] as String?,
      urgency: json['urgency'] as String?,
      sector: json['sector'] as String?,
      category: json['category'] as String?,
      delayReason: json['delay_reason'] as String?,
      delayDetails: json['delay_details'] as String?,
      delayedRescheduleDate: json['delayed_reschedule_date'] != null
          ? DateTime.tryParse(json['delayed_reschedule_date'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      interventionNumber: (json['intervention_number'] ?? json['interventionNumber'])?.toString(),
      isMaintenance: json['is_maintenance_occurrence'] == true || json['isMaintenance'] == true,
      documents: (json['documents'] as List<dynamic>?)
              ?.map(
                (doc) => Document(
                  id: doc['id'].toString(),
                  fileName: doc['file_name'] as String? ?? 'Unknown',
                  filePath: doc['file_path'] as String? ?? '',
                  fileType:
                      doc['file_type'] as String? ?? 'application/octet-stream',
                  createdAt: doc['created_at'] != null
                      ? DateTime.tryParse(doc['created_at'] as String)
                      : null,
                ),
              )
              .toList() ??
          [],
    );
  }

  static InterventionStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return InterventionStatus.pending;
      case 'DELAYED':
        return InterventionStatus.delayed;
      case 'COMPLETED':
        return InterventionStatus.completed;
      // Legacy fallbacks
      case 'SCHEDULED':
      case 'IN_PROGRESS':
        return InterventionStatus.pending;
      default:
        return InterventionStatus.pending;
    }
  }

  Intervention toEntity() => this;
}
