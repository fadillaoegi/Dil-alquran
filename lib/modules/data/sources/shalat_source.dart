import 'dart:convert';
import 'package:dilalquran/modules/shalat/model/shalat_model.dart';
import 'package:http/http.dart' as http;

class ShalatSource {
  static const String _baseUrl = "https://equran.id/api/v2/shalat";

  Future<List<String>> getProvinsi() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/provinsi"))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data'] != null) {
          return List<String>.from(body['data']);
        }
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  Future<List<String>> getKabKota(String provinsi) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/kabkota"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"provinsi": provinsi}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data'] != null) {
          return List<String>.from(body['data']);
        }
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  Future<List<ShalatModel>> getJadwal(String provinsi, String kabkota) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"provinsi": provinsi, "kabkota": kabkota}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['data'] != null && body['data']['jadwal'] != null) {
          final List<dynamic> jadwalList = body['data']['jadwal'];
          return jadwalList.map((e) => ShalatModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      // ignore
    }
    return [];
  }
}
