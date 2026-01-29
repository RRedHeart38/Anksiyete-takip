// lib/screens/breathing_exercise_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_remix/flutter_remix.dart';
import '../models/breathing_pattern.dart';
import 'universal_breathing_player_screen.dart';

class BreathingExerciseScreen extends StatelessWidget {
  final String? exerciseType;

  const BreathingExerciseScreen({super.key, this.exerciseType});

  @override
  Widget build(BuildContext context) {
    // Check if we came from AI Chat with a specific type
    if (exerciseType != null) {
      final patterns = BreathingPattern.getPatterns();
      // Try to find matching pattern logic (simple string matching)
      try {
        final pattern = patterns.firstWhere((p) => 
          p.title == exerciseType || 
          p.title.contains(exerciseType!) || 
          exerciseType!.contains(p.id)
        , orElse: () => patterns.first);
        
        return UniversalBreathingPlayerScreen(pattern: pattern);
      } catch (e) {
        // Fallback to normal list if not found
      }
    }

    final patterns = BreathingPattern.getPatterns();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nefes Egzersizleri'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: patterns.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nefesini Keşfet',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ).animate().fadeIn().slideX(),
                  const SizedBox(height: 8),
                  Text(
                    'Doğru nefes almak, stresi yönetmenin en hızlı yoludur. İhtiyacına uygun bir teknik seç.',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                ],
              ),
            );
          }
          
          final pattern = patterns[index - 1];
          return _buildExerciseCard(context, pattern, index).animate().fadeIn(delay: (200 + (index * 100)).ms).slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, BreathingPattern pattern, int index) {
    final theme = Theme.of(context);
    final color = pattern.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05), // Dark mode friendly opacity
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => UniversalBreathingPlayerScreen(pattern: pattern))
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(FlutterRemix.lungs_line, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pattern.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pattern.description,
                        style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
