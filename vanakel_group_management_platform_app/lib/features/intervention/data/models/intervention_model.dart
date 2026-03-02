import '../../domain/intervention.dart';

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
