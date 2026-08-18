import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan halaman terakhir mode buku untuk setiap juz dan surah.
class QuranReadingProgressStore {
  const QuranReadingProgressStore();

  static const preferenceKey = 'dilalquran_book_page_progress';

  static String contentKey({
    required String category,
    required int number,
  }) {
    final normalizedCategory =
        category.toLowerCase() == 'juz' ? 'juz' : 'surah';
    return '$normalizedCategory:$number';
  }

  Future<Map<String, int>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(preferenceKey);
    if (raw == null || raw.isEmpty) return <String, int>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};

      final progress = <String, int>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        final page = value is int ? value : int.tryParse(value.toString());
        if (page != null && page >= 0) {
          progress[entry.key.toString()] = page;
        }
      }
      return progress;
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> save(Map<String, int> progress) async {
    final preferences = await SharedPreferences.getInstance();
    final sanitized = <String, int>{};
    for (final entry in progress.entries) {
      if (entry.value >= 0) sanitized[entry.key] = entry.value;
    }
    await preferences.setString(preferenceKey, jsonEncode(sanitized));
  }
}
