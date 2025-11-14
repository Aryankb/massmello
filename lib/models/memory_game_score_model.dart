class MemoryGameScoreModel {
  final String userId;
  final String gameType;
  final int score;
  final DateTime timestamp;
  final String difficulty;

  MemoryGameScoreModel({
    required this.userId,
    required this.gameType,
    required this.score,
    required this.timestamp,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'gameType': gameType,
    'score': score,
    'timestamp': timestamp.toIso8601String(),
    'difficulty': difficulty,
  };

  factory MemoryGameScoreModel.fromJson(Map<String, dynamic> json) => MemoryGameScoreModel(
    userId: json['userId'] as String,
    gameType: json['gameType'] as String,
    score: json['score'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
    difficulty: json['difficulty'] as String,
  );

  MemoryGameScoreModel copyWith({
    String? userId,
    String? gameType,
    int? score,
    DateTime? timestamp,
    String? difficulty,
  }) => MemoryGameScoreModel(
    userId: userId ?? this.userId,
    gameType: gameType ?? this.gameType,
    score: score ?? this.score,
    timestamp: timestamp ?? this.timestamp,
    difficulty: difficulty ?? this.difficulty,
  );
}
