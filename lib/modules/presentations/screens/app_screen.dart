import 'package:dilalquran/modules/data/sources/home_source.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialRoute: RouteApp.home,
      getPages: [
        GetPage(
          name: RouteApp.home,
          page: () => const HomeScreen(),
        )
      ],
    );
  }
}
