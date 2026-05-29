import 'package:dilalquran/modules/data/models/surah_detail_model.dart';
import 'package:dilalquran/modules/data/models/surah_model.dart';
import 'package:dilalquran/modules/data/sources/home_source.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final _getSurah = <Surah>[].obs;
  List<Surah> get getSurah => _getSurah;

  final _isLoading = true.obs;
  bool get isLoading => _isLoading.value;

  final searchQ = "".obs;

  List<Surah> get filteredSurah {
    if (searchQ.value.isEmpty) {
      return _getSurah;
    }
    return _getSurah.where((surah) {
      final name = surah.name?.transliteration?.id?.toLowerCase() ?? "";
      final translation = surah.name?.translation?.id?.toLowerCase() ?? "";
      final num = surah.number?.toString() ?? "";
      final query = searchQ.value.toLowerCase();
      return name.contains(query) || translation.contains(query) || num == query;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    getFetchSurah();
  }

  getFetchSurah() async {
    try {
      _isLoading.value = true;
      _getSurah.assignAll(await HomeSource.fetchSurah());
    } finally {
      _isLoading.value = false;
    }
    update();
  }

  final _getSurahDetail = SurahDetail().obs;
  SurahDetail get getSurahDetail => _getSurahDetail.value;
  getFetchSurahDetail(String surahNumber) async {
    _getSurahDetail.value = await HomeSource.fetchDetailSurah(surahNumber);
    update();
  }
}
