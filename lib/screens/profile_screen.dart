import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/user_data_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/journal_provider.dart';
import '../models/achievement.dart';
import 'settings_screen.dart'; // Import SettingsScreen

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context),
            _buildStatsSection(context),
            _buildAchievementsSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, userProvider, _) {
        final userData = userProvider.userData;
        final userName = userProvider.userName;
        final streakCount = userProvider.streakCount;

        return Stack(
          children: [
            Container(
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
                children: [
                  // Avatar
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey[100],
                        child: Icon(
                          FlutterRemix.user_smile_line,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Profession
                  if (userData['meslek'] != null)
                    Text(
                      userData['meslek'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                  const SizedBox(height: 20),
                  // Streak Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FlutterRemix.fire_fill, color: Colors.orangeAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '$streakCount Günlük Seri',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Back Button
            Positioned(
              top: 50,
              left: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
            ),
            // Settings Icon -> Navigate to SettingsScreen
            Positioned(
              top: 50, 
              right: 16,
              child: IconButton(
                onPressed: () {
                   Navigator.of(context).push(
                     MaterialPageRoute(builder: (context) => const SettingsScreen())
                   );
                },
                icon: const Icon(FlutterRemix.settings_3_line, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Consumer2<JournalProvider, AchievementProvider>(
      builder: (context, journalProvider, achievementProvider, _) {
        final entries = journalProvider.entries;
        final anxietyEntries = entries.where((e) => e.type == 'anxiety').length;
        final thoughtEntries = entries.where((e) => e.type == 'thought').length;
        final journalEntries = entries.where((e) => e.type == 'journal').length;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'İstatistikler',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: FlutterRemix.heart_line,
                      label: 'Anksiyete\nKayıtları',
                      value: anxietyEntries.toString(),
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: FlutterRemix.lightbulb_line,
                      label: 'Düşünce\nKayıtları',
                      value: thoughtEntries.toString(),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: FlutterRemix.book_open_line,
                      label: 'Günlük\nYazıları',
                      value: journalEntries.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: FlutterRemix.trophy_line,
                      label: 'Başarımlar',
                      value: '${achievementProvider.unlockedCount}/${achievementProvider.totalCount}',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    return Consumer<AchievementProvider>(
      builder: (context, achievementProvider, _) {
        if (achievementProvider.isLoading) {
          return _buildAchievementsShimmer(context);
        }

        final achievements = achievementProvider.achievements;
        final progress = achievementProvider.progressPercentage;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Başarımlar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${achievementProvider.unlockedCount}/${achievementProvider.totalCount}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 8,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Achievement grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  return _buildAchievementCard(context, achievements[index]);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Helper to map icons string to IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star_line': return FlutterRemix.star_line;
      case 'calendar_line': return FlutterRemix.calendar_line;
      case 'calendar_fill': return FlutterRemix.calendar_fill;
      case 'trophy_line': return FlutterRemix.trophy_line;
      case 'lightbulb_line': return FlutterRemix.lightbulb_line;
      case 'book_open_line': return FlutterRemix.book_open_line;
      case 'lungs_line': return FlutterRemix.lungs_line;
      case 'mental_health_line': return FlutterRemix.mental_health_line;
      case 'focus_3_line': return FlutterRemix.focus_3_line;
      case 'quill_pen_line': return FlutterRemix.quill_pen_line;
      case 'book_2_line': return FlutterRemix.book_2_line;
      case 'leaf_line': return FlutterRemix.leaf_line;
      case 'chat_3_line': return FlutterRemix.chat_3_line;
      case 'line_chart_line': return FlutterRemix.line_chart_line;
      case 'flag_line': return FlutterRemix.flag_line;
      default: return FlutterRemix.star_line;
    }
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    final icon = _getIconData(achievement.icon);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? (isDark 
                ? primaryColor.withOpacity(0.15) 
                : primaryColor.withOpacity(0.08))
            : (isDark 
                ? Colors.grey[800]!.withOpacity(0.5) 
                : Colors.grey[100]?.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? primaryColor.withOpacity(isDark ? 0.4 : 0.3)
              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
             icon,
             size: 28,
             color: isUnlocked ? primaryColor : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isUnlocked 
                  ? (isDark ? Colors.white : Colors.black87)
                  : Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(height: 200, color: Colors.white),
      ),
    );
  }
}
