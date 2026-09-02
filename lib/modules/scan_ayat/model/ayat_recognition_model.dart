import 'dart:convert';

/// Satu dugaan ayat hasil pembacaan foto oleh AI.
///
/// PENTING: objek ini HANYA membawa nomor surah & ayat. Teks Arab tidak
/// pernah diambil dari AI — teks selalu ditarik dari sumber resmi
/// (equran.id) berdasarkan nomor di sini. Ini mencegah satu huruf pun
/// pada ayat Al-Qur'an berasal dari model bahasa.
class AyatCandidate {
  final int surahNumber;
  final int ayatStart;
  final int ayatEnd;

  /// Nama surah menurut dugaan AI. Dipakai hanya untuk ditampilkan sebagai
  /// petunjuk, bukan sebagai sumber data.
  final String surahNameGuess;

  /// 0.0 – 1.0
  final double confidence;

  const AyatCandidate({
    required this.surahNumber,
    required this.ayatStart,
    required this.ayatEnd,
    this.surahNameGuess = "",
    this.confidence = 0.0,
  });

  bool get isRange => ayatEnd > ayatStart;

  String get label => isRange
      ? "$surahNumber:$ayatStart-$ayatEnd"
      : "$surahNumber:$ayatStart";

  /// Jumlah ayat yang tercakup.
  int get ayatCount => ayatEnd - ayatStart + 1;

  factory AyatCandidate.fromJson(Map<String, dynamic> json) {
    final start = _asInt(json["ayat_start"] ?? json["ayatStart"] ?? json["ayat"]);
    final end = _asInt(json["ayat_end"] ?? json["ayatEnd"]);
    return AyatCandidate(
      surahNumber: _asInt(json["surah"] ?? json["surahNumber"] ?? json["nomor"]),
      ayatStart: start,
      ayatEnd: end < start ? start : end,
      surahNameGuess:
          (json["surah_name"] ?? json["surahName"] ?? "").toString().trim(),
      confidence: _asDouble(json["confidence"]),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AyatCandidate &&
      other.surahNumber == surahNumber &&
      other.ayatStart == ayatStart &&
      other.ayatEnd == ayatEnd;

  @override
  int get hashCode => Object.hash(surahNumber, ayatStart, ayatEnd);

  @override
  String toString() => "AyatCandidate($label, conf: $confidence)";

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString().trim() ?? "") ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble().clamp(0.0, 1.0);
    final parsed = double.tryParse(value?.toString().trim() ?? "");
    if (parsed == null) return 0.0;
    return parsed.clamp(0.0, 1.0);
  }
}

/// Hasil mentah pembacaan foto.
class AyatRecognition {
  /// `false` bila AI menilai foto bukan halaman Al-Qur'an.
  final bool isQuranPage;

  /// Dugaan ayat, sudah urut dari keyakinan tertinggi.
  final List<AyatCandidate> candidates;

  /// Catatan singkat, mis. "foto terlalu buram".
  final String note;

  const AyatRecognition({
    required this.isQuranPage,
    required this.candidates,
    this.note = "",
  });

  const AyatRecognition.empty({this.note = ""})
      : isQuranPage = false,
        candidates = const [];

  bool get hasCandidates => candidates.isNotEmpty;

  AyatCandidate? get best => candidates.isEmpty ? null : candidates.first;

  /// Dianggap yakin bila hanya ada satu dugaan kuat.
  bool get isConfident =>
      candidates.length == 1 || (best?.confidence ?? 0) >= 0.8;
}

/// Maksimal dugaan yang ditampilkan ke pengguna.
const int maxAyatCandidates = 3;

/// Mengurai balasan AI menjadi [AyatRecognition].
///
/// Tahan terhadap balasan yang dibungkus pagar markdown (```json ... ```)
/// atau diawali/diakhiri teks tambahan.
AyatRecognition parseAyatRecognition(String rawOutput) {
  final jsonText = extractJsonObject(rawOutput);
  if (jsonText == null) {
    return const AyatRecognition.empty(note: "Balasan AI tidak dapat dibaca.");
  }

  try {
    final decoded = json.decode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      return const AyatRecognition.empty(
        note: "Balasan AI tidak dapat dibaca.",
      );
    }

    final rawList = decoded["candidates"];
    final candidates = <AyatCandidate>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          candidates.add(AyatCandidate.fromJson(item));
        }
      }
    }

    return AyatRecognition(
      isQuranPage: decoded["is_quran_page"] == true ||
          decoded["isQuranPage"] == true,
      candidates: candidates,
      note: (decoded["note"] ?? "").toString().trim(),
    );
  } catch (_) {
    return const AyatRecognition.empty(note: "Balasan AI tidak dapat dibaca.");
  }
}

/// Mengambil objek JSON pertama dari teks bebas.
/// Dipisah agar mudah diuji sendiri.
String? extractJsonObject(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final start = text.indexOf('{');
  if (start < 0) return null;

  // Hitung kurung agar objek bersarang tetap utuh, dan abaikan kurung
  // yang berada di dalam string JSON.
  var depth = 0;
  var inString = false;
  var escaped = false;

  for (var i = start; i < text.length; i++) {
    final char = text[i];

    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (char == r'\') {
        escaped = true;
      } else if (char == '"') {
        inString = false;
      }
      continue;
    }

    if (char == '"') {
      inString = true;
    } else if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
      if (depth == 0) return text.substring(start, i + 1);
    }
  }

  return null;
}

/// Menyaring dugaan AI terhadap kenyataan Al-Qur'an.
///
/// [ayatCountBySurah] memetakan nomor surah -> jumlah ayat. Dugaan yang
/// menyebut surah atau nomor ayat yang tidak ada langsung dibuang, jadi
/// pengguna tidak pernah dibawa ke ayat yang tidak eksis.
List<AyatCandidate> validateCandidates(
  List<AyatCandidate> candidates,
  Map<int, int> ayatCountBySurah, {
  int limit = maxAyatCandidates,
}) {
  final valid = <AyatCandidate>[];

  for (final candidate in candidates) {
    if (candidate.surahNumber < 1 || candidate.surahNumber > 114) continue;
    if (candidate.ayatStart < 1) continue;
    if (candidate.ayatEnd < candidate.ayatStart) continue;

    final maxAyat = ayatCountBySurah[candidate.surahNumber];
    // Bila jumlah ayat surah belum diketahui, jangan tebak-tebak: tolak.
    if (maxAyat == null || maxAyat < 1) continue;
    if (candidate.ayatEnd > maxAyat) continue;

    if (valid.contains(candidate)) continue; // buang duplikat
    valid.add(candidate);
  }

  valid.sort((a, b) => b.confidence.compareTo(a.confidence));
  return valid.length > limit ? valid.sublist(0, limit) : valid;
}
