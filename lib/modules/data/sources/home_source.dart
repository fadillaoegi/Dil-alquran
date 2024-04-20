// ignore_for_file: avoid_print

import 'package:dilalquran/config/api_config.dart';
import 'package:dilalquran/config/request_config.dart';
import 'package:dilalquran/modules/data/models/surah_detail_model.dart';
import 'package:dilalquran/modules/data/models/surah_model.dart';

class HomeSource {
  static Future<List<Surah>> fetchSurah() async {
    try {
      String url = ApiConfig.surah;

      Map? resFetchSurah = await AppRequest.gets(url);

      if (resFetchSurah == null) return [];

      if (resFetchSurah["status"] == "OK") {
        List resToList = resFetchSurah["data"] ?? [];

        final listToModel = resToList.map((e) => Surah.fromJson(e)).toList();
        return listToModel;
      } else {
        return [];
      }
    } catch (error) {
      print("Catch from Source: $error");
      return [];
    }
  }

  static Future<SurahDetail> fetchDetailSurah(String surahNumber) async {
    try {
      String url = "https://api.quran.gading.dev/surah/$surahNumber";

      Map? resFetchSurahDetail = await AppRequest.gets(url);

      if (resFetchSurahDetail == null) return SurahDetail();

      if (resFetchSurahDetail["status"] == "OK") {
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
}
