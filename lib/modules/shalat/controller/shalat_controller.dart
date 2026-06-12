import 'package:dilalquran/modules/data/sources/shalat_source.dart';
import 'package:dilalquran/modules/shalat/model/shalat_model.dart';
import 'package:dilalquran/services/notification_service.dart';
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

  final RxBool isNotificationEnabled = false.obs;
  final RxString notificationSound = "adzan".obs;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
    fetchProvinsi();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    selectedProvinsi.value = prefs.getString('saved_provinsi') ?? "";
    selectedKabKota.value = prefs.getString('saved_kabkota') ?? "";
    isNotificationEnabled.value = prefs.getBool('notif_shalat') ?? false;
    notificationSound.value = prefs.getString('notif_sound') ?? "adzan";
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_provinsi', selectedProvinsi.value);
    await prefs.setString('saved_kabkota', selectedKabKota.value);
    await prefs.setBool('notif_shalat', isNotificationEnabled.value);
    await prefs.setString('notif_sound', notificationSound.value);
  }

  Future<void> fetchProvinsi() async {
    isLoadingProvinsi.value = true;
    final result = await _source.getProvinsi();
    listProvinsi.assignAll(result);
    isLoadingProvinsi.value = false;

    if (selectedProvinsi.value.isNotEmpty && listProvinsi.contains(selectedProvinsi.value)) {
      fetchKabKota(selectedProvinsi.value, isInit: true);
    } else if (selectedProvinsi.value.isEmpty) {
      // Jika belum ada lokasi tersimpan, coba deteksi otomatis
      _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String? adminArea = place.administrativeArea; // e.g. "Daerah Khusus Ibukota Jakarta"
        String? subAdminArea = place.subAdministrativeArea; // e.g. "Kota Jakarta Pusat"

        if (adminArea != null) {
          // Cari provinsi terdekat (Fuzzy search simpel)
          String matchedProv = _findClosestMatch(adminArea, listProvinsi);
          if (matchedProv.isNotEmpty) {
            selectedProvinsi.value = matchedProv;
            
            // Fetch kabkota berdasarkan provinsi yang cocok
            isLoadingKabKota.value = true;
            final kabKotaResult = await _source.getKabKota(matchedProv);
            listKabKota.assignAll(kabKotaResult);
            isLoadingKabKota.value = false;

            if (subAdminArea != null) {
              String matchedKota = _findClosestMatch(subAdminArea, listKabKota);
              if (matchedKota.isNotEmpty) {
                selectedKabKota.value = matchedKota;
                _savePreferences();
                fetchJadwal(matchedProv, matchedKota);
              }
            }
          }
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  String _findClosestMatch(String query, List<String> list) {
    String q = query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (String item in list) {
      String i = item.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (q.contains(i) || i.contains(q)) {
        return item;
      }
    }
    return "";
  }

  Future<void> fetchKabKota(String provinsi, {bool isInit = false}) async {
    isLoadingKabKota.value = true;
    selectedProvinsi.value = provinsi;
    
    if (!isInit) {
      selectedKabKota.value = "";
      listJadwal.clear();
      _savePreferences();
    }

    final result = await _source.getKabKota(provinsi);
    listKabKota.assignAll(result);
    isLoadingKabKota.value = false;

    if (isInit) {
      final prefs = await SharedPreferences.getInstance();
      final savedKabKota = prefs.getString('saved_kabkota') ?? "";
      if (savedKabKota.isNotEmpty && listKabKota.contains(savedKabKota)) {
        selectedKabKota.value = savedKabKota;
        fetchJadwal(provinsi, savedKabKota);
      }
    }
  }

  Future<void> onKabKotaSelected(String kabkota) async {
    selectedKabKota.value = kabkota;
    _savePreferences();
    await fetchJadwal(selectedProvinsi.value, kabkota);
  }

  Future<void> fetchJadwal(String provinsi, String kabkota) async {
    isLoadingJadwal.value = true;
    final result = await _source.getJadwal(provinsi, kabkota);
    listJadwal.assignAll(result);
    isLoadingJadwal.value = false;

    if (isNotificationEnabled.value) {
      _scheduleAllNotifications();
    }
  }

  Future<void> toggleNotification(bool value, BuildContext context) async {
    isNotificationEnabled.value = value;
    _savePreferences();

    if (value) {
      await _notificationService.requestPermissions();
      _scheduleAllNotifications();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pengingat waktu shalat telah diaktifkan."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await _notificationService.cancelAll();
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

  void _scheduleAllNotifications() async {
    await _notificationService.cancelAll();

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
        try {
          // Format dari API misal: "2026-06-01" dan jam "04:36"
          DateTime dt = DateTime.parse("${jadwal.tanggalLengkap} ${entry.value}:00");
          if (dt.isAfter(DateTime.now())) {
            _notificationService.schedulePrayer(
              idCounter++,
              "Waktu ${entry.key}",
              "Telah masuk waktu shalat ${entry.key} untuk wilayah ${selectedKabKota.value}.",
              dt,
              notificationSound.value,
            );
          }
        } catch (e) {
          // Abaikan error parse
        }
      }
    }
  }
}
