// ============================================================
// Konfigurasi layanan AI untuk fitur "Scan Ayat".
//
// PENYEDIA: Google Gemini (Gemini Developer API) lewat Interactions API
//   POST https://generativelanguage.googleapis.com/v1beta/interactions
//
// CATATAN LANGGANAN & BIAYA:
// Langganan konsumen "Google AI Pro/Ultra" TIDAK memberi akses API untuk
// aplikasi — manfaatnya hanya berlaku di dalam antarmuka web AI Studio.
// Untuk aplikasi ini diperlukan API key dari https://aistudio.google.com/apikey
//
// FREE TIER (per Agustus 2026):
//   * Model kelas Flash (mis. gemini-3.7-flash) gratis: input & output
//     "Free of charge". Model Pro TIDAK tersedia di free tier.
//   * Kuota dihitung PER PROJECT, bukan per pengguna. Satu API key dipakai
//     seluruh pengguna aplikasi, jadi limit harian dibagi bersama.
//     Kuota harian reset tengah malam waktu Pacific.
//   * Pada free tier, konten permintaan DIPAKAI Google untuk memperbaiki
//     produk mereka (pada paid tier tidak). Wajib diungkap di privacy policy
//     karena foto halaman mushaf dan pertanyaan pengguna ikut terkirim.
//
// PENTING — KEAMANAN KUNCI API:
// Nilai apa pun yang dikompilasi ke dalam aplikasi (termasuk lewat
// --dart-define) BISA diekstrak dari APK/IPA. Karena itu:
//
//   * PRODUKSI  -> WAJIB pakai `AI_PROXY_URL`. Kunci API disimpan di
//                  server proxy (Cloudflare Worker / Firebase Functions),
//                  bukan di aplikasi. Proxy juga tempat menaruh rate limit
//                  dan kuota per pengguna.
//   * DEV/LOKAL -> boleh pakai `GEMINI_API_KEY` sementara untuk uji coba,
//                  JANGAN dipakai pada build yang dirilis ke store.
//
// Contoh menjalankan versi dev:
//   flutter run --dart-define=GEMINI_API_KEY=xxxx
// Contoh build produksi:
//   flutter build appbundle --dart-define=AI_PROXY_URL=https://api.contoh.id/ai
// ============================================================
class AiConfig {
  const AiConfig._();

  /// URL proxy milik sendiri. Bila diisi, seluruh permintaan AI dikirim
  /// ke sini dan aplikasi TIDAK pernah memegang kunci API.
  static const String proxyUrl = String.fromEnvironment('AI_PROXY_URL');

  /// Kunci API Gemini untuk pemakaian langsung. HANYA untuk pengembangan.
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Model multimodal yang dipakai untuk membaca foto mushaf dan menjawab
  /// pertanyaan. Kelas Flash sudah multimodal, cepat, dan hemat biaya.
  /// Bisa ditimpa tanpa mengubah kode, mis. ke `gemini-3.6-flash`.
  static const String model = String.fromEnvironment(
    'AI_MODEL',
    defaultValue: 'gemini-3.7-flash',
  );

  /// Interactions API — endpoint tunggal untuk teks maupun gambar.
  static const String _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/interactions';

  static bool get usesProxy => proxyUrl.trim().isNotEmpty;

  static bool get usesDirectKey => !usesProxy && geminiApiKey.trim().isNotEmpty;

  /// Fitur hanya aktif bila salah satu jalur tersedia.
  static bool get isConfigured => usesProxy || usesDirectKey;

  /// Endpoint untuk mengenali ayat dari gambar.
  static Uri visionEndpoint() {
    if (usesProxy) return Uri.parse('${_trimmedProxy()}/scan-ayat');
    return Uri.parse(_geminiEndpoint);
  }

  /// Endpoint untuk tanya jawab seputar ayat.
  static Uri chatEndpoint() {
    if (usesProxy) return Uri.parse('${_trimmedProxy()}/ayat-chat');
    return Uri.parse(_geminiEndpoint);
  }

  static Map<String, String> headers() {
    final result = <String, String>{'Content-Type': 'application/json'};
    if (usesDirectKey) {
      // Header lebih aman dari query string: tidak ikut tercatat di log URL.
      result['x-goog-api-key'] = geminiApiKey.trim();
    }
    return result;
  }

  static String _trimmedProxy() {
    final value = proxyUrl.trim();
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  /// Pesan yang ditampilkan bila fitur belum dikonfigurasi.
  static const String notConfiguredMessage =
      'Fitur Scan Ayat belum aktif pada build ini. '
      'Hubungi pengembang aplikasi.';

  /// Batas ukuran gambar yang dikirim, menekan biaya dan waktu unggah.
  static const int maxImageWidth = 1280;
  static const int imageQuality = 85;

  static const Duration requestTimeout = Duration(seconds: 45);
}
