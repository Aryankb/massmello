class HologramMessageModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String? audioPath;
  final double latitude;
  final double longitude;
  final double radius;
  final Map<String, dynamic>? anchorData;
  final DateTime createdAt;

  HologramMessageModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.audioPath,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.anchorData,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'audioPath': audioPath,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'anchorData': anchorData,
    'createdAt': createdAt.toIso8601String(),
  };

  factory HologramMessageModel.fromJson(Map<String, dynamic> json) => HologramMessageModel(
    id: json['id'] as String,
    userId: json['userId'] as String,
    title: json['title'] as String,
    message: json['message'] as String,
    audioPath: json['audioPath'] as String?,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    radius: (json['radius'] as num).toDouble(),
    anchorData: json['anchorData'] as Map<String, dynamic>?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  HologramMessageModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? audioPath,
    double? latitude,
    double? longitude,
    double? radius,
    Map<String, dynamic>? anchorData,
    DateTime? createdAt,
  }) => HologramMessageModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    message: message ?? this.message,
    audioPath: audioPath ?? this.audioPath,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radius: radius ?? this.radius,
    anchorData: anchorData ?? this.anchorData,
    createdAt: createdAt ?? this.createdAt,
  );
}
