import 'package:dilalquran/modules/detail_surah/detail_controller.dart';
import 'package:dilalquran/modules/detail_surah/detail_screen.dart';
import 'package:dilalquran/modules/home/controller/home_controller.dart';
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
    binding: BindingsBuilder(() {
      Get.lazyPut<HomeController>(() => HomeController());
    }),
  ),
  GetPage(
    name: RouteScreen.detailSurah,
    page: () => const DetailSurahScreen(),
    binding: BindingsBuilder(() {
      Get.lazyPut<DetailSurahController>(() => DetailSurahController());
    }),
  ),
];
