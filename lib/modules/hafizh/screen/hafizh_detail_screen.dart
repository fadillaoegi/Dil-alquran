import 'package:dilalquran/modules/hafizh/controller/hafizh_detail_controller.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HafizhDetailScreen extends GetView<HafizhDetailController> {
  const HafizhDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.secondary,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: ColorApp.primary,
        iconTheme: const IconThemeData(color: ColorApp.white),
        title: Obx(
          () => Text(
            controller.title,
            style: primary700.copyWith(fontSize: 18.0, color: ColorApp.white),
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: "Mode sembunyi teks",
              icon: Icon(
                controller.hideText.value
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: ColorApp.white,
              ),
              onPressed: controller.toggleHideText,
            ),
          ),
          IconButton(
            tooltip: "Latihan susun ayat",
            icon: const Icon(Icons.extension_rounded, color: ColorApp.white),
            onPressed: () => Get.toNamed(
              RouteScreen.hafizhPractice,
              arguments: {
                "category": controller.isJuz ? "juz" : "surah",
                "number": controller.number,
                "startAyat": controller.startAyat,
                "endAyat": controller.endAyat,
              },
            ),
          ),
          IconButton(
            tooltip: "Tandai semua hafal",
            icon: const Icon(Icons.done_all_rounded, color: ColorApp.white),
            onPressed: () async {
              await controller.markAllMemorized();
              Get.snackbar(
                "Ditandai",
                "Semua ayat di sini ditandai sudah dihafal.",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: ColorApp.primary,
                colorText: ColorApp.white,
                margin: const EdgeInsets.all(16.0),
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: ColorApp.primary),
          );
        }

        final verses = controller.verses;
        if (verses.isEmpty) {
          return Center(
            child: Text(
              "Ayat tidak tersedia.",
              style: primary400.copyWith(fontSize: 14.0),
            ),
          );
        }

        return Column(
          children: [
            if (controller.hasCustomRange)
              _RangeBanner(label: controller.rangeLabel),
            _buildMurajaahPanel(),
            Expanded(
              child: RefreshIndicator(
                color: ColorApp.primary,
                onRefresh: controller.reload,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                  itemCount: verses.length,
                  itemBuilder: (context, index) {
                    final verse = verses[index];
                  // Tampilkan header surah saat surah berganti (mode juz).
                  final showHeader = controller.isJuz &&
                      (index == 0 ||
                          verses[index - 1].surahNumber != verse.surahNumber);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader) _surahHeader(verse.surahNameLatin),
                      _AyatCard(verse: verse),
                    ],
                  );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _surahHeader(String surahName) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded,
              color: ColorApp.primary, size: 16.0),
          const SizedBox(width: 8.0),
          Text(surahName, style: primary700.copyWith(fontSize: 14.0)),
        ],
      ),
    );
  }

  Widget _buildMurajaahPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(18.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.repeat_rounded,
                  color: ColorApp.primary, size: 20.0),
              const SizedBox(width: 8.0),
              Text("Muraja'ah Audio", style: primary700.copyWith(fontSize: 14.0)),
              const Spacer(),
              Obx(() {
                final active = controller.activeVerseKey.value.isNotEmpty;
                return GestureDetector(
                  onTap: controller.togglePlayFromStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: active ? Colors.redAccent : ColorApp.primary,
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: ColorApp.white,
                          size: 18.0,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          active ? "Stop" : "Putar",
                          style: white600.copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12.0),
          _selectorGroup(
            label: "Ulangi",
            child: Obx(
              () => Wrap(
                spacing: 6.0,
                children: HafizhDetailController.repeatOptions.map((opt) {
                  return _miniChip(
                    text: "${opt}x",
                    selected: controller.repeatCount.value == opt,
                    onTap: () => controller.setRepeat(opt),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          _selectorGroup(
            label: "Kecepatan",
            child: Obx(
              () => Wrap(
                spacing: 6.0,
                children: HafizhDetailController.speedOptions.map((opt) {
                  return _miniChip(
                    text: "${opt}x",
                    selected: controller.speed.value == opt,
                    onTap: () => controller.setSpeed(opt),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectorGroup({required String label, required Widget child}) {
    return Row(
      children: [
        SizedBox(
          width: 78.0,
          child: Text(label, style: black500.copyWith(fontSize: 12.5)),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _miniChip({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: selected ? ColorApp.primary : ColorApp.secondary,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: selected
                ? ColorApp.primary
                : ColorApp.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: selected ? ColorApp.white : ColorApp.primary,
          ),
        ),
      ),
    );
  }
}

class _RangeBanner extends StatelessWidget {
  const _RangeBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: ColorApp.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded,
              color: ColorApp.primary, size: 18.0),
          const SizedBox(width: 8.0),
          Text(
            "Fokus hafalan: $label",
            style: primary600.copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _AyatCard extends StatelessWidget {
  const _AyatCard({required this.verse});

  final HafizhVerse verse;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HafizhDetailController>();
    final number = verse.ayatNumber;

    return Obx(() {
      final active = controller.isVerseActive(verse);
      final memorized = controller.isMemorized(verse);
      final hidden =
          controller.hideText.value && !controller.isRevealed(verse);

      return Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: active
                ? ColorApp.primary
                : ColorApp.primary.withValues(alpha: 0.08),
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30.0,
                    height: 30.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ColorApp.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "$number",
                      style: primary700.copyWith(fontSize: 12.5),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: memorized ? "Sudah dihafal" : "Tandai hafal",
                    icon: Icon(
                      memorized
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: memorized
                          ? ColorApp.primary
                          : ColorApp.black.withValues(alpha: 0.3),
                    ),
                    onPressed: () => controller.toggleMemorized(verse),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: "Putar dari ayat ini",
                    icon: Icon(
                      active
                          ? Icons.graphic_eq_rounded
                          : Icons.play_circle_outline_rounded,
                      color: ColorApp.primary,
                    ),
                    onPressed: () =>
                        active ? controller.stop() : controller.startFrom(verse),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              if (hidden)
                _buildHiddenBox(controller)
              else ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    verse.ayat.teksArab ?? "",
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: black700.copyWith(fontSize: 24.0, height: 1.9),
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  verse.ayat.teksLatin ?? "",
                  style: primary400.copyWith(
                    fontSize: 13.0,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8.0),
              Text(
                verse.ayat.teksIndonesia ?? "",
                style: black400.copyWith(
                  fontSize: 13.0,
                  height: 1.5,
                  color: ColorApp.black.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHiddenBox(HafizhDetailController controller) {
    return GestureDetector(
      onTap: () => controller.reveal(verse),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: ColorApp.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: ColorApp.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.touch_app_rounded,
              color: ColorApp.primary.withValues(alpha: 0.7),
              size: 26.0,
            ),
            const SizedBox(height: 6.0),
            Text(
              "Coba lafalkan, lalu ketuk untuk mengecek",
              textAlign: TextAlign.center,
              style: primary600.copyWith(fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
