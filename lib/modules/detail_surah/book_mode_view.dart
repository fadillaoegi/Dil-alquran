import 'package:dilalquran/modules/detail_surah/page_flip_view.dart';
import 'package:dilalquran/modules/detail_surah/tajweed.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';

// Warna kertas & ornamen mushaf.
const Color _paper = Color(0xfffdf8ec);
const Color _paperEdge = Color(0xfff3e9d2);
const Color _frameGold = Color(0xffc9a227);
const Color _inkColor = Color(0xff1d2b22);

/// Satu ayat untuk keperluan Mode Buku.
class MushafVerse {
  const MushafVerse({
    required this.ayatNumber,
    required this.arabText,
    required this.surahNameLatin,
  });

  final int ayatNumber;
  final String arabText;
  final String surahNameLatin;
}

/// Satu halaman mushaf hasil pemenggalan teks.
class MushafPage {
  const MushafPage({
    required this.text,
    required this.firstAyat,
    required this.lastAyat,
    required this.surahNameLatin,
  });

  final String text;
  final int firstAyat;
  final int lastAyat;
  final String surahNameLatin;
}

/// Mode Buku: menampilkan ayat sebagai lembaran mushaf yang bisa dibalik.
class BookModeView extends StatefulWidget {
  const BookModeView({
    super.key,
    required this.verses,
    required this.title,
    this.tajweedEnabled = true,
    this.initialPage = 0,
    this.onPageChanged,
  });

  final List<MushafVerse> verses;

  /// Nama surah / "Juz N" untuk kepala halaman.
  final String title;

  final bool tajweedEnabled;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;

  @override
  State<BookModeView> createState() => _BookModeViewState();
}

class _BookModeViewState extends State<BookModeView> {
  final PageFlipController _flipController = PageFlipController();

  int _currentPage = 0;
  double _fontSize = 26.0;

