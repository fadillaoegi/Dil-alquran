import 'package:dilalquran/modules/detail_surah/detail_controller.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailSurahScreen extends GetView<DetailSurahController> {
  const DetailSurahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.secondary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ColorApp.primary,
        title: Obx(() {
          final title = controller.isLoading
              ? "Memuat..."
              : (controller.getSurahDetail.data?.name?.transliteration?.id ?? "Detail Surah");
          return Text(
            title,
            style: GoogleFonts.roboto(
              color: ColorApp.white,
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
            ),
          );
        }),
        iconTheme: IconThemeData(color: ColorApp.white),
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
                  "Memuat ayat-ayat suci...",
                  style: primary600.copyWith(fontSize: 14.0),
                ),
              ],
            ),
          );
        }

        final data = controller.getSurahDetail.data;
        if (data == null) {
          return Center(
            child: Text(
              "Gagal memuat detail surah.",
              style: black500.copyWith(fontSize: 14.0),
            ),
          );
        }

        final verses = data.verses ?? [];
        final transliteration = data.name?.transliteration?.id ?? "";
        final translation = data.name?.translation?.id ?? "";
        final arabicName = data.name?.short ?? "";
        final versesCount = data.numberOfVerses ?? 0;
        final revelation = data.revelation?.id ?? "Makkah";

        return ListView.builder(
          itemCount: verses.length + 1, // Header card + Verses
          padding: const EdgeInsets.only(bottom: 24.0),
          itemBuilder: (context, index) {
            if (index == 0) {
              // Gorgeous Surah Header Card
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ColorApp.primary, ColorApp.black],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: ColorApp.primary.withValues(alpha: 0.2),
                      offset: const Offset(0, 8),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      transliteration,
                      style: GoogleFonts.roboto(
                        color: ColorApp.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22.0,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      "($translation)",
                      style: GoogleFonts.roboto(
                        color: ColorApp.accent,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Divider(
                      color: ColorApp.white.withValues(alpha: 0.2),
                      thickness: 1.0,
                      indent: 40.0,
                      endIndent: 40.0,
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          revelation,
                          style: GoogleFonts.roboto(
                            color: ColorApp.white.withValues(alpha: 0.9),
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          width: 4.0,
                          height: 4.0,
                          decoration: BoxDecoration(
                            color: ColorApp.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          "$versesCount Ayat",
                          style: GoogleFonts.roboto(
                            color: ColorApp.white.withValues(alpha: 0.9),
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    // Centered Arab Short Name
                    Text(
                      arabicName,
                      style: GoogleFonts.amiri(
                        color: ColorApp.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32.0,
                      ),
                    ),
                    if (data.preBismillah != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        data.preBismillah["text"]["arab"] ?? "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                        style: GoogleFonts.amiri(
                          color: ColorApp.white.withValues(alpha: 0.95),
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              );
            }

            // Render Verses
            final verseIndex = index - 1;
            final verse = verses[verseIndex];
            final verseNum = verse.number?.inSurah ?? (verseIndex + 1);
            final arabText = verse.text?.arab ?? "";
            final translationText = verse.translation?.id ?? "";

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: ColorApp.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: ColorApp.black.withValues(alpha: 0.02),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
                border: Border.all(
                  color: ColorApp.primary.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verse Toolbar (Number Badge & Quick Action Buttons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: ColorApp.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          "Ayat $verseNum",
                          style: GoogleFonts.roboto(
                            color: ColorApp.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.play_circle_outline_rounded,
                              color: ColorApp.primary,
                              size: 22,
                            ),
                            tooltip: "Putar Audio",
                            onPressed: () {
                              final audioUrl = verse.audio?.primary;
                              if (audioUrl != null) {
                                Get.snackbar(
                                  "Audio Ayat $verseNum",
                                  "Memutar audio dari sumber cloud...",
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: ColorApp.primary,
                                  colorText: ColorApp.white,
                                  duration: const Duration(seconds: 2),
                                  icon: Icon(Icons.audiotrack_rounded, color: ColorApp.white),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.share_outlined,
                              color: ColorApp.primary,
                              size: 20,
                            ),
                            tooltip: "Bagikan",
                            onPressed: () {
                              Get.snackbar(
                                "Bagikan Ayat",
                                "Menyalin ayat $verseNum ke papan klip...",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: ColorApp.black,
                                colorText: ColorApp.white,
                                duration: const Duration(seconds: 2),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Arabic Verse Text
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      arabText,
                      style: GoogleFonts.amiri(
                        color: ColorApp.black,
                        height: 2.2,
                        fontSize: 24.0,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Translation
                  Text(
                    translationText,
                    style: GoogleFonts.roboto(
                      color: ColorApp.black.withValues(alpha: 0.8),
                      fontSize: 13.5,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
