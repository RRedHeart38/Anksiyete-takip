import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/journal_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/navigation_provider.dart';

class JournalEntryDetailScreen extends StatelessWidget {
  final JournalEntry entry;

  const JournalEntryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final bool isThoughtRecord = entry.type == 'thought';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('d MMMM y, HH:mm', 'tr_TR').format(entry.date)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kayıt tipine göre başlık göster
            Text(
              isThoughtRecord ? 'Düşünce Kaydı Detayları' : 'Anksiyete Kaydı Detayları',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Kayıt tipine göre ilgili veri alanlarını göster
            if (isThoughtRecord)
              ..._buildThoughtRecordDetails(entry.data)
            else
              ..._buildAnxietyEntryDetails(entry.data),

            const SizedBox(height: 40),

            // Sadece Düşünce Kayıtları için AI analiz butonu
            if (isThoughtRecord)
              ElevatedButton.icon(
                icon: const Icon(Icons.psychology_alt_rounded),
                label: const Text('Yapay Zeka ile Analiz Et'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  // ChatProvider'daki analiz fonksiyonunu çağır
                  context.read<ChatProvider>().analyzeJournalEntry(entry);
                  context.read<NavigationProvider>().changeTab(3);

                  // Detay ekranını kapatıp ana ekrana dön
                  Navigator.of(context).popUntil((route) => route.isFirst);

                  // TODO: Kullanıcıyı doğrudan sohbet sekmesine yönlendirmek
                  // Bu, daha ileri bir state management konusu (NavigationProvider)
                  // Şimdilik kullanıcı manuel olarak Sohbet sekmesine gidecek.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Analiz için Sohbet ekranına bakınız.')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Anksiyete kaydı detaylarını oluşturan yardımcı metod
  List<Widget> _buildAnxietyEntryDetails(Map<String, dynamic> data) {
    return [
      _buildDetailRow('Kaygı Seviyesi:', (data['kaygiSeviyesi'] ?? 0).toString()),
      _buildDetailRow('Tetikleyici:', data['tetikleyici'] ?? 'Belirtilmemiş'),
      _buildDetailRow('Notlar:', data['notlar'] ?? 'Ek not yok'),
    ];
  }

  // Düşünce kaydı detaylarını oluşturan yardımcı metod
  List<Widget> _buildThoughtRecordDetails(Map<String, dynamic> data) {
    return [
      _buildDetailRow('1. Durum:', data['durum'] ?? ''),
      _buildDetailRow('2. Olumsuz Düşünce:', data['olumsuz_dusunce'] ?? ''),
      _buildDetailRow('3. Duygular:', data['duygular'] ?? ''),
      _buildDetailRow('4. Kanıtlar:', data['kanitlar'] ?? ''),
      _buildDetailRow('5. Karşı Kanıtlar:', data['karsi_kanitlar'] ?? ''),
      _buildDetailRow('6. Alternatif Düşünce:', data['alternatif_dusunce'] ?? ''),
    ];
  }

  // Tek bir detay satırını oluşturan yardımcı metod
  Widget _buildDetailRow(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.4)),
          const Divider(height: 16),
        ],
      ),
    );
  }
}