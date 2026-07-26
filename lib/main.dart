import 'package:dilalquran/modules/app_screen.dart';
import 'package:dilalquran/services/connectivity_service.dart';
import 'package:dilalquran/services/notification_service.dart';
import 'package:dilalquran/services/offline_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await OfflineStore().init();
  Get.put(await ConnectivityService().init(), permanent: true);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const AppScreen();
  }
}
