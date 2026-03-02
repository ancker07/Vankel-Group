import '../../domain/intervention.dart';
import '../../domain/document.dart';

class InterventionModel extends Intervention {
  const InterventionModel({
    required super.id,
    required super.title,
    required super.address,
    required super.description,
    required super.status,
    required super.scheduledDate,
    super.tenantContact,
    super.codes = const [],
    super.documents = const [],
  });

  factory InterventionModel.fromJson(Map<String, dynamic> json) {
    return InterventionModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'No Title',
      address: json['address'] as String? ?? 'No Address',
      description: json['description'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      scheduledDate: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : DateTime.now(),
      tenantContact: json['tenant_contact'] as String?,
      codes:
          (json['codes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
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
      'address': address,
      'description': description,
      'status': status.name,
      'scheduled_at': scheduledDate.toIso8601String(),
      'tenant_contact': tenantContact,
      'codes': codes,
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

  static InterventionStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'scheduled':
        return InterventionStatus.scheduled;
      case 'in_progress':
        return InterventionStatus.in_progress;
      case 'delayed':
        return InterventionStatus.delayed;
      case 'completed':
        return InterventionStatus.completed;
      default:
        return InterventionStatus.scheduled;
    }
  }

  Intervention toEntity() {
    return Intervention(
      id: id,
      title: title,
      address: address,
      description: description,
      status: status,
      scheduledDate: scheduledDate,
      tenantContact: tenantContact,
      codes: codes,
    );
  }
}
