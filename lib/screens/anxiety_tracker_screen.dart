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
import '../providers/achievement_provider.dart';
import '../providers/goal_provider.dart';
import 'goals_screen.dart';
import 'thought_record_screen.dart';
import 'ai_analyses_screen.dart';
import 'profile_screen.dart';

class AnxietyTrackerScreen extends StatefulWidget {
  const AnxietyTrackerScreen({super.key});

  @override
  State<AnxietyTrackerScreen> createState() => _AnxietyTrackerScreenState();
}

class _AnxietyTrackerScreenState extends State<AnxietyTrackerScreen> {
  double _anxietyLevel = 5;
  final TextEditingController _triggerController = TextEditingController();


  @override
  void dispose() {
    _triggerController.dispose();

    super.dispose();
  }

  Future<void> _saveEntry() async {
    HapticFeedback.mediumImpact();

    final entryData = {
      'kaygiSeviyesi': _anxietyLevel.round(),
      'tetikleyici': _triggerController.text,
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Giriş kaydedildi ve analiz ediliyor...'),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _anxietyLevel = 5;
        _triggerController.clear();

      });
      navProvider.changeTab(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anxietyProvider = context.watch<AnxietyDataProvider>();
    final userDataProvider = context.watch<UserDataProvider>();
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPremiumHeader(context, userDataProvider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Row(
                    children: [
                       Expanded(child: _buildStreakCard(context, userDataProvider, theme.primaryColor)),
                       const SizedBox(width: 12),
                       Expanded(child: _buildWeeklyAverageCard(context, anxietyProvider, theme.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDailyTipCard(context, "Bugün kendine 5 dakika ayır ve sadece nefesine odaklan."),
                  const SizedBox(height: 24),
                  _buildTrackingSection(context, theme),
                  const SizedBox(height: 24),
                  _buildGoalsWidget(context),
                  const SizedBox(height: 24),
                  _buildChartCard(context, anxietyProvider, theme.primaryColor),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, UserDataProvider userProvider) {
    final userName = userProvider.userName;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba,',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildHeaderIconButton(
                    context, 
                    FlutterRemix.robot_line, 
                    () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiAnalysesScreen()))
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderIconButton(
                    context, 
                    FlutterRemix.user_smile_line, 
                    () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()))
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, UserDataProvider provider, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(FlutterRemix.fire_fill, color: Colors.orange, size: 32),
          const SizedBox(height: 8),
          Text(
            '${provider.streakCount}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Günlük Seri',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAverageCard(BuildContext context, AnxietyDataProvider provider, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(
             provider.weeklyAverage > 7 ? FlutterRemix.emotion_sad_line
            : provider.weeklyAverage > 4 ? FlutterRemix.emotion_normal_line
            : FlutterRemix.emotion_happy_line,
            color: primaryColor, 
            size: 32
          ),
          const SizedBox(height: 8),
          provider.isLoading
             ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
             : Text(
                provider.weeklyAverage.toStringAsFixed(1),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
          Text(
            'Haftalık Ort.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTipCard(BuildContext context, String tip) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Colors.white.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(FlutterRemix.lightbulb_flash_line, color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Günün Tavsiyesi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bugün Nasıl Hissediyorsun?',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              // Emoji Reaction
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _anxietyLevel),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Icon(
                    value > 7 ? FlutterRemix.emotion_sad_line
                    : value > 4 ? FlutterRemix.emotion_normal_line
                    : FlutterRemix.emotion_happy_line,
                    size: 48,
                    color: Color.lerp(Colors.green, Colors.red, (value-1) / 9),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                _anxietyLevel.round().toString(),
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primaryColor),
              ),
              Text('Kaygı Seviyesi', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              
              const SizedBox(height: 24),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 12,
                  activeTrackColor: Color.lerp(Colors.green, Colors.red, (_anxietyLevel-1)/9),
                  inactiveTrackColor: Colors.grey[200],
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16, elevation: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                  activeTickMarkColor: Colors.transparent,
                  inactiveTickMarkColor: Colors.transparent,
                ),
                child: Slider(
                  value: _anxietyLevel,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (val) {
                     setState(() => _anxietyLevel = val);
                     HapticFeedback.selectionClick();
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              Column(
                children: [
                  _buildInput(context, _triggerController, 'Neler tetikledi?', FlutterRemix.flashlight_fill),

                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: theme.primaryColor.withOpacity(0.4),
                  ),
                  child: const Text('KAYDET VE ANALİZ ET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInput(BuildContext context, TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  // Reuse previous logic but style it better
  Widget _buildGoalsWidget(BuildContext context) {
    return Consumer<GoalProvider>(
      builder: (context, goalProvider, _) {
        final activeGoals = goalProvider.activeGoals.take(2).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hedeflerin', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
                  child: const Text('Tümünü Gör'),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (activeGoals.isEmpty)
               _buildEmptyGoalCard(context),
            ...activeGoals.map((g) => _buildGoalCard(context, g)),
          ],
        );
      },
    );
  }
  
  Widget _buildGoalCard(BuildContext context, dynamic goal) {
     final double progress = (goal.progress ?? 0) / (goal.target ?? 1);
     final isDark = Theme.of(context).brightness == Brightness.dark;
     
     return Container(
       margin: const EdgeInsets.only(bottom: 12),
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: Theme.of(context).cardColor,
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
         boxShadow: [
           if (!isDark)
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
         ]
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold)),
               Text('${goal.progress}/${goal.target}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
             ],
           ),
           const SizedBox(height: 8),
           ClipRRect(
             borderRadius: BorderRadius.circular(4),
             child: LinearProgressIndicator(
               value: progress,
               backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
               color: Theme.of(context).primaryColor,
               minHeight: 6,
             ),
           ),
         ],
       ),
     );
  }

  Widget _buildEmptyGoalCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(FlutterRemix.add_circle_line, color: Colors.grey[400], size: 32),
              const SizedBox(height: 8),
              Text("Yeni Hedef Ekle", style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, AnxietyDataProvider provider, Color primaryColor) {
    if (provider.isChartLoading) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Haftalık Özet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: LineChart(
             LineChartData(
               gridData: const FlGridData(show: false),
               titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                     switch(v.toInt()) {
                       case 1: return const Text('Pzt', style: TextStyle(fontSize: 10, color: Colors.grey));
                       case 4: return const Text('Per', style: TextStyle(fontSize: 10, color: Colors.grey));
                       case 7: return const Text('Paz', style: TextStyle(fontSize: 10, color: Colors.grey));
                     }
                     return const Text('');
                  })),
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
                   barWidth: 3,
                   isStrokeCapRound: true,
                   dotData: const FlDotData(show: false),
                   belowBarData: BarAreaData(show: true, color: primaryColor.withOpacity(0.1)),
                 ),
               ],
             ),
          ),
        ),
      ],
    );
  }
}