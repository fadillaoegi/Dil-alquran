// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:dilalquran/config/api_config.dart';
import 'package:dilalquran/config/request_config.dart';
import 'package:dilalquran/modules/data/models/juz_model.dart';
import 'package:dilalquran/modules/data/models/surah_detail_model.dart';
import 'package:dilalquran/modules/data/models/surah_model.dart';
import 'package:dilalquran/services/offline_store.dart';
import 'package:flutter/services.dart' show rootBundle;

class HomeSource {

  static Future<List<Surah>> fetchSurah() async {
    try {
      final Map? response = await AppRequest.gets(ApiConfig.surah);
      if (response != null && response["code"] == 200) {
        final List data = response["data"] ?? [];
        final list = data.map((e) => Surah.fromJson(e)).toList();
        await OfflineStore().saveSurahIndex(list); // cache untuk offline
        return list;
      }
    } catch (error) {
      print("Catch from Source fetchSurah: $error");
    }

    // Fallback 1: daftar surah yang tersimpan offline (hasil online sebelumnya).
    final cached = await OfflineStore().readSurahIndex();
    if (cached.isNotEmpty) return cached;

    // Fallback 2: daftar 114 surah bawaan aplikasi (aset lokal) — selalu
    // tersedia walau belum pernah online. Ini menjaga daftar surah tetap
    // tampil tanpa internet.
    return _loadBundledSurahIndex();
  }

  // Muat daftar surah dari aset JSON yang dibundel dalam aplikasi.
  static Future<List<Surah>> _loadBundledSurahIndex() async {
    try {
      final raw = await rootBundle.loadString('assets/json/surah_index.json');
      final List data = json.decode(raw) as List;
      final list = data
          .map((e) => Surah.fromJson(e as Map<String, dynamic>))
          .toList();
      // Simpan ke cache agar pemakaian berikutnya konsisten.
      await OfflineStore().saveSurahIndex(list);
      return list;
    } catch (error) {
      print("Catch from Source _loadBundledSurahIndex: $error");
      return <Surah>[];
    }
  }

  static Future<SurahDetail> fetchDetailSurah(String surahNumber) async {
    final nomor = int.tryParse(surahNumber) ?? 0;
    try {
      String url = "${ApiConfig.baseUrl}/surat/$surahNumber";
      Map? resFetchSurahDetail = await AppRequest.gets(url);

      if (resFetchSurahDetail != null && resFetchSurahDetail["code"] == 200) {
        final detail = SurahDetail.fromJson(resFetchSurahDetail["data"]);
        await OfflineStore().saveSurahDetail(detail); // cache untuk offline
        return detail;
      }
    } catch (error) {
      print("Catch from Source: $error");
    }
    // Fallback: detail surah yang tersimpan offline.
    final cached = await OfflineStore().readSurahDetail(nomor);
    return cached ?? SurahDetail();
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
