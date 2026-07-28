import 'dart:convert';

import 'package:dilalquran/modules/data/sources/shalat_source.dart';
import 'package:dilalquran/modules/shalat/model/shalat_model.dart';
import 'package:dilalquran/services/notification_service.dart';
import 'package:dilalquran/services/power_service.dart';
import 'package:dilalquran/services/ringtone_picker.dart';
import 'package:dilalquran/widgets/app_notify.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShalatController extends GetxController {
  final ShalatSource _source = ShalatSource();
  final NotificationService _notificationService = NotificationService();

  final RxList<String> listProvinsi = <String>[].obs;
  final RxList<String> listKabKota = <String>[].obs;
  final RxList<ShalatModel> listJadwal = <ShalatModel>[].obs;

  final RxString selectedProvinsi = "".obs;
  final RxString selectedKabKota = "".obs;

  final RxBool isLoadingProvinsi = true.obs;
  final RxBool isLoadingKabKota = false.obs;
  final RxBool isLoadingJadwal = false.obs;
  final RxBool isDetectingLocation = false.obs;
  final RxString locationErrorMessage = "".obs;

  final RxBool isNotificationEnabled = false.obs;
  static const String notificationModeAdzan = "adzan";
  static const String notificationModeDevice = "device";
  static const String notificationModeCustom = "custom";
  static const String notificationModeSilent = "silent";
  static const String notificationModeOff = "off";
  static const List<String> notificationModes = [
    notificationModeAdzan,
    notificationModeDevice,
    notificationModeCustom,
    notificationModeSilent,
    notificationModeOff,
  ];
  // Legacy/default sound mode.
  final RxString notificationSound = "adzan".obs;
  // Suara pilihan dari HP (ringtone/MP3) untuk soundType 'custom'.
  final RxString customSoundUri = "".obs;
  final RxString customSoundTitle = "".obs;

  // Waktu sholat yang bisa dinotifikasi (Imsak/Dhuha/Terbit tidak termasuk).
  static const List<String> prayerNames = [
    "Subuh",
    "Dzuhur",
    "Ashar",
    "Maghrib",
    "Isya",
  ];

  // Setelan notifikasi per waktu sholat.
  final RxMap<String, String> prayerNotificationModes = <String, String>{
    for (final prayer in prayerNames) prayer: notificationModeAdzan,
  }.obs;

  // Status apakah aplikasi sudah dikecualikan dari optimasi baterai (Android).
  // Bila false, alarm/notifikasi shalat berisiko dimatikan OS saat app ditutup.
  final RxBool isIgnoringBatteryOptimization = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
    fetchProvinsi();
    refreshBatteryOptimizationStatus();
  }

  // Segarkan status pengecualian optimasi baterai (dipanggil saat masuk layar
  // dan setelah kembali dari dialog izin).
  Future<void> refreshBatteryOptimizationStatus() async {
    isIgnoringBatteryOptimization.value =
        await PowerManager.isIgnoringBatteryOptimizations();
  }

  // Minta agar aplikasi berjalan bebas di latar belakang (dialog sistem).
  Future<void> requestBackgroundPermission() async {
    await PowerManager.requestIgnoreBatteryOptimizations();
    // Beri jeda agar status ter-update setelah user menutup dialog.
    await Future.delayed(const Duration(milliseconds: 400));
    await refreshBatteryOptimizationStatus();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    selectedProvinsi.value = prefs.getString('saved_provinsi') ?? "";
    selectedKabKota.value = prefs.getString('saved_kabkota') ?? "";
    isNotificationEnabled.value = prefs.getBool('notif_shalat') ?? false;
    notificationSound.value = prefs.getString('notif_sound') ?? "adzan";
    customSoundUri.value = prefs.getString('notif_custom_uri') ?? "";
    customSoundTitle.value = prefs.getString('notif_custom_title') ?? "";

    final savedPrayerModes = prefs.getString('notif_prayer_modes');
    if (savedPrayerModes != null && savedPrayerModes.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedPrayerModes);
        if (decoded is Map) {
          for (final prayer in prayerNames) {
            final mode = decoded[prayer]?.toString();
            if (mode == "alarm") {
              prayerNotificationModes[prayer] = notificationModeDevice;
            } else if (notificationModes.contains(mode)) {
              prayerNotificationModes[prayer] = mode!;
            }
          }
        }
      } catch (_) {
        // fallback ke preferensi lama
      }
    } else {
      final savedPrayers = prefs.getStringList('notif_prayers');
      for (final prayer in prayerNames) {
        final enabled = savedPrayers == null || savedPrayers.contains(prayer);
        prayerNotificationModes[prayer] =
            enabled ? notificationSound.value : notificationModeOff;
      }
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_provinsi', selectedProvinsi.value);
    await prefs.setString('saved_kabkota', selectedKabKota.value);
    await prefs.setBool('notif_shalat', isNotificationEnabled.value);
    await prefs.setString('notif_sound', notificationSound.value);
    await prefs.setString('notif_custom_uri', customSoundUri.value);
    await prefs.setString('notif_custom_title', customSoundTitle.value);

    final enabledList =
        prayerNames.where((prayer) => isPrayerEnabled(prayer)).toList();
    await prefs.setStringList('notif_prayers', enabledList);
    await prefs.setString(
      'notif_prayer_modes',
      jsonEncode(prayerNotificationModes),
    );
  }

  Future<void> fetchProvinsi() async {
    isLoadingProvinsi.value = true;
    locationErrorMessage.value = "";
    try {
      final result = await _source.getProvinsi();
      listProvinsi.assignAll(result);

      final matchedSavedProvinsi = _findClosestMatch(
        selectedProvinsi.value,
        listProvinsi,
      );
      if (matchedSavedProvinsi.isNotEmpty) {
        selectedProvinsi.value = matchedSavedProvinsi;
        await fetchKabKota(matchedSavedProvinsi, isInit: true);
      } else if (selectedProvinsi.value.isEmpty) {
        // Jika belum ada lokasi tersimpan, coba deteksi otomatis (diam-diam).
        _resolveFromGps();
      }
    } on ShalatApiException catch (e) {
      listProvinsi.clear();
      locationErrorMessage.value = e.message;
      _snack("Lokasi Gagal Dimuat", e.message);
    } finally {
      isLoadingProvinsi.value = false;
    }
  }

  // Dipanggil tombol "Gunakan lokasi HP" — deteksi ulang lokasi via GPS.
  Future<void> useCurrentLocation() async {
    if (isDetectingLocation.value) return;
    isDetectingLocation.value = true;
    try {
      final ok = await _resolveFromGps(showFeedback: true);
      if (ok) {
        _snack(
          "Lokasi Diperbarui",
          "Jadwal disesuaikan dengan lokasi perangkatmu.",
          success: true,
        );
      }
    } finally {
      isDetectingLocation.value = false;
    }
  }

  // Deteksi lokasi via GPS lalu cocokkan ke provinsi & kab/kota.
  // Mengembalikan true bila berhasil menetapkan lokasi.
  Future<bool> _resolveFromGps({bool showFeedback = false}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (showFeedback) {
        _snack("Lokasi Nonaktif",
            "Aktifkan layanan lokasi (GPS) perangkat lalu coba lagi.");
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (showFeedback) {
          _snack("Izin Ditolak",
              "Aplikasi butuh izin lokasi untuk mendeteksi wilayahmu.");
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (showFeedback) {
        _snack(
            "Izin Diblokir", "Aktifkan izin lokasi lewat Pengaturan aplikasi.");
      }
      return false;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isEmpty) {
        if (showFeedback) {
          _snack("Gagal", "Tidak dapat menentukan wilayah dari lokasi.");
        }
        return false;
      }

      final place = placemarks.first;
      final adminArea = place.administrativeArea; // provinsi
      final subAdminArea = place.subAdministrativeArea; // kabupaten/kota

      if (adminArea == null) {
        if (showFeedback) _snack("Gagal", "Wilayah tidak terdeteksi.");
        return false;
      }

      final matchedProv = _findClosestMatch(adminArea, listProvinsi);
      if (matchedProv.isEmpty) {
        if (showFeedback) {
          _snack("Tidak Cocok", "Provinsi lokasimu tidak ditemukan di daftar.");
        }
        return false;
      }

      selectedProvinsi.value = matchedProv;
      locationErrorMessage.value = "";
      await fetchKabKota(matchedProv, isInit: false, silentError: true);

      final cityCandidates = [
        subAdminArea,
        place.locality,
        place.subLocality,
        place.name,
      ].whereType<String>().where((value) => value.trim().isNotEmpty);

      for (final candidate in cityCandidates) {
        final matchedKota = _findClosestMatch(candidate, listKabKota);
        if (matchedKota.isNotEmpty) {
          selectedKabKota.value = matchedKota;
          await _savePreferences();
          await fetchJadwal(matchedProv, matchedKota);
          return true;
        }
      }

      await _savePreferences();
      if (showFeedback) {
        _snack("Sebagian Terdeteksi",
            "Provinsi $matchedProv terdeteksi, silakan pilih kota secara manual.");
      }
      return false;
    } catch (e) {
      if (showFeedback) {
        _snack("Gagal", "Terjadi kesalahan saat mendeteksi lokasi.");
      }
      return false;
    }
  }

  void _snack(String title, String message, {bool success = false}) {
    showAppSnackbar(title, message, isError: !success);
  }

  static const Map<String, String> _areaAliases = {
    'nanggroe aceh darussalam': 'aceh',
    'special capital region of jakarta': 'dki jakarta',
    'jakarta special capital region': 'dki jakarta',
    'jakarta': 'dki jakarta',
    'special region of yogyakarta': 'di yogyakarta',
    'yogyakarta special region': 'di yogyakarta',
    'yogyakarta': 'di yogyakarta',
    'west java': 'jawa barat',
    'central java': 'jawa tengah',
    'east java': 'jawa timur',
    'west sumatra': 'sumatera barat',
    'north sumatra': 'sumatera utara',
    'south sumatra': 'sumatera selatan',
    'riau islands': 'kepulauan riau',
    'bangka belitung islands': 'kepulauan bangka belitung',
    'special region of aceh': 'aceh',
    'west kalimantan': 'kalimantan barat',
    'south kalimantan': 'kalimantan selatan',
    'central kalimantan': 'kalimantan tengah',
    'east kalimantan': 'kalimantan timur',
    'north kalimantan': 'kalimantan utara',
    'west nusa tenggara': 'nusa tenggara barat',
    'east nusa tenggara': 'nusa tenggara timur',
    'west sulawesi': 'sulawesi barat',
    'south sulawesi': 'sulawesi selatan',
    'central sulawesi': 'sulawesi tengah',
    'southeast sulawesi': 'sulawesi tenggara',
    'north sulawesi': 'sulawesi utara',
    'west papua': 'papua barat',
  };

  String _normalizeAreaName(String value) {
    var normalized = value.toLowerCase().trim();
    const replacements = <String, String>{
      'daerah istimewa': 'di',
      'daerah khusus ibukota': 'dki',
      'kabupaten': 'kab',
      'kab.': 'kab',
      'kota administrasi': 'kota',
      'provinsi': '',
    };

    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });

    normalized = normalized.replaceAll('&', ' dan ');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return _areaAliases[normalized] ?? normalized;
  }

  String _findClosestMatch(String query, List<String> list) {
    if (query.trim().isEmpty || list.isEmpty) return "";

    final normalizedQuery = _normalizeAreaName(query);
    final queryCompact = normalizedQuery.replaceAll(' ', '');
    final queryTokens =
        normalizedQuery.split(' ').where((e) => e.isNotEmpty).toList();

    for (final item in list) {
      final normalizedItem = _normalizeAreaName(item);
      final itemCompact = normalizedItem.replaceAll(' ', '');
      if (queryCompact == itemCompact ||
          queryCompact.contains(itemCompact) ||
          itemCompact.contains(queryCompact)) {
        return item;
      }
    }

    String bestItem = "";
    int bestScore = 0;
    for (final item in list) {
      final normalizedItem = _normalizeAreaName(item);
      final itemTokens =
          normalizedItem.split(' ').where((e) => e.isNotEmpty).toList();
      var score = 0;

      for (final token in queryTokens) {
        if (itemTokens.any(
          (itemToken) =>
              itemToken == token ||
              itemToken.startsWith(token) ||
              token.startsWith(itemToken),
        )) {
          score++;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestItem = item;
      }
    }

    if (bestScore > 0) return bestItem;
    return "";
  }

  Future<void> fetchKabKota(
    String provinsi, {
    bool isInit = false,
    bool silentError = false,
  }) async {
    isLoadingKabKota.value = true;
    selectedProvinsi.value = provinsi;
    locationErrorMessage.value = "";

    if (!isInit) {
      selectedKabKota.value = "";
      listJadwal.clear();
      await _savePreferences();
    }

    try {
      final result = await _source.getKabKota(provinsi);
      listKabKota.assignAll(result);

      if (isInit) {
        final prefs = await SharedPreferences.getInstance();
        final savedKabKota = prefs.getString('saved_kabkota') ?? "";
        final matchedSavedKabKota =
            _findClosestMatch(savedKabKota, listKabKota);
        if (matchedSavedKabKota.isNotEmpty) {
          selectedKabKota.value = matchedSavedKabKota;
          await fetchJadwal(provinsi, matchedSavedKabKota);
        }
      }
    } on ShalatApiException catch (e) {
      listKabKota.clear();
      locationErrorMessage.value = e.message;
      if (!silentError) {
        _snack("Kota Gagal Dimuat", e.message);
      }
    } finally {
      isLoadingKabKota.value = false;
    }
  }

  // Muat ulang data (untuk pull-to-refresh): jadwal bila lokasi sudah dipilih,
  // selain itu muat ulang daftar provinsi.
  Future<void> refreshJadwal() async {
    if (selectedProvinsi.value.isNotEmpty && selectedKabKota.value.isNotEmpty) {
      await fetchJadwal(selectedProvinsi.value, selectedKabKota.value);
    } else {
      await fetchProvinsi();
    }
  }

  Future<void> onKabKotaSelected(String kabkota) async {
    selectedKabKota.value = kabkota;
    _savePreferences();
    await fetchJadwal(selectedProvinsi.value, kabkota);
  }

  Future<void> fetchJadwal(String provinsi, String kabkota) async {
    isLoadingJadwal.value = true;
    locationErrorMessage.value = "";
    try {
      final result = await _source.getJadwal(provinsi, kabkota);
      listJadwal.assignAll(result);
      await _notificationService.cachePrayerSchedule(result);

      if (isNotificationEnabled.value) {
        _scheduleAllNotifications();
      }
    } on ShalatApiException catch (e) {
      listJadwal.clear();
      locationErrorMessage.value = e.message;
      _snack("Jadwal Gagal Dimuat", e.message);
    } finally {
      isLoadingJadwal.value = false;
    }
  }

  Future<void> toggleNotification(bool value, BuildContext context) async {
    isNotificationEnabled.value = value;
    _savePreferences();

    if (value) {
      await _notificationService.requestPermissions();

      // Pastikan aplikasi dibebaskan dari optimasi baterai agar notifikasi
      // tetap berjalan meski aplikasi ditutup (khususnya OEM agresif).
      await refreshBatteryOptimizationStatus();
      if (!isIgnoringBatteryOptimization.value) {
        await requestBackgroundPermission();
      }

      // Jika lokasi belum dipilih, tidak ada jadwal untuk dijadwalkan.
      if (selectedKabKota.value.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "Pilih lokasi terlebih dahulu untuk mengaktifkan pengingat."),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Jadwal belum termuat (mis. baru buka app), ambil dulu lalu jadwalkan.
      if (listJadwal.isEmpty) {
        await fetchJadwal(selectedProvinsi.value, selectedKabKota.value);
      } else {
        _scheduleAllNotifications();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pengingat waktu shalat telah diaktifkan."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await _cancelPrayerNotifications();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Semua pengingat waktu shalat telah dibatalkan."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> changeNotificationSound(String soundType) async {
    notificationSound.value = soundType;
    _savePreferences();
    if (isNotificationEnabled.value) {
      _scheduleAllNotifications();
    }
  }

  // Buka pemilih ringtone/suara HP (Android). Bila berhasil, set sebagai custom.
  Future<void> pickCustomSound() async {
    final picked = await RingtonePicker.pick(
      currentUri: customSoundUri.value.isEmpty ? null : customSoundUri.value,
    );
    if (picked == null) return; // dibatalkan / tidak didukung

    customSoundUri.value = picked.uri;
    customSoundTitle.value = picked.title;
    notificationSound.value = 'custom';
    // Hapus channel lama agar suara baru benar-benar dipakai.
    await _notificationService.deleteCustomChannel();
    _savePreferences();
    if (isNotificationEnabled.value) {
      _scheduleAllNotifications();
    }
  }

  Future<bool> ensureCustomSoundSelected() async {
    final previousUri = customSoundUri.value;
    await pickCustomSound();
    return customSoundUri.value.isNotEmpty &&
            customSoundUri.value != previousUri
        ? true
        : customSoundUri.value.isNotEmpty;
  }

  // Coba bunyikan notifikasi sesuai suara terpilih.
  Future<void> testNotificationSound() async {
    await _notificationService.testNotification(
      soundType: activePrayerModes.firstWhere(
        (mode) => mode != notificationModeOff,
        orElse: () => notificationModeAdzan,
      ),
      customSoundUri: customSoundUri.value,
    );
  }

  // Aktif/nonaktifkan notifikasi untuk satu waktu sholat tertentu.
  Future<void> togglePrayer(String prayer, bool value) async {
    await setPrayerNotificationMode(
      prayer,
      value ? notificationModeAdzan : notificationModeOff,
    );
  }

  Future<void> setPrayerNotificationMode(String prayer, String mode) async {
    if (mode == notificationModeCustom) {
      final hasCustomSound = await ensureCustomSoundSelected();
      if (!hasCustomSound) return;
    }
    prayerNotificationModes[prayer] = mode;
    await _savePreferences();
    if (isNotificationEnabled.value) {
      await _scheduleAllNotifications();
    }
  }

  Future<void> previewPrayerNotificationMode(String prayer, String mode) async {
    var previewMode = mode;
    if (mode == notificationModeCustom) {
      final hasCustomSound = await ensureCustomSoundSelected();
      if (!hasCustomSound) return;
      previewMode = notificationModeCustom;
    }
    if (previewMode == notificationModeOff) return;
    await _notificationService.testNotification(
      soundType: previewMode,
      customSoundUri: customSoundUri.value,
      title: "Tes $prayer",
      body: "Preview notifikasi untuk waktu shalat $prayer.",
    );
  }

  // Pilih semua / kosongkan semua waktu sholat sekaligus.
  Future<void> setAllPrayers(bool value) async {
    for (final prayer in prayerNames) {
      prayerNotificationModes[prayer] =
          value ? notificationModeAdzan : notificationModeOff;
    }
    await _savePreferences();
    if (isNotificationEnabled.value) {
      await _scheduleAllNotifications();
    }
  }

  bool isPrayerEnabled(String prayer) =>
      prayerNotificationModes[prayer] != notificationModeOff;

  List<String> get activePrayerModes => prayerNames
      .map((prayer) => prayerNotificationModes[prayer] ?? "")
      .toList();

  bool get allPrayersEnabled =>
      prayerNames.every((prayer) => isPrayerEnabled(prayer));

  // ---- Ringkasan untuk tampilan ----
  int get enabledPrayerCount =>
      prayerNames.where((prayer) => isPrayerEnabled(prayer)).length;

  String prayerModeLabel(String prayer) {
    switch (prayerNotificationModes[prayer]) {
      case notificationModeDevice:
        return "Suara ringtone system";
      case notificationModeCustom:
        return customSoundTitle.value.isNotEmpty
            ? customSoundTitle.value
            : "Suara chose file";
      case notificationModeSilent:
        return "Tanpa suara (notif saja)";
      case notificationModeOff:
        return "Nonaktif";
      case notificationModeAdzan:
      default:
        return "Suara adzan";
    }
  }

  String get soundLabel {
    switch (notificationSound.value) {
      case 'adzan':
        return "Adzan";
      case 'custom':
        return customSoundTitle.value.isNotEmpty
            ? customSoundTitle.value
            : "Suara HP";
      default:
        return "Suara ringtone system";
    }
  }

  String get locationLabel {
    final kota = selectedKabKota.value.trim();
    final provinsi = selectedProvinsi.value.trim();

    if (kota.isNotEmpty && provinsi.isNotEmpty) {
      return "$kota, $provinsi";
    }
    if (kota.isNotEmpty) return kota;
    if (provinsi.isNotEmpty) return provinsi;
    return "Lokasi belum dipilih";
  }

  String get _todayStr {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  ShalatModel? get todaySchedule {
    for (final jadwal in listJadwal) {
      if (jadwal.tanggalLengkap == _todayStr) return jadwal;
    }
    return null;
  }

  // Waktu sholat terdekat yang akan datang (lintas hari bila perlu).
  NextPrayer? get nextPrayer {
    final now = DateTime.now();
    for (final jadwal in listJadwal) {
      if (jadwal.tanggalLengkap == null) continue;
      final times = <String, String?>{
        "Subuh": jadwal.subuh,
        "Dzuhur": jadwal.dzuhur,
        "Ashar": jadwal.ashar,
        "Maghrib": jadwal.maghrib,
        "Isya": jadwal.isya,
      };
      for (final entry in times.entries) {
        final value = entry.value;
        if (value == null) continue;
        final dt = DateTime.tryParse("${jadwal.tanggalLengkap} $value:00");
        if (dt != null && dt.isAfter(now)) {
          return NextPrayer(name: entry.key, time: dt);
        }
      }
    }
    return null;
  }

  // Batas aman jumlah notifikasi terjadwal.
  // iOS hanya menyimpan maks 64 notifikasi pending; sisanya diam-diam dibuang.
  // 5 waktu x 12 hari = 60, masih di bawah batas dan mencakup ~2 minggu ke depan.
  static const int _maxScheduled = 60;

  // Batalkan hanya notifikasi sholat (id 1.._maxScheduled), tanpa menyentuh
  // pengingat lain seperti muraja'ah Hafizh (id 5001).
  Future<void> _cancelPrayerNotifications() async {
    for (var id = 1; id <= _maxScheduled; id++) {
      await _notificationService.cancel(id);
    }
  }

  Future<void> _scheduleAllNotifications() async {
    await _cancelPrayerNotifications();

    final now = DateTime.now();
    int idCounter = 1;

    for (var jadwal in listJadwal) {
      if (jadwal.tanggalLengkap == null) continue;

      final times = {
        "Subuh": jadwal.subuh,
        "Dzuhur": jadwal.dzuhur,
        "Ashar": jadwal.ashar,
        "Maghrib": jadwal.maghrib,
        "Isya": jadwal.isya,
      };

      for (var entry in times.entries) {
        if (entry.value == null) continue;
        final prayerMode =
            prayerNotificationModes[entry.key] ?? notificationModeAdzan;
        if (prayerMode == notificationModeOff) continue;
        try {
          // Format dari API misal: "2026-06-01" dan jam "04:36"
          DateTime dt =
              DateTime.parse("${jadwal.tanggalLengkap} ${entry.value}:00");
          if (dt.isAfter(now)) {
            await _notificationService.schedulePrayer(
              idCounter++,
              "Waktu ${entry.key}",
              "Telah masuk waktu shalat ${entry.key} untuk wilayah ${selectedKabKota.value}.",
              dt,
              prayerMode,
              customSoundUri: customSoundUri.value,
            );
          }
        } catch (e) {
          // Abaikan error parse
        }

        // Berhenti begitu mencapai batas aman agar tidak ada jadwal yang dibuang.
        if (idCounter > _maxScheduled) return;
      }
    }
  }
}

class NextPrayer {
  final String name;
  final DateTime time;

  const NextPrayer({required this.name, required this.time});
}
