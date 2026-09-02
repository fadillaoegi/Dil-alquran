// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:dilalquran/config/ai_config.dart';
import 'package:dilalquran/modules/scan_ayat/model/ayat_chat_model.dart';
import 'package:http/http.dart' as http;

class ChatOutcome {
  final String? answer;
  final String? errorMessage;

  const ChatOutcome.success(String value)
      : answer = value,
        errorMessage = null;

  const ChatOutcome.failure(String message)
      : answer = null,
        errorMessage = message;

  bool get isSuccess => answer != null;
}

/// Tanya jawab seputar SATU ayat yang sudah dikenali.
///
/// Jawaban dibatasi (grounded) pada terjemahan dan tafsir resmi yang sudah
/// ditarik aplikasi. Model diminta menolak menjawab bila pertanyaan keluar
/// dari bahan itu, dan diminta tidak mengeluarkan fatwa.
class AyatChatService {
  const AyatChatService._();

  /// Riwayat yang dikirim dibatasi agar biaya token tetap kecil.
  static const int maxHistoryMessages = 8;

  static const String _systemInstruction = '''
Kamu adalah pendamping belajar Al-Qur'an di dalam aplikasi "Dil Al-Quran".
Pengguna baru memfoto satu ayat, dan kamu membantu memahaminya.

BAHAN RUJUKAN:
Hanya gunakan bahan pada bagian "KONTEKS AYAT" di bawah (teks ayat,
terjemahan, dan tafsir resmi). Itu satu-satunya sumbermu.

ATURAN:
1. Jawab dalam bahasa Indonesia yang sederhana, hangat, dan singkat
   (maksimal sekitar 150 kata) kecuali pengguna meminta penjelasan panjang.
2. JANGAN menuliskan ulang teks Arab ayat. Teks Arab sudah ditampilkan oleh
   aplikasi. Bila perlu merujuk, sebut nomor ayatnya.
3. Bila pertanyaan tidak dapat dijawab dari bahan rujukan, katakan terus
   terang bahwa bahan yang tersedia tidak membahas hal itu. Jangan mengarang.
4. JANGAN memberi fatwa atau keputusan hukum fikih. Bila pengguna menanyakan
   hukum atau keputusan pribadi, sampaikan dengan sopan agar bertanya kepada
   ustadz atau ahli ilmu yang berkompeten.
5. Jangan membahas hal di luar Al-Qur'an dan ayat yang sedang dibuka.
6. Jangan menyebut kata "konteks", "prompt", atau menjelaskan cara kerjamu.
''';

  static Future<ChatOutcome> ask({
    required String question,
    required String ayatContext,
    List<ChatMessage> history = const [],
  }) async {
    if (!AiConfig.isConfigured) {
      return const ChatOutcome.failure(AiConfig.notConfiguredMessage);
    }
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) {
      return const ChatOutcome.failure('Pertanyaan masih kosong.');
    }

    final body = <String, dynamic>{
      'model': AiConfig.model,
      'input': [
        {
          'type': 'text',
          'text': _buildPrompt(
            question: trimmedQuestion,
            ayatContext: ayatContext,
            history: history,
          ),
        },
      ],
    };

    try {
      final response = await http
          .post(
            AiConfig.chatEndpoint(),
            headers: AiConfig.headers(),
            body: json.encode(body),
          )
          .timeout(AiConfig.requestTimeout);

      if (response.statusCode == 429) {
        return const ChatOutcome.failure(
          'Kuota harian tanya jawab sudah habis. Coba lagi besok.',
        );
      }
      if (response.statusCode != 200) {
        print('AyatChatService gagal: ${response.statusCode} ${response.body}');
        return const ChatOutcome.failure(
          'Layanan tanya jawab sedang tidak dapat dihubungi.',
        );
      }

      final answer = _extractAnswer(response.body);
      if (answer == null || answer.trim().isEmpty) {
        return const ChatOutcome.failure('Balasan layanan kosong.');
      }
      return ChatOutcome.success(answer.trim());
    } catch (error) {
      print('AyatChatService error: $error');
      return const ChatOutcome.failure(
        'Gagal menghubungi layanan. Periksa koneksi internet Anda.',
      );
    }
  }

  static String _buildPrompt({
    required String question,
    required String ayatContext,
    required List<ChatMessage> history,
  }) {
    final buffer = StringBuffer()
      ..writeln(_systemInstruction)
      ..writeln('=== KONTEKS AYAT ===')
      ..writeln(ayatContext)
      ..writeln('=== AKHIR KONTEKS ===');

    final recent = _recentHistory(history);
    if (recent.isNotEmpty) {
      buffer.writeln('\n=== PERCAKAPAN SEBELUMNYA ===');
      for (final message in recent) {
        final speaker = message.isUser ? 'Pengguna' : 'Kamu';
        buffer.writeln('$speaker: ${message.text}');
      }
      buffer.writeln('=== AKHIR PERCAKAPAN ===');
    }

    buffer
      ..writeln('\nPertanyaan pengguna sekarang:')
      ..writeln(question);

    return buffer.toString();
  }

  /// Hanya beberapa pesan terakhir yang sudah selesai (bukan placeholder).
  static List<ChatMessage> _recentHistory(List<ChatMessage> history) {
    final settled = history
        .where((message) => !message.isPending && message.text.trim().isNotEmpty)
        .toList();
    if (settled.length <= maxHistoryMessages) return settled;
    return settled.sublist(settled.length - maxHistoryMessages);
  }

  static String? _extractAnswer(String responseBody) {
    try {
      final decoded = json.decode(responseBody);
      if (decoded is! Map<String, dynamic>) return responseBody;

      final direct = decoded['output_text'] ??
          decoded['outputText'] ??
          decoded['answer'];
      if (direct is String) return direct;
      return null;
    } catch (_) {
      return responseBody;
    }
  }
}
