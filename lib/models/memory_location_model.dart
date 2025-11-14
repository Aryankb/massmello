class MemoryLocationModel {
  final String id;
  final String userId;
  final String locationName;
  final double latitude;
  final double longitude;
  final double radius;
  final List<String> photos;
  final String description;
  final String? audioPath;
  final DateTime createdAt;

  MemoryLocationModel({
    required this.id,
    required this.userId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.photos,
    required this.description,
    this.audioPath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'locationName': locationName,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'photos': photos,
    'description': description,
    'audioPath': audioPath,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MemoryLocationModel.fromJson(Map<String, dynamic> json) => MemoryLocationModel(
    id: json['id'] as String,
    userId: json['userId'] as String,
    locationName: json['locationName'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    radius: (json['radius'] as num).toDouble(),
    photos: List<String>.from(json['photos'] as List),
    description: json['description'] as String,
    audioPath: json['audioPath'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  MemoryLocationModel copyWith({
    String? id,
    String? userId,
    String? locationName,
    double? latitude,
    double? longitude,
    double? radius,
    List<String>? photos,
    String? description,
    String? audioPath,
    DateTime? createdAt,
  }) => MemoryLocationModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    locationName: locationName ?? this.locationName,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radius: radius ?? this.radius,
    photos: photos ?? this.photos,
    description: description ?? this.description,
    audioPath: audioPath ?? this.audioPath,
    createdAt: createdAt ?? this.createdAt,
  );
}
