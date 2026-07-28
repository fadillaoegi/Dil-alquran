import 'package:flutter/services.dart';

// Jembatan ke native (Android) untuk membebaskan aplikasi dari optimasi
// baterai, agar alarm/notifikasi shalat tetap berjalan saat aplikasi ditutup.
// Di platform selain Android, metode ini no-op dan dianggap sudah "aman".
class PowerManager {
  static const MethodChannel _channel = MethodChannel('dilalquran/power');

  // Apakah aplikasi sudah dikecualikan dari optimasi baterai?
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true; // iOS / platform lain
    }
  }

  // Minta pengecualian optimasi baterai (memunculkan dialog sistem Android).
  // Mengembalikan true bila dialog/pengaturan berhasil dibuka.
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final result = await _channel
          .invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
