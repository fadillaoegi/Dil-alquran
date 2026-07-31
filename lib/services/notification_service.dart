import 'dart:convert';

import 'package:dilalquran/modules/shalat/model/shalat_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static const _prefPrayerEnabled = 'notif_shalat';
  static const _prefPrayerSound = 'notif_sound';
  static const _prefPrayerCustomUri = 'notif_custom_uri';
  static const _prefPrayerSelectedKabKota = 'saved_kabkota';
  static const _prefPrayerScheduleCache = 'notif_shalat_schedule_cache';
  static const _prefPrayerEnabledList = 'notif_prayers';
  static const _prefPrayerModes = 'notif_prayer_modes';
  static const _prefHafizhReminderOn = 'hafizh_reminder_on';
  static const _prefHafizhReminderHour = 'hafizh_reminder_hour';
  static const _prefHafizhReminderMinute = 'hafizh_reminder_minute';
  static const List<String> _prayerNames = [
    "Subuh",
    "Dzuhur",
    "Ashar",
    "Maghrib",
    "Isya",
  ];
  static const String _modeAdzan = 'adzan';
  static const String _modeAlarm = 'alarm';
  static const String _modeSilent = 'silent';
  static const String _modeOff = 'off';
  static const String _alarmSoundUri = 'content://settings/system/alarm_alert';

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

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    await _ensureAndroidChannels();
    await restoreSchedulesFromStorage();
  }

  // Channel Android mengunci suaranya saat pertama dibuat. Jika channel adzan
  // lama sudah terbuat dengan konfigurasi/suara yang salah (mis. dari build
  // sebelumnya), suara adzan tidak akan bunyi. Maka: hapus channel lama dan
  // buat channel dengan ID baru + suara adzan yang benar.
  Future<void> _ensureAndroidChannels() async {
    final android =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    // Bersihkan channel adzan lama yang mungkin ter-cache dengan suara salah
    // atau suara adzan versi terpotong (30 detik).
    await android.deleteNotificationChannel('prayer_channel_adzan');
    await android.deleteNotificationChannel('prayer_channel_adzan_test');
    await android.deleteNotificationChannel('prayer_channel_adzan_v2');
    await android.deleteNotificationChannel('prayer_channel_alarm');
    await android.deleteNotificationChannel('prayer_channel_device');
    await android.deleteNotificationChannel('prayer_channel_silent');

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        adzanChannelId,
        'Notifikasi Shalat Adzan',
        description: 'Pengingat Waktu Shalat dengan suara Adzan',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('adzan'),
        playSound: true,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'prayer_channel_alarm',
        'Notifikasi Shalat Alarm',
        description: 'Pengingat Waktu Shalat dengan suara alarm perangkat',
        importance: Importance.max,
        sound: UriAndroidNotificationSound(_alarmSoundUri),
        playSound: true,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'prayer_channel_device',
        'Notifikasi Shalat Sistem',
        description: 'Pengingat Waktu Shalat dengan suara notifikasi perangkat',
        importance: Importance.max,
        playSound: true,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'prayer_channel_silent',
        'Notifikasi Shalat Tanpa Suara',
        description: 'Pengingat Waktu Shalat tanpa suara',
        importance: Importance.max,
        playSound: false,
      ),
    );
  }

  // ID channel adzan (v3: memakai suara adzan penuh ~3 menit, tidak terpotong).
  static const String adzanChannelId = 'prayer_channel_adzan_v3';

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

    if (soundType == _modeSilent) {
      android = const AndroidNotificationDetails(
        'prayer_channel_silent',
        'Notifikasi Shalat Tanpa Suara',
        channelDescription: 'Pengingat Waktu Shalat tanpa suara',
        importance: Importance.max,
        priority: Priority.high,
        playSound: false,
      );
      ios = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );
    } else if (soundType == _modeAlarm) {
      android = const AndroidNotificationDetails(
        'prayer_channel_alarm',
        'Notifikasi Shalat Alarm',
        channelDescription:
            'Pengingat Waktu Shalat dengan suara alarm perangkat',
        importance: Importance.max,
        priority: Priority.high,
        sound: UriAndroidNotificationSound(_alarmSoundUri),
        playSound: true,
      );
      ios = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
    } else if (soundType == 'custom' &&
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
        adzanChannelId,
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

  Future<void> cachePrayerSchedule(List<ShalatModel> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = schedules.map((item) => item.toJson()).toList();
    await prefs.setString(_prefPrayerScheduleCache, jsonEncode(payload));
  }

  Future<List<ShalatModel>> _readCachedPrayerSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefPrayerScheduleCache);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(ShalatModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> restoreSchedulesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(_prefPrayerEnabled) ?? false) {
      final schedules = await _readCachedPrayerSchedules();
      if (schedules.isNotEmpty) {
        final customSoundUri = prefs.getString(_prefPrayerCustomUri);
        final kabkota = prefs.getString(_prefPrayerSelectedKabKota) ?? "";
        final prayerModes = <String, String>{};
        final savedPrayerModes = prefs.getString(_prefPrayerModes);
        if (savedPrayerModes != null && savedPrayerModes.isNotEmpty) {
          try {
            final decoded = jsonDecode(savedPrayerModes);
            if (decoded is Map) {
              for (final prayer in _prayerNames) {
                prayerModes[prayer] = decoded[prayer]?.toString() ?? _modeAdzan;
              }
            }
          } catch (_) {
            // fallback to legacy prefs
          }
        }
        if (prayerModes.isEmpty) {
          final soundType = prefs.getString(_prefPrayerSound) ?? _modeAdzan;
          final enabledPrayers =
              prefs.getStringList(_prefPrayerEnabledList) ?? _prayerNames;
          for (final prayer in _prayerNames) {
            prayerModes[prayer] =
                enabledPrayers.contains(prayer) ? soundType : _modeOff;
          }
        }
        await restorePrayerSchedules(
          schedules: schedules,
          locationName: kabkota,
          prayerModes: prayerModes,
          customSoundUri: customSoundUri,
        );
      }
    }

    if (prefs.getBool(_prefHafizhReminderOn) ?? false) {
      final hour = prefs.getInt(_prefHafizhReminderHour) ?? 5;
      final minute = prefs.getInt(_prefHafizhReminderMinute) ?? 0;
      await scheduleDailyReminder(
        id: 5001,
        hour: hour,
        minute: minute,
        title: "Waktunya Muraja'ah",
        body: "Yuk jaga hafalanmu, ulangi ayat yang sudah dihafal hari ini.",
      );
    }
  }

  Future<void> restorePrayerSchedules({
    required List<ShalatModel> schedules,
    required String locationName,
    required Map<String, String> prayerModes,
    String? customSoundUri,
  }) async {
    for (var id = 1; id <= 60; id++) {
      await cancel(id);
    }

    final now = DateTime.now();
    var idCounter = 1;
    for (final jadwal in schedules) {
      if (jadwal.tanggalLengkap == null) continue;

      final times = <String, String?>{
        "Subuh": jadwal.subuh,
        "Dzuhur": jadwal.dzuhur,
        "Ashar": jadwal.ashar,
        "Maghrib": jadwal.maghrib,
        "Isya": jadwal.isya,
      };

      for (final entry in times.entries) {
        final mode = prayerModes[entry.key] ?? _modeAdzan;
        if (mode == _modeOff) continue;
        final timeValue = entry.value;
        if (timeValue == null) continue;

        final scheduledAt =
            DateTime.tryParse("${jadwal.tanggalLengkap} $timeValue:00");
        if (scheduledAt == null || !scheduledAt.isAfter(now)) continue;

        await schedulePrayer(
          idCounter++,
          "Waktu ${entry.key}",
          "Telah masuk waktu shalat ${entry.key} untuk wilayah $locationName.",
          scheduledAt,
          mode,
          customSoundUri: customSoundUri,
        );

        if (idCounter > 60) return;
      }
    }
  }

  Future<void> schedulePrayer(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
    String soundType, {
    String? customSoundUri,
  }) async {
    // Bangun waktu tepat pada zona lokal berdasarkan komponen wall-clock
    // (bukan konversi instant via TZDateTime.from), agar tidak salah zona.
    final scheduled = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
      scheduledTime.second,
    );

    // Jangan jadwalkan waktu yang sudah lewat (dibandingkan pada zona yang
    // sama), agar notifikasi tidak langsung muncul dini.
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;

    final details = _prayerDetails(soundType, customUri: customSoundUri);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Fallback: bila exact alarm tidak diizinkan OS/perangkat, jadwalkan
      // mode inexact agar notifikasi tetap muncul (mungkin telat beberapa
      // menit) — lebih baik daripada tidak muncul sama sekali.
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        // Abaikan; jadwal ini gagal dibuat.
      }
    }
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

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(android: androidDetails, iOS: iOSDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(android: androidDetails, iOS: iOSDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> testNotification({
    String soundType = 'adzan',
    String? customSoundUri,
    String title = 'Waktunya Salat (Tes Instan)',
    String body = 'Ayo segera dirikan salat!',
  }) async {
    await flutterLocalNotificationsPlugin.show(
      999,
      title,
      body,
      _prayerDetails(soundType, customUri: customSoundUri),
    );
  }
}
