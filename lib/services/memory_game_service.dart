import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:massmello/models/memory_game_score_model.dart';

class MemoryGameService {
  static const String _scoresKey = 'game_scores';

  Future<void> saveScore(MemoryGameScoreModel score) async {
    try {
      final scores = await getScores();
      scores.add(score);
      await _saveAll(scores);
    } catch (e) {
      debugPrint('Error saving score: $e');
      rethrow;
    }
  }

  Future<List<MemoryGameScoreModel>> getScores({String? gameType}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoresData = prefs.getString(_scoresKey);
      if (scoresData == null) return [];
      
      final List<dynamic> scoresList = json.decode(scoresData) as List;
      final allScores = scoresList.map((s) => MemoryGameScoreModel.fromJson(s as Map<String, dynamic>)).toList();
      
      if (gameType != null) {
        return allScores.where((s) => s.gameType == gameType).toList();
      }
      
      return allScores;
    } catch (e) {
      debugPrint('Error getting scores: $e');
      return [];
    }
  }

  Future<int> getHighScore(String gameType) async {
    try {
      final scores = await getScores(gameType: gameType);
      if (scores.isEmpty) return 0;
      
      return scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
    } catch (e) {
      debugPrint('Error getting high score: $e');
      return 0;
    }
  }

  Future<void> _saveAll(List<MemoryGameScoreModel> scores) async {
    final prefs = await SharedPreferences.getInstance();
    final scoresData = scores.map((s) => s.toJson()).toList();
    await prefs.setString(_scoresKey, json.encode(scoresData));
  }
}
