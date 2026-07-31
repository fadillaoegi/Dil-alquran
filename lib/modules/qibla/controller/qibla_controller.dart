import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

enum QiblaStatus { loading, ready, noSensor, locationOff, permissionDenied, error }

// Tingkat akurasi kompas berdasarkan deviasi sensor magnetometer.
enum CompassAccuracy { unknown, low, medium, high }

class QiblaController extends GetxController {
  // Koordinat Ka'bah (Masjidil Haram, Makkah).
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  final Rx<QiblaStatus> status = QiblaStatus.loading.obs;

  // Heading kompas HP (derajat dari utara magnetik), null bila belum ada data.
  final RxnDouble heading = RxnDouble();
  // Deviasi/akurasi sensor kompas (derajat; null/negatif = tidak diketahui).
  final RxnDouble accuracy = RxnDouble();
  // Apakah overlay panduan kalibrasi sedang ditampilkan.
  final RxBool calibrationVisible = false.obs;
  // Heading hasil penghalusan (low-pass) untuk mengurangi getaran pembacaan.
  double? _smoothedHeading;
  // Agar panduan kalibrasi otomatis hanya muncul sekali per sesi.
  bool _autoCalibShown = false;
  // Arah kiblat dari utara (derajat), searah jarum jam.
  final RxDouble qiblaBearing = 0.0.obs;
  // Jarak ke Makkah (km).
  final RxDouble distanceKm = 0.0.obs;
  // Nama lokasi pengguna (kota, provinsi) untuk info.
  final RxString locationLabel = "".obs;

  StreamSubscription<CompassEvent>? _compassSub;
  bool _sensorChecked = false;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    status.value = QiblaStatus.loading;
    _sensorChecked = false;

    final position = await _resolvePosition();
    if (position == null) return; // status sudah diset oleh _resolvePosition

    qiblaBearing.value = _computeQiblaBearing(
      position.latitude,
      position.longitude,
    );
    distanceKm.value = _computeDistanceKm(
      position.latitude,
      position.longitude,
    );
    _resolveLocationLabel(position.latitude, position.longitude);

    _startCompass();
  }

  void _startCompass() {
    final stream = FlutterCompass.events;
    if (stream == null) {
      status.value = QiblaStatus.noSensor;
      return;
    }

    status.value = QiblaStatus.ready;
    _compassSub?.cancel();
    _compassSub = stream.listen((event) {
      final h = event.heading;
      accuracy.value = event.accuracy;
      // Deteksi ketiadaan magnetometer: event pertama tanpa heading.
      if (h == null) {
        if (!_sensorChecked && heading.value == null) {
          status.value = QiblaStatus.noSensor;
        }
        _sensorChecked = true;
        return;
      }
      _sensorChecked = true;
      // Haluskan heading (low-pass melingkar) agar penunjuk tidak bergetar,
      // sehingga arah kiblat lebih stabil dan terasa akurat.
      heading.value = _smoothHeading((h + 360) % 360);

      // Tawarkan kalibrasi otomatis sekali bila akurasi terdeteksi rendah.
      if (!_autoCalibShown &&
          accuracyLevel == CompassAccuracy.low &&
          !calibrationVisible.value) {
        _autoCalibShown = true;
        calibrationVisible.value = true;
      }
    });
  }

  // Low-pass filter melingkar: rata-ratakan lewat komponen sin/cos agar
  // transisi 359°→0° tidak melompat.
  double _smoothHeading(double newHeading) {
    final prev = _smoothedHeading;
    if (prev == null) {
      _smoothedHeading = newHeading;
      return newHeading;
    }
    const double alpha = 0.2; // 0=sangat halus/lambat, 1=mentah/responsif
    final prevRad = _deg2rad(prev);
    final nextRad = _deg2rad(newHeading);
    final sinV = (1 - alpha) * math.sin(prevRad) + alpha * math.sin(nextRad);
    final cosV = (1 - alpha) * math.cos(prevRad) + alpha * math.cos(nextRad);
    var result = (_rad2deg(math.atan2(sinV, cosV)) + 360) % 360;
    _smoothedHeading = result;
    return result;
  }

  // Tingkat akurasi kompas dari deviasi sensor (derajat).
  CompassAccuracy get accuracyLevel {
    final a = accuracy.value;
    if (a == null || a < 0) return CompassAccuracy.unknown;
    if (a <= 15) return CompassAccuracy.high;
    if (a <= 30) return CompassAccuracy.medium;
    return CompassAccuracy.low;
  }

  String get accuracyLabel {
    switch (accuracyLevel) {
      case CompassAccuracy.high:
        return "Tinggi";
      case CompassAccuracy.medium:
        return "Sedang";
      case CompassAccuracy.low:
        return "Rendah";
      case CompassAccuracy.unknown:
        return "Belum diketahui";
    }
  }

  bool get needsCalibration => accuracyLevel == CompassAccuracy.low;

  void startCalibration() => calibrationVisible.value = true;
  void dismissCalibration() => calibrationVisible.value = false;

  // Selisih terkecil antara heading & arah kiblat (0..180), untuk deteksi lurus.
  double get angleDifference {
    final h = heading.value;
    if (h == null) return 180.0;
    var diff = (qiblaBearing.value - h).abs() % 360;
    if (diff > 180) diff = 360 - diff;
    return diff;
  }

  bool get isAligned => heading.value != null && angleDifference <= 5.0;

  Future<Position?> _resolvePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        status.value = QiblaStatus.locationOff;
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        status.value = QiblaStatus.permissionDenied;
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      status.value = QiblaStatus.error;
      return null;
    }
  }

  Future<void> _resolveLocationLabel(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final kota = (p.subAdministrativeArea?.isNotEmpty ?? false)
            ? p.subAdministrativeArea!
            : (p.locality ?? "");
        final provinsi = p.administrativeArea ?? "";
        final parts = [kota, provinsi].where((s) => s.trim().isNotEmpty);
        locationLabel.value = parts.join(", ");
      }
    } catch (_) {
      // Label lokasi opsional — abaikan bila gagal.
    }
  }

  // Bearing awal great-circle dari lokasi pengguna ke Ka'bah (derajat 0..360).
  double _computeQiblaBearing(double lat, double lng) {
    final phi1 = _deg2rad(lat);
    final phi2 = _deg2rad(_kaabaLat);
    final deltaLambda = _deg2rad(_kaabaLng - lng);

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
    final theta = math.atan2(y, x);
    return (_rad2deg(theta) + 360) % 360;
  }

  // Jarak haversine ke Makkah (km).
  double _computeDistanceKm(double lat, double lng) {
    const earthRadius = 6371.0;
    final phi1 = _deg2rad(lat);
    final phi2 = _deg2rad(_kaabaLat);
    final dPhi = _deg2rad(_kaabaLat - lat);
    final dLambda = _deg2rad(_kaabaLng - lng);

    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * math.pi / 180.0;
  double _rad2deg(double rad) => rad * 180.0 / math.pi;

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  void onClose() {
    _compassSub?.cancel();
    super.onClose();
  }
}
