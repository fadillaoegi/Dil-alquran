import 'package:dilalquran/modules/data/models/juz_model.dart';
import 'package:dilalquran/modules/data/models/surah_detail_model.dart';
import 'package:dilalquran/modules/detail_surah/detail_controller.dart';
import 'package:dilalquran/modules/home/controller/home_controller.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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

        _rebuildVerseIndexMap(verseItems);
        _scheduleInitialScroll();

        return Column(
          children: [
            _QariToolbar(controller: controller),
            if (controller.hasLastReadOnCurrentPage) _LastReadBanner(
              summary: controller.lastReadSummary,
              onTap: () {
                final key = controller.currentPageLastReadVerseKey;
                if (key != null) {
                  _scrollToVerseKey(key, animate: true);
                }
              },
            ),
            Expanded(
              child: verseItems.isEmpty
                  ? _emptyState('Gagal memuat detail.', 'Coba buka ulang halaman ini.')
                  : ScrollablePositionedList.builder(
                      itemCount: verseItems.length + 1,
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      padding: const EdgeInsets.only(bottom: 24.0),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return isJuz
                              ? _JuzHeaderCard(juzDetail: controller.juzDetail!)
                              : _SurahHeaderCard(data: controller.surahDetail);
                        }

                        final item = verseItems[index - 1];
                        return _AyatCard(
                          title: 'Ayat ${item.ayatNumber}',
                          subtitle: item.subtitle,
                          arabText: item.arabText,
                          latinText: item.latinText,
                          translationText: item.translationText,
                          isPlaying: controller.isVersePlaying(item.verseKey),
                          isLastRead: controller.isLastReadVerse(item.verseKey),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: ColorApp.primary.withValues(alpha: 0.15)),
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
            child: Obx(
              () => DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: controller.selectedQari,
                  style: black600.copyWith(fontSize: 12.0),
                  icon: const Icon(Icons.keyboard_arrow_down, color: ColorApp.primary),
                  items: controller.qariOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option['id'],
                          child: Text(option['name'] ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.changeQari(value);
                    }
                  },
                ),
              ),
            ),
          ),
          Obx(
            () => IconButton(
              onPressed: controller.isPlaying ? controller.stopAudio : null,
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
    );
  }
}

class _LastReadBanner extends StatelessWidget {
  const _LastReadBanner({required this.summary, required this.onTap});

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: ColorApp.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: ColorApp.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark_rounded, color: ColorApp.primary, size: 20),
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
    );
  }
}

class _SurahHeaderCard extends StatelessWidget {
  const _SurahHeaderCard({required this.data});

  final SurahDetail data;

  @override
  Widget build(BuildContext context) {
    final nameLatin = data.namaLatin ?? '';
    final meaning = data.arti ?? '';
    final arabicName = data.nama ?? '';
    final versesCount = data.jumlahAyat ?? 0;
    final revelation = data.tempatTurun ?? 'Mekah';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ColorApp.primary, Color(0xff143a2a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.0),
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
          Text(nameLatin, style: white700.copyWith(fontSize: 22.0)),
          const SizedBox(height: 4.0),
          Text(meaning, style: white500.copyWith(fontSize: 14.0)),
          const SizedBox(height: 10.0),
          Text(
            arabicName,
            style: const TextStyle(
              color: ColorApp.white,
              fontWeight: FontWeight.bold,
              fontSize: 34.0,
            ),
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
        ],
      ),
    );
  }

  Widget _pillText(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: ColorApp.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(text, style: white600.copyWith(fontSize: 11.5)),
    );
  }
}

class _JuzHeaderCard extends StatelessWidget {
  const _JuzHeaderCard({required this.juzDetail});

  final JuzDetail juzDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff0c3f2a),
            ColorApp.primary,
            Color(0xff102b22)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Juz ${juzDetail.number}', style: white700.copyWith(fontSize: 24.0)),
          const SizedBox(height: 6.0),
          Text(
            '${juzDetail.startSurahName} - ${juzDetail.endSurahName}',
            style: white500.copyWith(fontSize: 13.0),
          ),
          const SizedBox(height: 10.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: ColorApp.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              'Total ${juzDetail.totalAyat} ayat',
              style: white600.copyWith(fontSize: 12.0),
            ),
          ),
        ],
      ),
    );
  }
}

class _AyatCard extends StatelessWidget {
  const _AyatCard({
    required this.title,
    required this.subtitle,
    required this.arabText,
    required this.latinText,
    required this.translationText,
    required this.isPlaying,
    required this.isLastRead,
    required this.onPlayTap,
  });

  final String title;
  final String subtitle;
  final String arabText;
  final String latinText;
  final String translationText;
  final bool isPlaying;
  final bool isLastRead;
  final VoidCallback onPlayTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: isLastRead ? ColorApp.primary.withValues(alpha: 0.04) : ColorApp.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: ColorApp.black.withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
        border: Border.all(
          color: isLastRead
              ? ColorApp.primary.withValues(alpha: 0.35)
              : ColorApp.primary.withValues(alpha: 0.08),
          width: isLastRead ? 1.4 : 1,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                    Text(title, style: primary700.copyWith(fontSize: 12.0)),
                    Text(subtitle, style: black400.copyWith(fontSize: 11.0)),
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
            child: Text(
              arabText,
              style: const TextStyle(
                color: ColorApp.black,
                height: 2.0,
                fontSize: 24.0,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
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
