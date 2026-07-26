import 'package:flutter/services.dart';

class PickedRingtone {
  final String uri;
  final String title;
  const PickedRingtone({required this.uri, required this.title});
}

// Membuka pemilih ringtone/suara bawaan Android (RingtoneManager).
// Bisa memilih ringtone, nada notifikasi, alarm, maupun suara di perangkat.
class RingtonePicker {
  static const MethodChannel _channel = MethodChannel('dilalquran/ringtone');

  // Return null bila dibatalkan atau tidak didukung (mis. iOS).
  static Future<PickedRingtone?> pick({String? currentUri}) async {
    try {
      final result = await _channel.invokeMethod<dynamic>(
        'pickRingtone',
        {'current': currentUri},
      );
      if (result is Map) {
        final uri = result['uri']?.toString();
        final title = result['title']?.toString() ?? 'Suara terpilih';
        if (uri != null && uri.isNotEmpty) {
          return PickedRingtone(uri: uri, title: title);
        }
      }
      return null;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
