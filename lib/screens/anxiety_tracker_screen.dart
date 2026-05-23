import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../providers/anxiety_data_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_data_provider.dart';
import 'ai_analyses_screen.dart';
import 'goals_screen.dart';
import 'profile_screen.dart';

class AnxietyTrackerScreen extends StatefulWidget {
  const AnxietyTrackerScreen({super.key});

  @override
  State<AnxietyTrackerScreen> createState() => _AnxietyTrackerScreenState();
}

class _AnxietyTrackerScreenState extends State<AnxietyTrackerScreen> {
  double _anxietyLevel = 5;

  static const Color _background = Color(0xFF121212);
  static const Color _surface = Color(0xFF1A1F2E);
  static const Color _surfaceAlt = Color(0xFF20263A);
  static const Color _primaryAccent = Color(0xFF8BC6EC);
  static const Color _secondaryAccent = Color(0xFFC4B5FD);
  static const Color _sageAccent = Color(0xFFA7D7B8);

  static const List<_MoodOption> _moodOptions = [
    _MoodOption(level: 1, emoji: '😌', label: 'Sakin', accent: Color(0xFF9FD5E8)),
    _MoodOption(level: 2, emoji: '🙂', label: 'Yumuşak', accent: Color(0xFF93C5FD)),
    _MoodOption(level: 3, emoji: '😊', label: 'İyi', accent: Color(0xFFA7D7B8)),
    _MoodOption(level: 4, emoji: '😐', label: 'Dengeli', accent: Color(0xFFB6C7F0)),
    _MoodOption(level: 5, emoji: '🤍', label: 'Nötr', accent: Color(0xFFC4B5FD)),
    _MoodOption(level: 6, emoji: '😕', label: 'Karmaşık', accent: Color(0xFF9CCFD6)),
    _MoodOption(level: 7, emoji: '😟', label: 'Gergin', accent: Color(0xFF8BC6EC)),
    _MoodOption(level: 8, emoji: '😣', label: 'Zor', accent: Color(0xFFB7A7E8)),
    _MoodOption(level: 9, emoji: '😰', label: 'Yoğun', accent: Color(0xFFA7C4F2)),
    _MoodOption(level: 10, emoji: '🫧', label: 'Çok yoğun', accent: Color(0xFFC7D7F2)),
  ];

  _MoodOption get _selectedMood =>
      _moodOptions.firstWhere((option) => option.level == _anxietyLevel.round());

  Future<void> _saveEntry() async {
    HapticFeedback.mediumImpact();

    final selectedMood = _selectedMood;
    final entryData = {
      'kaygiSeviyesi': _anxietyLevel.round(),
      'tetikleyici': selectedMood.label,
      'moodEmoji': selectedMood.emoji,
    };

    final anxietyProvider = context.read<AnxietyDataProvider>();
    final userProvider = context.read<UserDataProvider>();
    final chatProvider = context.read<ChatProvider>();
    final navProvider = context.read<NavigationProvider>();
    final achievementProvider = context.read<AchievementProvider>();
    final goalProvider = context.read<GoalProvider>();

    await anxietyProvider.saveAnxietyEntry(entryData);
    await userProvider.updateStreakAndGoals();
    chatProvider.analyzeAnxietyEntry(entryData);
    achievementProvider.checkAchievements();
    await goalProvider.updateProgressByCategory('anxiety_tracking', 1);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Kaydın alındı, analiz hazırlanıyor.'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );

    setState(() {
      _anxietyLevel = 5;
    });
    navProvider.changeTab(2);
  }

