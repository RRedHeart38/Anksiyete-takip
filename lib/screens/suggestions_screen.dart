import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_application_1/screens/music_screen.dart';
import 'package:flutter_application_1/screens/breathing_exercise_screen.dart';
import 'package:flutter_application_1/screens/meditation_screen.dart';
import 'package:flutter_application_1/screens/goals_screen.dart';
import 'package:flutter_application_1/screens/meditation_player_screen.dart';
import 'package:flutter_application_1/models/meditation.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/navigation_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/skeleton_loader.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({Key? key}) : super(key: key);

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().generateDailyPlan();
    });
  }

  void _handlePlanAction(Map<String, dynamic> item) {
    final actionType = item['actionType'];
    final target = item['target'];
    final navProvider = context.read<NavigationProvider>();

    HapticFeedback.lightImpact();

    switch (actionType) {
      case 'BREATHING':
        Navigator.push(context, MaterialPageRoute(builder: (context) => BreathingExerciseScreen(exerciseType: target)));
        break;
      case 'MEDITATION':
        if (target != null) {
          try {
            final meditation = Meditation.getMeditations().firstWhere(
                  (m) => m.title.toLowerCase() == target.toString().toLowerCase(),
              orElse: () => Meditation.getMeditations().first,
            );
            Navigator.push(context, MaterialPageRoute(builder: (context) => MeditationPlayerScreen(meditation: meditation)));
          } catch (e) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MeditationScreen()));
          }
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const MeditationScreen()));
        }
        break;
      case 'JOURNAL':
        navProvider.changeTab(3); 
        break;
      case 'MUSIC':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MusicScreen()));
        break;
      case 'GOAL':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalsScreen()));
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildDailyPlanSection(context, chatProvider),
                      const SizedBox(height: 32),
                      const Text('Kategoriler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildActionCard(
                        context,
                        title: 'Sakinleştirici Müzikler',
                        description: 'Rahatlamana yardımcı olacak müzikleri dinle.',
                        icon: FlutterRemix.sound_module_line,
                        color: Colors.pinkAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MusicScreen())),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Nefes Egzersizleri',
                        description: 'Stresi azaltmak için rehberli egzersizler.',
                        icon: FlutterRemix.lungs_line,
                        color: Colors.blueAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BreathingExerciseScreen())),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Meditasyon',
                        description: 'Zihnini sakinleştir ve farkındalığını artır.',
                        icon: FlutterRemix.mental_health_line,
                        color: Colors.purpleAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MeditationScreen())),
                      ),
                      _buildActionCard(
                        context,
                        title: 'Hedefler',
                        description: 'Kendine hedefler koy ve ilerle.',
                        icon: FlutterRemix.trophy_line,
                        color: Colors.orangeAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalsScreen())),
                      ),
                      
                      const SizedBox(height: 24),
                      const Text('Hızlı İpuçları', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickTipCard(context, 'Kısa Yürüyüş', FlutterRemix.walk_line, Colors.green),
                            _buildQuickTipCard(context, '5-4-3-2-1 Tekniği', FlutterRemix.focus_3_line, Colors.blue),
                            _buildQuickTipCard(context, 'Kas Gevşetme', FlutterRemix.body_scan_line, Colors.purple),
                            _buildQuickTipCard(context, 'Ilık Duş', FlutterRemix.drizzle_line, Colors.orange),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      const Text('Yapay Zeka Önerileri', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildAiSuggestionsList(context, chatProvider),
                      
                      const SizedBox(height: 80), 
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(FlutterRemix.lightbulb_flash_line, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sana Özel',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              Text(
                'Öneriler',
                style: TextStyle(
                  fontSize: 28,
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

  Widget _buildDailyPlanSection(BuildContext context, ChatProvider chatProvider) {
    if (chatProvider.isGeneratingPlan) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor)
            ),
            const SizedBox(width: 16),
            Expanded(child: Text("Yapay zeka bugün için planını hazırlıyor...", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500))),
          ],
        ),
      ).animate().shimmer(duration: 1500.ms);
    }

    if (chatProvider.dailyPlan.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.9),
            const Color(0xFF818CF8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
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
              const Row(
                children: [
                   Icon(FlutterRemix.star_fill, color: Colors.white, size: 20),
                   SizedBox(width: 8),
                   Text("Günün Planı", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(FlutterRemix.refresh_line, color: Colors.white70, size: 20),
                onPressed: () => chatProvider.refreshDailyPlan(),
                tooltip: 'Planı Yenile',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            ],
          ),
          const SizedBox(height: 20),
          ...chatProvider.dailyPlan.map((item) => _buildPlanItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildPlanItem(BuildContext context, Map<String, dynamic> item) {
    IconData icon;
    switch(item['actionType']) {
      case 'BREATHING': icon = FlutterRemix.lungs_line; break;
      case 'MEDITATION': icon = FlutterRemix.mental_health_line; break;
      case 'JOURNAL': icon = FlutterRemix.quill_pen_line; break;
      case 'MUSIC': icon = FlutterRemix.music_2_line; break;
      case 'GOAL': icon = FlutterRemix.task_line; break;
      default: icon = FlutterRemix.check_line;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handlePlanAction(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(item['description'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAiSuggestionsList(BuildContext context, ChatProvider chatProvider) {
    final aiResponses = chatProvider.chatMessages
            .where((message) => message['ai_response'] != null && message['source'] == 'anxiety_tracker')
            .toList();

    if (chatProvider.isLoadingHistory) {
      return Shimmer.fromColors(
          baseColor: Theme.of(context).cardColor,
          highlightColor: Theme.of(context).scaffoldBackgroundColor,
          child: Column(children: List.generate(2, (index) => const SkeletonLoaderCard())),
      );
    }
    
    if (aiResponses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
           children: [
             Icon(FlutterRemix.robot_line, size: 40, color: Colors.grey[400]),
             const SizedBox(height: 12),
             Text(
               'Henüz yapay zekadan kişisel bir önerin yok.',
               style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 4),
             Text(
               'Anksiyete kaydı girdikçe burası dolacak.',
               style: TextStyle(color: Colors.grey[500], fontSize: 12),
               textAlign: TextAlign.center,
             ),
           ],
        ),
      );
    }

    return Column(
      children: aiResponses.map((response) {
        return _buildSuggestionCard(
          context,
          suggestion: response['ai_response'],
          docId: response['id'],
          isHelpful: response['isHelpful'],
          onFeedback: (docId, isHelpful) {
            context.read<ChatProvider>().saveFeedback(docId, isHelpful);
          },
        ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
      }).toList(),
    );
  }

  Widget _buildSuggestionCard(BuildContext context, {
    required String suggestion,
    required String? docId,
    required bool? isHelpful,
    required Function(String docId, bool isHelpful) onFeedback,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FlutterRemix.magic_line, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text("AI Analizi", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(suggestion, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, fontSize: 15)),
          const SizedBox(height: 16),
          if (docId != null) 
            if (isHelpful == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("Faydalı mı?", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => onFeedback(docId, true),
                    icon: const Icon(FlutterRemix.thumb_up_line, size: 20),
                    color: Colors.grey[400],
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    onPressed: () => onFeedback(docId, false),
                    icon: const Icon(FlutterRemix.thumb_down_line, size: 20),
                    color: Colors.grey[400],
                     constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              )
            else
              Text(
                isHelpful ? 'Geri bildirimin için teşekkürler! 😊' : 'Geri bildirimin için teşekkürler. 😔',
                style: TextStyle(
                  color: isHelpful ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12
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
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.3)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[300], size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickTipCard(BuildContext context, String title, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
             child: Icon(icon, color: color, size: 24)
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}