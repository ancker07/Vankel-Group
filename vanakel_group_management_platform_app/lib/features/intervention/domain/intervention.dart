import 'document.dart';

/// Maps to backend's status strings: PENDING, DELAYED, COMPLETED
enum InterventionStatus { pending, delayed, completed }

extension InterventionStatusX on InterventionStatus {
  String get label {
    switch (this) {
      case InterventionStatus.pending:
        return 'In progress';
      case InterventionStatus.delayed:
        return 'Delayed';
      case InterventionStatus.completed:
        return 'Completed';
    }
  }
}

class Intervention {
  final String id;
  final String title;
  final String description;
  final InterventionStatus status;
  final DateTime scheduledDate;

  // Building info
  final String? buildingId;
  final String? buildingSyndicId;
  final String address; // building.address
  final String? city;   // building.city

  // Assignments
  final String? syndicId;
  final String? proId;
  final String? syndicName;
  final String? professionalName;

  // On-site contact
  final String? onSiteContactName;
  final String? onSiteContactPhone;
  final String? onSiteContactEmail;

  // Admin fields
  final String? adminFeedback;
  final String? urgency;    // LOW / MEDIUM / HIGH / CRITICAL
  final String? sector;     // GENERAL, PLUMBING, etc.
  final String? category;

  // Delay info
  final String? delayReason;
  final String? delayDetails;
  final DateTime? delayedRescheduleDate;
  final DateTime? completedAt;
  final String? interventionNumber;
  final bool isMaintenance;
  final List<Document> documents;

  const Intervention({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.scheduledDate,
    required this.address,
    this.interventionNumber,
    this.isMaintenance = false,
    this.buildingId,
    this.buildingSyndicId,
    this.city,
    this.syndicId,
    this.proId,
    this.syndicName,
    this.professionalName,
    this.onSiteContactName,
    this.onSiteContactPhone,
    this.onSiteContactEmail,
    this.adminFeedback,
    this.urgency,
    this.sector,
    this.category,
    this.delayReason,
    this.delayDetails,
    this.delayedRescheduleDate,
    this.completedAt,
    this.documents = const [],
  });

  Intervention copyWith({
    String? id,
    String? title,
    String? description,
    InterventionStatus? status,
    DateTime? scheduledDate,
    String? address,
    String? buildingId,
    String? city,
    String? syndicId,
    String? proId,
    String? syndicName,
    String? professionalName,
    String? onSiteContactName,
    String? onSiteContactPhone,
    String? onSiteContactEmail,
    String? adminFeedback,
    String? urgency,
    String? sector,
    String? delayDetails,
    DateTime? delayedRescheduleDate,
    DateTime? completedAt,
    String? interventionNumber,
    bool? isMaintenance,
    List<Document>? documents,
  }) {
    return Intervention(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      address: address ?? this.address,
      interventionNumber: interventionNumber ?? this.interventionNumber,
      isMaintenance: isMaintenance ?? this.isMaintenance,
      buildingId: buildingId ?? this.buildingId,
      buildingSyndicId: buildingSyndicId ?? this.buildingSyndicId,
      city: city ?? this.city,
      syndicId: syndicId ?? this.syndicId,
      proId: proId ?? this.proId,
      syndicName: syndicName ?? this.syndicName,
      professionalName: professionalName ?? this.professionalName,
      onSiteContactName: onSiteContactName ?? this.onSiteContactName,
      onSiteContactPhone: onSiteContactPhone ?? this.onSiteContactPhone,
      onSiteContactEmail: onSiteContactEmail ?? this.onSiteContactEmail,
      adminFeedback: adminFeedback ?? this.adminFeedback,
      urgency: urgency ?? this.urgency,
      sector: sector ?? this.sector,
      category: category ?? this.category,
      delayReason: delayReason ?? this.delayReason,
      delayDetails: delayDetails ?? this.delayDetails,
      delayedRescheduleDate: delayedRescheduleDate ?? this.delayedRescheduleDate,
      completedAt: completedAt ?? this.completedAt,
      documents: documents ?? this.documents,
    );
  }
}
