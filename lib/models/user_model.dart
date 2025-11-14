class UserModel {
  final String id;
  final String name;
  final String location;
  final double homeLatitude;
  final double homeLongitude;
  final List<String> profileImages;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.location,
    required this.homeLatitude,
    required this.homeLongitude,
    required this.profileImages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'homeLatitude': homeLatitude,
    'homeLongitude': homeLongitude,
    'profileImages': profileImages,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    location: json['location'] as String,
    homeLatitude: (json['homeLatitude'] as num).toDouble(),
    homeLongitude: (json['homeLongitude'] as num).toDouble(),
    profileImages: List<String>.from(json['profileImages'] as List),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  UserModel copyWith({
    String? id,
    String? name,
    String? location,
    double? homeLatitude,
    double? homeLongitude,
    List<String>? profileImages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserModel(
    id: id ?? this.id,
    name: name ?? this.name,
    location: location ?? this.location,
    homeLatitude: homeLatitude ?? this.homeLatitude,
    homeLongitude: homeLongitude ?? this.homeLongitude,
    profileImages: profileImages ?? this.profileImages,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
