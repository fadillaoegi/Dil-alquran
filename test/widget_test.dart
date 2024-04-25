// ignore_for_file: avoid_print

import 'package:dilalquran/modules/data/models/surah_model.dart';
import 'package:dilalquran/modules/data/sources/home_source.dart';

void main() async {
  List<Surah>? surah = await HomeSource.fetchSurah();
  if (surah.isNotEmpty) {
    print("Jumlah surah: ${surah.length}");
    for (var i = 0; i < surah.length; i++) {
      print("Surah ${i + 1} - Jumlah ayat: ${surah[i].numberOfVerses}");
    }
  } else {
    print("Gagal mendapatkan daftar surah.");
  }
}
