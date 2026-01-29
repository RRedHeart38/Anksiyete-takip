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

  static const List<Widget> _widgetOptions = <Widget>[
    AnxietyTrackerScreen(),
    SuggestionsScreen(),
    AiChatScreen(),
    JournalScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Widget oluşturulduğunda profil kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileCompletion();
      _setupAchievementListener();
      _refreshNotifications();
    });
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
    final userName = userDataProvider.userName;
    final navProvider = context.watch<NavigationProvider>();

    // Profil bilgileri eksikse loading göster (yönlendirme yapılacak)
    if (!userDataProvider.isProfileComplete && !userDataProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true, // Status bar'ın arkasına geçmesi için
      body: IndexedStack(
        // Index'i artık NavigationProvider'dan alıyoruz
        index: navProvider.selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(FlutterRemix.pulse_line), label: 'Takip'),
          BottomNavigationBarItem(icon: Icon(FlutterRemix.lightbulb_line), label: 'Öneriler'),
          BottomNavigationBarItem(icon: Icon(FlutterRemix.chat_2_line), label: 'Sohbet'),
          BottomNavigationBarItem(icon: Icon(FlutterRemix.book_open_line), label: 'Günlük'),
        ],
        // Mevcut index'i NavigationProvider'dan alıyoruz
        currentIndex: navProvider.selectedIndex,
        // Tıklandığında NavigationProvider'daki fonksiyonu çağırıyoruz (dinlemeden)
        onTap: (index) {
          context.read<NavigationProvider>().changeTab(index);
        },
      ),
    );
  }
}