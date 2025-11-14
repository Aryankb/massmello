import 'dart:async';
import 'package:flutter/material.dart';
import 'package:massmello/widgets/neomorphic_button.dart';
import 'package:massmello/services/memory_game_service.dart';
import 'package:massmello/services/user_service.dart';
import 'package:massmello/models/memory_game_score_model.dart';

class ObjectIdentificationGameScreen extends StatefulWidget {
  const ObjectIdentificationGameScreen({super.key});

  @override
  State<ObjectIdentificationGameScreen> createState() => _ObjectIdentificationGameScreenState();
}

class _ObjectIdentificationGameScreenState extends State<ObjectIdentificationGameScreen> {
  final List<Map<String, dynamic>> _objects = [
    {'icon': '🥄', 'name': 'Spoon'},
    {'icon': '🍎', 'name': 'Apple'},
    {'icon': '☕', 'name': 'Cup'},
    {'icon': '🚗', 'name': 'Car'},
    {'icon': '📱', 'name': 'Phone'},
    {'icon': '🏠', 'name': 'House'},
    {'icon': '⚽', 'name': 'Ball'},
    {'icon': '🌺', 'name': 'Flower'},
  ];

  int _currentRound = 0;
  int _score = 0;
  String? _targetObject;
  List<Map<String, dynamic>> _displayedObjects = [];
  bool _showFeedback = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _startNewRound();
  }

  void _startNewRound() {
    setState(() {
      _showFeedback = false;
      _displayedObjects = (_objects..shuffle()).take(4).toList();
      _targetObject = _displayedObjects[0]['name'];
      _displayedObjects.shuffle();
    });
  }

  void _onObjectTap(Map<String, dynamic> object) {
    if (_showFeedback) return;

    final correct = object['name'] == _targetObject;
    setState(() {
      _isCorrect = correct;
      _showFeedback = true;
      if (correct) _score += 10;
      _currentRound++;
    });

    Timer(const Duration(seconds: 1), () {
      if (_currentRound >= 10) {
        _gameComplete();
      } else {
        _startNewRound();
      }
    });
  }

  Future<void> _gameComplete() async {
    final user = await UserService().getUser();
    
    if (user != null) {
      final gameScore = MemoryGameScoreModel(
        userId: user.id,
        gameType: 'object_identification',
        score: _score,
        timestamp: DateTime.now(),
        difficulty: 'easy',
      );
      await MemoryGameService().saveScore(gameScore);
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('🎉 Game Over!'),
          content: Text('Your Score: $_score/100'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentRound = 0;
                  _score = 0;
                });
                _startNewRound();
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Exit'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Object Identification',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreItem('Round', '${_currentRound + 1}/10'),
                _buildScoreItem('Score', _score.toString()),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Tap the',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _targetObject ?? '',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _displayedObjects.length,
                itemBuilder: (context, index) {
                  final object = _displayedObjects[index];
                  return GestureDetector(
                    onTap: () => _onObjectTap(object),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withValues(alpha: 0.5)
                                : const Color(0xFFA3B1C6),
                            offset: const Offset(6, 6),
                            blurRadius: 12,
                          ),
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white,
                            offset: const Offset(-6, -6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          object['icon'],
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_showFeedback)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isCorrect
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _isCorrect ? '✓ Correct!' : '✗ Try again next time',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
