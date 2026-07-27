import 'package:dilalquran/modules/onboarding/controller/onboarding_controller.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:dilalquran/themes/responsive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool(OnboardingController.seenKey) ?? false;

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // First-launch diarahkan ke onboarding, selebihnya langsung ke menu.
    Get.offAndToNamed(
      seenOnboarding ? RouteScreen.menu : RouteScreen.onboarding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        margin: const EdgeInsets.all(0.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorApp.primary,
              ColorApp.black,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Dil ~ AlQuran",
              style: dancing700.copyWith(
                fontSize: context.scale(48.0),
                color: ColorApp.white,
                shadows: [
                  Shadow(
                    color: ColorApp.black.withValues(alpha: 0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Kitab Suci Al-Quran Digital",
              style: TextStyle(
                color: ColorApp.white.withValues(alpha: 0.8),
                fontSize: 14.0,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: (context.screenWidth * 0.72).clamp(200.0, 320.0),
              width: (context.screenWidth * 0.72).clamp(200.0, 320.0),
              child: Lottie.asset(
                "assets/lotties/animationReadQuran.json",
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: ColorApp.primary,
            ),
          ],
        ),
      ),
    );
  }
}
