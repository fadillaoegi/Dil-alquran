import 'package:dilalquran/modules/data/models/juz_model.dart';
import 'package:dilalquran/modules/data/models/surah_detail_model.dart';
import 'package:dilalquran/modules/detail_surah/book_mode_view.dart';
import 'package:dilalquran/modules/detail_surah/detail_controller.dart';
import 'package:dilalquran/modules/detail_surah/tajweed.dart';
import 'package:dilalquran/modules/home/controller/home_controller.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:dilalquran/widgets/search_dropdown_widget.dart';

const _detailCardBorderColor = Color(0xFFD3D3D3);
const _detailCardBaseShadowColor = Color(0xFFCFCFCF);

class DetailSurahScreen extends StatefulWidget {
  const DetailSurahScreen({super.key});

  @override
  State<DetailSurahScreen> createState() => _DetailSurahScreenState();
}

class _DetailSurahScreenState extends State<DetailSurahScreen> {
  late final DetailSurahController controller;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final Map<String, int> _verseIndexMap = {};

  Worker? _activeVerseWorker;
  bool _didInitialScroll = false;
  String? _pendingScrollKey;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DetailSurahController>();
    _activeVerseWorker = ever<String>(
      controller.activeVerseKeyRx,
      _handleActiveVerseChanged,
    );
  }

  @override
  void dispose() {
    _activeVerseWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ColorApp.secondary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ColorApp.primary,
        title: Obx(() {
          if (controller.isLoading) {
            return Text(
              'Memuat...',
              style: white700.copyWith(fontSize: 18.0),
            );
          }

          if (controller.category == QuranCategory.juz) {
            return Text(
              'Detail Juz ${controller.number}',
              style: white700.copyWith(fontSize: 18.0),
            );
          }

          return Text(
            controller.surahDetail.namaLatin ?? 'Detail Surah',
            style: white700.copyWith(fontSize: 18.0),
          );
        }),
        iconTheme: const IconThemeData(color: ColorApp.white),
        actions: [
          Obx(() {
            final enabled = controller.isTajweedEnabled;
            return IconButton(
              tooltip: enabled
                  ? 'Tajwid berwarna aktif'
                  : 'Tajwid berwarna nonaktif',
              onPressed: _showTajweedSheet,
              icon: Icon(
                enabled ? Icons.palette_rounded : Icons.palette_outlined,
                color: enabled
                    ? const Color(0xFFFFD166)
                    : ColorApp.white.withValues(alpha: 0.75),
              ),
            );
          }),
          // Pengalih tampilan: Mode Gulir (default) <-> Mode Buku (mushaf).
          Obx(() {
            final book = controller.isBookMode;
            return IconButton(
              tooltip: book ? 'Mode Gulir' : 'Mode Buku',
              onPressed: controller.toggleBookMode,
              icon: Icon(
                book ? Icons.view_agenda_rounded : Icons.menu_book_rounded,
                color: ColorApp.white,
              ),
            );
          }),
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
                  'Memuat ayat-ayat suci...',
                  style: primary600.copyWith(fontSize: 14.0),
                ),
              ],
            ),
          );
        }

        final isJuz = controller.category == QuranCategory.juz;
        final verseItems = isJuz
            ? _buildJuzVerseItems(controller.juzDetail)
            : _buildSurahVerseItems(controller.surahDetail);

        // Mode Buku: tampilan mushaf yang dibalik per lembar. Dicabang lebih
        // dulu karena tidak memakai daftar bergulir (dan controller scroll-nya
        // tidak terpasang di mode ini).
        if (controller.isBookMode && verseItems.isNotEmpty) {
          return BookModeView(
            tajweedEnabled: controller.isTajweedEnabled,
            initialPage: controller.initialBookPage,
            onPageChanged: controller.saveBookPage,
            title: isJuz
                ? 'Juz ${controller.number}'
                : (controller.surahDetail.namaLatin ?? 'Surah'),
            verses: verseItems
                .map(
                  (item) => MushafVerse(
                    ayatNumber: item.ayatNumber,
                    arabText: item.arabText,
                    surahNameLatin: item.surahNameLatin,
                  ),
                )
                .toList(),
          );
        }

        _rebuildVerseIndexMap(verseItems);
        _scheduleInitialScroll();

        return Column(
          children: [
            _QariToolbar(controller: controller),
            if (controller.hasLastReadOnCurrentPage)
              _LastReadBanner(
                summary: controller.lastReadSummary,
                onTap: () {
                  final key = controller.currentPageLastReadVerseKey;
                  if (key != null) {
                    _scrollToVerseKey(key, animate: true);
                  }
                },
              ),
            Expanded(
              child: RefreshIndicator(
                color: ColorApp.primary,
                onRefresh: controller.loadDetail,
                child: verseItems.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          _emptyState('Gagal memuat detail.',
                              'Coba buka ulang halaman ini.'),
                        ],
                      )
                    : ScrollablePositionedList.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: verseItems.length + 1,
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        padding: const EdgeInsets.only(bottom: 24.0),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return isJuz
                                ? _JuzHeaderCard(
                                    juzDetail: controller.juzDetail!,
                                    verseItems: verseItems,
                                  )
                                : _SurahHeaderCard(
                                    data: controller.surahDetail,
                                    verseItems: verseItems,
                                  );
                          }

                          final item = verseItems[index - 1];
                          return _AyatCard(
                            title: 'Ayat ${item.ayatNumber}',
                            subtitle: item.subtitle,
                            arabText: item.arabText,
                            tajweedEnabled: controller.isTajweedEnabled,
                            latinText: item.latinText,
                            translationText: item.translationText,
                            isPlaying: controller.isVersePlaying(item.verseKey),
                            isLastRead:
                                controller.isLastReadVerse(item.verseKey),
                            onPlayTap: () {
                              controller.playAyatAudio(
                                verseKey: item.verseKey,
                                audio: item.audio,
                                surahNumber: item.surahNumber,
                                ayatNumber: item.ayatNumber,
                                surahNameLatin: item.surahNameLatin,
                              );
                            },
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

  List<_VerseUiModel> _buildSurahVerseItems(SurahDetail data) {
    final verses = data.ayat ?? [];
    return verses.asMap().entries.map((entry) {
      final ayat = entry.value;
      final ayatNumber = ayat.nomorAyat ?? entry.key + 1;
      return _VerseUiModel(
        verseKey: 's${data.nomor}_$ayatNumber',
        surahNumber: data.nomor ?? 0,
        surahNameLatin: data.namaLatin ?? '',
        ayatNumber: ayatNumber,
        subtitle: data.namaLatin ?? '',
        arabText: ayat.teksArab ?? '',
        latinText: ayat.teksLatin ?? '',
        translationText: ayat.teksIndonesia ?? '',
        audio: ayat.audio,
      );
    }).toList();
  }

  List<_VerseUiModel> _buildJuzVerseItems(JuzDetail? juzDetail) {
    if (juzDetail == null) return [];

    return juzDetail.verses.asMap().entries.map((entry) {
      final verse = entry.value;
      final ayatNumber = verse.ayat.nomorAyat ?? entry.key + 1;
      return _VerseUiModel(
        verseKey: 'j${juzDetail.number}_${verse.surahNumber}_$ayatNumber',
        surahNumber: verse.surahNumber,
        surahNameLatin: verse.surahNameLatin,
        ayatNumber: ayatNumber,
        subtitle: '${verse.surahNameLatin} (${verse.surahNumber})',
        arabText: verse.ayat.teksArab ?? '',
        latinText: verse.ayat.teksLatin ?? '',
        translationText: verse.ayat.teksIndonesia ?? '',
        audio: verse.ayat.audio,
      );
    }).toList();
  }

  void _rebuildVerseIndexMap(List<_VerseUiModel> items) {
    _verseIndexMap
      ..clear()
      ..addEntries(
        items.asMap().entries.map(
              (entry) => MapEntry(entry.value.verseKey, entry.key + 1),
            ),
      );
  }

  void _scheduleInitialScroll() {
    if (_didInitialScroll || controller.isLoading) return;
    final key = controller.currentPageLastReadVerseKey;
    if (key == null) return;

    _didInitialScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToVerseKey(key, animate: false);
    });
  }

  void _handleActiveVerseChanged(String verseKey) {
    if (verseKey.isEmpty) return;
    _scrollToVerseKey(verseKey, animate: true);
  }

  void _scrollToVerseKey(String verseKey, {required bool animate}) {
    final index = _verseIndexMap[verseKey];
    if (index == null) {
      _pendingScrollKey = verseKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _pendingScrollKey == null) return;
        final pending = _pendingScrollKey;
        _pendingScrollKey = null;
        if (pending != null) {
          _scrollToVerseKey(pending, animate: animate);
        }
      });
      return;
    }

    if (!_itemScrollController.isAttached) {
      _pendingScrollKey = verseKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _pendingScrollKey == null) return;
        final pending = _pendingScrollKey;
        _pendingScrollKey = null;
        if (pending != null) {
          _scrollToVerseKey(pending, animate: animate);
        }
      });
      return;
    }

    if (animate) {
      _itemScrollController.scrollTo(
        index: index,
        alignment: 0.15,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _itemScrollController.jumpTo(index: index, alignment: 0.15);
    }
  }

  void _showTajweedSheet() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: ColorApp.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.78,
          child: Column(
            children: [
              Container(
                width: 42.0,
                height: 4.0,
                margin: const EdgeInsets.only(top: 10.0, bottom: 14.0),
                decoration: BoxDecoration(
                  color: ColorApp.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99.0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Row(
                  children: [
                    const Icon(Icons.palette_rounded, color: ColorApp.primary),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'Tajwid Berwarna',
                        style: primary700.copyWith(fontSize: 19.0),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Obx(
                () => SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18.0),
                  activeThumbColor: ColorApp.primary,
                  title: Text(
                    'Tampilkan warna tajwid',
                    style: black600.copyWith(fontSize: 14.0),
                  ),
                  subtitle: Text(
                    'Pengaturan ini tersimpan untuk pembacaan berikutnya.',
                    style: black400.copyWith(fontSize: 11.5),
                  ),
                  value: controller.isTajweedEnabled,
                  onChanged: controller.setTajweedEnabled,
                ),
              ),
              const Divider(height: 1.0),
              Padding(
                padding: const EdgeInsets.fromLTRB(18.0, 14.0, 18.0, 6.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Legenda warna',
                    style: black700.copyWith(fontSize: 14.0),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 8.0),
                  itemCount: TajweedRule.values.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2.0),
                  itemBuilder: (context, index) {
                    final rule = TajweedRule.values[index];
                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 18.0,
                        height: 18.0,
                        decoration: BoxDecoration(
                          color: rule.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorApp.black.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      title: Text(
                        rule.label,
                        style: black600.copyWith(fontSize: 13.0),
                      ),
                      subtitle: Text(
                        rule.description,
                        style: black400.copyWith(fontSize: 11.5),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18.0, 6.0, 18.0, 14.0),
                child: Text(
                  'Warna adalah panduan berdasarkan huruf dan harakat. '
                  'Pelajari pelafalan tajwid bersama guru untuk hasil terbaik.',
                  textAlign: TextAlign.center,
                  style: black400.copyWith(
                    fontSize: 10.5,
                    height: 1.35,
                    color: ColorApp.black.withValues(alpha: 0.62),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 58,
            color: ColorApp.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(title, style: black600.copyWith(fontSize: 14.0)),
          const SizedBox(height: 4),
          Text(subtitle, style: black400.copyWith(fontSize: 12.0)),
        ],
      ),
    );
  }
}

class _QariToolbar extends StatelessWidget {
  const _QariToolbar({required this.controller});

  final DetailSurahController controller;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 18.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 8,
              bottom: -8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _detailCardBaseShadowColor,
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: ColorApp.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: _detailCardBorderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: ColorApp.primary.withValues(alpha: 0.03),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over_rounded,
                      color: ColorApp.primary, size: 20),
                  const SizedBox(width: 8.0),
                  Text(
                    'Qari:',
                    style: primary700.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Obx(() {
                      final selectedName = controller.qariOptions.firstWhere(
                            (element) =>
                                element['id'] == controller.selectedQari,
                            orElse: () => {'name': ''},
                          )['name'] ??
                          '';

                      return SearchDropdown(
                        hintText: "Pilih Qari",
                        selectedValue: selectedName,
                        items: controller.qariOptions
                            .map((e) => e['name'] ?? '')
                            .toList(),
                        onSelected: (name) {
                          final selectedOption =
                              controller.qariOptions.firstWhere(
                            (element) => element['name'] == name,
                            orElse: () => {'id': ''},
                          );
                          if (selectedOption['id'] != null &&
                              selectedOption['id']!.isNotEmpty) {
                            controller.changeQari(selectedOption['id']!);
                          }
                        },
                        emptyText: "Qari tidak ditemukan",
                      );
                    }),
                  ),
                  Obx(
                    () => IconButton(
                      onPressed:
                          controller.isPlaying ? controller.stopAudio : null,
                      icon: Icon(
                        Icons.stop_circle_outlined,
                        color: controller.isPlaying
                            ? ColorApp.primary
                            : ColorApp.black.withValues(alpha: 0.35),
                      ),
                      tooltip: 'Stop Audio',
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
}

class _LastReadBanner extends StatelessWidget {
  const _LastReadBanner({required this.summary, required this.onTap});

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 18.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 8,
              bottom: -8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _detailCardBaseShadowColor,
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: ColorApp.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: _detailCardBorderColor,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorApp.primary.withValues(alpha: 0.03),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_rounded,
                      color: ColorApp.primary, size: 20),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      summary,
                      style: black600.copyWith(fontSize: 12.0),
                    ),
                  ),
                  TextButton(
                    onPressed: onTap,
                    child: Text(
                      'Ke Ayat',
                      style: primary700.copyWith(fontSize: 12.0),
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
}

class _SurahHeaderCard extends StatelessWidget {
  const _SurahHeaderCard({
    required this.data,
    required this.verseItems,
  });

  final SurahDetail data;
  final List<_VerseUiModel> verseItems;

  @override
  Widget build(BuildContext context) {
    final DetailSurahController controller = Get.find<DetailSurahController>();
    final nameLatin = data.namaLatin ?? '';
    final meaning = data.arti ?? '';
    final arabicName = data.nama ?? '';
    final versesCount = data.jumlahAyat ?? 0;
    final revelation = data.tempatTurun ?? 'Mekah';

    return _PressableScale(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 22.0),
        padding: const EdgeInsets.all(22.0),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: ColorApp.primary.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorApp.primary.withValues(alpha: 0.18),
              offset: const Offset(0, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(nameLatin, style: primary700.copyWith(fontSize: 22.0)),
            const SizedBox(height: 4.0),
            Text(
              meaning,
              style: black500.copyWith(
                fontSize: 14.0,
                color: ColorApp.black.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              arabicName,
              style: const TextStyle(
                fontFamily: arabicFontFamily,
                color: ColorApp.primary,
                fontWeight: FontWeight.bold,
                fontSize: 34.0,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pillText(revelation),
                const SizedBox(width: 8.0),
                _pillText('$versesCount Ayat'),
              ],
            ),
            const SizedBox(height: 16.0),
            Obx(() {
              final isCurrentPlaylistActive = controller.audioCtrl
                  .isPlaylistActive('surah', data.nomor ?? 0);
              final isPlaying = controller.audioCtrl.isPlaying.value &&
                  isCurrentPlaylistActive;
              final isLoading = controller.audioCtrl.isLoading.value &&
                  isCurrentPlaylistActive;

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: const [
                    // Hard offset shadow — tombol chunky (kreate.gg).
                    BoxShadow(
                      color: Color(0xff0c3f2a),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    final urls = verseItems
                        .map((item) {
                          return item.audio?[controller.selectedQari] ??
                              (item.audio != null && item.audio!.isNotEmpty
                                  ? item.audio!.values.first
                                  : '');
                        })
                        .where((url) => url.isNotEmpty)
                        .toList();

                    final keys =
                        verseItems.map((item) => item.verseKey).toList();

                    controller.playPlaylist(urls: urls, keys: keys);
                  },
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: ColorApp.white, strokeWidth: 2),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: ColorApp.white,
                          size: 20,
                        ),
                  label: Text(
                    isLoading
                        ? 'Memuat...'
                        : (isPlaying ? 'Jeda Surah' : 'Putar Surah Penuh'),
                    style: const TextStyle(
                      color: ColorApp.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorApp.primary,
                    foregroundColor: ColorApp.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 14.0),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _pillText(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: ColorApp.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999.0),
        border: Border.all(
          color: ColorApp.primary.withValues(alpha: 0.20),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorApp.primary.withValues(alpha: 0.12),
            offset: const Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        text,
        style: primary600.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _JuzHeaderCard extends StatelessWidget {
  const _JuzHeaderCard({
    required this.juzDetail,
    required this.verseItems,
  });

  final JuzDetail juzDetail;
  final List<_VerseUiModel> verseItems;

  @override
  Widget build(BuildContext context) {
    final DetailSurahController controller = Get.find<DetailSurahController>();

    return _PressableScale(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 18.0),
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
                  color: _detailCardBaseShadowColor,
                  borderRadius: BorderRadius.circular(24.0),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: ColorApp.white,
                borderRadius: BorderRadius.circular(22.0),
                border: Border.all(
                  color: _detailCardBorderColor,
                  width: 1.25,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorApp.primary.withValues(alpha: 0.04),
                    offset: const Offset(0, 2),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Juz ${juzDetail.number}',
                      style: primary700.copyWith(fontSize: 24.0)),
                  const SizedBox(height: 6.0),
                  Text(
                    '${juzDetail.startSurahName} - ${juzDetail.endSurahName}',
                    style: black500.copyWith(
                      fontSize: 13.0,
                      color: ColorApp.black.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: ColorApp.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: ColorApp.primary.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Text(
                          'Total ${juzDetail.totalAyat} ayat',
                          style: primary600.copyWith(fontSize: 12.0),
                        ),
                      ),
                      Obx(() {
                        final isCurrentPlaylistActive = controller.audioCtrl
                            .isPlaylistActive('juz', juzDetail.number);
                        final isPlaying =
                            controller.audioCtrl.isPlaying.value &&
                                isCurrentPlaylistActive;
                        final isLoading =
                            controller.audioCtrl.isLoading.value &&
                                isCurrentPlaylistActive;

                        return ElevatedButton.icon(
                          onPressed: () {
                            final urls = verseItems
                                .map((item) {
                                  return item.audio?[controller.selectedQari] ??
                                      (item.audio != null &&
                                              item.audio!.isNotEmpty
                                          ? item.audio!.values.first
                                          : '');
                                })
                                .where((url) => url.isNotEmpty)
                                .toList();

                            final keys = verseItems
                                .map((item) => item.verseKey)
                                .toList();

                            controller.playPlaylist(urls: urls, keys: keys);
                          },
                          icon: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: ColorApp.white, strokeWidth: 2),
                                )
                              : Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: ColorApp.white,
                                  size: 18,
                                ),
                          label: Text(
                            isLoading
                                ? 'Memuat...'
                                : (isPlaying ? 'Jeda Juz' : 'Putar Juz'),
                            style: const TextStyle(
                              color: ColorApp.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorApp.primary,
                            foregroundColor: ColorApp.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyatCard extends StatelessWidget {
  const _AyatCard({
    required this.title,
    required this.subtitle,
    required this.arabText,
    required this.tajweedEnabled,
    required this.latinText,
    required this.translationText,
    required this.isPlaying,
    required this.isLastRead,
    required this.onPlayTap,
  });

  final String title;
  final String subtitle;
  final String arabText;
  final bool tajweedEnabled;
  final String latinText;
  final String translationText;
  final bool isPlaying;
  final bool isLastRead;
  final VoidCallback onPlayTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 18.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (!isLastRead)
              Positioned(
                left: 0,
                right: 0,
                top: 10,
                bottom: -10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _detailCardBaseShadowColor,
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: isLastRead
                    ? ColorApp.primary.withValues(alpha: 0.04)
                    : ColorApp.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: isLastRead
                    ? const []
                    : [
                        BoxShadow(
                          color: ColorApp.primary.withValues(alpha: 0.03),
                          offset: const Offset(0, 2),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                border: Border.all(
                  color: isLastRead
                      ? ColorApp.primary.withValues(alpha: 0.35)
                      : _detailCardBorderColor,
                  width: isLastRead ? 1.4 : 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isLastRead)
                        Container(
                          margin: const EdgeInsets.only(right: 8.0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: ColorApp.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Text(
                            'Terakhir dibaca',
                            style: primary700.copyWith(fontSize: 10.5),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: primary700.copyWith(fontSize: 12.0)),
                            Text(subtitle,
                                style: black400.copyWith(fontSize: 11.0)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onPlayTap,
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: isPlaying ? ColorApp.accent : ColorApp.primary,
                          size: 30,
                        ),
                        tooltip: isPlaying ? 'Stop' : 'Play',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TajweedText(
                      arabText,
                      enabled: tajweedEnabled,
                      style: arabicQuran,
                    ),
                  ),
                  if (latinText.isNotEmpty) ...[
                    const SizedBox(height: 10.0),
                    Text(
                      latinText,
                      style: TextStyle(
                        color: ColorApp.primary.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10.0),
                  Text(
                    translationText,
                    style: TextStyle(
                      color: ColorApp.black.withValues(alpha: 0.8),
                      fontSize: 13.5,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
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
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child});

  final Widget child;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _VerseUiModel {
  final String verseKey;
  final int surahNumber;
  final String surahNameLatin;
  final int ayatNumber;
  final String subtitle;
  final String arabText;
  final String latinText;
  final String translationText;
  final Map<String, String>? audio;

  const _VerseUiModel({
    required this.verseKey,
    required this.surahNumber,
    required this.surahNameLatin,
    required this.ayatNumber,
    required this.subtitle,
    required this.arabText,
    required this.latinText,
    required this.translationText,
    required this.audio,
  });
}
