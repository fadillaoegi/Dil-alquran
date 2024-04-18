import 'package:dilalquran/config/get_screen_config.dart';
import 'package:dilalquran/modules/presentations/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: const HomeScreen(),
      getPages: getPages,
    );
  }
}
