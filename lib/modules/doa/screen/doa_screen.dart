import 'package:dilalquran/modules/doa/controller/doa_controller.dart';
import 'package:dilalquran/routes/route.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
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

        if (controller.isError.value || (controller.displayedDoasList.isEmpty && controller.searchQuery.isEmpty)) {
          return Center(
            child: Column(
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
          );
        }

        return Column(
          children: [
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
            if (controller.displayedDoasList.isEmpty && controller.searchQuery.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    "Doa tidak ditemukan",
                    style: primary400.copyWith(fontSize: 16, color: ColorApp.black.withValues(alpha: 0.5)),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: controller.displayedDoasList.length + (controller.isLoadMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.displayedDoasList.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Center(
                          child: CircularProgressIndicator(color: ColorApp.primary),
                        ),
                      );
                    }

                    final doa = controller.displayedDoasList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Material(
                        color: ColorApp.white,
                        borderRadius: BorderRadius.circular(16.0),
                        elevation: 2.0,
                        shadowColor: ColorApp.black.withValues(alpha: 0.1),
                        child: InkWell(
                          onTap: () {
                            Get.toNamed(RouteScreen.detailDoa, arguments: doa);
                          },
                          borderRadius: BorderRadius.circular(16.0),
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
                                    color: ColorApp.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "${doa.id}",
                                    style: primary600.copyWith(fontSize: 12.0),
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
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16.0,
                                  color: ColorApp.black.withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
