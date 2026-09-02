// ignore_for_file: avoid_print

import 'package:dilalquran/config/api_config.dart';
import 'package:dilalquran/config/request_config.dart';
import 'package:dilalquran/modules/data/models/tafsir_model.dart';

/// Sumber tafsir resmi (equran.id). Dipakai fitur Scan Ayat sebagai
/// bahan rujukan; tafsir TIDAK pernah dibuat oleh AI.
class TafsirSource {
  // Cache sederhana per sesi: tafsir satu surah berukuran besar, jadi
  // sekali ambil dipakai berulang saat pengguna memindai ayat lain di
  // surah yang sama.
  static final Map<int, SurahTafsir> _cache = {};

  static Future<SurahTafsir?> fetchBySurah(int surahNumber) async {
    if (surahNumber < 1 || surahNumber > 114) return null;

    final cached = _cache[surahNumber];
    if (cached != null) return cached;

    try {
      final response = await AppRequest.gets(
        "${ApiConfig.tafsir}/$surahNumber",
      );
      if (response != null && response["code"] == 200) {
        final data = response["data"];
        if (data is Map<String, dynamic>) {
          final tafsir = SurahTafsir.fromJson(data);
          _cache[surahNumber] = tafsir;
          return tafsir;
        }
      }
    } catch (error) {
      print("Catch from TafsirSource.fetchBySurah: $error");
    }
    return null;
  }

  /// Tafsir untuk satu ayat spesifik.
  static Future<TafsirAyat?> fetchAyat({
    required int surahNumber,
    required int ayatNumber,
  }) async {
    final surah = await fetchBySurah(surahNumber);
    return surah?.forAyat(ayatNumber);
  }

  static void clearCache() => _cache.clear();
}
