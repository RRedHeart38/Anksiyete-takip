import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/journal_provider.dart';
import 'journal_entry_detail_screen.dart';
import 'write_journal_screen.dart';
import '../widgets/skeleton_loader.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, journalProvider, child) {
        return Scaffold(
          body: journalProvider.isLoading
              ? Column(
                  children: [
                    _buildHeader(context),
                    Expanded(child: _buildShimmerList(context)),
                  ],
                )
              : journalProvider.entries.isEmpty
                  ? Column(
                      children: [
                        _buildHeader(context),
                        Expanded(child: _buildEmptyState(context)),
                      ],
                    )
                  : Stack(
                      children: [
                        _buildJournalList(context, journalProvider.entries),
                        Positioned(
                          // raise FAB above other persistent bottom UI (e.g. "Günlük" button)
                          bottom: MediaQuery.of(context).padding.bottom + 80,
                          right: 24,
                          child: FloatingActionButton.extended(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const WriteJournalScreen()),
                              );
                            },
                            icon: const Icon(FlutterRemix.quill_pen_line),
                            label: const Text('Yeni Yazı'),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 4,
                          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            const Color(0xFF818CF8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(FlutterRemix.book_read_line, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Duygu durumu ve',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              Text(
                'Günlüğün',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJournalList(BuildContext context, List<JournalEntry> allEntries) {
    final journalEntries = allEntries.where((entry) => entry.type == 'journal').toList();

    // Header dahil edilerek liste oluşturuluyor
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 180), // FAB için daha geniş boşluk
      itemCount: journalEntries.length + 1, // +1 Header için
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(context);
        }
        final entry = journalEntries[index - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildJournalEntryCard(context, entry)
              .animate()
              .fade(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOut, delay: ((index - 1) * 50).ms),
        );
      },
    );
  }

  Widget _buildJournalEntryCard(BuildContext context, JournalEntry entry) {
    final data = entry.data;
    final title = data['baslik'] ?? 'Başlıksız';
    final content = data['icerik'] ?? '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => JournalEntryDetailScreen(entry: entry)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('d MMMM yyyy', 'tr_TR').format(entry.date),
                        style: TextStyle(color: theme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8), height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(FlutterRemix.quill_pen_line, size: 48, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 24),
            const Text('Henüz bir şey yazmadın.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'İçini dökmek, rahatlamanın en iyi yollarından biridir. Hadi, bugünü anlatarak başla.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const WriteJournalScreen()),
                );
              },
              icon: const Icon(FlutterRemix.edit_line),
              label: const Text('İlk Yazını Yaz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) => const SkeletonLoaderCard(),
      ),
    );
  }
}