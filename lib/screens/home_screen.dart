import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import '../providers/navigation_provider.dart';
import 'settings_screen.dart';
import 'breathing_exercise_screen.dart';
import 'suggestions_screen.dart';
import 'anxiety_tracker_screen.dart';
import 'ai_chat_screen.dart';
import 'journal_screen.dart';

// Artık StatelessWidget olabilir çünkü kendi state'ini tutmuyor.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Widget> _widgetOptions = <Widget>[
    AnxietyTrackerScreen(),
    BreathingExerciseScreen(),
    SuggestionsScreen(),
    AiChatScreen(),
    JournalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Provider'ları izleyerek (watch) ilgili verileri alıyoruz
    final userName = context.watch<UserDataProvider>().userName;
    final navProvider = context.watch<NavigationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Merhaba, $userName'),
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
            icon: const Icon(FlutterRemix.settings_3_line),
          ),
        ],
      ),
      body: IndexedStack(
        // Index'i artık NavigationProvider'dan alıyoruz
        index: navProvider.selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(FlutterRemix.pulse_line), label: 'Takip'),
          BottomNavigationBarItem(icon: Icon(FlutterRemix.lungs_line), label: 'Nefes'),
          BottomNavigationBarItem(icon: Icon(FlutterRemix.lightbulb_line), label: 'Öneriler'),
          BottomNavigationBarItem(icon: Icon(FlutterRemix.chat_2_line), label: 'Sohbet'),
          BottomNavigationBarItem(icon: Icon(FlutterRemix.book_open_line), label: 'Günlüğüm'),
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