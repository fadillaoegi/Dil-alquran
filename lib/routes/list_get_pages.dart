import 'package:dilalquran/modules/presentations/screens/detail_screen.dart';
import 'package:dilalquran/modules/presentations/screens/home_screen.dart';
import 'package:dilalquran/modules/presentations/screens/splash_screen.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:get/get.dart';

List<GetPage<dynamic>>? getPages = [
  GetPage(
    name: RouteScreen.splash,
    page: () => const SplashScreen(),
  ),
  GetPage(
    name: RouteScreen.home,
    page: () => const HomeScreen(),
  ),
  GetPage(
    name: RouteScreen.detailSurah,
    page: () => const DetailSurahScreen(),
  ),
];
