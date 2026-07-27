import 'dart:convert';

import 'package:dilalquran/config/api_config.dart';
import 'package:dilalquran/modules/doa/model/doa_model.dart';
import 'package:dilalquran/services/offline_store.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

class DoaSource extends GetConnect {
  // Sumber 1: ambil doa dari API (equran.id).
  Future<List<DoaModel>?> fetchAllDoa() async {
    try {
      final response = await get(ApiConfig.doa);

      if (!response.status.hasError &&
          response.body != null &&
          response.body['data'] != null) {
        List<dynamic> data = response.body['data'];
        List<DoaModel> doasList =
            data.map((json) => DoaModel.fromJson(json)).toList();
        await OfflineStore().saveDoa(doasList); // cache untuk offline
        return doasList;
      }
    } catch (e) {
      // ignore
    }
    // Fallback: doa yang tersimpan offline.
    return OfflineStore().readDoa();
  }

  // Sumber 2: gabungkan doa lokal bawaan + koleksi NU Online yang sudah
  // dibundel ke assets. Tidak butuh koneksi internet — selalu tersedia.
  Future<List<DoaModel>?> fetchLocalDoa() async {
    final umum = await _fetchAssetDoa('assets/json/doa_umum.json') ?? const [];
    final nu = await _fetchAssetDoa('assets/json/doa_nu.json') ?? const [];
    return _mergeUniqueDoa([umum, nu]);
  }

  // Sumber 3: kumpulan doa NU Online (quran.nu.or.id), dibundel sebagai
  // JSON di assets. Tidak butuh koneksi internet.
  Future<List<DoaModel>?> fetchNuDoa() async {
    return _fetchAssetDoa('assets/json/doa_nu.json');
  }

  Future<List<DoaModel>?> _fetchAssetDoa(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final Map<String, dynamic> decoded = json.decode(raw);
      final List<dynamic> data = decoded['data'] ?? [];
      return data.map((json) => DoaModel.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  List<DoaModel> _mergeUniqueDoa(List<List<DoaModel>> sources) {
    final merged = <DoaModel>[];
    final seen = <String>{};
    var nextId = 1;

    for (final list in sources) {
      for (final doa in list) {
        final key = _dedupeKey(doa);
        if (key.isEmpty || seen.contains(key)) continue;
        seen.add(key);

        final normalized = DoaModel(
          id: nextId++,
          grup: doa.grup,
          nama: doa.nama,
          ar: doa.ar,
          tr: doa.tr,
          idn: doa.idn,
          tentang: doa.tentang,
          tag: doa.tag ?? const [],
        );
        merged.add(normalized);
      }
    }

    return merged;
  }

  String _dedupeKey(DoaModel doa) {
    final name = _normalize(doa.nama);
    final arabic = _normalize(doa.ar);

    if (name.isNotEmpty) return 'name:$name';
    if (arabic.isNotEmpty) return 'arab:$arabic';
    return '';
  }

  String _normalize(String? value) {
    if (value == null) return '';
    final lower = value.toLowerCase().trim();
    return lower
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
