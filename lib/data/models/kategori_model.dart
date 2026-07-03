class KategoriModel {
  final int id;
  final String namaKategori;
  final String? deskripsi;
  final int isActive;

  KategoriModel({
    required this.id,
    required this.namaKategori,
    this.deskripsi,
    required this.isActive,
  });

  factory KategoriModel.fromJson(Map<String, dynamic> json) {
    return KategoriModel(
      id: json['id'],
      namaKategori: json['nama_kategori'],
      deskripsi: json['deskripsi'],
      isActive: json['is_active'] ?? 1,
    );
  }
}
