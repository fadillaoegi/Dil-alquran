import 'package:dilalquran/modules/download/download_controller.dart';
import 'package:dilalquran/modules/home/controller/home_controller.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/services/connectivity_service.dart';
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
  final DownloadController dl = Get.find<DownloadController>();
  final ConnectivityService conn = Get.find<ConnectivityService>();
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
        iconTheme: const IconThemeData(color: ColorApp.white),
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
        final online = conn.isOnline.value;

        // Saat offline, hanya tampilkan konten yang sudah di-download.
        final surahList = online
            ? controller.filteredSurah
            : controller.filteredSurah
                .where((s) => dl.isSurahDownloaded(s.nomor ?? -1))
                .toList();
        final juzList = online
            ? controller.filteredJuz
            : controller.filteredJuz
                .where((j) => dl.isJuzDownloaded(j.number))
                .toList();

        return Column(
          children: [
            if (!online) _buildOfflineBanner(),
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
                    borderSide:
                        const BorderSide(color: ColorApp.primary, width: 1.5),
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

  Widget _wrapRefresh(Widget child) {
    return RefreshIndicator(
      color: ColorApp.primary,
      onRefresh: controller.getInitialData,
      child: child,
    );
  }

  Widget _buildSurahList(List surahList) {
    if (surahList.isEmpty) {
      return _wrapRefresh(
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            _EmptyState(
              title: "Surah tidak ditemukan",
              subtitle: "Coba kata kunci lain ya.",
            ),
          ],
        ),
      );
    }

    return _wrapRefresh(
      ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: surahList.length,
        padding: const EdgeInsets.only(bottom: 16.0),
        itemBuilder: (context, index) {
          final surah = surahList[index];
          return ListSurahAyat(
            surah: surah,
            trailing: _surahDownloadBtn(surah.nomor ?? 0),
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
      ),
    );
  }

  Widget _buildJuzList(List juzList) {
    if (juzList.isEmpty) {
      return _wrapRefresh(
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            _EmptyState(
              title: "Juz tidak ditemukan",
              subtitle: "Coba pencarian lain atau kosongkan filter.",
            ),
          ],
        ),
      );
    }

    return _wrapRefresh(
      ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: juzList.length,
        padding: const EdgeInsets.only(bottom: 16.0),
        itemBuilder: (context, index) {
          final juz = juzList[index];
          return ListJuzCard(
            juz: juz,
            trailing: _juzDownloadBtn(juz.number),
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
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: ColorApp.black.withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: ColorApp.white, size: 16.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              "Mode offline — menampilkan konten yang sudah diunduh.",
              style: white400.copyWith(fontSize: 12.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _surahDownloadBtn(int nomor) {
    return Obx(() {
      if (dl.isSurahDownloading(nomor)) {
        return const SizedBox(
          width: 40.0,
          height: 40.0,
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: CircularProgressIndicator(
                strokeWidth: 2.0, color: ColorApp.primary),
          ),
        );
      }
      final done = dl.isSurahDownloaded(nomor);
      return IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: done ? "Terunduh (ketuk untuk hapus)" : "Unduh untuk offline",
        icon: Icon(
          done ? Icons.download_done_rounded : Icons.download_outlined,
          size: 22.0,
          color:
              done ? ColorApp.primary : ColorApp.black.withValues(alpha: 0.35),
        ),
        onPressed: () => dl.toggleSurah(nomor),
      );
    });
  }

  Widget _juzDownloadBtn(int juzNumber) {
    return Obx(() {
      if (dl.isJuzDownloading(juzNumber)) {
        return const SizedBox(
          width: 40.0,
          height: 40.0,
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: CircularProgressIndicator(
                strokeWidth: 2.0, color: ColorApp.primary),
          ),
        );
      }
      final done = dl.isJuzDownloaded(juzNumber);
      return IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: done ? "Juz terunduh" : "Unduh juz untuk offline",
        icon: Icon(
          done ? Icons.download_done_rounded : Icons.download_outlined,
          size: 22.0,
          color:
              done ? ColorApp.primary : ColorApp.black.withValues(alpha: 0.35),
        ),
        onPressed: done ? null : () => dl.downloadJuz(juzNumber),
      );
    });
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
    const borderColor = Color(0xFFD3D3D3);
    const baseShadowColor = Color(0xFFCFCFCF);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(bottom: 10.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (!selected)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 8,
                  bottom: -8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: baseShadowColor,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: selected ? ColorApp.primary : ColorApp.white,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: selected ? ColorApp.primary : borderColor,
                    width: 1.2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: ColorApp.primary.withValues(alpha: 0.18),
                            offset: const Offset(0, 6),
                            blurRadius: 14,
                            spreadRadius: -4,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: ColorApp.primary.withValues(alpha: 0.03),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ],
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
