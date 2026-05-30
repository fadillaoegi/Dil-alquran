import 'package:dilalquran/modules/home/controller/home_controller.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:dilalquran/widgets/list_surahayat_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.find<HomeController>();
  final TextEditingController searchTextController = TextEditingController();

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.info_outline_rounded, color: ColorApp.white),
            onPressed: () {
              Get.defaultDialog(
                title: "Tentang Aplikasi",
                titleStyle: black700.copyWith(fontSize: 16.0),
                middleText:
                    "Pilih bacaan berdasarkan Surah atau Juz, lalu nikmati ayat dengan terjemah dan audio qari favoritmu.",
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
                  child: const Text(
                    "Tutup",
                    style: TextStyle(color: ColorApp.white),
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
                const CircularProgressIndicator(
                  color: ColorApp.primary,
                  strokeWidth: 4,
                ),
                const SizedBox(height: 16),
                Text(
                  "Menyiapkan data Quran...",
                  style: primary600.copyWith(fontSize: 14.0),
                ),
              ],
            ),
          );
        }

        final isSurah =
            controller.selectedCategory.value == QuranCategory.surah;
        final surahList = controller.filteredSurah;
        final juzList = controller.filteredJuz;

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff0d4e34),
                    ColorApp.primary,
                    Color(0xff8ccf72),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: ColorApp.primary.withValues(alpha: 0.35),
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
                      Text(
                        isSurah ? "Mode Surah" : "Mode Juz",
                        style: white700.copyWith(fontSize: 12.0),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 5.0,
                        ),
                        decoration: BoxDecoration(
                          color: ColorApp.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          isSurah
                              ? "${surahList.length} surah"
                              : "${juzList.length} juz",
                          style: white600.copyWith(fontSize: 11.0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Assalamualaikum",
                    style: TextStyle(
                      color: ColorApp.white,
                      fontSize: 26.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSurah
                        ? "Cari surah dan baca ayat lengkap dengan audio."
                        : "Telusuri 30 juz dengan navigasi ayat yang rapi.",
                    style: TextStyle(
                      color: ColorApp.white.withValues(alpha: 0.9),
                      fontSize: 13.0,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _CategoryChip(
                    label: "Surah",
                    icon: Icons.menu_book_rounded,
                    selected: isSurah,
                    onTap: () => controller.changeCategory(QuranCategory.surah),
                  ),
                  const SizedBox(width: 10.0),
                  _CategoryChip(
                    label: "Juz",
                    icon: Icons.grid_view_rounded,
                    selected: !isSurah,
                    onTap: () => controller.changeCategory(QuranCategory.juz),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: searchTextController,
                onChanged: (val) {
                  controller.searchQ.value = val;
                },
                style: black500.copyWith(fontSize: 14.0),
                decoration: InputDecoration(
                  hintText: isSurah
                      ? "Cari nomor atau nama surah..."
                      : "Cari nomor juz atau nama surah pembuka...",
                  hintStyle: black400.copyWith(
                    color: ColorApp.black.withValues(alpha: 0.4),
                    fontSize: 13.5,
                  ),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: ColorApp.primary),
                  suffixIcon: controller.searchQ.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: ColorApp.primary),
                          onPressed: () {
                            searchTextController.clear();
                            controller.searchQ.value = "";
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: ColorApp.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(color: ColorApp.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child:
                  isSurah ? _buildSurahList(surahList) : _buildJuzList(juzList),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSurahList(List surahList) {
    if (surahList.isEmpty) {
      return const _EmptyState(
        title: "Surah tidak ditemukan",
        subtitle: "Coba kata kunci lain ya.",
      );
    }

    return ListView.builder(
      itemCount: surahList.length,
      padding: const EdgeInsets.only(bottom: 16.0),
      itemBuilder: (context, index) {
        final surah = surahList[index];
        return ListSurahAyat(
          surah: surah,
          onTap: () {
            Get.toNamed(
              RouteScreen.detailSurah,
              arguments: {
                "category": "surah",
                "number": surah.nomor,
              },
            );
          },
        );
      },
    );
  }

  Widget _buildJuzList(List juzList) {
    if (juzList.isEmpty) {
      return const _EmptyState(
        title: "Juz tidak ditemukan",
        subtitle: "Coba pencarian lain atau kosongkan filter.",
      );
    }

    return ListView.builder(
      itemCount: juzList.length,
      padding: const EdgeInsets.only(bottom: 16.0),
      itemBuilder: (context, index) {
        final juz = juzList[index];
        return ListJuzCard(
          juz: juz,
          onTap: () {
            Get.toNamed(
              RouteScreen.detailSurah,
              arguments: {
                "category": "juz",
                "number": juz.number,
              },
            );
          },
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: selected ? ColorApp.primary : ColorApp.white,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: selected
                  ? ColorApp.primary
                  : ColorApp.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? ColorApp.white : ColorApp.primary,
              ),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: TextStyle(
                  color: selected ? ColorApp.white : ColorApp.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
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
            title,
            style: black600.copyWith(fontSize: 14.0),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: black400.copyWith(fontSize: 12.0),
          ),
        ],
      ),
    );
  }
}
