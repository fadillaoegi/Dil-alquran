import 'package:dilalquran/modules/dzikir/controller/dzikir_controller.dart';
import 'package:dilalquran/modules/dzikir/model/dzikir_model.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:dilalquran/widgets/form_search_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DzikirScreen extends StatefulWidget {
  const DzikirScreen({super.key});

  @override
  State<DzikirScreen> createState() => _DzikirScreenState();
}

class _DzikirScreenState extends State<DzikirScreen> {
  final DzikirController controller = Get.find<DzikirController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  static const Color _cardBorderColor = Color(0xFFD3D3D3);
  static const Color _cardBaseShadowColor = Color(0xFFCFCFCF);
  static const double _cardRadius = 18.0;
  int? _pressedDzikirId;

  void _setPressedDzikir(int? dzikirId) {
    if (!mounted) return;
    if (_pressedDzikirId != dzikirId) {
      setState(() => _pressedDzikirId = dzikirId);
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
          "Dzikir",
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
            (controller.allDzikir.isEmpty && controller.searchQuery.isEmpty)) {
          return RefreshIndicator(
            color: ColorApp.primary,
            onRefresh: controller.fetchDzikir,
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
                      "Gagal memuat data dzikir",
                      style: primary600.copyWith(fontSize: 16.0),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        controller.fetchDzikir();
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

        final dzikirList = controller.displayedDzikirList.toList();

        return Column(
          children: [
            _buildDzikirBanner(dzikirList.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0.0),
              child: FormSearch(
                controller: _searchController,
                onChanged: controller.onSearch,
                hintText: "Cari dzikir...",
                showClearIcon: controller.searchQuery.isNotEmpty,
                onClear: () {
                  _searchController.clear();
                  controller.onSearch("");
                },
              ),
            ),
            _buildBookmarkFilter(),
            if (dzikirList.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    controller.showBookmarkedOnly.value
                        ? "Belum ada dzikir favorit"
                        : "Dzikir tidak ditemukan",
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
                  onRefresh: controller.fetchDzikir,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    itemCount: dzikirList.length +
                        (controller.isLoadMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == dzikirList.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: ColorApp.primary),
                          ),
                        );
                      }

                      final dzikir = dzikirList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 18.0),
                        child: Listener(
                          onPointerDown: (_) => _setPressedDzikir(dzikir.id),
                          onPointerUp: (_) => _setPressedDzikir(null),
                          onPointerCancel: (_) => _setPressedDzikir(null),
                          child: AnimatedScale(
                            scale: _pressedDzikirId == dzikir.id ? 0.97 : 1.0,
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
                                    onTap: () => _showDzikirDetail(dzikir),
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
                                                "${dzikir.id}",
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
                                                    dzikir.nama ?? "Dzikir",
                                                    style: primary600.copyWith(
                                                      fontSize: 16.0,
                                                      color: ColorApp.black,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6.0),
                                                  Row(
                                                    children: [
                                                      if ((dzikir.grup ?? "")
                                                          .trim()
                                                          .isNotEmpty)
                                                        _grupBadge(
                                                            dzikir.grup!),
                                                      if ((dzikir.jumlah ?? 0) >
                                                          0) ...[
                                                        const SizedBox(
                                                            width: 6.0),
                                                        _jumlahBadge(
                                                            dzikir.jumlah!),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: controller
                                                      .isBookmarked(dzikir.id)
                                                  ? 'Hapus dari favorit'
                                                  : 'Simpan ke favorit',
                                              onPressed: () => controller
                                                  .toggleBookmark(dzikir.id),
                                              icon: Icon(
                                                controller
                                                        .isBookmarked(dzikir.id)
                                                    ? Icons.bookmark_rounded
                                                    : Icons
                                                        .bookmark_border_rounded,
                                                color: controller
                                                        .isBookmarked(dzikir.id)
                                                    ? ColorApp.primary
                                                    : ColorApp.primary
                                                        .withValues(alpha: 0.6),
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

  Widget _buildBookmarkFilter() {
    final active = controller.showBookmarkedOnly.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 2.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ChoiceChip(
          selected: active,
          showCheckmark: false,
          selectedColor: ColorApp.primary,
          backgroundColor: ColorApp.white,
          side: BorderSide(
            color: ColorApp.primary.withValues(alpha: active ? 1.0 : 0.28),
            width: 1.4,
          ),
          avatar: Icon(
            active ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: 17.0,
            color: active ? ColorApp.white : ColorApp.primary,
          ),
          label: Text(
            "Favorit (${controller.bookmarkCount})",
            style: TextStyle(
              color: active ? ColorApp.white : ColorApp.primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          onSelected: controller.setShowBookmarkedOnly,
        ),
      ),
    );
  }

  // Banner hero Dzikir bergaya chunky 3D (gradient hijau + hard offset shadow).
  Widget _buildDzikirBanner(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
      child: Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff11623f), Color(0xff2f9e69)],
          ),
          borderRadius: BorderRadius.circular(22.0),
          // Hard offset shadow — chunky 3D.
          boxShadow: const [
            BoxShadow(
              color: Color(0xff0a3d29),
              offset: Offset(0, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(13.0),
              decoration: BoxDecoration(
                color: ColorApp.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: ColorApp.white.withValues(alpha: 0.28),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.self_improvement_rounded,
                color: ColorApp.white,
                size: 28.0,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dzikir Harian",
                    style: white700.copyWith(fontSize: 19.0),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    "Perbanyak mengingat Allah di setiap waktu.",
                    style: TextStyle(
                      color: ColorApp.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 5.0),
                    decoration: BoxDecoration(
                      color: ColorApp.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999.0),
                      border: Border.all(
                        color: ColorApp.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 13.0,
                          color: ColorApp.white,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          "$count bacaan",
                          style: white700.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDzikirDetail(DzikirModel dzikir) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DzikirDetailSheet(dzikir: dzikir),
    );
  }

  // Badge kecil kategori/grup dzikir.
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

  // Badge bilangan bacaan (mis. 33x).
  Widget _jumlahBadge(int jumlah) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: ColorApp.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.repeat_rounded,
            size: 11.0,
            color: ColorApp.primary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 3.0),
          Text(
            "${jumlah}x",
            style: primary600.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom sheet detail dzikir dengan tasbih counter.
class _DzikirDetailSheet extends StatefulWidget {
  const _DzikirDetailSheet({required this.dzikir});

  final DzikirModel dzikir;

  @override
  State<_DzikirDetailSheet> createState() => _DzikirDetailSheetState();
}

class _DzikirDetailSheetState extends State<_DzikirDetailSheet> {
  final DzikirController controller = Get.find<DzikirController>();
  int _count = 0;

  int get _target => widget.dzikir.jumlah ?? 0;
  bool get _isDone => _target > 0 && _count >= _target;

  void _tapCount() {
    if (_target > 0 && _count >= _target) return;
    setState(() => _count++);
  }

  void _resetCount() {
    setState(() => _count = 0);
  }

  @override
  Widget build(BuildContext context) {
    final dzikir = widget.dzikir;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: ColorApp.secondary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10.0),
              Container(
                width: 44.0,
                height: 5.0,
                decoration: BoxDecoration(
                  color: ColorApp.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999.0),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: ColorApp.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${dzikir.id}",
                              style: primary600.copyWith(fontSize: 12.0),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Text(
                              dzikir.nama ?? "Dzikir",
                              style: primary700.copyWith(
                                fontSize: 18.0,
                                color: ColorApp.black,
                              ),
                            ),
                          ),
                          Obx(() {
                            final bookmarked =
                                controller.isBookmarked(dzikir.id);
                            return IconButton(
                              tooltip: bookmarked
                                  ? 'Hapus dari favorit'
                                  : 'Simpan ke favorit',
                              onPressed: () =>
                                  controller.toggleBookmark(dzikir.id),
                              icon: Icon(
                                bookmarked
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: ColorApp.primary,
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          dzikir.ar ?? "",
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 26.0,
                            height: 1.9,
                            fontWeight: FontWeight.w700,
                            color: ColorApp.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18.0),
                      if ((dzikir.tr ?? "").isNotEmpty)
                        Text(
                          dzikir.tr!,
                          style: const TextStyle(
                            color: ColorApp.primary,
                            fontSize: 15.0,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 14.0),
                      if ((dzikir.idn ?? "").isNotEmpty)
                        Text(
                          dzikir.idn!,
                          style: TextStyle(
                            color: ColorApp.black.withValues(alpha: 0.8),
                            fontSize: 15.0,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      if ((dzikir.faedah ?? "").isNotEmpty) ...[
                        const SizedBox(height: 20.0),
                        const Divider(),
                        const SizedBox(height: 12.0),
                        Text(
                          "Faedah / Keterangan:",
                          style: primary600.copyWith(
                            fontSize: 14.0,
                            color: ColorApp.black,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          dzikir.faedah!,
                          style: TextStyle(
                            color: ColorApp.black.withValues(alpha: 0.6),
                            fontSize: 13.0,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24.0),
                      _buildCounter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCounter() {
    final target = _target;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color(0xFFD3D3D3),
          width: 1.25,
        ),
      ),
      child: Column(
        children: [
          Text(
            "Penghitung Dzikir",
            style: primary600.copyWith(fontSize: 13.0),
          ),
          const SizedBox(height: 4.0),
          Text(
            target > 0 ? "$_count / $target" : "$_count",
            style: primary700.copyWith(
              fontSize: 30.0,
              color: _isDone ? ColorApp.primary : ColorApp.black,
            ),
          ),
          const SizedBox(height: 14.0),
          Material(
            color: _isDone
                ? ColorApp.primary.withValues(alpha: 0.5)
                : ColorApp.primary,
            borderRadius: BorderRadius.circular(16.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16.0),
              onTap: _tapCount,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                alignment: Alignment.center,
                child: Text(
                  _isDone
                      ? "Selesai — Alhamdulillah"
                      : "Ketuk untuk menghitung",
                  style: white700.copyWith(fontSize: 15.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          TextButton.icon(
            onPressed: _count == 0 ? null : _resetCount,
            icon: const Icon(Icons.refresh_rounded, size: 18.0),
            label: const Text("Reset"),
            style: TextButton.styleFrom(
              foregroundColor: ColorApp.primary,
            ),
          ),
        ],
      ),
    );
  }
}
