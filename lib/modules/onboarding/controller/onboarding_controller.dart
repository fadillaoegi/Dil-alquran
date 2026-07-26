import 'package:dilalquran/routes/route.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingController extends GetxController {
  // Key SharedPreferences penanda onboarding sudah pernah dilihat.
  static const String seenKey = "has_seen_onboarding";

  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  // Jumlah halaman, di-set dari screen agar controller tidak tahu detail UI.
  int totalPages = 0;

  bool get isLastPage => currentPage.value == totalPages - 1;

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void next() {
    if (isLastPage) {
      finish();
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenKey, true);
    Get.offAllNamed(RouteScreen.menu);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
