import 'package:dilalquran/modules/shalat/model/shalat_model.dart';
import 'package:get/get.dart';

class ShalatSource extends GetConnect {
  static const String _baseUrl = "https://equran.id/api/v2/shalat";

  Future<List<String>> getProvinsi() async {
    try {
      final response = await get("$_baseUrl/provinsi");
      if (!response.status.hasError && response.body['data'] != null) {
        return List<String>.from(response.body['data']);
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  Future<List<String>> getKabKota(String provinsi) async {
    try {
      final response = await post("$_baseUrl/kabkota", {
        "provinsi": provinsi
      });
      if (!response.status.hasError && response.body['data'] != null) {
        return List<String>.from(response.body['data']);
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  Future<List<ShalatModel>> getJadwal(String provinsi, String kabkota) async {
    try {
      final response = await post(_baseUrl, {
        "provinsi": provinsi,
        "kabkota": kabkota,
      });

      if (!response.status.hasError && response.body['data'] != null) {
        List<dynamic> jadwalList = response.body['data']['jadwal'];
        return jadwalList.map((e) => ShalatModel.fromJson(e)).toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }
}
