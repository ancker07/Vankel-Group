enum MissionStatus { pending, approved, rejected, completed }
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

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.status,
    required this.urgency,
    required this.createdAt,
    this.isAiDetected = false,
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
    );
  }
}
