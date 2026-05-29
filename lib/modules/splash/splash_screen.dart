import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        margin: const EdgeInsets.all(0.0),
        decoration: BoxDecoration(
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
                fontSize: 48.0,
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
              style: GoogleFonts.roboto(
                color: ColorApp.white.withValues(alpha: 0.8),
                fontSize: 14.0,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 320.0,
              width: 320.0,
              child: Lottie.asset(
                "assets/lotties/animationReadQuran.json",
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Get.offAndToNamed(RouteScreen.home);
              },
              icon: Icon(
                Icons.menu_book_rounded,
                color: ColorApp.primary,
                size: 22,
              ),
              label: Text(
                "Mulai Membaca",
                style: GoogleFonts.roboto(
                  color: ColorApp.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.0,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorApp.white,
                foregroundColor: ColorApp.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 36.0,
                  vertical: 16.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                elevation: 10.0,
                shadowColor: ColorApp.black.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
