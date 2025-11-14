class ObjectNoteModel {
  final String id;
  final String objectName;
  final String objectLabel;  // ML Kit detected label
  final String note;
  final String? audioPath;   // Path to audio note
  final String? imagePath;   // Reference image of the object
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Additional object features

  ObjectNoteModel({
    required this.id,
    required this.objectName,
    required this.objectLabel,
    required this.note,
    this.audioPath,
    this.imagePath,
    required this.createdAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'objectName': objectName,
      'objectLabel': objectLabel,
      'note': note,
      'audioPath': audioPath,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ObjectNoteModel.fromJson(Map<String, dynamic> json) {
    return ObjectNoteModel(
      id: json['id'] as String,
      objectName: json['objectName'] as String,
      objectLabel: json['objectLabel'] as String,
      note: json['note'] as String,
      audioPath: json['audioPath'] as String?,
      imagePath: json['imagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
