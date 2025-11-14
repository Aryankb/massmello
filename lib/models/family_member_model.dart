class FamilyMemberModel {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String relationship;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyMemberModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'phoneNumber': phoneNumber,
    'relationship': relationship,
    'imagePath': imagePath,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) => FamilyMemberModel(
    id: json['id'] as String,
    userId: json['userId'] as String,
    name: json['name'] as String,
    phoneNumber: json['phoneNumber'] as String,
    relationship: json['relationship'] as String,
    imagePath: json['imagePath'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  FamilyMemberModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phoneNumber,
    String? relationship,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FamilyMemberModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    relationship: relationship ?? this.relationship,
    imagePath: imagePath ?? this.imagePath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
