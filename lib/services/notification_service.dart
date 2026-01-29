import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Bildirim mesajları listesi
  final List<String> _morningMessages = [
    'Bugün nasılsın? Günlüğüne bir şeyler yazmak ister misin?',
    'Merhaba! Bugün kendini nasıl hissediyorsun?',
    'Günaydın! Bugün için bir günlük yazısı yazmak ister misin?',
    'Merhaba! Bugün nasıl geçiyor? Duygularını paylaşmak ister misin?',
  ];

  final List<String> _afternoonMessages = [
    'Bugün hiç nefes egzersizi yaptın mı?',
    'Nefes egzersizi yapmak için harika bir zaman!',
    'Bugün nefes egzersizi yapmayı unutma!',
    'Rahatlamak için bir nefes egzersizi yapmaya ne dersin?',
  ];

  Future<void> initialize() async {
    if (_initialized) return;

    // İzin kontrolü
    await _requestPermissions();

    // Android ayarları
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS ayarları (opsiyonel)
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android için kanal oluştur
    await _createNotificationChannel();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    // Android 13+ için bildirim izni
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'daily_reminders',
      'Günlük Hatırlatmalar',
      description: 'Günlük hatırlatma bildirimleri için kanal',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Bildirime tıklandığında yapılacak işlemler
    // Örneğin: Uygulamayı aç, belirli bir ekrana yönlendir
  }

  Future<void> scheduleDailyNotifications() async {
    if (!_initialized) {
      await initialize();
    }

    // Önceki bildirimleri iptal et
    await cancelAllNotifications();

    // Sabah bildirimi (09:00)
    await _scheduleDailyNotification(
      id: 1,
      title: 'Günlük Hatırlatma',
      body: _morningMessages[DateTime.now().day % _morningMessages.length],
      hour: 9,
      minute: 0,
    );

    // Öğleden sonra bildirimi (15:00)
    await _scheduleDailyNotification(
      id: 2,
      title: 'Nefes Egzersizi Hatırlatması',
      body: _afternoonMessages[DateTime.now().day % _afternoonMessages.length],
      hour: 15,
      minute: 0,
    );
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // Bugünün tarihini al
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Eğer saat geçmişse, yarın için ayarla
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Günlük Hatırlatmalar',
      channelDescription: 'Günlük hatırlatma bildirimleri için kanal',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // Günlük tekrarlayan bildirim (Her gün aynı saatte)
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidAllowWhileIdle: false,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Bu parametre günlük tekrarı sağlar
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Test bildirimi gönder (hemen)
  Future<void> showTestNotification() async {
    if (!_initialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Günlük Hatırlatmalar',
      channelDescription: 'Günlük hatırlatma bildirimleri için kanal',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      'Test Bildirimi',
      'Bildirimler çalışıyor!',
      notificationDetails,
    );
  }
}