  @override
  Widget build(BuildContext context) {
    final anxietyProvider = context.watch<AnxietyDataProvider>();
    final userDataProvider = context.watch<UserDataProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, userDataProvider),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: FlutterRemix.fire_fill,
                        title: 'Seri',
                        value: '${userDataProvider.streakCount}',
                        subtitle: 'gün',
                        accent: _sageAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: _weeklyAverageIcon(anxietyProvider.weeklyAverage),
                        title: 'Ortalama',
                        value: anxietyProvider.isLoading
                            ? '...'
                            : anxietyProvider.weeklyAverage.toStringAsFixed(1),
                        subtitle: 'son 7 gün',
                        accent: _secondaryAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInsightCard(
                  context,
                  title: 'Bugünün ritmi',
                  body: 'Sadece sayı seç, sonra devam et. Gereksiz yazı yok, sadece his ve akış.',
                  accent: colorScheme.secondary,
                ),
                const SizedBox(height: 24),
                _buildTrackingCard(context),
                const SizedBox(height: 24),
                _buildGoalsWidget(context),
                const SizedBox(height: 24),
                _buildChartCard(context, anxietyProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserDataProvider userProvider) {
    final theme = Theme.of(context);
    final userName = userProvider.userName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF20263A), Color(0xFF18263D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba,',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.72),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      userName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: const Color(0xFFF8FAFC),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Yumuşak takip alanın',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFD7E4F7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _buildHeaderIconButton(
                    context,
                    FlutterRemix.robot_line,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiAnalysesScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildHeaderIconButton(
                    context,
                    FlutterRemix.user_smile_line,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: const Color(0xFFF8FAFC), size: 22),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accent,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: const Color(0xFFF8FAFC),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFE2E8F0),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  IconData _weeklyAverageIcon(double average) {
    if (average >= 7) return FlutterRemix.emotion_sad_line;
    if (average >= 4) return FlutterRemix.emotion_normal_line;
    return FlutterRemix.emotion_happy_line;
  }

  Widget _buildInsightCard(
    BuildContext context, {
    required String title,
    required String body,
    required Color accent,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFF8FAFC),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFCBD5E1),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard(BuildContext context) {
    final theme = Theme.of(context);
    final selectedMood = _selectedMood;
    final accent = selectedMood.accent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bugün Nasıl Hissediyorsun?',
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFFF8FAFC),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sayı seç, sonra kaydet. Yazı alanı yok.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.22), Colors.white.withOpacity(0.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: accent.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(selectedMood.emoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 6),
                  Text(
                    '${selectedMood.level}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFFF8FAFC),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              selectedMood.label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFE2E8F0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: accent.withOpacity(0.75),
              inactiveTrackColor: const Color(0xFF30384C),
              thumbColor: Colors.white,
              overlayColor: accent.withOpacity(0.14),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15, elevation: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              trackShape: const RoundedRectSliderTrackShape(),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 0),
            ),
            child: Slider(
              value: _anxietyLevel,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _anxietyLevel = value;
                });
                HapticFeedback.selectionClick();
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _moodOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final option = _moodOptions[index];
                final selected = option.level == _anxietyLevel.round();
                return _MoodButton(
                  option: option,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _anxietyLevel = option.level.toDouble();
                    });
                    HapticFeedback.selectionClick();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveEntry,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: const Color(0xFF101828),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text(
                'KAYDET VE ANALİZ ET',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsWidget(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<GoalProvider>(
      builder: (context, goalProvider, _) {
        final activeGoals = goalProvider.activeGoals.take(2).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hedeflerin',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFFF8FAFC),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GoalsScreen()),
                  ),
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activeGoals.isEmpty) _buildEmptyGoalCard(context),
            ...activeGoals.map((goal) => _buildGoalCard(context, goal)),
          ],
        );
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, dynamic goal) {
    final theme = Theme.of(context);
    final progress = (goal.progress ?? 0) / (goal.target ?? 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFF8FAFC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${goal.progress}/${goal.target}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _secondaryAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFF2B3346),
              color: _primaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGoalCard(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GoalsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _primaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(FlutterRemix.add_line, color: _primaryAccent, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                'Yeni hedef ekle',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFF8FAFC),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, AnxietyDataProvider provider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Haftalık Özet',
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFFF8FAFC),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: _surfaceAlt,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: provider.isChartLoading
              ? SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _secondaryAccent,
                      strokeWidth: 2.4,
                    ),
                  ),
                )
              : provider.anxietyChartData.isEmpty
                  ? SizedBox(
                      height: 220,
                      child: Center(
                        child: Text(
                          'Grafik için birkaç kayıt ekle.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          minX: 1,
                          maxX: 7,
                          minY: 0,
                          maxY: 10,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData: const LineTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: 2,
                                getTitlesWidget: (value, meta) {
                                  final label = value.toInt();
                                  if (![0, 2, 4, 6, 8, 10].contains(label)) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      label.toString(),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 1:
                                      return const Text('Pzt');
                                    case 3:
                                      return const Text('Çrş');
                                    case 5:
                                      return const Text('Cum');
                                    case 7:
                                      return const Text('Paz');
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: provider.anxietyChartData,
                              isCurved: true,
                              curveSmoothness: 0.34,
                              color: _primaryAccent,
                              barWidth: 3.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    _primaryAccent.withOpacity(0.26),
                                    _secondaryAccent.withOpacity(0.10),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _MoodOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 72,
          decoration: BoxDecoration(
            color: selected ? option.accent.withOpacity(0.18) : const Color(0xFF222838),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? option.accent.withOpacity(0.65) : Colors.white.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(selected ? 0.18 : 0.10),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(option.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                option.level.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? const Color(0xFFF8FAFC) : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodOption {
  const _MoodOption({
    required this.level,
    required this.emoji,
    required this.label,
    required this.accent,
  });

  final int level;
  final String emoji;
  final String label;
  final Color accent;
}