// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:dilalquran/config/ai_config.dart';
import 'package:dilalquran/modules/scan_ayat/model/ayat_recognition_model.dart';
import 'package:http/http.dart' as http;

/// Hasil pemanggilan layanan AI, membedakan gagal teknis dari "tidak
/// ditemukan" agar UI bisa memberi pesan yang tepat.
class VisionOutcome {
  final AyatRecognition? recognition;
  final String? errorMessage;

  const VisionOutcome.success(AyatRecognition value)
      : recognition = value,
        errorMessage = null;

  const VisionOutcome.failure(String message)
      : recognition = null,
        errorMessage = message;

  bool get isSuccess => recognition != null;
}

/// Membaca foto halaman Al-Qur'an dan menebak surah:ayat.
///
/// Model TIDAK diminta menuliskan teks Arab. Ia hanya diminta menyebut
/// nomor surah dan ayat, lalu aplikasi menarik teks resmi dari equran.id.
/// Dengan begitu tidak ada satu huruf ayat pun yang berasal dari AI.
class AyatVisionService {
  const AyatVisionService._();

  static const String _prompt = '''
Kamu adalah pembantu pengenal halaman Al-Qur'an.

Tugasmu: lihat gambar dan tentukan ayat Al-Qur'an mana yang paling menonjol
di sana (biasanya ayat di bagian tengah/atas halaman, atau ayat yang ditandai
oleh pengguna).

ATURAN KETAT:
1. JANGAN menuliskan ulang teks Arab apa pun.
2. JANGAN menerjemahkan.
3. Jawab HANYA dengan nomor surah dan nomor ayat.
4. Bila kamu tidak yakin, berikan sampai 3 kemungkinan, diurutkan dari yang
   paling mungkin, masing-masing dengan nilai keyakinan 0..1.
5. Bila gambar bukan halaman Al-Qur'an (mis. foto orang, pemandangan, teks
   Latin), setel is_quran_page = false dan kosongkan candidates.
6. Nomor surah harus 1..114 dan nomor ayat harus benar-benar ada pada surah
   tersebut. Jangan mengarang nomor.

Isi "note" dengan alasan singkat dalam bahasa Indonesia bila gambar buram,
gelap, terpotong, atau kamu ragu. Kosongkan bila tidak ada masalah.
''';

  static const Map<String, dynamic> _responseSchema = {
    "type": "object",
    "properties": {
      "is_quran_page": {"type": "boolean"},
      "note": {"type": "string"},
      "candidates": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "surah": {"type": "integer"},
            "surah_name": {"type": "string"},
            "ayat_start": {"type": "integer"},
            "ayat_end": {"type": "integer"},
            "confidence": {"type": "number"},
          },
          "required": ["surah", "ayat_start", "ayat_end", "confidence"],
        },
      },
    },
    "required": ["is_quran_page", "candidates"],
  };

  /// [imageBytes] sebaiknya sudah dikecilkan oleh pemanggil.
  static Future<VisionOutcome> recognize({
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    if (!AiConfig.isConfigured) {
      return const VisionOutcome.failure(AiConfig.notConfiguredMessage);
    }
    if (imageBytes.isEmpty) {
      return const VisionOutcome.failure('Gambar tidak terbaca.');
    }

    // Teks prompt diletakkan SEBELUM gambar, sesuai anjuran dokumentasi
    // Gemini untuk kasus satu gambar bersama instruksi teks.
    final body = <String, dynamic>{
      'model': AiConfig.model,
      'input': [
        {'type': 'text', 'text': _prompt},
        {
          'type': 'image',
          'data': base64Encode(imageBytes),
          'mime_type': mimeType,
        },
      ],
      'response_format': {
        'type': 'text',
        'mime_type': 'application/json',
        'schema': _responseSchema,
      },
    };

    try {
      final response = await http
          .post(
            AiConfig.visionEndpoint(),
            headers: AiConfig.headers(),
            body: json.encode(body),
          )
          .timeout(AiConfig.requestTimeout);

      if (response.statusCode == 429) {
        return const VisionOutcome.failure(
          'Kuota harian Scan Ayat sudah habis. Coba lagi besok.',
        );
      }
      if (response.statusCode != 200) {
        print('AyatVisionService gagal: ${response.statusCode} ${response.body}');
        return const VisionOutcome.failure(
          'Layanan pengenalan ayat sedang tidak dapat dihubungi.',
        );
      }

      final outputText = _extractOutputText(response.body);
      if (outputText == null || outputText.trim().isEmpty) {
        return const VisionOutcome.failure('Balasan layanan tidak lengkap.');
      }

      return VisionOutcome.success(parseAyatRecognition(outputText));
    } catch (error) {
      print('AyatVisionService error: $error');
      return const VisionOutcome.failure(
        'Gagal menghubungi layanan. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Mengambil teks jawaban dari respons.
  ///
  /// Mendukung dua bentuk: respons asli Gemini Interactions API
  /// (`output_text`) dan respons proxy sendiri yang boleh langsung
  /// mengirim objek hasilnya.
  static String? _extractOutputText(String responseBody) {
    try {
      final decoded = json.decode(responseBody);
      if (decoded is! Map<String, dynamic>) return responseBody;

      final direct = decoded['output_text'] ?? decoded['outputText'];
      if (direct is String) return direct;

      // Proxy boleh meneruskan objek hasil apa adanya.
      if (decoded.containsKey('candidates') ||
          decoded.containsKey('is_quran_page')) {
        return responseBody;
      }
      return null;
    } catch (_) {
      return responseBody;
    }
  }
}
