import 'package:dilalquran/modules/detail_surah/book_mode_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Normalisasi spasi agar perbandingan tidak terganggu pemenggalan baris.
String _normalize(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

List<MushafVerse> _verses(int count) {
  return List.generate(
    count,
    (i) => MushafVerse(
      ayatNumber: i + 1,
      arabText: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ الرَّحْمَٰنِ الرَّحِيمِ',
      surahNameLatin: 'Al-Fatihah',
    ),
  );
}

void main() {
  const style = TextStyle(fontSize: 26.0, height: 2.1);

  test('memenggal ayat menjadi beberapa halaman', () {
    final pages = paginateMushaf(
      verses: _verses(40),
      style: style,
      maxWidth: 320,
      maxHeight: 420,
    );

    expect(pages.length, greaterThan(1));
  });

  test('tidak ada teks ayat yang hilang saat dipenggal', () {
    final verses = _verses(40);
    final pages = paginateMushaf(
      verses: verses,
      style: style,
      maxWidth: 320,
      maxHeight: 420,
    );

    final joined = _normalize(pages.map((p) => p.text).join(' '));

    // Setiap ayat harus muncul utuh di salah satu halaman.
    for (final v in verses) {
      expect(joined.contains(_normalize(v.arabText)), isTrue,
          reason: 'Ayat ${v.ayatNumber} hilang dari hasil pemenggalan');
    }
  });

  test('tiap halaman muat dalam tinggi yang tersedia', () {
    const maxWidth = 320.0;
    const maxHeight = 420.0;
    final pages = paginateMushaf(
      verses: _verses(40),
      style: style,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );

    for (var i = 0; i < pages.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: pages[i].text, style: style),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
      )..layout(maxWidth: maxWidth);

      expect(tp.height, lessThanOrEqualTo(maxHeight),
          reason: 'Halaman ${i + 1} melebihi tinggi halaman');
    }
  });

  test('rentang ayat tiap halaman berurutan dan menaik', () {
    final pages = paginateMushaf(
      verses: _verses(40),
      style: style,
      maxWidth: 320,
      maxHeight: 420,
    );

    for (var i = 0; i < pages.length; i++) {
      expect(pages[i].firstAyat, lessThanOrEqualTo(pages[i].lastAyat));
      if (i > 0) {
        expect(pages[i].firstAyat,
            greaterThanOrEqualTo(pages[i - 1].firstAyat));
      }
    }
  });

  test('daftar ayat kosong menghasilkan nol halaman', () {
    expect(
      paginateMushaf(
        verses: const [],
        style: style,
        maxWidth: 320,
        maxHeight: 420,
      ),
      isEmpty,
    );
  });
}
