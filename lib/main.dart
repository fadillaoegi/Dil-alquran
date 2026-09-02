import 'dart:async';
import 'package:dilalquran/modules/app_screen.dart';
import 'package:dilalquran/services/connectivity_service.dart';
import 'package:dilalquran/services/notification_service.dart';
import 'package:dilalquran/services/offline_store.dart';
import 'package:dilalquran/services/startup_diagnostics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final startupDiagnostics = StartupDiagnostics();
  final launchState = await startupDiagnostics.beginLaunch();

  // Aktifkan media notification (panel notifikasi + lock screen) untuk audio Al-Quran.
  await _safeStartupTask(
    'JustAudioBackground.init',
    () => JustAudioBackground.init(
      androidNotificationChannelId: 'com.dilalquran.audio.channel',
      androidNotificationChannelName: 'Audio Al-Quran',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      artDownscaleWidth: 256,
      artDownscaleHeight: 256,
    ),
    diagnostics: startupDiagnostics,
  );

  await _safeStartupTask('NotificationService.init', () {
    return NotificationService().init();
  }, diagnostics: startupDiagnostics);
  await _safeStartupTask(
    'OfflineStore.init',
    () => OfflineStore().init(),
    diagnostics: startupDiagnostics,
  );

  final connectivityService = Get.put(ConnectivityService(), permanent: true);
  unawaited(
    _safeStartupTask(
      'ConnectivityService.init',
      () => connectivityService.init(),
      timeout: const Duration(seconds: 5),
      diagnostics: startupDiagnostics,
    ),
  );

  // Jadwalkan ulang notifikasi shalat dari cache setiap aplikasi kembali aktif,
  // agar jendela jadwal (maks 60 notif) terus bergeser maju walau aplikasi
  // jarang dibuka — melengkapi penjadwalan ulang saat cold start & boot.
  WidgetsBinding.instance.addObserver(_NotificationReScheduler());

  runApp(const MainApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(startupDiagnostics.markReady());

    if (launchState.recoveryMode) {
      unawaited(
        startupDiagnostics.logStep(
          'NotificationService.restoreSchedulesFromStorage',
          state: 'skipped',
          details:
              'Skipped once because previous launch did not finish normally.',
        ),
      );
      return;
    }

    unawaited(
      _safeStartupTask(
        'NotificationService.restoreSchedulesFromStorage',
        () => NotificationService().restoreSchedulesFromStorage(),
        timeout: const Duration(seconds: 12),
        diagnostics: startupDiagnostics,
      ),
    );
  });
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

Future<void> _safeStartupTask(
  String label,
  Future<void> Function() task, {
  Duration timeout = const Duration(seconds: 8),
  StartupDiagnostics? diagnostics,
}) async {
  try {
    await diagnostics?.logStep(label, state: 'start');
    await task().timeout(timeout);
    await diagnostics?.logStep(label, details: 'Completed successfully.');
  } on TimeoutException {
    await diagnostics?.markFailure(
        label, 'Timeout after ${timeout.inSeconds}s');
    debugPrint('[startup] $label timed out after ${timeout.inSeconds}s');
  } catch (e, stackTrace) {
    await diagnostics?.markFailure(label, e);
    debugPrint('[startup] $label failed: $e');
    debugPrint('$stackTrace');
  }
}
