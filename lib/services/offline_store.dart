import 'dart:convert';
import 'dart:io';

import 'package:dilalquran/modules/data/models/surah_detail_model.dart';
import 'package:dilalquran/modules/data/models/surah_model.dart';
import 'package:dilalquran/modules/doa/model/doa_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Penyimpanan konten offline (teks): daftar surah, detail surah, dan doa
// disimpan sebagai file JSON di direktori dokumen aplikasi. Manifest surah
// yang di-download disimpan di SharedPreferences.
class OfflineStore {
  static final OfflineStore _instance = OfflineStore._internal();
  factory OfflineStore() => _instance;
  OfflineStore._internal();

  static const _kSurahIds = 'offline_downloaded_surah';
  static const _kDoaIds = 'offline_downloaded_doa_ids';

  Directory? _root;
  SharedPreferences? _prefs;

  Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    _root = Directory('${docs.path}/offline');
    if (!_root!.existsSync()) {
      _root!.createSync(recursive: true);
    }
    _prefs = await SharedPreferences.getInstance();
  }

  File _surahFile(int nomor) => File('${_root!.path}/surah_$nomor.json');
  File get _indexFile => File('${_root!.path}/surah_index.json');
  File get _doaFile => File('${_root!.path}/doa.json');

  // ---- Daftar surah (index) ----
  Future<void> saveSurahIndex(List<Surah> list) async {
    if (_root == null || list.isEmpty) return;
    final data = list.map((s) => s.toJson()).toList();
    await _indexFile.writeAsString(jsonEncode(data));
  }

  Future<List<Surah>> readSurahIndex() async {
    if (_root == null || !_indexFile.existsSync()) return [];
    try {
      final data = jsonDecode(await _indexFile.readAsString()) as List;
      return data.map((e) => Surah.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ---- Detail surah ----
  Future<void> saveSurahDetail(SurahDetail detail) async {
    if (_root == null || detail.nomor == null) return;
    await _surahFile(detail.nomor!).writeAsString(surahDetailToJson(detail));
  }

  Future<SurahDetail?> readSurahDetail(int nomor) async {
    if (_root == null || !_surahFile(nomor).existsSync()) return null;
    try {
      return surahDetailFromJson(await _surahFile(nomor).readAsString());
    } catch (_) {
      return null;
    }
  }

  bool hasSurahDetail(int nomor) =>
      _root != null && _surahFile(nomor).existsSync();

  // ---- Doa ----
  // Menulis file cache doa (tidak menandai sebagai "di-download" — itu eksplisit).
  Future<void> saveDoa(List<DoaModel> list) async {
    if (_root == null || list.isEmpty) return;
    final data = list.map((d) => d.toJson()).toList();
    await _doaFile.writeAsString(jsonEncode(data));
  }

  Future<List<DoaModel>?> readDoa() async {
    if (_root == null || !_doaFile.existsSync()) return null;
    try {
      final data = jsonDecode(await _doaFile.readAsString()) as List;
      return data.map((e) => DoaModel.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  // ---- Manifest doa yang di-download (per-id) ----
  Set<int> get downloadedDoaIds {
    final raw = _prefs?.getStringList(_kDoaIds) ?? const [];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> _setDoaIds(Set<int> ids) async {
    await _prefs?.setStringList(
      _kDoaIds,
      ids.map((e) => e.toString()).toList(),
    );
  }

  Future<void> markDoaItem(int id) async {
    await _setDoaIds(downloadedDoaIds..add(id));
  }

  Future<void> removeDoaItem(int id) async {
    await _setDoaIds(downloadedDoaIds..remove(id));
  }

  Future<void> setAllDoaIds(Iterable<int> ids) async {
    await _setDoaIds(ids.toSet());
  }

  Future<void> clearDoaIds() async {
    await _setDoaIds(<int>{});
    if (_root != null && _doaFile.existsSync()) {
      await _doaFile.delete();
    }
  }

  // ---- Manifest surah yang di-download (eksplisit) ----
  Set<int> get downloadedSurah {
    final raw = _prefs?.getStringList(_kSurahIds) ?? const [];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  bool isSurahDownloaded(int nomor) => downloadedSurah.contains(nomor);

  Future<void> markSurahDownloaded(int nomor) async {
    final ids = downloadedSurah..add(nomor);
    await _prefs?.setStringList(
      _kSurahIds,
      ids.map((e) => e.toString()).toList(),
    );
  }

  Future<void> removeSurah(int nomor) async {
    final ids = downloadedSurah..remove(nomor);
    await _prefs?.setStringList(
      _kSurahIds,
      ids.map((e) => e.toString()).toList(),
    );
    if (_root != null && _surahFile(nomor).existsSync()) {
      await _surahFile(nomor).delete();
    }
  }
}
