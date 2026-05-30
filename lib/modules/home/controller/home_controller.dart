import 'package:dilalquran/modules/data/models/juz_model.dart';
import 'package:dilalquran/modules/data/models/surah_model.dart';
import 'package:dilalquran/modules/data/sources/home_source.dart';
import 'package:get/get.dart';

enum QuranCategory { surah, juz }

class HomeController extends GetxController {
  final _surahList = <Surah>[].obs;
  List<Surah> get surahList => _surahList;

  final _juzList = <JuzSummary>[].obs;
  List<JuzSummary> get juzList => _juzList;

  final _isLoading = true.obs;
  bool get isLoading => _isLoading.value;

  final searchQ = "".obs;
  final selectedCategory = QuranCategory.surah.obs;

  List<Surah> get filteredSurah {
    if (searchQ.value.trim().isEmpty) {
      return _surahList;
    }

    final query = searchQ.value.toLowerCase();
    return _surahList.where((surah) {
      final nameLatin = (surah.namaLatin ?? "").toLowerCase();
      final meaning = (surah.arti ?? "").toLowerCase();
      final nomor = (surah.nomor ?? 0).toString();

      return nameLatin.contains(query) ||
          meaning.contains(query) ||
          nomor == query;
    }).toList();
  }

  List<JuzSummary> get filteredJuz {
    if (searchQ.value.trim().isEmpty) {
      return _juzList;
    }

    final query = searchQ.value.toLowerCase();
    return _juzList.where((juz) {
      final nomor = juz.number.toString();
      final start = juz.startSurahName.toLowerCase();
      final end = juz.endSurahName.toLowerCase();

      return nomor == query || start.contains(query) || end.contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    getInitialData();
  }

  Future<void> getInitialData() async {
    try {
      _isLoading.value = true;
      final surah = await HomeSource.fetchSurah();
      _surahList.assignAll(surah);
      _juzList.assignAll(HomeSource.buildJuzSummaries(surah));
    } finally {
      _isLoading.value = false;
    }
  }

  void changeCategory(QuranCategory category) {
    selectedCategory.value = category;
  }
}
