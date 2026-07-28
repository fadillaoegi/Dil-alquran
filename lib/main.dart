import 'package:dilalquran/modules/app_screen.dart';
import 'package:dilalquran/services/connectivity_service.dart';
import 'package:dilalquran/services/notification_service.dart';
import 'package:dilalquran/services/offline_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Aktifkan media notification (panel notifikasi + lock screen) untuk audio Al-Quran.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.dilalquran.audio.channel',
    androidNotificationChannelName: 'Audio Al-Quran',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
  );

  await NotificationService().init();
  await OfflineStore().init();
  Get.put(await ConnectivityService().init(), permanent: true);

  // Jadwalkan ulang notifikasi shalat dari cache setiap aplikasi kembali aktif,
  // agar jendela jadwal (maks 60 notif) terus bergeser maju walau aplikasi
  // jarang dibuka — melengkapi penjadwalan ulang saat cold start & boot.
  WidgetsBinding.instance.addObserver(_NotificationReScheduler());

  runApp(const MainApp());
}

class _NotificationReScheduler with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService().restoreSchedulesFromStorage();
    }
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const AppScreen();
  }
}
