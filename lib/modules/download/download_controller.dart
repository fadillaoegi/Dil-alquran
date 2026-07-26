import 'package:dilalquran/modules/data/models/juz_model.dart';
import 'package:dilalquran/modules/data/sources/doa_source.dart';
import 'package:dilalquran/modules/data/sources/home_source.dart';
import 'package:dilalquran/services/offline_store.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Mengelola unduhan konten teks (surah/juz/doa) untuk akses offline.
class DownloadController extends GetxController {
  final OfflineStore _store = OfflineStore();

  final RxSet<int> downloadedSurah = <int>{}.obs;
  final RxSet<int> downloadingSurah = <int>{}.obs; // sedang diunduh
  final RxSet<int> downloadedDoa = <int>{}.obs; // id doa yang di-download
  final RxBool doaBusy = false.obs; // proses unduh/hapus semua doa

  @override
  void onInit() {
    super.onInit();
    downloadedSurah.addAll(_store.downloadedSurah);
    downloadedDoa.addAll(_store.downloadedDoaIds);
  }

  // ---- Surah ----
  bool isSurahDownloaded(int nomor) => downloadedSurah.contains(nomor);
  bool isSurahDownloading(int nomor) => downloadingSurah.contains(nomor);

  Future<void> downloadSurah(int nomor) async {
    if (downloadingSurah.contains(nomor)) return;
    downloadingSurah.add(nomor);
    try {
      // fetchDetailSurah otomatis menyimpan ke cache saat berhasil.
      final detail = await HomeSource.fetchDetailSurah(nomor.toString());
      if (detail.ayat != null && detail.ayat!.isNotEmpty) {
        await _store.markSurahDownloaded(nomor);
        downloadedSurah.add(nomor);
      } else {
        _failSnackbar();
      }
    } finally {
      downloadingSurah.remove(nomor);
    }
  }

  Future<void> removeSurah(int nomor) async {
    await _store.removeSurah(nomor);
    downloadedSurah.remove(nomor);
  }

  Future<void> toggleSurah(int nomor) =>
      isSurahDownloaded(nomor) ? removeSurah(nomor) : downloadSurah(nomor);

  // ---- Juz (unduh semua surah pembentuknya) ----
  List<int> _juzSurahNumbers(int juzNumber) {
    for (final boundary in juzBoundaries) {
      if (boundary.number == juzNumber) {
        return [
          for (var s = boundary.startSurah; s <= boundary.endSurah; s++) s,
        ];
      }
    }
    return const [];
  }

  bool isJuzDownloaded(int juzNumber) {
    final surahs = _juzSurahNumbers(juzNumber);
    return surahs.isNotEmpty &&
        surahs.every((s) => downloadedSurah.contains(s));
  }

  bool isJuzDownloading(int juzNumber) {
    final surahs = _juzSurahNumbers(juzNumber);
    return downloadingSurah.any(surahs.contains);
  }

  Future<void> downloadJuz(int juzNumber) async {
    for (final s in _juzSurahNumbers(juzNumber)) {
      if (!downloadedSurah.contains(s)) {
        await downloadSurah(s);
      }
    }
  }

  // ---- Doa (per-id; data seluruh list sudah tersimpan saat fetch) ----
  bool isDoaDownloaded(int id) => downloadedDoa.contains(id);

  Future<void> toggleDoaItem(int id) async {
    if (downloadedDoa.contains(id)) {
      await _store.removeDoaItem(id);
      downloadedDoa.remove(id);
    } else {
      await _store.markDoaItem(id);
      downloadedDoa.add(id);
    }
  }

  // Unduh semua doa sekaligus (mengambil list + menandai semua id).
  Future<void> downloadAllDoa() async {
    if (doaBusy.value) return;
    doaBusy.value = true;
    try {
      final list = await DoaSource().fetchAllDoa();
      if (list != null && list.isNotEmpty) {
        final ids = list.map((d) => d.id).whereType<int>();
        await _store.setAllDoaIds(ids);
        downloadedDoa
          ..clear()
          ..addAll(ids);
      } else {
        _failSnackbar();
      }
    } finally {
      doaBusy.value = false;
    }
  }

  Future<void> removeAllDoa() async {
    await _store.clearDoaIds();
    downloadedDoa.clear();
  }

  void _failSnackbar() {
    Get.snackbar(
      "Gagal Mengunduh",
      "Periksa koneksi internet lalu coba lagi.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: ColorApp.black,
      colorText: ColorApp.white,
      margin: const EdgeInsets.all(16.0),
    );
  }
}
