import 'package:hive/hive.dart';

part 'document.g.dart';

/// A vehicle-related document (e.g. insurance, PUC, registration).
@HiveType(typeId: 4)
class Document {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String vehicleId;

  /// Document type — either a well-known enum value name or a custom string.
  @HiveField(2)
  final String documentType;

  @HiveField(3)
  final DateTime expiryDate;

  @HiveField(4)
  final DateTime? issueDate;

  @HiveField(5)
  final String? documentNumber;

  /// Local file system path to a photo or PDF of the document.
  @HiveField(6)
  final String? filePath;

  const Document({
    required this.id,
    required this.vehicleId,
    required this.documentType,
    required this.expiryDate,
    this.issueDate,
    this.documentNumber,
    this.filePath,
  });

  Document copyWith({
    String? id,
    String? vehicleId,
    String? documentType,
    DateTime? expiryDate,
    DateTime? issueDate,
    String? documentNumber,
    String? filePath,
    bool clearIssueDate = false,
    bool clearDocumentNumber = false,
    bool clearFilePath = false,
  }) {
    return Document(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      documentType: documentType ?? this.documentType,
      expiryDate: expiryDate ?? this.expiryDate,
      issueDate: clearIssueDate ? null : (issueDate ?? this.issueDate),
      documentNumber:
          clearDocumentNumber ? null : (documentNumber ?? this.documentNumber),
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'documentType': documentType,
      'expiryDate': expiryDate.toIso8601String(),
      'issueDate': issueDate?.toIso8601String(),
      'documentNumber': documentNumber,
      'filePath': filePath,
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      documentType: json['documentType'] as String,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      issueDate: json['issueDate'] != null
          ? DateTime.parse(json['issueDate'] as String)
          : null,
      documentNumber: json['documentNumber'] as String?,
      filePath: json['filePath'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Document &&
        other.id == id &&
        other.vehicleId == vehicleId &&
        other.documentType == documentType &&
        other.expiryDate == expiryDate &&
        other.issueDate == issueDate &&
        other.documentNumber == documentNumber &&
        other.filePath == filePath;
  }

  @override
  int get hashCode => Object.hash(
        id,
        vehicleId,
        documentType,
        expiryDate,
        issueDate,
        documentNumber,
        filePath,
      );

  @override
  String toString() {
    return 'Document(id: $id, vehicleId: $vehicleId, documentType: $documentType, '
        'expiryDate: $expiryDate, issueDate: $issueDate, '
        'documentNumber: $documentNumber)';
  }
}
