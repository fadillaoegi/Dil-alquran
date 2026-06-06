class ShalatModel {
  int? tanggal;
  String? tanggalLengkap;
  String? hari;
  String? imsak;
  String? subuh;
  String? terbit;
  String? dhuha;
  String? dzuhur;
  String? ashar;
  String? maghrib;
  String? isya;

  ShalatModel({
    this.tanggal,
    this.tanggalLengkap,
    this.hari,
    this.imsak,
    this.subuh,
    this.terbit,
    this.dhuha,
    this.dzuhur,
    this.ashar,
    this.maghrib,
    this.isya,
  });

  ShalatModel.fromJson(Map<String, dynamic> json) {
    tanggal = json['tanggal'];
    tanggalLengkap = json['tanggal_lengkap'];
    hari = json['hari'];
    imsak = json['imsak'];
    subuh = json['subuh'];
    terbit = json['terbit'];
    dhuha = json['dhuha'];
    dzuhur = json['dzuhur'];
    ashar = json['ashar'];
    maghrib = json['maghrib'];
    isya = json['isya'];
  }
}
