import '../../intervention/domain/document.dart';

enum MissionStatus { pending, approved, rejected, completed, needsReview }

enum MissionUrgency { low, normal, urgent }

class Mission {
  final String id;
  final String title;
  final String description;
  final String address;
  final MissionStatus status;
  final MissionUrgency urgency;
  final DateTime createdAt;
  final bool isAiDetected;
  final String? buildingId;
  final String? syndicId;
  final String? syndicName;
  final String? extractedSyndicName;
  final String? sector;
  final List<Document> documents;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.status,
    required this.urgency,
    required this.createdAt,
    this.buildingId,
    this.syndicId,
    this.syndicName,
    this.extractedSyndicName,
    this.sector,
    this.isAiDetected = false,
    this.documents = const [],
  });

  Mission copyWith({
    String? id,
    String? title,
    String? description,
    String? address,
    MissionStatus? status,
    MissionUrgency? urgency,
    DateTime? createdAt,
    bool? isAiDetected,
    String? buildingId,
    String? syndicId,
    String? syndicName,
    String? extractedSyndicName,
    String? sector,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      status: status ?? this.status,
      urgency: urgency ?? this.urgency,
      createdAt: createdAt ?? this.createdAt,
      isAiDetected: isAiDetected ?? this.isAiDetected,
      buildingId: buildingId ?? this.buildingId,
      syndicId: syndicId ?? this.syndicId,
      syndicName: syndicName ?? this.syndicName,
      extractedSyndicName: extractedSyndicName ?? this.extractedSyndicName,
      sector: sector ?? this.sector,
    );
  }
}
