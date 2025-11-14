import 'package:flutter/material.dart';
import 'package:neurolink/widgets/neomorphic_card.dart';
import 'package:neurolink/screens/games/memory_card_game_screen.dart';
import 'package:neurolink/screens/games/object_identification_game_screen.dart';
import 'package:neurolink/screens/games/sequence_game_screen.dart';

class MemoryGamesScreen extends StatelessWidget {
  const MemoryGamesScreen({super.key});

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
          'Memory Games',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a Game',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Exercise your mind with fun activities',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            _buildGameCard(
              context,
              icon: Icons.grid_on,
              title: 'Memory Card Game',
              description: 'Match pairs of cards',
              color: Theme.of(context).colorScheme.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MemoryCardGameScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildGameCard(
              context,
              icon: Icons.touch_app,
              title: 'Object Identification',
              description: 'Tap the correct object',
              color: Theme.of(context).colorScheme.secondary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ObjectIdentificationGameScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildGameCard(
              context,
              icon: Icons.memory,
              title: 'Sequence Game',
              description: 'Remember the pattern',
              color: Theme.of(context).colorScheme.tertiary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SequenceGameScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return NeomorphicCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
