class DashboardModel {
  final DashboardSummary summary;
  final List<DashboardLowStock> stokRendah;
  final List<DashboardStatusPengajuan> statusPengajuan;
  final List<DashboardMutasi> mutasiTerbaru;
  final List<DashboardTopBarang> topBarangKeluar;

  DashboardModel({
    required this.summary,
    required this.stokRendah,
    required this.statusPengajuan,
    required this.mutasiTerbaru,
    required this.topBarangKeluar,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    // Parsing Summary
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};
    final summary = DashboardSummary.fromJson(summaryJson);

    // Parsing Stok Rendah
    final stokRendahList = json['stok_rendah'] as List<dynamic>? ?? [];
    final stokRendah = stokRendahList
        .map((e) => DashboardLowStock.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parsing Status Pengajuan
    final statusList = json['status_pengajuan'] as List<dynamic>? ?? [];
    final statusPengajuan = statusList
        .map((e) => DashboardStatusPengajuan.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parsing Mutasi Terbaru
    final mutasiList = json['mutasi_terbaru'] as List<dynamic>? ?? [];
    final mutasiTerbaru = mutasiList
        .map((e) => DashboardMutasi.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parsing Top Barang Keluar
    final topList = json['top_barang_keluar'] as List<dynamic>? ?? [];
    final topBarangKeluar = topList
        .map((e) => DashboardTopBarang.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardModel(
      summary: summary,
      stokRendah: stokRendah,
      statusPengajuan: statusPengajuan,
      mutasiTerbaru: mutasiTerbaru,
      topBarangKeluar: topBarangKeluar,
    );
  }
}

class DashboardSummary {
  final int totalBarang;
  final int totalStok;
  final int stokKritis;
  final int pengajuanPending;

  DashboardSummary({
    required this.totalBarang,
    required this.totalStok,
    required this.stokKritis,
    required this.pengajuanPending,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalBarang: _toInt(json['total_barang']),
      totalStok: _toInt(json['total_stok']),
      stokKritis: _toInt(json['stok_kritis']),
      pengajuanPending: _toInt(json['pengajuan_pending']),
    );
  }
}

class DashboardLowStock {
  final int id;
  final String namaBarang;
  final int stok;
  final int stokMinimum;
  final String? rak;

  DashboardLowStock({
    required this.id,
    required this.namaBarang,
    required this.stok,
    required this.stokMinimum,
    this.rak,
  });

  factory DashboardLowStock.fromJson(Map<String, dynamic> json) {
    return DashboardLowStock(
      id: _toInt(json['id']),
      namaBarang: json['nama_barang'] as String? ?? '',
      stok: _toInt(json['stok']),
      stokMinimum: _toInt(json['stok_minimum']),
      rak: json['rak'] as String?,
    );
  }
}

class DashboardStatusPengajuan {
  final String status;
  final int total;

  DashboardStatusPengajuan({
    required this.status,
    required this.total,
  });

  factory DashboardStatusPengajuan.fromJson(Map<String, dynamic> json) {
    return DashboardStatusPengajuan(
      status: json['status'] as String? ?? '',
      total: _toInt(json['total']),
    );
  }
}

class DashboardMutasi {
  final String jenis; // 'masuk' atau 'keluar'
  final String namaBarang;
  final String? foto;
  final int jumlah;
  final String tanggal;
  final String? keterangan;

  DashboardMutasi({
    required this.jenis,
    required this.namaBarang,
    this.foto,
    required this.jumlah,
    required this.tanggal,
    this.keterangan,
  });

  factory DashboardMutasi.fromJson(Map<String, dynamic> json) {
    return DashboardMutasi(
      jenis: json['jenis'] as String? ?? 'masuk',
      namaBarang: json['nama_barang'] as String? ?? '',
      foto: json['foto'] as String?,
      jumlah: _toInt(json['jumlah']),
      tanggal: json['tanggal'] as String? ?? '',
      keterangan: json['keterangan'] as String?,
    );
  }
}

class DashboardTopBarang {
  final int id;
  final String namaBarang;
  final String kodeBarang;
  final String satuan;
  final int totalKeluar;
  final String? kategori;

  DashboardTopBarang({
    required this.id,
    required this.namaBarang,
    required this.kodeBarang,
    required this.satuan,
    required this.totalKeluar,
    this.kategori,
  });

  factory DashboardTopBarang.fromJson(Map<String, dynamic> json) {
    return DashboardTopBarang(
      id: _toInt(json['id']),
      namaBarang: json['nama_barang'] as String? ?? '',
      kodeBarang: json['kode_barang'] as String? ?? '',
      satuan: json['satuan'] as String? ?? '',
      totalKeluar: _toInt(json['total_keluar']),
      kategori: json['kategori'] as String?,
    );
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

