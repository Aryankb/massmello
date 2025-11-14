class PersonModel {
  final String id;
  final String name;
  final String? relationship;
  final String? notes;
  final String? photoUrl;
  final DateTime addedDate;
  final List<String> identifiedDates;
  final Map<String, dynamic>? aiAnalysis;

  PersonModel({
    required this.id,
    required this.name,
    this.relationship,
    this.notes,
    this.photoUrl,
    required this.addedDate,
    List<String>? identifiedDates,
    this.aiAnalysis,
  }) : identifiedDates = identifiedDates ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'notes': notes,
      'photoUrl': photoUrl,
      'addedDate': addedDate.toIso8601String(),
      'identifiedDates': identifiedDates,
      'aiAnalysis': aiAnalysis,
    };
  }

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      relationship: json['relationship'],
      notes: json['notes'],
      photoUrl: json['photoUrl'],
      addedDate: DateTime.parse(json['addedDate'] ?? DateTime.now().toIso8601String()),
      identifiedDates: List<String>.from(json['identifiedDates'] ?? []),
      aiAnalysis: json['aiAnalysis'],
    );
  }

  PersonModel copyWith({
    String? id,
    String? name,
    String? relationship,
    String? notes,
    String? photoUrl,
    DateTime? addedDate,
    List<String>? identifiedDates,
    Map<String, dynamic>? aiAnalysis,
  }) {
    return PersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      addedDate: addedDate ?? this.addedDate,
      identifiedDates: identifiedDates ?? this.identifiedDates,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
    );
  }
}
