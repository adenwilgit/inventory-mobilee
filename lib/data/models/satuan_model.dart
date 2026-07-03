class SatuanModel {
  final int id;
  final String namaSatuan;

  SatuanModel({
    required this.id,
    required this.namaSatuan,
  });

  factory SatuanModel.fromJson(Map<String, dynamic> json) {
    return SatuanModel(
      id: json['id'],
      namaSatuan: json['nama_satuan'],
    );
  }
}
