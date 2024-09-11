import 'package:dilalquran/routes/list_get_pages.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialRoute: RouteScreen.splash,
      debugShowCheckedModeBanner: false,
      getPages: getPages,
    );
  }
}
