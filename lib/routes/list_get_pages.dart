import 'package:dilalquran/modules/detail_surah/detail_screen.dart';
import 'package:dilalquran/modules/home/screen/home_screen.dart';
import 'package:dilalquran/modules/splash/splash_screen.dart';
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
