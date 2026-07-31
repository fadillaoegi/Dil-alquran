import 'dart:io';

import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

// Layanan pengecekan pembaruan aplikasi via Google Play (In-App Update API)
// dan pengarah ke halaman Play Store.
class UpdateService {
  static const String _packageId = 'com.fldev.dilalquran';

  // Cek apakah ada versi lebih baru di Google Play.
  // Hanya berlaku di Android dan pada build yang dipasang dari Play Store
  // (di debug/sideload akan melempar error → dianggap tidak ada pembaruan).
  static Future<bool> isUpdateAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      final info = await InAppUpdate.checkForUpdate();
      return info.updateAvailability == UpdateAvailability.updateAvailable;
    } catch (_) {
      return false;
    }
  }

  // Buka halaman aplikasi di Google Play. Utamakan skema market:// (langsung
  // membuka app Play Store), fallback ke URL web bila tidak tersedia.
  static Future<void> openStore() async {
    final market = Uri.parse('market://details?id=$_packageId');
    final web =
        Uri.parse('https://play.google.com/store/apps/details?id=$_packageId');

    try {
      if (await launchUrl(market, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // abaikan, coba fallback web
    }
    try {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    } catch (_) {
      // abaikan
    }
  }
}
