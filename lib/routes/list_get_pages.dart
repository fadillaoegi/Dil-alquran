import 'package:dilalquran/modules/detail_surah/detail_controller.dart';
import 'package:dilalquran/modules/detail_surah/detail_screen.dart';
import 'package:dilalquran/modules/detail_doa/controller/detail_doa_controller.dart';
import 'package:dilalquran/modules/detail_doa/screen/detail_doa_screen.dart';
import 'package:dilalquran/modules/doa/controller/doa_controller.dart';
import 'package:dilalquran/modules/doa/screen/doa_screen.dart';
import 'package:dilalquran/modules/shalat/controller/shalat_controller.dart';
import 'package:dilalquran/modules/shalat/screen/shalat_notif_screen.dart';
import 'package:dilalquran/modules/shalat/screen/shalat_screen.dart';
import 'package:dilalquran/modules/hafizh/controller/hafizh_controller.dart';
import 'package:dilalquran/modules/hafizh/controller/hafizh_detail_controller.dart';
import 'package:dilalquran/modules/hafizh/controller/hafizh_practice_controller.dart';
import 'package:dilalquran/modules/hafizh/screen/hafizh_detail_screen.dart';
import 'package:dilalquran/modules/hafizh/screen/hafizh_practice_screen.dart';
import 'package:dilalquran/modules/hafizh/screen/hafizh_screen.dart';
import 'package:dilalquran/modules/home/controller/home_controller.dart';
import 'package:dilalquran/modules/home/screen/home_screen.dart';
import 'package:dilalquran/modules/menu/screen/menu_screen.dart';
import 'package:dilalquran/modules/onboarding/controller/onboarding_controller.dart';
import 'package:dilalquran/modules/onboarding/screen/onboarding_screen.dart';
import 'package:dilalquran/modules/splash/splash_screen.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:get/get.dart';

List<GetPage<dynamic>>? getPages = [
  GetPage(
    name: RouteScreen.splash,
    page: () => const SplashScreen(),
  ),
  GetPage(
    name: RouteScreen.onboarding,
    page: () => const OnboardingScreen(),
    binding: BindingsBuilder(() {
      Get.lazyPut<OnboardingController>(() => OnboardingController());
    }),
  ),
  GetPage(
    name: RouteScreen.menu,
    page: () => const MenuScreen(),
  ),
  GetPage(
    name: RouteScreen.home,
    page: () => const HomeScreen(),
    binding: BindingsBuilder(() {
      Get.lazyPut<HomeController>(() => HomeController());
    }),
  ),
  GetPage(
    name: RouteScreen.hafizh,
    page: () => const HafizhScreen(),
    binding: BindingsBuilder(() {
      Get.lazyPut<HafizhController>(() => HafizhController());
    }),
  ),
  GetPage(
    name: RouteScreen.hafizhDetail,
    page: () => const HafizhDetailScreen(),
    binding: BindingsBuilder(() {
      Get.lazyPut<HafizhDetailController>(() => HafizhDetailController());
    }),
  ),
  GetPage(
    name: RouteScreen.hafizhPractice,
    page: () => const HafizhPracticeScreen(),
    binding: BindingsBuilder(() {
      Get.lazyPut<HafizhPracticeController>(() => HafizhPracticeController());
    }),
  ),
  GetPage(
    name: RouteScreen.doa,
    page: () => const DoaScreen(),
    binding: BindingsBuilder(() {
      Get.lazyPut<DoaController>(() => DoaController());
    }),
  ),
  GetPage(
    name: RouteScreen.shalat,
    page: () => const ShalatScreen(),
    binding: BindingsBuilder(() {
      Get.lazyPut<ShalatController>(() => ShalatController());
    }),
  ),
  GetPage(
    name: RouteScreen.shalatNotif,
    page: () => const ShalatNotifScreen(),
  ),
  GetPage(
    name: RouteScreen.detailDoa,
    page: () => const DetailDoaScreen(),
    binding: BindingsBuilder(() {
      Get.lazyPut<DetailDoaController>(() => DetailDoaController());
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