  // Cache hasil pemenggalan agar tidak dihitung ulang tiap frame.
  List<MushafPage> _pages = const [];
  String? _cacheKey;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage < 0 ? 0 : widget.initialPage;
  }

  void _changeFontSize(double delta) {
    final next = (_fontSize + delta).clamp(20.0, 38.0);
    if (next == _fontSize) return;
    setState(() {
      _fontSize = next;
      _cacheKey = null; // paksa hitung ulang halaman
    });
  }

  List<MushafPage> _resolvePages(Size pageSize) {
    final key = "${widget.verses.length}"
        "|${widget.title}"
        "|${pageSize.width.toStringAsFixed(1)}"
        "|${pageSize.height.toStringAsFixed(1)}"
        "|$_fontSize";

    if (_cacheKey == key) return _pages;

    _pages = paginateMushaf(
      verses: widget.verses,
      style: _mushafTextStyle(_fontSize),
      maxWidth: pageSize.width,
      maxHeight: pageSize.height,
    );
    _cacheKey = key;

    if (_currentPage > _pages.length - 1) {
      _currentPage = _pages.isEmpty ? 0 : _pages.length - 1;
    }
    return _pages;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.verses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14.0, 12.0, 14.0, 8.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Ruang teks bersih setelah dikurangi bingkai, kepala & kaki.
                final textSize = Size(
                  constraints.maxWidth - _kPageHorizontalChrome,
                  constraints.maxHeight - _kPageVerticalChrome,
                );

                if (textSize.width <= 0 || textSize.height <= 0) {
                  return const SizedBox.shrink();
                }

                final pages = _resolvePages(textSize);
                if (pages.isEmpty) return const SizedBox.shrink();

                return PageFlipView(
                  controller: _flipController,
                  pageCount: pages.length,
                  initialPage: _currentPage,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    widget.onPageChanged?.call(index);
                  },
                  builder: (context, index) {
                    return _MushafPageCard(
                      page: pages[index],
                      title: widget.title,
                      pageNumber: index + 1,
                      totalPages: pages.length,
                      fontSize: _fontSize,
                      tajweedEnabled: widget.tajweedEnabled,
                    );
                  },
                );
              },
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildBottomBar() {
    final total = _pages.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 14.0),
      child: Row(
        children: [
          _barButton(
            icon: Icons.text_decrease_rounded,
            tooltip: "Perkecil teks",
            onTap: () => _changeFontSize(-2),
          ),
          const SizedBox(width: 8.0),
          _barButton(
            icon: Icons.text_increase_rounded,
            tooltip: "Perbesar teks",
            onTap: () => _changeFontSize(2),
          ),
          const Spacer(),
          // Geser ke kanan = halaman berikutnya (arah buku Arab).
          _barButton(
            icon: Icons.chevron_left_rounded,
            tooltip: "Halaman sebelumnya",
            onTap: _currentPage > 0 ? _flipController.previous : null,
          ),
          const SizedBox(width: 10.0),
          Tooltip(
            message: "Progres halaman tersimpan otomatis",
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bookmark_rounded,
                  size: 15.0,
                  color: ColorApp.primary,
                ),
                const SizedBox(width: 4.0),
                Text(
                  total == 0 ? "-" : "${_currentPage + 1} / $total",
                  style: primary700.copyWith(fontSize: 13.0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),
          _barButton(
            icon: Icons.chevron_right_rounded,
            tooltip: "Halaman berikutnya",
            onTap: _currentPage < total - 1 ? _flipController.next : null,
          ),
        ],
      ),
    );
  }

  Widget _barButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? ColorApp.white : ColorApp.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: onTap,
          child: Container(
            width: 40.0,
            height: 36.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: ColorApp.primary.withValues(alpha: enabled ? 0.3 : 0.12),
                width: 1.4,
              ),
            ),
            child: Icon(
              icon,
              size: 20.0,
              color: ColorApp.primary.withValues(alpha: enabled ? 1.0 : 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

// Perkiraan ruang yang dipakai bingkai + kepala + kaki halaman.
const double _kPageHorizontalChrome = 56.0;
const double _kPageVerticalChrome = 118.0;

TextStyle _mushafTextStyle(double fontSize) => TextStyle(
      fontFamily: arabicFontFamily,
      color: _inkColor,
      fontSize: fontSize,
      height: 2.1,
      fontWeight: FontWeight.w400,
    );

/// Kartu satu lembar mushaf: kertas krem, bingkai ornamen, kepala & nomor kaki.
class _MushafPageCard extends StatelessWidget {
  const _MushafPageCard({
    required this.page,
    required this.title,
    required this.pageNumber,
    required this.totalPages,
    required this.fontSize,
    required this.tajweedEnabled,
  });

  final MushafPage page;
  final String title;
  final int pageNumber;
  final int totalPages;
  final double fontSize;
  final bool tajweedEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_paper, _paper, _paperEdge],
          stops: [0.0, 0.85, 1.0],
        ),
        border:
            Border.all(color: _frameGold.withValues(alpha: 0.55), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            offset: const Offset(0, 6),
            blurRadius: 14,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(6.0),
        padding: const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: ColorApp.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 6.0),
            Divider(
              height: 10.0,
              thickness: 1.0,
              color: _frameGold.withValues(alpha: 0.4),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: TajweedText(
                  page.text,
                  enabled: tajweedEnabled,
                  textAlign: TextAlign.justify,
                  style: _mushafTextStyle(fontSize),
                ),
              ),
            ),
            Divider(
              height: 10.0,
              thickness: 1.0,
              color: _frameGold.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 4.0),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: primary700.copyWith(
              fontSize: 12.0,
              color: ColorApp.primary.withValues(alpha: 0.8),
            ),
          ),
        ),
        Text(
          page.firstAyat == page.lastAyat
              ? "Ayat ${page.firstAyat}"
              : "Ayat ${page.firstAyat}–${page.lastAyat}",
          style: primary400.copyWith(
            fontSize: 11.5,
            color: _inkColor.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: ColorApp.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999.0),
        border: Border.all(color: _frameGold.withValues(alpha: 0.5)),
      ),
      child: Text(
        "$pageNumber / $totalPages",
        style: primary700.copyWith(
          fontSize: 11.5,
          color: ColorApp.primary.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

/// Angka Arab-Indic (١٢٣) untuk penanda akhir ayat.
String _arabicIndicDigits(int number) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number.toString().split('').map((c) => digits[int.parse(c)]).join();
}

/// Memenggal teks Arab yang mengalir menjadi halaman-halaman yang pas.
///
/// Teks seluruh surah dirangkai lebih dulu (ayat dipisah penanda ۝), diukur
/// dengan [TextPainter], lalu dipotong per baris sehingga tiap halaman terisi
/// penuh seperti mushaf — bukan dipotong kaku per ayat.
List<MushafPage> paginateMushaf({
  required List<MushafVerse> verses,
  required TextStyle style,
  required double maxWidth,
  required double maxHeight,
}) {
  if (verses.isEmpty || maxWidth <= 0 || maxHeight <= 0) return const [];

  // 1. Rangkai teks penuh sambil mencatat posisi awal tiap ayat.
  final buffer = StringBuffer();
  final List<int> verseStartOffsets = [];
  for (final v in verses) {
    verseStartOffsets.add(buffer.length);
    buffer.write(v.arabText.trim());
    buffer.write(' ۝');
    buffer.write(_arabicIndicDigits(v.ayatNumber));
    buffer.write('  ');
  }
  final fullText = buffer.toString();

  // 2. Ukur seluruh teks pada lebar halaman.
  final painter = TextPainter(
    text: TextSpan(text: fullText, style: style),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.justify,
  )..layout(maxWidth: maxWidth);

  final metrics = painter.computeLineMetrics();
  if (metrics.isEmpty) {
    return [
      MushafPage(
        text: fullText,
        firstAyat: verses.first.ayatNumber,
        lastAyat: verses.last.ayatNumber,
        surahNameLatin: verses.first.surahNameLatin,
      ),
    ];
  }

  // 3. Kelompokkan baris menjadi halaman sesuai tinggi yang tersedia.
  final List<int> pageStartLines = [0];
  final List<double> lineTops = [];
  double top = 0;
  double used = 0;
  for (int i = 0; i < metrics.length; i++) {
    lineTops.add(top);
    final h = metrics[i].height;
    if (used > 0 && used + h > maxHeight) {
      pageStartLines.add(i);
      used = h;
    } else {
      used += h;
    }
    top += h;
  }

  // 4. Ubah batas baris menjadi batas karakter.
  //    Untuk teks RTL, awal baris berada di tepi KANAN area teks.
  final List<int> cutOffsets = [0];
  for (int p = 1; p < pageStartLines.length; p++) {
    final line = pageStartLines[p];
    final probeY = lineTops[line] + metrics[line].height / 2;
    final pos = painter.getPositionForOffset(Offset(maxWidth - 0.5, probeY));
    final offset = pos.offset;
    // Jaga agar batas selalu maju; bila tidak, buang batas yang bermasalah.
    if (offset > cutOffsets.last && offset < fullText.length) {
      cutOffsets.add(offset);
    }
  }
  cutOffsets.add(fullText.length);

  // 5. Bentuk halaman beserta rentang ayatnya. Batas dihitung ulang dari
  //    panjang teks agar tidak ada satu pun karakter yang hilang.
  final List<MushafPage> pages = [];
  int consumed = 0;
  for (int i = 0; i < cutOffsets.length - 1; i++) {
    final start = cutOffsets[i];
    var end = cutOffsets[i + 1];
    var text = fullText.substring(start, end);

    // Pengaman: bila potongan ternyata masih melebihi tinggi halaman
    // (mis. ada batas baris yang tidak bisa dipetakan), pindahkan kata-kata
    // terakhir ke halaman berikutnya alih-alih membiarkannya terpotong.
    while (_measureHeight(text, style, maxWidth) > maxHeight) {
      final lastSpace = text.trimRight().lastIndexOf(' ');
      if (lastSpace <= 0) break;
      end = start + lastSpace;
      text = fullText.substring(start, end);
    }
    cutOffsets[i + 1] = end;

    final trimmed = text.trim();
    if (trimmed.isEmpty) continue;

    final firstIdx = _verseIndexAtOffset(verseStartOffsets, start);
    final lastIdx = _verseIndexAtOffset(verseStartOffsets, end - 1);

    pages.add(
      MushafPage(
        text: trimmed,
        firstAyat: verses[firstIdx].ayatNumber,
        lastAyat: verses[lastIdx].ayatNumber,
        surahNameLatin: verses[firstIdx].surahNameLatin,
      ),
    );
    consumed = end;
  }

  // Sisa teks yang terdorong keluar oleh pengaman di atas -> halaman tambahan.
  while (consumed < fullText.length) {
    var end = fullText.length;
    var text = fullText.substring(consumed, end);
    while (_measureHeight(text, style, maxWidth) > maxHeight) {
      final lastSpace = text.trimRight().lastIndexOf(' ');
      if (lastSpace <= 0) break;
      end = consumed + lastSpace;
      text = fullText.substring(consumed, end);
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) break;

    final firstIdx = _verseIndexAtOffset(verseStartOffsets, consumed);
    final lastIdx = _verseIndexAtOffset(verseStartOffsets, end - 1);
    pages.add(
      MushafPage(
        text: trimmed,
        firstAyat: verses[firstIdx].ayatNumber,
        lastAyat: verses[lastIdx].ayatNumber,
        surahNameLatin: verses[firstIdx].surahNameLatin,
      ),
    );
    consumed = end;
  }

  return pages;
}

// Ukur tinggi sepotong teks pada lebar halaman tertentu.
double _measureHeight(String text, TextStyle style, double maxWidth) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.justify,
  )..layout(maxWidth: maxWidth);
  return tp.height;
}

// Cari ayat mana yang memuat posisi karakter tertentu.
int _verseIndexAtOffset(List<int> starts, int offset) {
  int lo = 0;
  int hi = starts.length - 1;
  int result = 0;
  while (lo <= hi) {
    final mid = (lo + hi) ~/ 2;
    if (starts[mid] <= offset) {
      result = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return result.clamp(0, starts.length - 1);
}
