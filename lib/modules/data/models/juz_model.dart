import 'package:dilalquran/modules/data/models/surah_detail_model.dart';

class JuzBoundary {
  final int number;
  final int startSurah;
  final int startAyat;
  final int endSurah;
  final int endAyat;

  const JuzBoundary({
    required this.number,
    required this.startSurah,
    required this.startAyat,
    required this.endSurah,
    required this.endAyat,
  });
}

class JuzRange {
  final int surahNumber;
  final int startAyat;
  final int endAyat;

  const JuzRange({
    required this.surahNumber,
    required this.startAyat,
    required this.endAyat,
  });
}

class JuzSummary {
  final int number;
  final int totalAyat;
  final String startSurahName;
  final String endSurahName;

  const JuzSummary({
    required this.number,
    required this.totalAyat,
    required this.startSurahName,
    required this.endSurahName,
  });
}

class JuzVerseItem {
  final int surahNumber;
  final String surahNameArab;
  final String surahNameLatin;
  final Ayat ayat;

  const JuzVerseItem({
    required this.surahNumber,
    required this.surahNameArab,
    required this.surahNameLatin,
    required this.ayat,
  });
}

class JuzDetail {
  final int number;
  final int totalAyat;
  final String startSurahName;
  final String endSurahName;
  final List<JuzVerseItem> verses;

  const JuzDetail({
    required this.number,
    required this.totalAyat,
    required this.startSurahName,
    required this.endSurahName,
    required this.verses,
  });
}

const List<JuzBoundary> juzBoundaries = [
  JuzBoundary(
      number: 1, startSurah: 1, startAyat: 1, endSurah: 2, endAyat: 141),
  JuzBoundary(
      number: 2, startSurah: 2, startAyat: 142, endSurah: 2, endAyat: 252),
  JuzBoundary(
      number: 3, startSurah: 2, startAyat: 253, endSurah: 3, endAyat: 92),
  JuzBoundary(
      number: 4, startSurah: 3, startAyat: 93, endSurah: 4, endAyat: 23),
  JuzBoundary(
      number: 5, startSurah: 4, startAyat: 24, endSurah: 4, endAyat: 147),
  JuzBoundary(
      number: 6, startSurah: 4, startAyat: 148, endSurah: 5, endAyat: 81),
  JuzBoundary(
      number: 7, startSurah: 5, startAyat: 82, endSurah: 6, endAyat: 110),
  JuzBoundary(
      number: 8, startSurah: 6, startAyat: 111, endSurah: 7, endAyat: 87),
  JuzBoundary(
      number: 9, startSurah: 7, startAyat: 88, endSurah: 8, endAyat: 40),
  JuzBoundary(
      number: 10, startSurah: 8, startAyat: 41, endSurah: 9, endAyat: 92),
  JuzBoundary(
      number: 11, startSurah: 9, startAyat: 93, endSurah: 11, endAyat: 5),
  JuzBoundary(
      number: 12, startSurah: 11, startAyat: 6, endSurah: 12, endAyat: 52),
  JuzBoundary(
      number: 13, startSurah: 12, startAyat: 53, endSurah: 14, endAyat: 52),
  JuzBoundary(
      number: 14, startSurah: 15, startAyat: 1, endSurah: 16, endAyat: 128),
  JuzBoundary(
      number: 15, startSurah: 17, startAyat: 1, endSurah: 18, endAyat: 74),
  JuzBoundary(
      number: 16, startSurah: 18, startAyat: 75, endSurah: 20, endAyat: 135),
  JuzBoundary(
      number: 17, startSurah: 21, startAyat: 1, endSurah: 22, endAyat: 78),
  JuzBoundary(
      number: 18, startSurah: 23, startAyat: 1, endSurah: 25, endAyat: 20),
  JuzBoundary(
      number: 19, startSurah: 25, startAyat: 21, endSurah: 27, endAyat: 55),
  JuzBoundary(
      number: 20, startSurah: 27, startAyat: 56, endSurah: 29, endAyat: 45),
  JuzBoundary(
      number: 21, startSurah: 29, startAyat: 46, endSurah: 33, endAyat: 30),
  JuzBoundary(
      number: 22, startSurah: 33, startAyat: 31, endSurah: 36, endAyat: 27),
  JuzBoundary(
      number: 23, startSurah: 36, startAyat: 28, endSurah: 39, endAyat: 31),
  JuzBoundary(
      number: 24, startSurah: 39, startAyat: 32, endSurah: 41, endAyat: 46),
  JuzBoundary(
      number: 25, startSurah: 41, startAyat: 47, endSurah: 45, endAyat: 37),
  JuzBoundary(
      number: 26, startSurah: 46, startAyat: 1, endSurah: 51, endAyat: 30),
  JuzBoundary(
      number: 27, startSurah: 51, startAyat: 31, endSurah: 57, endAyat: 29),
  JuzBoundary(
      number: 28, startSurah: 58, startAyat: 1, endSurah: 66, endAyat: 12),
  JuzBoundary(
      number: 29, startSurah: 67, startAyat: 1, endSurah: 77, endAyat: 50),
  JuzBoundary(
      number: 30, startSurah: 78, startAyat: 1, endSurah: 114, endAyat: 6),
];
