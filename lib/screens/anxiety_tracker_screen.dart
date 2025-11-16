import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/anxiety_data_provider.dart';
import '../providers/user_data_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/navigation_provider.dart';

import 'thought_record_screen.dart';

class AnxietyTrackerScreen extends StatefulWidget {
  const AnxietyTrackerScreen({super.key});

  @override
  State<AnxietyTrackerScreen> createState() => _AnxietyTrackerScreenState();
}

class _AnxietyTrackerScreenState extends State<AnxietyTrackerScreen> {
  // Bu ekranın kendi içindeki geçici durumları (form alanları)
  double _anxietyLevel = 5;
  final TextEditingController _triggerController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _triggerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Kaydetme işlemi artık ilgili provider'ları tetikliyor
  Future<void> _saveEntry() async {
    HapticFeedback.mediumImpact(); // Dokunsal geri bildirim

    // 1. UI'dan anlık verileri bir haritaya topla
    final entryData = {
      'kaygiSeviyesi': _anxietyLevel.round(),
      'tetikleyici': _triggerController.text,
      'notlar': _notesController.text,
    };

    // 2. Fonksiyonları çağırmak için provider'ları "dinlemeden" al (listen: false)
    final anxietyProvider = context.read<AnxietyDataProvider>();
    final userProvider = context.read<UserDataProvider>();
    final chatProvider = context.read<ChatProvider>();
    final navProvider = context.read<NavigationProvider>();

    // 3. İlgili Provider'lardaki fonksiyonları sırasıyla çağır
    await anxietyProvider.saveAnxietyEntry(entryData);
    await userProvider.updateStreakAndGoals();
    chatProvider.analyzeAnxietyEntry(entryData);

    // 4. Kullanıcıya geri bildirim ver ve formu temizle
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş kaydedildi ve analiz ediliyor...')),
      );
      setState(() {
        _anxietyLevel = 5;
        _triggerController.clear();
        _notesController.clear();
      });

      // 5. Kullanıcıyı "Sohbet" sekmesine yönlendir
      navProvider.changeTab(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verileri dinlemek için provider'ları "izle" (watch)
    final anxietyProvider = context.watch<AnxietyDataProvider>();
    final userDataProvider = context.watch<UserDataProvider>();
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStreakAndGoalCard(context, userDataProvider, primaryColor),
          _buildWeeklyAverageCard(context, anxietyProvider, primaryColor),
          const SizedBox(height: 24),
          _buildDailyTipCard(context, "Bugün kendine 5 dakika ayır ve sadece nefesine odaklan."),
          const SizedBox(height: 24),
          _buildThoughtRecordButton(context, primaryColor),
          const SizedBox(height: 24),
          _buildAnxietyTrackingForm(context, primaryColor),
          const SizedBox(height: 24),
          _buildChartCard(context, anxietyProvider, primaryColor),
          const SizedBox(height: 24),
          _buildReportButton(context),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- ARAYÜZÜ OLUŞTURAN YARDIMCI METODLAR ---

  Widget _buildStreakAndGoalCard(BuildContext context, UserDataProvider provider, Color primaryColor) {
    final goal = provider.activeGoal;
    final goalProgress = goal['progress'] as int? ?? 0;
    final goalTarget = goal['target'] as int? ?? 1;
    final double progressValue = goalTarget > 0 ? goalProgress / goalTarget : 0;

    return Card(
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.local_fire_department_rounded, color: Colors.orange[600], size: 28),
              const SizedBox(width: 8),
              Text('${provider.streakCount} Günlük Seri!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[800])),
            ]),
            const SizedBox(height: 16),
            Text('Haftalık Hedef: $goalTarget gün giriş yap', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressValue, backgroundColor: Colors.grey[300],
              color: primaryColor, minHeight: 8, borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerRight, child: Text('$goalProgress / $goalTarget gün tamamlandı', style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyAverageCard(BuildContext context, AnxietyDataProvider provider, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Haftalık Kaygı Ortalama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primaryColor)),
              const SizedBox(height: 8),
              provider.isLoading
                  ? Shimmer.fromColors(
                baseColor: primaryColor.withOpacity(0.3),
                highlightColor: primaryColor.withOpacity(0.1),
                child: Container(width: 80, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
              )
                  : Text(provider.weeklyAverage.toStringAsFixed(1), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          )),
          Icon(
            provider.weeklyAverage > 7 ? FlutterRemix.emotion_sad_line
                : provider.weeklyAverage > 4 ? FlutterRemix.emotion_normal_line
                : FlutterRemix.emotion_happy_line,
            color: primaryColor, size: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTipCard(BuildContext context, String tip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Günlük Öneri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
          ),
          child: Text(tip, style: const TextStyle(fontSize: 16, height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildThoughtRecordButton(BuildContext context, Color primaryColor) {
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.psychology, color: primaryColor),
        title: const Text('Düşünce Kaydı Yap', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Düşünce kalıplarını keşfet ve değiştir.'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ThoughtRecordScreen()));
        },
      ),
    );
  }

  Widget _buildAnxietyTrackingForm(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kaygı Seviyesi Takibi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kaygı Seviyesi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text(_anxietyLevel.round().toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primaryColor)),
                ],
              ),
              Slider(
                value: _anxietyLevel, min: 1, max: 10, divisions: 9,
                label: _anxietyLevel.round().toString(),
                onChanged: (value) => setState(() => _anxietyLevel = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _triggerController,
                decoration: InputDecoration(labelText: 'Kaygınızı ne tetikledi?', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(FlutterRemix.flashlight_line)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Ek Notlar', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(FlutterRemix.pencil_line)),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveEntry,
                  icon: const Icon(Icons.save),
                  label: const Text('Kaydet ve Analiz Et'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(BuildContext context, AnxietyDataProvider provider, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Son 7 Günlük Kaygı Grafiği', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 12),
        provider.isChartLoading
            ? Shimmer.fromColors(
          baseColor: Theme.of(context).cardColor,
          highlightColor: Theme.of(context).scaffoldBackgroundColor,
          child: Container(height: 250, decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12))),
        )
            : Container(
          height: 250, padding: const EdgeInsets.all(16).copyWith(right: 24, top: 24),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    const style = TextStyle(fontSize: 12);
                    switch (value.toInt()) {
                      case 1: return const Text('Pzt', style: style);
                      case 2: return const Text('Sal', style: style);
                      case 3: return const Text('Çar', style: style);
                      case 4: return const Text('Per', style: style);
                      case 5: return const Text('Cum', style: style);
                      case 6: return const Text('Cmt', style: style);
                      case 7: return const Text('Paz', style: style);
                    }
                    return const Text('');
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                  getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 12)),
                )),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 1, maxX: 7, minY: 0, maxY: 10,
              lineBarsData: [
                LineChartBarData(
                  spots: provider.anxietyChartData,
                  isCurved: true,
                  color: primaryColor,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: primaryColor.withOpacity(0.3)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportButton(BuildContext context) {
    return SizedBox(width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () { /* TODO: Rapor oluşturma fonksiyonunu provider'a bağla */ },
        icon: const Icon(FlutterRemix.file_text_line),
        label: const Text('Rapor Oluştur'),
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}