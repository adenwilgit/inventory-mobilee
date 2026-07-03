class PengajuanModel {
  final int id;
  final String nomorPengajuan;
  final int userId;
  final String status;
  final String urgensi;
  final String tanggalPengajuan;
  final String? catatan;
  final String? namaPengaju;
  final String? rolePengaju;
  final String? deptPengaju;
  final String? subDeptPengaju;
  final List<PengajuanDetailModel> items;
  final int? totalBarang;

  PengajuanModel({
    required this.id,
    required this.nomorPengajuan,
    required this.userId,
    required this.status,
    required this.urgensi,
    required this.tanggalPengajuan,
    this.catatan,
    this.namaPengaju,
    this.rolePengaju,
    this.deptPengaju,
    this.subDeptPengaju,
    this.items = const [],
    this.totalBarang,
  });

  factory PengajuanModel.fromJson(Map<String, dynamic> json,
      [List<dynamic>? detailJson]) {
    List<PengajuanDetailModel> parsedItems = [];

    // Try to get items from detailJson first, then try json['items'] or json['detail']
    if (detailJson != null) {
      parsedItems =
          detailJson.map((d) => PengajuanDetailModel.fromJson(d)).toList();
    } else if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((d) => PengajuanDetailModel.fromJson(d))
          .toList();
    } else if (json['detail'] != null && json['detail'] is List) {
      parsedItems = (json['detail'] as List)
          .map((d) => PengajuanDetailModel.fromJson(d))
          .toList();
    }

    return PengajuanModel(
      id: _toInt(json['id']),
      nomorPengajuan: json['nomor_pengajuan'] as String? ?? '',
      userId: _toInt(json['user_id']),
      status: json['status'] as String? ?? 'pending_asisten_manager',
      urgensi: json['urgensi'] as String? ?? 'Normal',
      tanggalPengajuan:
          (json['tanggal_pengajuan'] ?? json['created_at'] ?? '') as String,
      catatan: json['catatan'] as String?,
      namaPengaju: json['nama'] as String?,
      rolePengaju: json['pengaju_role'] as String?,
      deptPengaju: json['dept_pengaju'] as String?,
      subDeptPengaju: json['sub_dept_pengaju'] as String?,
      items: parsedItems,
      totalBarang:
          json['total_barang'] != null ? _toInt(json['total_barang']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomor_pengajuan': nomorPengajuan,
      'user_id': userId,
      'status': status,
      'urgensi': urgensi,
      'tanggal_pengajuan': tanggalPengajuan,
      'catatan': catatan,
      'nama': namaPengaju,
      'pengaju_role': rolePengaju,
      'dept_pengaju': deptPengaju,
      'sub_dept_pengaju': subDeptPengaju,
      'total_barang': totalBarang,
    };
  }
}

class PengajuanDetailModel {
  final int barangId;
  final String namaBarang;
  final String kodeBarang;
  final String satuan;
  final String? lokasiRak;
  final String? foto;
  final int jumlah;
  final int stokTersedia;

  PengajuanDetailModel({
    required this.barangId,
    required this.namaBarang,
    required this.kodeBarang,
    required this.satuan,
    this.lokasiRak,
    this.foto,
    required this.jumlah,
    required this.stokTersedia,
  });

  factory PengajuanDetailModel.fromJson(Map<String, dynamic> json) {
    return PengajuanDetailModel(
      barangId: _toInt(json['barang_id']),
      namaBarang: json['nama_barang'] as String? ?? '',
      kodeBarang: json['kode_barang'] as String? ?? '',
      satuan: json['satuan'] as String? ?? '',
      lokasiRak: json['lokasi_rak'] as String?,
      foto: json['foto'] as String?,
      jumlah: _toInt(json['jumlah']),
      stokTersedia: _toInt(json['stok_tersedia']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barang_id': barangId,
      'nama_barang': namaBarang,
      'kode_barang': kodeBarang,
      'satuan': satuan,
      'lokasi_rak': lokasiRak,
      'foto': foto,
      'jumlah': jumlah,
      'stok_tersedia': stokTersedia,
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
