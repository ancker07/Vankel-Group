import 'document.dart';

/// Maps to backend's status strings: PENDING, DELAYED, COMPLETED
enum InterventionStatus { pending, delayed, completed }

class Intervention {
  final String id;
  final String title;
  final String? titleEn;
  final String? titleFr;
  final String? titleNl;
  final String description;
  final String? descriptionEn;
  final String? descriptionFr;
  final String? descriptionNl;
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
  final String? extractedSyndicName;
  final String? professionalName;

  /// The work is assigned to an admin / super admin (shown as a blue badge).
  final bool assignedToAdmin;

  // On-site contact
  final String? onSiteContactName;
  final String? onSiteContactPhone;
  final String? onSiteContactEmail;
  /// Phone / e-mail to reach the customer when the on-site contact is incomplete (mission, customer e-mail, syndic).
  final String? fallbackContactPhone;
  final String? fallbackContactEmail;

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

  /// When the record last changed (a status update, a note...): Reports lists the latest work first.
  final DateTime? updatedAt;

  /// Set when a technician sent the work to the admin for review (cleared when an admin saves it).
  final DateTime? submittedAt;
  final String? submittedByName;
  final String? interventionNumber;
  final bool isMaintenance;
  final List<Document> documents;

  const Intervention({
    required this.id,
    required this.title,
    this.titleEn,
    this.titleFr,
    this.titleNl,
    required this.description,
    this.descriptionEn,
    this.descriptionFr,
    this.descriptionNl,
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
    this.extractedSyndicName,
    this.professionalName,
    this.assignedToAdmin = false,
    this.onSiteContactName,
    this.onSiteContactPhone,
    this.onSiteContactEmail,
    this.fallbackContactPhone,
    this.fallbackContactEmail,
    this.adminFeedback,
    this.urgency,
    this.sector,
    this.category,
    this.delayReason,
    this.delayDetails,
    this.delayedRescheduleDate,
    this.completedAt,
    this.updatedAt,
    this.submittedAt,
    this.submittedByName,
    this.documents = const [],
  });

  Intervention copyWith({
    String? id,
    String? title,
    String? titleEn,
    String? titleFr,
    String? titleNl,
    String? description,
    String? descriptionEn,
    String? descriptionFr,
    String? descriptionNl,
    InterventionStatus? status,
    DateTime? scheduledDate,
    String? address,
    String? buildingId,
    String? city,
    String? syndicId,
    String? proId,
    String? syndicName,
    String? extractedSyndicName,
    String? professionalName,
    bool? assignedToAdmin,
    String? onSiteContactName,
    String? onSiteContactPhone,
    String? onSiteContactEmail,
    String? fallbackContactPhone,
    String? fallbackContactEmail,
    String? adminFeedback,
    String? urgency,
    String? sector,
    String? delayReason,
    String? delayDetails,
    DateTime? delayedRescheduleDate,
    DateTime? completedAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    String? submittedByName,
    String? interventionNumber,
    bool? isMaintenance,
    List<Document>? documents,
  }) {
    return Intervention(
      id: id ?? this.id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      titleFr: titleFr ?? this.titleFr,
      titleNl: titleNl ?? this.titleNl,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionFr: descriptionFr ?? this.descriptionFr,
      descriptionNl: descriptionNl ?? this.descriptionNl,
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
      extractedSyndicName: extractedSyndicName ?? this.extractedSyndicName,
      professionalName: professionalName ?? this.professionalName,
      assignedToAdmin: assignedToAdmin ?? this.assignedToAdmin,
      onSiteContactName: onSiteContactName ?? this.onSiteContactName,
      onSiteContactPhone: onSiteContactPhone ?? this.onSiteContactPhone,
      onSiteContactEmail: onSiteContactEmail ?? this.onSiteContactEmail,
      fallbackContactPhone: fallbackContactPhone ?? this.fallbackContactPhone,
      fallbackContactEmail: fallbackContactEmail ?? this.fallbackContactEmail,
      adminFeedback: adminFeedback ?? this.adminFeedback,
      urgency: urgency ?? this.urgency,
      sector: sector ?? this.sector,
      category: category ?? this.category,
      delayReason: delayReason ?? this.delayReason,
      delayDetails: delayDetails ?? this.delayDetails,
      delayedRescheduleDate: delayedRescheduleDate ?? this.delayedRescheduleDate,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedByName: submittedByName ?? this.submittedByName,
      documents: documents ?? this.documents,
    );
  }
}
