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
      isAiDetected: json['is_ai_detected'] == 1 || json['is_ai_detected'] == true,
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
    );
  }
}
