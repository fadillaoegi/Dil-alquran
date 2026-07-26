import 'package:dilalquran/modules/doa/controller/doa_controller.dart';
import 'package:dilalquran/modules/download/download_controller.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/services/connectivity_service.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoaScreen extends StatefulWidget {
  const DoaScreen({super.key});

  @override
  State<DoaScreen> createState() => _DoaScreenState();
}

class _DoaScreenState extends State<DoaScreen> {
  final DoaController controller = Get.find<DoaController>();
  final DownloadController dl = Get.find<DownloadController>();
  final ConnectivityService conn = Get.find<ConnectivityService>();
  final ScrollController _scrollController = ScrollController();
  static const Color _cardBorderColor = Color(0xFFD3D3D3);
  static const Color _cardBaseShadowColor = Color(0xFFCFCFCF);
  static const double _cardRadius = 18.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
          "Doa Umum",
          style: primary700.copyWith(
            fontSize: 20.0,
            color: ColorApp.white,
          ),
        ),
        iconTheme: const IconThemeData(color: ColorApp.white),
        actions: [
          Obx(() {
            if (dl.doaBusy.value) {
              return const Padding(
                padding: EdgeInsets.all(14.0),
                child: SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.0, color: ColorApp.white),
                ),
              );
            }
            final all = controller.allDoa;
            final allDownloaded = all.isNotEmpty &&
                all.every((d) => dl.isDoaDownloaded(d.id ?? -1));
            return IconButton(
              tooltip:
                  allDownloaded ? "Hapus semua unduhan doa" : "Unduh semua doa",
              icon: Icon(
                allDownloaded
                    ? Icons.cloud_done_rounded
                    : Icons.download_rounded,
                color: ColorApp.white,
              ),
              onPressed: () =>
                  allDownloaded ? dl.removeAllDoa() : dl.downloadAllDoa(),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorApp.primary,
              strokeWidth: 4,
            ),
          );
        }

        if (controller.isError.value ||
            (controller.displayedDoasList.isEmpty &&
                controller.searchQuery.isEmpty)) {
          return RefreshIndicator(
            color: ColorApp.primary,
            onRefresh: controller.fetchDoa,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 140),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: ColorApp.primary,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Gagal memuat data doa",
                      style: primary600.copyWith(fontSize: 16.0),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        controller.fetchDoa();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorApp.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Coba Lagi",
                        style: TextStyle(color: ColorApp.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final online = conn.isOnline.value;
        // Saat offline, tampilkan semua doa yang sudah di-download
        // (dari daftar penuh, tidak terbatas paginasi).
        final doaList = online
            ? controller.displayedDoasList.toList()
            : controller.allDoa
                .where((d) => dl.isDoaDownloaded(d.id ?? -1))
                .toList();

        return Column(
          children: [
            if (!online) _buildOfflineBanner(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: controller.onSearch,
                decoration: InputDecoration(
                  hintText: "Cari doa...",
                  prefixIcon: const Icon(Icons.search, color: ColorApp.primary),
                  filled: true,
                  fillColor: ColorApp.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (doaList.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    !online && controller.searchQuery.isEmpty
                        ? "Belum ada doa yang diunduh"
                        : "Doa tidak ditemukan",
                    textAlign: TextAlign.center,
                    style: primary400.copyWith(
                        fontSize: 16,
                        color: ColorApp.black.withValues(alpha: 0.5)),
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  color: ColorApp.primary,
                  onRefresh: controller.fetchDoa,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    itemCount: doaList.length +
                        (online && controller.isLoadMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                    if (index == doaList.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: ColorApp.primary),
                        ),
                      );
                    }

                    final doa = doaList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 18.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 10,
                            bottom: -10,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _cardBaseShadowColor,
                                borderRadius: BorderRadius.circular(
                                  _cardRadius + 2,
                                ),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Get.toNamed(RouteScreen.detailDoa,
                                    arguments: doa);
                              },
                              borderRadius: BorderRadius.circular(_cardRadius),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: ColorApp.white,
                                  borderRadius: BorderRadius.circular(
                                    _cardRadius,
                                  ),
                                  border: Border.all(
                                    color: _cardBorderColor,
                                    width: 1.25,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ColorApp.primary.withValues(
                                        alpha: 0.04,
                                      ),
                                      offset: const Offset(0, 2),
                                      blurRadius: 10,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                    vertical: 16.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                          color: ColorApp.primary.withValues(
                                            alpha: 0.10,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          "${doa.id}",
                                          style: primary600.copyWith(
                                            fontSize: 12.0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16.0),
                                      Expanded(
                                        child: Text(
                                          doa.nama ?? "Doa",
                                          style: primary600.copyWith(
                                            fontSize: 16.0,
                                            color: ColorApp.black,
                                          ),
                                        ),
                                      ),
                                      _doaDownloadBtn(doa.id ?? 0),
                                      const SizedBox(width: 4.0),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16.0,
                                        color: ColorApp.primary.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _doaDownloadBtn(int id) {
    return Obx(() {
      final done = dl.isDoaDownloaded(id);
      return IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: done ? "Terunduh (ketuk untuk hapus)" : "Unduh untuk offline",
        icon: Icon(
          done ? Icons.download_done_rounded : Icons.download_outlined,
          size: 22.0,
          color:
              done ? ColorApp.primary : ColorApp.black.withValues(alpha: 0.35),
        ),
        onPressed: () => dl.toggleDoaItem(id),
      );
    });
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
              "Mode offline — menampilkan doa yang sudah diunduh.",
              style: white400.copyWith(fontSize: 12.0),
            ),
          ),
        ],
      ),
    );
  }
}
