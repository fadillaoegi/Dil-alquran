import 'dart:convert';

SurahDetail surahDetailFromJson(String str) =>
    SurahDetail.fromJson(json.decode(str));

String surahDetailToJson(SurahDetail data) => json.encode(data.toJson());

class SurahDetail {
  int? nomor;
  String? nama;
  String? namaLatin;
  int? jumlahAyat;
  String? tempatTurun;
  String? arti;
  String? deskripsi;
  Map<String, String>? audioFull;
  List<Ayat>? ayat;

  SurahDetail({
    this.nomor,
    this.nama,
    this.namaLatin,
    this.jumlahAyat,
    this.tempatTurun,
    this.arti,
    this.deskripsi,
    this.audioFull,
    this.ayat,
  });

  factory SurahDetail.fromJson(Map<String, dynamic> json) => SurahDetail(
        nomor: json["nomor"],
        nama: json["nama"],
        namaLatin: json["namaLatin"],
        jumlahAyat: json["jumlahAyat"],
        tempatTurun: json["tempatTurun"],
        arti: json["arti"],
        deskripsi: json["deskripsi"],
        audioFull: (json["audioFull"] as Map<String, dynamic>?)
            ?.map((key, value) => MapEntry(key, value.toString())),
        ayat: json["ayat"] == null
            ? []
            : List<Ayat>.from(
                json["ayat"].map((x) => Ayat.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
        "nomor": nomor,
        "nama": nama,
        "namaLatin": namaLatin,
        "jumlahAyat": jumlahAyat,
        "tempatTurun": tempatTurun,
        "arti": arti,
        "deskripsi": deskripsi,
        "audioFull": audioFull,
        "ayat": ayat == null
            ? []
            : List<dynamic>.from(ayat!.map((x) => x.toJson())),
      };
}

class Ayat {
  int? nomorAyat;
  String? teksArab;
  String? teksLatin;
  String? teksIndonesia;
  Map<String, String>? audio;

  Ayat({
    this.nomorAyat,
    this.teksArab,
    this.teksLatin,
    this.teksIndonesia,
    this.audio,
  });

  factory Ayat.fromJson(Map<String, dynamic> json) => Ayat(
        nomorAyat: json["nomorAyat"],
        teksArab: json["teksArab"],
        teksLatin: json["teksLatin"],
        teksIndonesia: json["teksIndonesia"],
        audio: (json["audio"] as Map<String, dynamic>?)
            ?.map((key, value) => MapEntry(key, value.toString())),
      );

  Map<String, dynamic> toJson() => {
        "nomorAyat": nomorAyat,
        "teksArab": teksArab,
        "teksLatin": teksLatin,
        "teksIndonesia": teksIndonesia,
        "audio": audio,
      };
}
