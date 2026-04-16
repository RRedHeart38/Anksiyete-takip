// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/onboarding_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:provider/provider.dart';
import 'package:flutter_application_1/utils/theme_provider.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/providers/user_data_provider.dart';
import 'package:flutter_application_1/providers/anxiety_data_provider.dart';
import 'package:flutter_application_1/providers/chat_provider.dart';
import 'package:flutter_application_1/providers/journal_provider.dart';
import 'package:flutter_application_1/providers/navigation_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  tz.initializeTimeZones();
  await initializeDateFormatting('tr_TR', null);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserDataProvider()),
        ChangeNotifierProvider(create: (context) => AnxietyDataProvider()),
        ChangeNotifierProvider(create: (context) => JournalProvider()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProxyProvider<UserDataProvider, ChatProvider>(
          create: (context) => ChatProvider(),
          update: (context, userDataProvider, previousChatProvider) {
            previousChatProvider!.updateDependencies(userDataProvider);
            return previousChatProvider;
          },
        ),
      ],
      child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const MyApp({super.key, required this.hasSeenOnboarding});

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF6366f1),
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: const AppBarTheme(
      elevation: 1,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w500),
    ),
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo).copyWith(secondary: const Color(0xFF6366f1)),
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF6366f1),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      elevation: 1,
      backgroundColor: Colors.grey[900],
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark, primarySwatch: Colors.indigo).copyWith(secondary: const Color(0xFF6366f1)),
  );

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ThemeProvider, ThemeMode>((p) => p.themeMode);

    return MaterialApp(
      title: 'Nefes',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      home: hasSeenOnboarding
          ? const AuthWrapper()
          : const OnboardingScreen(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((p) => p.status);

    if (status == AuthStatus.Uninitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (status == AuthStatus.Authenticated) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}