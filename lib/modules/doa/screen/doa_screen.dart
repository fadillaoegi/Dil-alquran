import 'package:dilalquran/modules/doa/controller/doa_controller.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:dilalquran/widgets/form_search_widget.dart';
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
  final TextEditingController _searchController = TextEditingController();
  static const Color _cardBorderColor = Color(0xFFD3D3D3);
  static const Color _cardBaseShadowColor = Color(0xFFCFCFCF);
  static const double _cardRadius = 18.0;
  int? _pressedDoaId;

  void _setPressedDoa(int? doaId) {
    if (!mounted) return;
    if (_pressedDoaId != doaId) {
      setState(() => _pressedDoaId = doaId);
    }
  }

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
    _searchController.dispose();
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
                      onPressed: controller.fetchDoa,
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

        final doaList = controller.displayedDoasList.toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 16.0, 18.0, 0.0),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_rounded,
                    size: 14.0,
                    color: ColorApp.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    "Data lokal · ${doaList.length} doa",
                    style: primary400.copyWith(
                      fontSize: 11.5,
                      color: ColorApp.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FormSearch(
                controller: _searchController,
                onChanged: controller.onSearch,
                hintText: "Cari doa...",
                showClearIcon: controller.searchQuery.isNotEmpty,
                onClear: () {
                  _searchController.clear();
                  controller.onSearch("");
                },
              ),
            ),
            _buildLocalCategoryFilter(),
            if (doaList.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    "Doa tidak ditemukan",
                    textAlign: TextAlign.center,
                    style: primary400.copyWith(
                      fontSize: 16,
                      color: ColorApp.black.withValues(alpha: 0.5),
                    ),
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
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount:
                        doaList.length + (controller.isLoadMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == doaList.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: ColorApp.primary,
                            ),
                          ),
                        );
                      }

                      final doa = doaList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 18.0),
                        child: Listener(
                          onPointerDown: (_) => _setPressedDoa(doa.id),
                          onPointerUp: (_) => _setPressedDoa(null),
                          onPointerCancel: (_) => _setPressedDoa(null),
                          child: AnimatedScale(
                            scale: _pressedDoaId == doa.id ? 0.97 : 1.0,
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
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
                                      Get.toNamed(
                                        RouteScreen.detailDoa,
                                        arguments: doa,
                                      );
                                    },
                                    borderRadius:
                                        BorderRadius.circular(_cardRadius),
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
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              decoration: BoxDecoration(
                                                color:
                                                    ColorApp.primary.withValues(
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
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    doa.nama ?? "Doa",
                                                    style: primary600.copyWith(
                                                      fontSize: 16.0,
                                                      color: ColorApp.black,
                                                    ),
                                                  ),
                                                  if ((doa.grup ?? "")
                                                      .trim()
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 6.0),
                                                    _grupBadge(doa.grup!),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 16.0,
                                              color:
                                                  ColorApp.primary.withValues(
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
                          ),
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

  Widget _grupBadge(String grup) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: ColorApp.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999.0),
        border: Border.all(color: ColorApp.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        grup,
        style: primary600.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLocalCategoryFilter() {
    return Obx(() {
      final categories = controller.localCategories;
      final selected = controller.selectedCategory.value;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2.0, bottom: 10.0),
              child: Text(
                "Kategori Doa",
                style: primary600.copyWith(
                  fontSize: 12.5,
                  color: ColorApp.black.withValues(alpha: 0.7),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  final active = selected == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999.0),
                        onTap: () => controller.selectCategory(category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 9.0,
                          ),
                          decoration: BoxDecoration(
                            color: active ? ColorApp.primary : ColorApp.white,
                            borderRadius: BorderRadius.circular(999.0),
                            border: Border.all(
                              color:
                                  active ? ColorApp.primary : _cardBorderColor,
                              width: 1.15,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: ColorApp.primary.withValues(
                                        alpha: 0.14,
                                      ),
                                      offset: const Offset(0, 4),
                                      blurRadius: 10,
                                      spreadRadius: -3,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: ColorApp.primary.withValues(
                                        alpha: 0.03,
                                      ),
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                      spreadRadius: -2,
                                    ),
                                  ],
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w700,
                              color: active ? ColorApp.white : ColorApp.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    });
  }
}
