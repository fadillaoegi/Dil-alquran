import 'package:dilalquran/modules/data/models/surah_detail_model.dart';

/// Ayat yang sudah terkunci ke sumber resmi (equran.id).
///
/// Seluruh teks di sini berasal dari API resmi, bukan dari AI.
class ResolvedAyat {
  final int surahNumber;
  final String surahNameLatin;
  final String surahNameArab;
  final List<Ayat> ayatList;

  /// Tafsir resmi untuk ayat pertama pada rentang. Kosong bila gagal diambil.
  final String tafsir;

  const ResolvedAyat({
    required this.surahNumber,
    required this.surahNameLatin,
    required this.surahNameArab,
    required this.ayatList,
    this.tafsir = "",
  });

  bool get isEmpty => ayatList.isEmpty;

  int get firstAyatNumber => ayatList.isEmpty ? 0 : (ayatList.first.nomorAyat ?? 0);

  int get lastAyatNumber => ayatList.isEmpty ? 0 : (ayatList.last.nomorAyat ?? 0);

  String get rangeLabel => firstAyatNumber == lastAyatNumber
      ? "$surahNameLatin: $firstAyatNumber"
      : "$surahNameLatin: $firstAyatNumber-$lastAyatNumber";

  /// Daftar URL audio murottal untuk seluruh ayat pada rentang.
  List<String> get audioUrls {
    final urls = <String>[];
    for (final ayat in ayatList) {
      final audio = ayat.audio;
      if (audio == null || audio.isEmpty) continue;
      // equran.id memberi beberapa qari dengan kunci "01".."05".
      final url = audio["05"] ?? audio["01"] ?? audio.values.first;
      if (url.trim().isNotEmpty) urls.add(url);
    }
    return urls;
  }

  /// Ringkasan teks yang dipakai sebagai konteks (grounding) untuk chat.
  String buildChatContext() {
    final buffer = StringBuffer()
      ..writeln("Surah: $surahNameLatin (nomor $surahNumber)");

    for (final ayat in ayatList) {
      buffer
        ..writeln("--- Ayat ${ayat.nomorAyat} ---")
        ..writeln("Arab: ${ayat.teksArab ?? '-'}")
        ..writeln("Latin: ${ayat.teksLatin ?? '-'}")
        ..writeln("Terjemahan: ${ayat.teksIndonesia ?? '-'}");
    }

    if (tafsir.trim().isNotEmpty) {
      buffer
        ..writeln("--- Tafsir resmi (Kemenag via equran.id) ---")
        ..writeln(tafsir.trim());
    }

    return buffer.toString();
  }
}

enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String text;

  /// Menandai gelembung "sedang mengetik".
  final bool isPending;

  const ChatMessage({
    required this.role,
    required this.text,
    this.isPending = false,
  });

  const ChatMessage.user(this.text)
      : role = ChatRole.user,
        isPending = false;

  const ChatMessage.assistant(this.text, {this.isPending = false})
      : role = ChatRole.assistant;

  bool get isUser => role == ChatRole.user;
}
