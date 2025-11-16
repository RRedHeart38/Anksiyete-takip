// lib/screens/reminder_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({Key? key}) : super(key: key);

  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final List<String> _reminders = [];

  // Bildirim planlama fonksiyonu
  Future<void> _scheduleNotification(String reminderText, DateTime scheduledTime) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'reminder_channel_id', // Benzersiz bir kanal ID'si
      'Hatırlatma Kanalı',    // Kanal Adı
      channelDescription: 'Hatırlatma bildirimleri için kanal', // Açıklama
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Bildirim ID'si, benzersiz olmalı
      'Hatırlatma',
      reminderText,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Yeni hatırlatma ekleme fonksiyonu
  void _addReminder() async {
    final now = DateTime.now();
    final scheduledTime = now.add(const Duration(seconds: 10)); // 10 saniye sonra bildirim

    // Bildirim planla
    await _scheduleNotification('Bu bir test hatırlatmasıdır!', scheduledTime);

    setState(() {
      _reminders.add('Yeni Hatırlatma: ${scheduledTime.toLocal()}');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hatırlatma başarıyla planlandı!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hatırlatmalarım'),
      ),
      body: _reminders.isEmpty
          ? const Center(child: Text('Henüz hatırlatma yok.'))
          : ListView.builder(
        itemCount: _reminders.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_reminders[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
    );
  }
}