// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// --- DÜZELTME: Bu pakete bir takma ad (ön ek) veriyoruz ---
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:provider/provider.dart';
import 'package:flutter_application_1/utils/theme_provider.dart';
import 'package:flutter_application_1/providers/auth_provider.dart'; // Bu bizim kendi AuthProvider'ımız
import 'package:flutter_application_1/providers/user_data_provider.dart';
import 'package:flutter_application_1/providers/anxiety_data_provider.dart';
import 'package:flutter_application_1/providers/chat_provider.dart';
import 'package:flutter_application_1/providers/journal_provider.dart';
import 'package:flutter_application_1/providers/navigation_provider.dart';
import 'package:flutter_application_1/providers/achievement_provider.dart';
import 'package:flutter_application_1/providers/goal_provider.dart';
import 'package:flutter_application_1/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını yükle (API key'ler için)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('UYARI: .env dosyası yüklenemedi. API key\'ler çalışmayabilir: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  tz.initializeTimeZones();
  await initializeDateFormatting('tr_TR', null);

  // Bildirim servisi initialization'ı aşağıya, MyApp içine taşındı
  // await notificationService.initialize(); // ANA THREAD'I KILITLEMEMEK İÇİN BURADAN KALDIRILDI

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create an anonymous session before providers start fetching Firestore data.
  try {
    if (firebase_auth.FirebaseAuth.instance.currentUser == null) {
      await firebase_auth.FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    print('Anonim oturum ana girişte başlatılamadı: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserDataProvider()),
        ChangeNotifierProvider(create: (context) => AnxietyDataProvider()),
        ChangeNotifierProvider(create: (context) => JournalProvider()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (context) => AchievementProvider()),
        ChangeNotifierProxyProvider<AchievementProvider, GoalProvider>(
          create: (context) {
            final goalProvider = GoalProvider();
            final achievementProvider = context.read<AchievementProvider>();
            goalProvider.setAchievementProvider(achievementProvider);
            return goalProvider;
          },
          update: (context, achievementProvider, previousGoalProvider) {
            previousGoalProvider ??= GoalProvider();
            previousGoalProvider.setAchievementProvider(achievementProvider);
            return previousGoalProvider;
          },
        ),
        ChangeNotifierProxyProvider<UserDataProvider, ChatProvider>(
          create: (context) => ChatProvider(),
          update: (context, userDataProvider, previousChatProvider) {
            previousChatProvider ??= ChatProvider();
            previousChatProvider.updateDependencies(userDataProvider);
            // AchievementProvider'ı güncelle
            final achievementProvider = context.read<AchievementProvider>();
            previousChatProvider.setAchievementProvider(achievementProvider);
            return previousChatProvider;
          },
        ),
      ],
      child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool hasSeenOnboarding;
  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Bildirimleri burada başlatıyoruz, böylece app açılışını beklemiyor
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.scheduleDailyNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    const background = Color(0xFF121212);
    const surface = Color(0xFF1A1F2E);
    const surfaceAlt = Color(0xFF20263A);
    const primary = Color(0xFF8BC6EC);
    const secondary = Color(0xFFC4B5FD);
    const tertiary = Color(0xFFA7D7B8);

    return MaterialApp(
      title: 'Nefes',
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: const Duration(milliseconds: 300),
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF4F5F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF4B6B88),
          secondary: const Color(0xFF7E8CCB),
          tertiary: const Color(0xFF89A98E),
          surface: const Color(0xFFF7F8FB),
          onSurface: const Color(0xFF1E2430),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Color(0xFFF4F5F8),
          foregroundColor: Color(0xFF1E2430),
          titleTextStyle: TextStyle(
            color: Color(0xFF1E2430),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4B6B88),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4B6B88),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4B6B88),
            side: const BorderSide(color: Color(0xFFB8C6D9)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFFD7DEE8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF7E8CCB), width: 1.4),
          ),
          hintStyle: const TextStyle(color: Color(0xFF7C8798), fontFamily: 'Poppins'),
          labelStyle: const TextStyle(color: Color(0xFF5E6878), fontFamily: 'Poppins'),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
          headlineSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontFamily: 'Poppins'),
          bodyMedium: TextStyle(fontFamily: 'Poppins'),
          bodySmall: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: background,
        cardColor: surface,
        dividerColor: const Color(0xFF2A3142),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primary,
          secondary: secondary,
          tertiary: tertiary,
          surface: surface,
          onSurface: const Color(0xFFF3F4F6),
          surfaceContainerHighest: surfaceAlt,
          outline: const Color(0xFF334155),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: background,
          foregroundColor: Color(0xFFF3F4F6),
          titleTextStyle: TextStyle(
            color: Color(0xFFF3F4F6),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shadowColor: Colors.black.withOpacity(0.24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: secondary,
            foregroundColor: const Color(0xFF111827),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: secondary,
            foregroundColor: const Color(0xFF111827),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF3F4F6),
            side: const BorderSide(color: Color(0xFF3A4258)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1F2937),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF8BC6EC), width: 1.4),
          ),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Poppins'),
          labelStyle: const TextStyle(color: Color(0xFFCBD5E1), fontFamily: 'Poppins'),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC)),
          headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC)),
          headlineSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC)),
          titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
          titleMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
          bodyLarge: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE2E8F0)),
          bodyMedium: TextStyle(fontFamily: 'Poppins', color: Color(0xFFCBD5E1)),
          bodySmall: TextStyle(fontFamily: 'Poppins', color: Color(0xFF94A3B8)),
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: widget.hasSeenOnboarding
          ? const AuthWrapper()
          : const OnboardingScreen(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // --- DÜZELTME: StreamBuilder içinde takma adı (ön eki) kullanıyoruz ---
    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}