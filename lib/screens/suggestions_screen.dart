// lib/screens/suggestions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_application_1/screens/music_screen.dart';
import 'package:flutter_application_1/screens/breathing_exercise_screen.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/skeleton_loader.dart';

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {

        final List<Map<String, dynamic>> aiResponses = chatProvider.chatMessages
            .where((message) =>
        message['ai_response'] != null &&
            message['id'] != null &&
            message['source'] == 'anxiety_tracker')
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Öneriler', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildActionCard(
                context,
                title: 'Sakinleştirici Müzikler',
                description: 'Rahatlamana yardımcı olacak müzikleri dinle.',
                icon: FlutterRemix.sound_module_line,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MusicScreen()));
                },
              ),
              _buildActionCard(
                context,
                title: 'Nefes Egzersizleri',
                description: 'Stresi azaltmak için rehberli egzersizleri dene.',
                icon: FlutterRemix.lungs_line,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BreathingExerciseScreen()));
                },
              ),
              const SizedBox(height: 24),
              const Text('Kişisel Analizlerin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // --- DEĞİŞİKLİK BURADA BAŞLIYOR ---

              if (chatProvider.isLoadingHistory)
              // Yüklenirken Shimmer efekti göster
                Shimmer.fromColors(
                  baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
                  highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Column(children: List.generate(3, (index) => const SkeletonLoaderCard())),
                )
              else if (aiResponses.isEmpty)
              // Öneri yoksa bilgilendirme mesajı göster
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Text(
                      'Henüz yapay zekadan bir önerin yok. Yeni bir anksiyete kaydı girdiğinde, yapay zeka sana burada kişisel öneriler sunacak.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
              // Öneriler varsa animasyonlu bir şekilde listele
                ...aiResponses.map((response) {
                  return _buildSuggestionCard(
                    context,
                    suggestion: response['ai_response'],
                    docId: response['id'],
                    isHelpful: response['isHelpful'],
                    onFeedback: (docId, isHelpful) {
                      context.read<ChatProvider>().saveFeedback(docId, isHelpful);
                    },
                  )
                  // --- ANİMASYON SATIRI ---
                      .animate().fade(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionCard(BuildContext context, {
    required String suggestion,
    required String docId,
    required bool? isHelpful,
    required Function(String docId, bool isHelpful) onFeedback,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(suggestion, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          const SizedBox(height: 16),
          if (isHelpful == null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onFeedback(docId, true),
                    icon: const Icon(FlutterRemix.thumb_up_line),
                    label: const Text('Faydalı'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onFeedback(docId, false),
                    icon: const Icon(FlutterRemix.thumb_down_line),
                    label: const Text('Değil'),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                isHelpful ? 'Bu öneriyi faydalı buldun. 😊' : 'Bu öneriyi faydalı bulmadın. 😔',
                style: TextStyle(
                  color: isHelpful ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: theme.colorScheme.primary, size: 30),
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(description, style: theme.textTheme.bodyMedium),
        trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        onTap: onTap,
      ),
    );
  }
}