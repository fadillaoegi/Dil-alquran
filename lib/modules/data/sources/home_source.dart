// ignore_for_file: avoid_print

import 'package:dilalquran/config/api_config.dart';
import 'package:dilalquran/config/request_config.dart';
import 'package:dilalquran/modules/data/models/juz_model.dart';
import 'package:dilalquran/modules/data/models/surah_detail_model.dart';
import 'package:dilalquran/modules/data/models/surah_model.dart';

class HomeSource {

  static Future<List<Surah>> fetchSurah() async {
    try {
      final Map? response = await AppRequest.gets(ApiConfig.surah);
      if (response == null || response["code"] != 200) return [];

      final List data = response["data"] ?? [];
      return data.map((e) => Surah.fromJson(e)).toList();
    } catch (error) {
      print("Catch from Source fetchSurah: $error");
      return [];
    }
  }

  static Future<SurahDetail> fetchDetailSurah(String surahNumber) async {
    try {
      String url = "${ApiConfig.baseUrl}/surat/$surahNumber";

      Map? resFetchSurahDetail = await AppRequest.gets(url);

      if (resFetchSurahDetail == null) return SurahDetail();

      if (resFetchSurahDetail["code"] == 200) {
        SurahDetail mapToModel =
            SurahDetail.fromJson(resFetchSurahDetail["data"]);
        return mapToModel;
      } else {
        return SurahDetail();
      }
    } catch (error) {
      print("Catch from Source: $error");
      return SurahDetail();
    }
  }

  static List<JuzSummary> buildJuzSummaries(List<Surah> surahList) {
    return juzBoundaries.map((boundary) {
      final ranges = _resolveRanges(boundary, surahList);
      final totalAyat = ranges.fold<int>(
        0,
        (total, range) => total + (range.endAyat - range.startAyat + 1),
      );

      final startSurah = _findSurahByNumber(surahList, boundary.startSurah);
      final endSurah = _findSurahByNumber(surahList, boundary.endSurah);

      return JuzSummary(
        number: boundary.number,
        totalAyat: totalAyat,
        startSurahName: startSurah?.namaLatin ?? "Surah ${boundary.startSurah}",
        endSurahName: endSurah?.namaLatin ?? "Surah ${boundary.endSurah}",
      );
    }).toList();
  }

  static Future<JuzDetail> fetchDetailJuz({
    required int juzNumber,
    required List<Surah> surahList,
  }) async {
    final boundary = juzBoundaries.firstWhere(
      (item) => item.number == juzNumber,
      orElse: () => const JuzBoundary(
        number: 0,
        startSurah: 1,
        startAyat: 1,
        endSurah: 1,
        endAyat: 1,
      ),
    );

    if (boundary.number == 0) {
      return const JuzDetail(
        number: 0,
        totalAyat: 0,
        startSurahName: "",
        endSurahName: "",
        verses: [],
      );
    }

    final ranges = _resolveRanges(boundary, surahList);
    final List<JuzVerseItem> verses = [];

    final details = await Future.wait(
      ranges.map((range) => fetchDetailSurah(range.surahNumber.toString())),
    );

    for (var i = 0; i < ranges.length; i++) {
      final range = ranges[i];
      final detail = details[i];
      final surahAyat = detail.ayat ?? [];
      final filtered = surahAyat.where((item) {
        final no = item.nomorAyat ?? 0;
        return no >= range.startAyat && no <= range.endAyat;
      });

      for (final ayat in filtered) {
        verses.add(
          JuzVerseItem(
            surahNumber: detail.nomor ?? range.surahNumber,
            surahNameArab: detail.nama ?? "",
            surahNameLatin: detail.namaLatin ?? "Surah ${range.surahNumber}",
            ayat: ayat,
          ),
        );
      }
    }

    return JuzDetail(
      number: boundary.number,
      totalAyat: verses.length,
      startSurahName:
          _findSurahByNumber(surahList, boundary.startSurah)?.namaLatin ??
              "Surah ${boundary.startSurah}",
      endSurahName:
          _findSurahByNumber(surahList, boundary.endSurah)?.namaLatin ??
              "Surah ${boundary.endSurah}",
      verses: verses,
    );
  }

  static List<JuzRange> _resolveRanges(
    JuzBoundary boundary,
    List<Surah> surahList,
  ) {
    final List<JuzRange> ranges = [];

    for (int surahNo = boundary.startSurah;
        surahNo <= boundary.endSurah;
        surahNo++) {
      final surah = _findSurahByNumber(surahList, surahNo);
      final maxAyat = surah?.jumlahAyat ?? 0;
      if (maxAyat == 0) continue;

      final start = surahNo == boundary.startSurah ? boundary.startAyat : 1;
      final end = surahNo == boundary.endSurah ? boundary.endAyat : maxAyat;

      ranges.add(
        JuzRange(
          surahNumber: surahNo,
          startAyat: start,
          endAyat: end,
        ),
      );
    }

    return ranges;
  }

  static Surah? _findSurahByNumber(List<Surah> surahList, int number) {
    for (final surah in surahList) {
      if (surah.nomor == number) return surah;
    }
    return null;
  }
}
