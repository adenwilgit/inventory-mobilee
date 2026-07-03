class BarangModel {
  final int id;
  final String kodeBarang;
  final String namaBarang;
  final String? kategori;
  final String satuan;
  final String? lokasiRak;
  final int stok;
  final int stokTersedia;
  final int stokMinimum;
  final String? foto;
  final String? qrCode;

  BarangModel({
    required this.id,
    required this.kodeBarang,
    required this.namaBarang,
    this.kategori,
    required this.satuan,
    this.lokasiRak,
    required this.stok,
    required this.stokTersedia,
    required this.stokMinimum,
    this.foto,
    this.qrCode,
  });

  factory BarangModel.fromJson(Map<String, dynamic> json) {
    return BarangModel(
      id: _toInt(json['id']),
      kodeBarang: json['kode_barang'] as String? ?? '',
      namaBarang: json['nama_barang'] as String? ?? '',
      kategori: json['nama_kategori'] as String?,
      satuan: json['satuan'] as String? ?? '',
      lokasiRak: json['lokasi_rak'] as String?,
      stok: _toInt(json['stok']),
      stokTersedia: _toInt(json['stok_tersedia'] ?? json['stok']),
      stokMinimum: _toInt(json['stok_minimum']),
      foto: json['foto'] as String?,
      qrCode: json['qr_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kode_barang': kodeBarang,
      'nama_barang': namaBarang,
      'nama_kategori': kategori,
      'satuan': satuan,
      'lokasi_rak': lokasiRak,
      'stok': stok,
      'stok_tersedia': stokTersedia,
      'stok_minimum': stokMinimum,
      'foto': foto,
      'qr_code': qrCode,
    };
  }
}

// Helper function untuk konversi tipe data dinamis ke integer secara aman
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}
