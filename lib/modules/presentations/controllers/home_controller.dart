// ignore_for_file: invalid_use_of_protected_member

import 'package:dilalquran/modules/data/models/surah_detail_model.dart';
import 'package:dilalquran/modules/data/models/surah_model.dart';
import 'package:dilalquran/modules/data/sources/home_source.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final _getSurah = <Surah>[].obs;
  List<Surah> get getSurah => _getSurah.value;

  getFetchSurah() async {
    _getSurah.value = await HomeSource.fetchSurah();
    update();
  }

  final _getSurahDetail = SurahDetail().obs;
  SurahDetail get getSurahDetail => _getSurahDetail.value;
  getFetchSurahDetail(String surahNumber) async {
    _getSurahDetail.value = await HomeSource.fetchDetailSurah(surahNumber);
    update();
  }
}
