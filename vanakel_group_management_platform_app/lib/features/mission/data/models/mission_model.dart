import '../../../intervention/domain/document.dart';
import '../../domain/mission.dart';

class MissionModel extends Mission {
  const MissionModel({
    required super.id,
    required super.title,
    required super.description,
    required super.address,
    required super.status,
    required super.urgency,
    required super.createdAt,
    super.isAiDetected = false,
    super.documents = const [],
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? '',
      address: json['building']?['address'] as String? ?? 'No Address',
      status: _parseStatus(json['status'] as String?),
      urgency: _parseUrgency(json['urgency'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
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
      description: description,
      address: address,
      status: status,
      urgency: urgency,
      createdAt: createdAt,
      isAiDetected: isAiDetected,
      documents: documents,
    );
  }
}