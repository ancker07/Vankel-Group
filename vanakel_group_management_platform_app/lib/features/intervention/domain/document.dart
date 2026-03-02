class Document {
  final String id;
  final String fileName;
  final String filePath;
  final String fileType;
  final DateTime? createdAt;

  const Document({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    this.createdAt,
  });

  bool get isImage => fileType.startsWith('image/');
  bool get isPdf => fileType == 'application/pdf';
  bool get isDocument => !isImage && !isPdf;

  Document copyWith({
    String? id,
    String? fileName,
    String? filePath,
    String? fileType,
    DateTime? createdAt,
  }) {
    return Document(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}