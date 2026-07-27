import 'dart:convert';

import 'package:dilalquran/modules/dzikir/model/dzikir_model.dart';
import 'package:flutter/services.dart' show rootBundle;

class DzikirSource {
  // Ambil dzikir dari file JSON lokal (assets/json/dzikir.json).
  // Tidak butuh koneksi internet — selalu tersedia.
  Future<List<DzikirModel>?> fetchLocalDzikir() async {
    try {
      final raw = await rootBundle.loadString('assets/json/dzikir.json');
      final Map<String, dynamic> decoded = json.decode(raw);
      final List<dynamic> data = decoded['data'] ?? [];
      return data.map((json) => DzikirModel.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }
}
