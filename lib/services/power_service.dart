import 'package:flutter/services.dart';

// Jembatan ke native (Android) untuk pengaturan sistem yang memengaruhi alarm
// dan notifikasi aplikasi.
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

  static Future<bool> openNotificationSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openNotificationSettings');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> openExactAlarmSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openExactAlarmSettings');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> openNotificationChannelSettings(String channelId) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openNotificationChannelSettings',
        {'channelId': channelId},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
