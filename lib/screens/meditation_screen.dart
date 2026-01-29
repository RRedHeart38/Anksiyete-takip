import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import '../models/meditation.dart';
import 'meditation_player_screen.dart';

class MeditationScreen extends StatelessWidget {
  const MeditationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meditations = Meditation.getMeditations();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditasyon ve Mindfulness'),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Kısa Meditasyonlar', FlutterRemix.mental_health_line, const Color(0xFF9C27B0)),
          ...meditations
              .where((m) => m.type == 'meditation')
              .map((m) => _buildMeditationCard(context, m)),
          
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Mindfulness Egzersizleri', FlutterRemix.focus_3_line, const Color(0xFF009688)),
          ...meditations
              .where((m) => m.type == 'mindfulness')
              .map((m) => _buildMeditationCard(context, m)),
          
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Beden Taraması', FlutterRemix.mental_health_line, const Color(0xFFFF9800)),
          ...meditations
              .where((m) => m.type == 'body_scan')
              .map((m) => _buildMeditationCard(context, m)),
          
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Görselleştirme', FlutterRemix.eye_line, const Color(0xFF3F51B5)),
          ...meditations
              .where((m) => m.type == 'visualization')
              .map((m) => _buildMeditationCard(context, m)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeditationCard(BuildContext context, Meditation meditation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: meditation.color.withOpacity(0.05), // Reduced opacity for better look in dark mode
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1), // Use divider color for border
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MeditationPlayerScreen(meditation: meditation),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meditation.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meditation.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          height: 1.3,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: meditation.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FlutterRemix.time_line, size: 14, color: meditation.color),
                            const SizedBox(width: 4),
                            Text(
                              '${meditation.duration} dk',
                              style: TextStyle(
                                color: meditation.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: meditation.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: meditation.color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(FlutterRemix.play_fill, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

