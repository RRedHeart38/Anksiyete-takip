// lib/screens/breathing_exercise_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // <-- YENİ İMPORT
import 'breathing_478_screen.dart';
import 'breathing_box_screen.dart';
import 'breathing_diaphragmatic_screen.dart';
import 'breathing_deep_screen.dart';
import 'breathing_alternate_nostril_screen.dart';

class BreathingExerciseScreen extends StatelessWidget {
  final String? exerciseType;

  const BreathingExerciseScreen({super.key, this.exerciseType});

  Widget _getExerciseScreen(String? type) {
    switch (type) {
      case '4-7-8 Nefesi':
      case '4-7-8 Tekniği':
        return const Breathing478Screen();
      case 'Kutu Nefesi':
      case 'Kare Nefesi':
        return const BreathingBoxScreen();
      case 'Diyafram Nefesi':
        return const BreathingDiaphragmaticScreen();
      case 'Odaklanmış Nefes':
      case 'Odaklanmış Nefes Egzersizi':
      case 'Derin Nefes Egzersizi':
      case 'Derin Karın Nefesi': // Sohbet ekranından gelebilecek yeni bir varyasyon
        return const BreathingDeepScreen();
      case 'Alternatif Burun Nefesi':
        return const BreathingAlternateNostrilScreen();
      default:
      // Bilinmeyen bir egzersiz türü gelirse, ana listeye yönlendir.
        return const BreathingExerciseScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (exerciseType != null) {
      return _getExerciseScreen(exerciseType);
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nefes Egzersizleri'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bir nefes egzersizi seçin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildExerciseCard(
              context,
              title: '4-7-8 Tekniği',
              description: 'Anksiyete ve stresi hızla azaltmak için.',
              icon: Icons.access_alarm,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Breathing478Screen())),
            ).animate().fade(delay: 100.ms).slideX(),
            _buildExerciseCard(
              context,
              title: 'Kutu Nefesi',
              description: 'Odaklanmayı ve sakinleşmeyi sağlar.',
              icon: Icons.square_foot_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BreathingBoxScreen())),
            ).animate().fade(delay: 200.ms).slideX(),
            _buildExerciseCard(
              context,
              title: 'Diyafram Nefesi',
              description: 'Karından nefes alarak gevşemeyi aktive eder.',
              icon: Icons.spa_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BreathingDiaphragmaticScreen())),
            ).animate().fade(delay: 300.ms).slideX(),
            _buildExerciseCard(
              context,
              title: 'Derin Nefes Egzersizi',
              description: 'Kapasitenizi kullanarak yavaşça nefes alın.',
              icon: Icons.favorite_border_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BreathingDeepScreen())),
            ).animate().fade(delay: 400.ms).slideX(),
            _buildExerciseCard(
              context,
              title: 'Alternatif Burun Nefesi',
              description: 'Vücut dengesini ve zihni sakinleştirmeye yardımcı olur.',
              icon: Icons.air,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BreathingAlternateNostrilScreen())),
            ).animate().fade(delay: 500.ms).slideX(),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(description, style: theme.textTheme.bodyMedium),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        onTap: onTap,
      ),
    );
  }
}