import '../../../intervention/domain/document.dart';
import '../../domain/mission.dart';

class MissionModel extends Mission {
  const MissionModel({
    required super.id,
    required super.title,
    super.titleEn,
    super.titleFr,
    super.titleNl,
    required super.description,
    super.descriptionEn,
    super.descriptionFr,
    super.descriptionNl,
    required super.address,
    required super.status,
    required super.urgency,
    required super.createdAt,
    super.buildingId,
    super.syndicId,
    super.syndicName,
    super.syndicEmail,
    super.syndicPhone,
    super.extractedSyndicName,
    super.sector,
    super.isAiDetected = false,
    super.documents = const [],
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'No Title',
      titleEn: json['title_en'] as String?,
      titleFr: json['title_fr'] as String?,
      titleNl: json['title_nl'] as String?,
      description: json['description'] as String? ?? '',
      descriptionEn: json['description_en'] as String?,
      descriptionFr: json['description_fr'] as String?,
      descriptionNl: json['description_nl'] as String?,
      address: json['building']?['address'] as String? ?? json['extracted_address'] as String? ?? 'No Address',
      syndicId: json['syndic_id']?.toString() ?? json['syndicId']?.toString(),
      syndicName: json['syndic'] != null ? (json['syndic']['company_name'] ?? json['syndic']['companyName']) as String? : null,
      syndicEmail: json['syndic'] != null ? (json['syndic']['email']) as String? : null,
      syndicPhone: json['syndic'] != null ? (json['syndic']['phone']) as String? : null,
      extractedSyndicName: json['extracted_syndic_name'] as String? ?? json['extractedSyndicName'] as String?,
      status: _parseStatus(json['status'] as String?),
      urgency: _parseUrgency(json['urgency'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      buildingId: json['building_id']?.toString() ?? json['buildingId']?.toString(),
      sector: json['sector'] as String?,
      isAiDetected:
          json['is_ai_detected'] == 1 || json['is_ai_detected'] == true,
      documents:
          (json['documents'] as List<dynamic>?)
              ?.map(
                (doc) => Document(
                  id: doc['id'].toString(),
                  fileName: doc['file_name'] as String? ?? 'Unknown',
                  filePath: doc['file_path'] as String? ?? '',
                  fileType:
                      doc['file_type'] as String? ?? 'application/octet-stream',
                  createdAt: doc['created_at'] != null
                      ? DateTime.parse(doc['created_at'] as String)
                      : null,
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'urgency': urgency.name,
      'created_at': createdAt.toIso8601String(),
      'is_ai_detected': isAiDetected,
      'documents': documents
          .map(
            (doc) => {
              'id': doc.id,
              'file_name': doc.fileName,
              'file_path': doc.filePath,
              'file_type': doc.fileType,
              'created_at': doc.createdAt?.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  static MissionStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return MissionStatus.pending;
      case 'needs_review':
        return MissionStatus.needsReview;
      case 'approved':
        return MissionStatus.approved;
      case 'rejected':
        return MissionStatus.rejected;
      case 'completed':
        return MissionStatus.completed;
      default:
        return MissionStatus.pending;
    }
  }

  static MissionUrgency _parseUrgency(String? urgency) {
    switch (urgency?.toLowerCase()) {
      case 'low':
        return MissionUrgency.low;
      case 'normal':
        return MissionUrgency.normal;
      case 'urgent':
        return MissionUrgency.urgent;
      default:
        return MissionUrgency.normal;
    }
  }

  Mission toEntity() {
    return Mission(
      id: id,
      title: title,
      titleEn: titleEn,
      titleFr: titleFr,
      titleNl: titleNl,
      description: description,
      descriptionEn: descriptionEn,
      descriptionFr: descriptionFr,
      descriptionNl: descriptionNl,
      address: address,
      status: status,
      urgency: urgency,
      createdAt: createdAt,
      buildingId: buildingId,
      syndicId: syndicId,
      syndicName: syndicName,
      syndicEmail: syndicEmail,
      syndicPhone: syndicPhone,
      extractedSyndicName: extractedSyndicName,
      sector: sector,
      isAiDetected: isAiDetected,
      documents: documents,
    );
  }
}