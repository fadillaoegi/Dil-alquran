import 'package:dilalquran/modules/data/models/surah_detail_model.dart';
import 'package:dilalquran/modules/data/sources/home_source.dart';
import 'package:get/get.dart';

class DetailSurahController extends GetxController {
  final _getSurahDetail = SurahDetail().obs;
  SurahDetail get getSurahDetail => _getSurahDetail.value;

  final _isLoading = true.obs;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    final String? surahNumber = Get.arguments;
    if (surahNumber != null) {
      getFetchSurahDetail(surahNumber);
    }
  }

  getFetchSurahDetail(String surahNumber) async {
    try {
      _isLoading.value = true;
      _getSurahDetail.value = await HomeSource.fetchDetailSurah(surahNumber);
    } finally {
      _isLoading.value = false;
    }
    update();
  }
}
