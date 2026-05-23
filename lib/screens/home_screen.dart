import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/achievement_provider.dart';
import '../widgets/achievement_notification.dart';
import '../models/achievement.dart';
import '../services/notification_service.dart';
import 'breathing_exercise_screen.dart';
import 'suggestions_screen.dart';
import 'anxiety_tracker_screen.dart';
import 'ai_chat_screen.dart';
import 'journal_screen.dart';
import 'profile_setup_screen.dart';
import 'profile_screen.dart';
import 'ai_analyses_screen.dart';

// Kullanıcı profil bilgilerini kontrol etmek için StatefulWidget'a çevirdik
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;
  int _lastSyncedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    AnxietyTrackerScreen(),
    SuggestionsScreen(),
    AiChatScreen(),
    JournalScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    // Widget oluşturulduğunda profil kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileCompletion();
      _setupAchievementListener();
      _refreshNotifications();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _refreshNotifications() {
    // Uygulama açıldığında bildirimleri yeniden zamanla
    // (30 günlük bildirimlerin sürekli aktif kalması için)
    NotificationService().scheduleDailyNotifications();
  }

  void _setupAchievementListener() {
    final achievementProvider = context.read<AchievementProvider>();
    
    // Achievement callback'ini ayarla
    achievementProvider.onAchievementUnlocked = (Achievement achievement) {
      if (mounted) {
        // Notification'ı göster
        AchievementNotification.show(context, achievement);
      }
    };
  }

  void _checkProfileCompletion() {
    final userDataProvider = context.read<UserDataProvider>();
    
    // Veriler yüklenene kadar bekle
    if (userDataProvider.isLoading) {
      // Veriler yüklenene kadar tekrar kontrol et
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _checkProfileCompletion();
      });
      return;
    }
    
    // Profil bilgileri eksikse ProfileSetupScreen'e yönlendir
    if (!userDataProvider.isProfileComplete && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provider'ları izleyerek (watch) ilgili verileri alıyoruz
    final userDataProvider = context.watch<UserDataProvider>();
    final navProvider = context.watch<NavigationProvider>();

    if (_lastSyncedIndex != navProvider.selectedIndex && _pageController.hasClients) {
      _lastSyncedIndex = navProvider.selectedIndex;
      _pageController.animateToPage(
        navProvider.selectedIndex,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubicEmphasized,
      );
    }

    // Profil bilgileri eksikse loading göster (yönlendirme yapılacak)
    if (!userDataProvider.isProfileComplete && !userDataProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          _lastSyncedIndex = index;
          if (navProvider.selectedIndex != index) {
            context.read<NavigationProvider>().changeTab(index);
          }
        },
        children: _widgetOptions,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              selectedIndex: navProvider.selectedIndex,
              onDestinationSelected: (index) {
                _lastSyncedIndex = index;
                context.read<NavigationProvider>().changeTab(index);
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeInOutCubicEmphasized,
                  );
                }
              },
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const <NavigationDestination>[
                NavigationDestination(icon: Icon(FlutterRemix.pulse_line), selectedIcon: Icon(FlutterRemix.pulse_fill), label: 'Takip'),
                NavigationDestination(icon: Icon(FlutterRemix.lightbulb_line), selectedIcon: Icon(FlutterRemix.lightbulb_fill), label: 'Öneriler'),
                NavigationDestination(icon: Icon(FlutterRemix.chat_2_line), selectedIcon: Icon(FlutterRemix.chat_2_fill), label: 'Sohbet'),
                NavigationDestination(icon: Icon(FlutterRemix.book_open_line), selectedIcon: Icon(FlutterRemix.book_open_fill), label: 'Günlük'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}