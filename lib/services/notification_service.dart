import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final TimezoneInfo timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> schedulePrayer(
      int id, String title, String body, DateTime scheduledTime, String soundType) async {
    // Pastikan tidak menjadwalkan di masa lalu
    if (scheduledTime.isBefore(DateTime.now())) return;

    final bool isAdzan = soundType == 'adzan';
    
    final AndroidNotificationDetails androidPlatformChannelSpecifics = isAdzan
        ? const AndroidNotificationDetails(
            'prayer_channel_adzan',
            'Notifikasi Shalat Adzan',
            channelDescription: 'Pengingat Waktu Shalat dengan suara Adzan',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('adzan'),
            playSound: true,
          )
        : const AndroidNotificationDetails(
            'prayer_channel_device',
            'Notifikasi Shalat Sistem',
            channelDescription: 'Pengingat Waktu Shalat dengan suara perangkat',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics = isAdzan
        ? const DarwinNotificationDetails(
            sound: 'adzan.wav',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          )
        : const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> testNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'prayer_channel_adzan_test',
      'Test Adzan',
      channelDescription: 'Pengingat Waktu Shalat dengan suara Adzan',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('adzan'),
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = 
        DarwinNotificationDetails(
          sound: 'adzan.wav',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    await flutterLocalNotificationsPlugin.show(
      999,
      'Waktunya Salat (Tes Instan)',
      'Ayo segera dirikan salat!',
      const NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      ),
    );
  }
}
