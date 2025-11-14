import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neurolink/widgets/neomorphic_button.dart';
import 'package:neurolink/services/memory_game_service.dart';
import 'package:neurolink/services/user_service.dart';
import 'package:neurolink/models/memory_game_score_model.dart';

class SequenceGameScreen extends StatefulWidget {
  const SequenceGameScreen({super.key});

  @override
  State<SequenceGameScreen> createState() => _SequenceGameScreenState();
}

class _SequenceGameScreenState extends State<SequenceGameScreen> {
  final List<Color> _colors = [
    const Color(0xFF6C63FF),
    const Color(0xFFFF6584),
    const Color(0xFF4CAF50),
    const Color(0xFFFFA726),
  ];
  
  List<int> _sequence = [];
  List<int> _userInput = [];
  int _currentStep = 0;
  bool _isPlaying = false;
  bool _isUserTurn = false;
  int _score = 0;
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    setState(() {
      _sequence = [];
      _userInput = [];
      _currentStep = 0;
      _score = 0;
      _isPlaying = false;
      _isUserTurn = false;
    });
    _addToSequence();
  }

  void _addToSequence() {
    setState(() {
      _sequence.add(_colors.length * (DateTime.now().millisecondsSinceEpoch % 100) ~/ 100);
      _userInput = [];
      _isPlaying = true;
      _isUserTurn = false;
    });
    _playSequence();
  }

  Future<void> _playSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    for (int i = 0; i < _sequence.length; i++) {
      setState(() => _highlightedIndex = _sequence[i]);
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _highlightedIndex = -1);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      _isPlaying = false;
      _isUserTurn = true;
    });
  }

  void _onColorTap(int index) {
    if (!_isUserTurn || _isPlaying) return;

    setState(() {
      _userInput.add(index);
      _highlightedIndex = index;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => _highlightedIndex = -1);
    });

    if (_userInput.length == _sequence.length) {
      _checkSequence();
    }
  }

  void _checkSequence() {
    bool isCorrect = true;
    for (int i = 0; i < _sequence.length; i++) {
      if (_sequence[i] != _userInput[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      setState(() {
        _score += 10;
        _currentStep++;
      });
      
      Future.delayed(const Duration(milliseconds: 500), () {
        _addToSequence();
      });
    } else {
      _gameOver();
    }
  }

  Future<void> _gameOver() async {
    final user = await UserService().getUser();
    
    if (user != null) {
      final gameScore = MemoryGameScoreModel(
        userId: user.id,
        gameType: 'sequence',
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
          title: const Text('Game Over!'),
          content: Text('You reached level $_currentStep\nScore: $_score'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startGame();
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
          'Sequence Game',
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
                _buildScoreItem('Level', _currentStep.toString()),
                _buildScoreItem('Score', _score.toString()),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _isPlaying ? 'Watch the sequence' : _isUserTurn ? 'Your turn!' : 'Get ready...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(32),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => _buildColorButton(index),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: NeomorphicButton(
              onPressed: _startGame,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Restart Game',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(int index) {
    final isHighlighted = _highlightedIndex == index;
    
    return GestureDetector(
      onTap: () => _onColorTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isHighlighted ? _colors[index] : _colors[index].withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: _colors[index].withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : [
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
