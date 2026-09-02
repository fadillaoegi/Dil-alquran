import 'dart:convert';

SurahTafsir surahTafsirFromJson(String str) =>
    SurahTafsir.fromJson(json.decode(str));

/// Tafsir satu surah dari equran.id (`/api/v2/tafsir/{nomor}`).
class SurahTafsir {
  final int nomor;
  final String namaLatin;
  final List<TafsirAyat> tafsir;

  const SurahTafsir({
    required this.nomor,
    required this.namaLatin,
    required this.tafsir,
  });

  factory SurahTafsir.fromJson(Map<String, dynamic> json) => SurahTafsir(
        nomor: json["nomor"] is int
            ? json["nomor"] as int
            : int.tryParse(json["nomor"]?.toString() ?? "") ?? 0,
        namaLatin: json["namaLatin"]?.toString() ?? "",
        tafsir: json["tafsir"] == null
            ? const []
            : List<TafsirAyat>.from(
                (json["tafsir"] as List).map((x) => TafsirAyat.fromJson(x)),
              ),
      );

  /// Tafsir untuk nomor ayat tertentu, `null` bila tidak ada.
  TafsirAyat? forAyat(int nomorAyat) {
    for (final item in tafsir) {
      if (item.ayat == nomorAyat) return item;
    }
    return null;
  }
}

class TafsirAyat {
  final int ayat;
  final String teks;

  const TafsirAyat({required this.ayat, required this.teks});

  factory TafsirAyat.fromJson(Map<String, dynamic> json) => TafsirAyat(
        ayat: json["ayat"] is int
            ? json["ayat"] as int
            : int.tryParse(json["ayat"]?.toString() ?? "") ?? 0,
        teks: json["teks"]?.toString() ?? "",
      );
}
