import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neurolink/widgets/neomorphic_button.dart';
import 'package:neurolink/services/memory_game_service.dart';
import 'package:neurolink/services/user_service.dart';
import 'package:neurolink/models/memory_game_score_model.dart';

class MemoryCardGameScreen extends StatefulWidget {
  const MemoryCardGameScreen({super.key});

  @override
  State<MemoryCardGameScreen> createState() => _MemoryCardGameScreenState();
}

class _MemoryCardGameScreenState extends State<MemoryCardGameScreen> {
  final List<String> _icons = ['🌟', '🎨', '🎵', '🌸', '🌈', '⚡'];
  List<String> _cards = [];
  List<bool> _revealed = [];
  List<int> _selected = [];
  int _matches = 0;
  int _moves = 0;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _cards = [..._icons, ..._icons]..shuffle();
    _revealed = List.filled(_cards.length, false);
    _selected = [];
    _matches = 0;
    _moves = 0;
  }

  void _onCardTap(int index) {
    if (_isChecking || _revealed[index] || _selected.contains(index)) return;

    setState(() {
      _selected.add(index);
      _revealed[index] = true;
    });

    if (_selected.length == 2) {
      _moves++;
      _isChecking = true;

      Timer(const Duration(milliseconds: 800), () {
        if (_cards[_selected[0]] == _cards[_selected[1]]) {
          _matches++;
          if (_matches == _icons.length) {
            _gameComplete();
          }
        } else {
          setState(() {
            _revealed[_selected[0]] = false;
            _revealed[_selected[1]] = false;
          });
        }
        setState(() {
          _selected.clear();
          _isChecking = false;
        });
      });
    }
  }

  Future<void> _gameComplete() async {
    final score = 1000 - (_moves * 10);
    final user = await UserService().getUser();
    
    if (user != null) {
      final gameScore = MemoryGameScoreModel(
        userId: user.id,
        gameType: 'memory_card',
        score: score > 0 ? score : 100,
        timestamp: DateTime.now(),
        difficulty: 'easy',
      );
      await MemoryGameService().saveScore(gameScore);
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('🎉 Congratulations!'),
          content: Text('You completed the game in $_moves moves!\nScore: $score'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(_initializeGame);
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
          'Memory Card Game',
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
                _buildScoreItem('Moves', _moves.toString()),
                _buildScoreItem('Matches', '$_matches/${_icons.length}'),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) => _buildCard(index),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: NeomorphicButton(
              onPressed: () => setState(_initializeGame),
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

  Widget _buildCard(int index) {
    final isRevealed = _revealed[index];
    
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isRevealed
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.5)
                  : const Color(0xFFA3B1C6),
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              offset: const Offset(-4, -4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Text(
            isRevealed ? _cards[index] : '?',
            style: TextStyle(
              fontSize: isRevealed ? 40 : 32,
              fontWeight: FontWeight.bold,
              color: isRevealed
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
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
