import 'package:dilalquran/modules/home/controller/home_controller.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:dilalquran/widgets/list_surahayat_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchTextController = TextEditingController();

    return Scaffold(
      backgroundColor: ColorApp.secondary,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: ColorApp.primary,
        title: Text(
          "Dil ~ AlQuran",
          style: dancing700.copyWith(
            fontSize: 28.0,
            color: ColorApp.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: ColorApp.white),
            onPressed: () {
              Get.defaultDialog(
                title: "Tentang Aplikasi",
                titleStyle: black700.copyWith(fontSize: 16.0),
                middleText: "Aplikasi Dil ~ AlQuran adalah aplikasi Kitab Suci Al-Quran digital yang cepat, indah, dan interaktif dengan nuansa hijau Islami premium.",
                middleTextStyle: black400.copyWith(fontSize: 14.0),
                backgroundColor: ColorApp.white,
                radius: 16.0,
                confirm: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorApp.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Tutup",
                    style: GoogleFonts.roboto(color: ColorApp.white),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: ColorApp.primary,
                  strokeWidth: 4,
                ),
                const SizedBox(height: 16),
                Text(
                  "Memuat data surah...",
                  style: primary600.copyWith(fontSize: 14.0),
                ),
              ],
            ),
          );
        }

        final surahList = controller.filteredSurah;

        return Column(
          children: [
            // Gorgeous Decorative Banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ColorApp.primary, ColorApp.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: ColorApp.primary.withValues(alpha: 0.3),
                    offset: const Offset(0, 8),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.star_border_purple500_rounded,
                        color: ColorApp.accent,
                        size: 28,
                      ),
                      Text(
                        "Surah Pilihan",
                        style: GoogleFonts.roboto(
                          color: ColorApp.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Assalamualaikum",
                    style: GoogleFonts.dancingScript(
                      color: ColorApp.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Selamat membaca Al-Quran, semoga berkah.",
                    style: GoogleFonts.roboto(
                      color: ColorApp.white.withValues(alpha: 0.85),
                      fontSize: 13.0,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar Widget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: searchTextController,
                onChanged: (val) {
                  controller.searchQ.value = val;
                },
                style: black500.copyWith(fontSize: 14.0),
                decoration: InputDecoration(
                  hintText: "Cari nomor atau nama surah...",
                  hintStyle: black400.copyWith(
                    color: ColorApp.black.withValues(alpha: 0.4),
                    fontSize: 13.5,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: ColorApp.primary),
                  suffixIcon: Obx(() => controller.searchQ.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: ColorApp.primary),
                          onPressed: () {
                            searchTextController.clear();
                            controller.searchQ.value = "";
                          },
                        )
                      : const SizedBox.shrink()),
                  filled: true,
                  fillColor: ColorApp.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: ColorApp.primary, width: 1.5),
                  ),
                ),
              ),
            ),

            // Surah List
            Expanded(
              child: surahList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: ColorApp.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Surah tidak ditemukan",
                            style: black600.copyWith(fontSize: 14.0),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: surahList.length,
                      padding: const EdgeInsets.only(bottom: 16.0),
                      itemBuilder: (context, index) {
                        final surah = surahList[index];
                        return ListSurahAyat(
                          surah: surah,
                          onTap: () {
                            Get.toNamed(
                              RouteScreen.detailSurah,
                              arguments: surah.number.toString(),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}
