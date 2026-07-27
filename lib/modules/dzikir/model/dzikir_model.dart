class DzikirModel {
  int? id;
  String? grup;
  String? nama;
  String? ar;
  String? tr;
  String? idn;
  String? faedah;
  int? jumlah;

  DzikirModel({
    this.id,
    this.grup,
    this.nama,
    this.ar,
    this.tr,
    this.idn,
    this.faedah,
    this.jumlah,
  });

  DzikirModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    grup = json['grup'];
    nama = json['nama'];
    ar = json['ar'];
    tr = json['tr'];
    idn = json['idn'];
    faedah = json['faedah'];
    jumlah = json['jumlah'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['grup'] = grup;
    data['nama'] = nama;
    data['ar'] = ar;
    data['tr'] = tr;
    data['idn'] = idn;
    data['faedah'] = faedah;
    data['jumlah'] = jumlah;
    return data;
  }
}
