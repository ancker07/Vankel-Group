import 'document.dart';

enum InterventionStatus { scheduled, in_progress, delayed, completed }

class Intervention {
  final String id;
  final String title;
  final String address;
  final String description;
  final InterventionStatus status;
  final DateTime scheduledDate;
  final String? tenantContact;
  final List<String> codes;
  final List<Document> documents;

  const Intervention({
    required this.id,
    required this.title,
    required this.address,
    required this.description,
    required this.status,
    required this.scheduledDate,
    this.tenantContact,
    this.codes = const [],
    this.documents = const [],
  });

  Intervention copyWith({
    String? id,
    String? title,
    String? address,
    String? description,
    InterventionStatus? status,
    DateTime? scheduledDate,
    String? tenantContact,
    List<String>? codes,
    List<Document>? documents,
  }) {
    return Intervention(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      description: description ?? this.description,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      tenantContact: tenantContact ?? this.tenantContact,
      codes: codes ?? this.codes,
      documents: documents ?? this.documents,
    );
  }
}
