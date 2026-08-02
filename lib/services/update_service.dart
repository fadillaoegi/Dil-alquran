import 'dart:io';

import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.isUpdateAvailable,
    required this.title,
    required this.message,
    this.isError = false,
  });

  final bool isUpdateAvailable;
  final String title;
  final String message;
  final bool isError;
}

// Layanan pengecekan pembaruan aplikasi via Google Play (In-App Update API)
// dan pengarah ke halaman Play Store.
class UpdateService {
  static const String _packageId = 'com.fldev.dilalquran';

  static Future<UpdateCheckResult> checkUpdateStatus() async {
    if (!Platform.isAndroid) {
      return const UpdateCheckResult(
        isUpdateAvailable: false,
        title: 'Cek Update Tidak Tersedia',
        message: 'Pengecekan update otomatis hanya tersedia di Android.',
      );
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        return const UpdateCheckResult(
          isUpdateAvailable: true,
          title: 'Pembaruan Tersedia',
          message: 'Versi terbaru aplikasi ditemukan di Google Play.',
        );
      }

      return const UpdateCheckResult(
        isUpdateAvailable: false,
        title: 'Aplikasi Sudah Terbaru',
        message: 'Belum ada pembaruan baru yang tersedia saat ini.',
      );
    } catch (_) {
      return const UpdateCheckResult(
        isUpdateAvailable: false,
        title: 'Cek Update Gagal',
        message:
            'Pastikan aplikasi terpasang dari Google Play dan akunmu mendapat release terbaru.',
        isError: true,
      );
    }
  }

  // Cek apakah ada versi lebih baru di Google Play.
  // Hanya berlaku di Android dan pada build yang dipasang dari Play Store
  // (di debug/sideload akan melempar error → dianggap tidak ada pembaruan).
  static Future<bool> isUpdateAvailable() async {
    final result = await checkUpdateStatus();
    return result.isUpdateAvailable;
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
