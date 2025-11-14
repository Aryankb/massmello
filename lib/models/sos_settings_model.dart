class SOSSettingsModel {
  final String userId;
  final double homeLatitude;
  final double homeLongitude;
  final double radius;
  final bool isEnabled;
  final DateTime? lastTriggered;
  final String backendUrl;

  SOSSettingsModel({
    required this.userId,
    required this.homeLatitude,
    required this.homeLongitude,
    required this.radius,
    required this.isEnabled,
    this.lastTriggered,
    required this.backendUrl,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'homeLatitude': homeLatitude,
    'homeLongitude': homeLongitude,
    'radius': radius,
    'isEnabled': isEnabled,
    'lastTriggered': lastTriggered?.toIso8601String(),
    'backendUrl': backendUrl,
  };

  factory SOSSettingsModel.fromJson(Map<String, dynamic> json) => SOSSettingsModel(
    userId: json['userId'] as String,
    homeLatitude: (json['homeLatitude'] as num).toDouble(),
    homeLongitude: (json['homeLongitude'] as num).toDouble(),
    radius: (json['radius'] as num).toDouble(),
    isEnabled: json['isEnabled'] as bool,
    lastTriggered: json['lastTriggered'] != null ? DateTime.parse(json['lastTriggered'] as String) : null,
    backendUrl: json['backendUrl'] as String,
  );

  SOSSettingsModel copyWith({
    String? userId,
    double? homeLatitude,
    double? homeLongitude,
    double? radius,
    bool? isEnabled,
    DateTime? lastTriggered,
    String? backendUrl,
  }) => SOSSettingsModel(
    userId: userId ?? this.userId,
    homeLatitude: homeLatitude ?? this.homeLatitude,
    homeLongitude: homeLongitude ?? this.homeLongitude,
    radius: radius ?? this.radius,
    isEnabled: isEnabled ?? this.isEnabled,
    lastTriggered: lastTriggered ?? this.lastTriggered,
    backendUrl: backendUrl ?? this.backendUrl,
  );
}
