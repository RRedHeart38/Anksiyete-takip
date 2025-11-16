import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Bu import satırı zaten vardı
import '../providers/journal_provider.dart';
import 'journal_entry_detail_screen.dart';
import '../widgets/skeleton_loader.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, journalProvider, child) {
        if (journalProvider.isLoading) {
          // Shimmer efekti kısmı aynı kalıyor
          return Shimmer.fromColors(
            baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
            child: ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) => const SkeletonLoaderCard(),
            ),
          );
        }

        if (journalProvider.entries.isEmpty) {
          // Boş durum ekranı aynı kalıyor
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FlutterRemix.emotion_normal_line, size: 60, color: Colors.grey[600]),
                const SizedBox(height: 16),
                const Text('Günlüğün henüz boş.', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    'Bir anksiyete veya düşünce kaydı eklediğinde burada görünecek.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: journalProvider.entries.length,
          itemBuilder: (context, index) {
            final entry = journalProvider.entries[index];
            if (entry.type == 'anxiety') {
              return _buildAnxietyEntryCard(context, entry);
            } else {
              return _buildThoughtRecordCard(context, entry);
            }
          },
        );
      },
    );
  }

  Widget _buildAnxietyEntryCard(BuildContext context, JournalEntry entry) {
    final data = entry.data;
    final level = data['kaygiSeviyesi'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          child: Text(level.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text('Anksiyete Kaydı: Seviye $level'),
        subtitle: Text(
          (data['tetikleyici'] as String?)?.isNotEmpty == true ? data['tetikleyici'] : 'Tetikleyici belirtilmemiş',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(DateFormat('dd MMM', 'tr_TR').format(entry.date)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => JournalEntryDetailScreen(entry: entry)),
          );
        },
      ),
    )
    // --- ANİMASYON SATIRI EKLENDİ ---
        .animate().fade(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }

  Widget _buildThoughtRecordCard(BuildContext context, JournalEntry entry) {
    final data = entry.data;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.psychology, color: Colors.white, size: 20),
        ),
        title: const Text('Düşünce Kaydı'),
        subtitle: Text(
          data['olumsuz_dusunce'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(DateFormat('dd MMM', 'tr_TR').format(entry.date)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => JournalEntryDetailScreen(entry: entry)),
          );
        },
      ),
    )
    // --- ANİMASYON SATIRI EKLENDİ ---
        .animate().fade(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}