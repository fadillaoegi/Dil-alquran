import 'dart:convert';

import 'package:dilalquran/modules/shalat/model/shalat_model.dart';
import 'package:http/http.dart' as http;

class ShalatApiException implements Exception {
  final String message;

  const ShalatApiException(this.message);

  @override
  String toString() => message;
}

class ShalatSource {
  static const String _baseUrl = "https://equran.id/api/v2/shalat";

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw ShalatApiException(
        "Server jadwal shalat merespons ${response.statusCode}.",
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const ShalatApiException("Format data jadwal shalat tidak valid.");
    }

    return body;
  }

  Future<List<String>> getProvinsi() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/provinsi"))
          .timeout(const Duration(seconds: 15));

      final body = _decodeResponse(response);
      if (body['data'] != null) {
        return List<String>.from(body['data']);
      }
      throw const ShalatApiException("Daftar provinsi tidak tersedia.");
    } on ShalatApiException {
      rethrow;
    } on http.ClientException {
      throw const ShalatApiException(
        "Tidak bisa terhubung ke server jadwal shalat.",
      );
    } on FormatException {
      throw const ShalatApiException("Format data provinsi tidak dikenali.");
    } catch (_) {
      throw const ShalatApiException("Gagal memuat daftar provinsi.");
    }
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

      final body = _decodeResponse(response);
      if (body['data'] != null) {
        return List<String>.from(body['data']);
      }
      throw ShalatApiException("Daftar kabupaten/kota untuk $provinsi kosong.");
    } on ShalatApiException {
      rethrow;
    } on http.ClientException {
      throw const ShalatApiException(
        "Tidak bisa terhubung ke server jadwal shalat.",
      );
    } on FormatException {
      throw const ShalatApiException(
        "Format data kabupaten/kota tidak dikenali.",
      );
    } catch (_) {
      throw const ShalatApiException("Gagal memuat daftar kabupaten/kota.");
    }
  }

  Future<List<ShalatModel>> getJadwal(
    String provinsi,
    String kabkota, {
    int? bulan,
    int? tahun,
  }) async {
    try {
      final bodyMap = <String, dynamic>{
        "provinsi": provinsi,
        "kabkota": kabkota,
      };
      if (bulan != null) bodyMap["bulan"] = bulan;
      if (tahun != null) bodyMap["tahun"] = tahun;

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(bodyMap),
          )
          .timeout(const Duration(seconds: 15));

      final body = _decodeResponse(response);
      if (body['data'] != null && body['data']['jadwal'] != null) {
        final List<dynamic> jadwalList = body['data']['jadwal'];
        return jadwalList.map((e) => ShalatModel.fromJson(e)).toList();
      }
      throw const ShalatApiException("Jadwal shalat tidak tersedia.");
    } on ShalatApiException {
      rethrow;
    } on http.ClientException {
      throw const ShalatApiException(
        "Tidak bisa terhubung ke server jadwal shalat.",
      );
    } on FormatException {
      throw const ShalatApiException(
          "Format data jadwal shalat tidak dikenali.");
    } catch (_) {
      throw const ShalatApiException("Gagal memuat jadwal shalat.");
    }
  }
}
