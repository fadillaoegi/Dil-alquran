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
    // Android 13+: izin menampilkan notifikasi + izin exact alarm (Android 12+)
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    // iOS: izin alert, badge, dan suara
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Detail notifikasi shalat sesuai jenis suara: 'adzan' (bundled),
  // 'device' (default sistem), atau 'custom' (URI ringtone/suara HP - Android).
  NotificationDetails _prayerDetails(String soundType, {String? customUri}) {
    final AndroidNotificationDetails android;
    final DarwinNotificationDetails ios;

    if (soundType == 'custom' &&
        customUri != null &&
        customUri.isNotEmpty) {
      android = AndroidNotificationDetails(
        'prayer_channel_custom',
        'Notifikasi Shalat (Suara HP)',
        channelDescription:
            'Pengingat Waktu Shalat dengan suara pilihan dari perangkat',
        importance: Importance.max,
        priority: Priority.high,
        sound: UriAndroidNotificationSound(customUri),
        playSound: true,
      );
      // iOS tidak mendukung file sembarang -> pakai suara default.
      ios = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
    } else if (soundType == 'adzan') {
      android = const AndroidNotificationDetails(
        'prayer_channel_adzan',
        'Notifikasi Shalat Adzan',
        channelDescription: 'Pengingat Waktu Shalat dengan suara Adzan',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('adzan'),
        playSound: true,
      );
      ios = const DarwinNotificationDetails(
        sound: 'adzan.caf',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
    } else {
      android = const AndroidNotificationDetails(
        'prayer_channel_device',
        'Notifikasi Shalat Sistem',
        channelDescription: 'Pengingat Waktu Shalat dengan suara perangkat',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );
      ios = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
    }

    return NotificationDetails(android: android, iOS: ios);
  }

  // Hapus channel suara custom agar suara baru diterapkan saat dijadwalkan
  // ulang (channel Android mengunci suaranya saat pertama dibuat).
  Future<void> deleteCustomChannel() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel('prayer_channel_custom');
  }

  Future<void> schedulePrayer(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
    String soundType, {
    String? customSoundUri,
  }) async {
    // Pastikan tidak menjadwalkan di masa lalu
    if (scheduledTime.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _prayerDetails(soundType, customUri: customSoundUri),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Pengingat harian berulang pada jam tertentu (mis. muraja'ah hafalan).
  Future<void> scheduleDailyReminder({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'hafizh_reminder_channel',
      'Pengingat Muraja\'ah',
      channelDescription: 'Pengingat harian untuk mengulang hafalan Al-Quran',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(android: androidDetails, iOS: iOSDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Berulang setiap hari pada jam yang sama.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> testNotification({
    String soundType = 'adzan',
    String? customSoundUri,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      999,
      'Waktunya Salat (Tes Instan)',
      'Ayo segera dirikan salat!',
      _prayerDetails(soundType, customUri: customSoundUri),
    );
  }
}
