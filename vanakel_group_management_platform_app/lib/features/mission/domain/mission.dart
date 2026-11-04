import '../../intervention/domain/document.dart';

enum MissionStatus { pending, approved, rejected, completed, needsReview }

enum MissionUrgency { low, normal, urgent }

/// A follow-up email (reply, reminder, forward...) attached to a mission
/// instead of being created as a duplicate mission.
class MissionFollowUp {
  final String id;
  final String? subject;
  final String? summary;
  final String? reason; // reference | thread | building_title | merge
  final DateTime? createdAt;

  const MissionFollowUp({required this.id, this.subject, this.summary, this.reason, this.createdAt});
}

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

  /// Set when the mission looks like a duplicate of another one (admin review).
  final String? possibleDuplicateOfId;
  final int? duplicateScore;
  final List<MissionFollowUp> followUps;

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
    this.possibleDuplicateOfId,
    this.duplicateScore,
    this.followUps = const [],
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
    String? possibleDuplicateOfId,
    int? duplicateScore,
    List<MissionFollowUp>? followUps,
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
      possibleDuplicateOfId: possibleDuplicateOfId ?? this.possibleDuplicateOfId,
      duplicateScore: duplicateScore ?? this.duplicateScore,
      followUps: followUps ?? this.followUps,
    );
  }
}
