import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/widgets/card_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24.0),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Assalamualaikum",
                    style: TextStyle(
                      color: ColorApp.black,
                      fontSize: 26.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Mau ibadah apa hari ini?",
                    style: TextStyle(
                      color: ColorApp.black.withValues(alpha: 0.6),
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
            CardMenu(
              title: "Al-Quran",
              subtitle: "Baca Al-Quran dan terjemahan",
              icon: Icons.menu_book_rounded,
              gradientColors: const [
                Color(0xff0d4e34),
                ColorApp.primary,
                Color(0xff8ccf72),
              ],
              onTap: () {
                Get.toNamed(RouteScreen.home);
              },
            ),
            CardMenu(
              title: "Doa Umum",
              subtitle: "Kumpulan doa sehari-hari",
              icon: Icons.pan_tool_rounded,
              gradientColors: const [
                Color(0xff143a2a),
                ColorApp.primary,
              ],
              onTap: () {
                Get.toNamed(RouteScreen.doa);
              },
            ),
            CardMenu(
              title: "Jadwal Sholat",
              subtitle: "Waktu sholat akurat",
              icon: Icons.access_time_filled_rounded,
              gradientColors: const [
                Color(0xff0c3f2a),
                ColorApp.primary,
              ],
              onTap: () {
                Get.toNamed(RouteScreen.shalat);
              },
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }
}
