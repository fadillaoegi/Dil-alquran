class DoaModel {
  int? id;
  String? grup;
  String? nama;
  String? ar;
  String? tr;
  String? idn;
  String? tentang;
  List<String>? tag;

  DoaModel(
      {this.id,
      this.grup,
      this.nama,
      this.ar,
      this.tr,
      this.idn,
      this.tentang,
      this.tag});

  DoaModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    grup = json['grup'];
    nama = json['nama'];
    ar = json['ar'];
    tr = json['tr'];
    idn = json['idn'];
    tentang = json['tentang'];
    tag = json['tag'] != null ? json['tag'].cast<String>() : [];
  }

  get artinya => null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['grup'] = grup;
    data['nama'] = nama;
    data['ar'] = ar;
    data['tr'] = tr;
    data['idn'] = idn;
    data['tentang'] = tentang;
    data['tag'] = tag;
    return data;
  }
}
