class StokMasukModel {
  final int id;
  final int barangId;
  final String namaBarang;
  final String kodeBarang;
  final String satuan;
  final String? foto;
  final String? namaKategori;
  final int jumlah;
  final int stokSekarang;
  final String? keterangan;
  final String tanggal;

  StokMasukModel({
    required this.id,
    required this.barangId,
    required this.namaBarang,
    required this.kodeBarang,
    required this.satuan,
    this.foto,
    this.namaKategori,
    required this.jumlah,
    required this.stokSekarang,
    this.keterangan,
    required this.tanggal,
  });

  factory StokMasukModel.fromJson(Map<String, dynamic> json) {
    return StokMasukModel(
      id: _toInt(json['id']),
      barangId: _toInt(json['barang_id']),
      namaBarang: json['nama_barang'] as String? ?? '',
      kodeBarang: json['kode_barang'] as String? ?? '',
      satuan: json['satuan'] as String? ?? '',
      foto: json['foto'] as String?,
      namaKategori: json['nama_kategori'] as String?,
      jumlah: _toInt(json['jumlah']),
      stokSekarang: _toInt(json['stok_sekarang']),
      keterangan: json['keterangan'] as String?,
      tanggal: json['tanggal'] as String? ?? '',
    );
  }
}

class StokKeluarModel {
  final int id;
  final int barangId;
  final String namaBarang;
  final String kodeBarang;
  final String satuan;
  final String? foto;
  final String? namaKategori;
  final String? lokasiRak;
  final int jumlah;
  final int stokSekarang;
  final String? keterangan;
  final String tanggal;
  final int? pengajuanId;
  final String? nomorPengajuan;
  final String? pengaju;

  StokKeluarModel({
    required this.id,
    required this.barangId,
    required this.namaBarang,
    required this.kodeBarang,
    required this.satuan,
    this.foto,
    this.namaKategori,
    this.lokasiRak,
    required this.jumlah,
    required this.stokSekarang,
    this.keterangan,
    required this.tanggal,
    this.pengajuanId,
    this.nomorPengajuan,
    this.pengaju,
  });

  factory StokKeluarModel.fromJson(Map<String, dynamic> json) {
    return StokKeluarModel(
      id: _toInt(json['id']),
      barangId: _toInt(json['barang_id']),
      namaBarang: json['nama_barang'] as String? ?? '',
      kodeBarang: json['kode_barang'] as String? ?? '',
      satuan: json['satuan'] as String? ?? '',
      foto: json['foto'] as String?,
      namaKategori: json['nama_kategori'] as String?,
      lokasiRak: json['lokasi_rak'] as String?,
      jumlah: _toInt(json['jumlah']),
      stokSekarang: _toInt(json['stok_sekarang']),
      keterangan: json['keterangan'] as String?,
      tanggal: json['tanggal'] as String? ?? '',
      pengajuanId: _toInt(json['pengajuan_id']),
      nomorPengajuan: json['nomor_pengajuan'] as String?,
      pengaju: json['pengaju'] as String?,
    );
  }
}

// Helper function for safe int conversion
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}
