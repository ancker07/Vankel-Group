import '../../intervention/domain/document.dart';

enum MissionStatus { pending, approved, rejected, completed, needsReview }

enum MissionUrgency { low, normal, urgent }

class Mission {
  final String id;
  final String title;
  final String? titleEn;
  final String? titleFr;
  final String? titleNl;
  final String description;
  final String? descriptionEn;
  final String? descriptionFr;
  final String? descriptionNl;
  final String address;
  final MissionStatus status;
  final MissionUrgency urgency;
  final DateTime createdAt;
  final bool isAiDetected;
  final String? buildingId;
  final String? syndicId;
  final String? syndicName;
  final String? syndicEmail;
  final String? syndicPhone;
  final String? extractedSyndicName;
  final String? sector;
  final String? onSiteContactName;
  final String? onSiteContactPhone;
  final String? onSiteContactEmail;
  final List<Document> documents;

  const Mission({
    required this.id,
    required this.title,
    this.titleEn,
    this.titleFr,
    this.titleNl,
    required this.description,
    this.descriptionEn,
    this.descriptionFr,
    this.descriptionNl,
    required this.address,
    required this.status,
    required this.urgency,
    required this.createdAt,
    this.buildingId,
    this.syndicId,
    this.syndicName,
    this.syndicEmail,
    this.syndicPhone,
    this.extractedSyndicName,
    this.sector,
    this.onSiteContactName,
    this.onSiteContactPhone,
    this.onSiteContactEmail,
    this.isAiDetected = false,
    this.documents = const [],
  });

  Mission copyWith({
    String? id,
    String? title,
    String? titleEn,
    String? titleFr,
    String? titleNl,
    String? description,
    String? descriptionEn,
    String? descriptionFr,
    String? descriptionNl,
    String? address,
    MissionStatus? status,
    MissionUrgency? urgency,
    DateTime? createdAt,
    bool? isAiDetected,
    String? buildingId,
    String? syndicId,
    String? syndicName,
    String? syndicEmail,
    String? syndicPhone,
    String? extractedSyndicName,
    String? sector,
    String? onSiteContactName,
    String? onSiteContactPhone,
    String? onSiteContactEmail,
    List<Document>? documents,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      titleFr: titleFr ?? this.titleFr,
      titleNl: titleNl ?? this.titleNl,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionFr: descriptionFr ?? this.descriptionFr,
      descriptionNl: descriptionNl ?? this.descriptionNl,
      address: address ?? this.address,
      status: status ?? this.status,
      urgency: urgency ?? this.urgency,
      createdAt: createdAt ?? this.createdAt,
      isAiDetected: isAiDetected ?? this.isAiDetected,
      buildingId: buildingId ?? this.buildingId,
      syndicId: syndicId ?? this.syndicId,
      syndicName: syndicName ?? this.syndicName,
      syndicEmail: syndicEmail ?? this.syndicEmail,
      syndicPhone: syndicPhone ?? this.syndicPhone,
      extractedSyndicName: extractedSyndicName ?? this.extractedSyndicName,
      sector: sector ?? this.sector,
      onSiteContactName: onSiteContactName ?? this.onSiteContactName,
      onSiteContactPhone: onSiteContactPhone ?? this.onSiteContactPhone,
      onSiteContactEmail: onSiteContactEmail ?? this.onSiteContactEmail,
      documents: documents ?? this.documents,
    );
  }
}
