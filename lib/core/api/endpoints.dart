class Endpoints {
  // Autentikasi
  static const String login = '/auth/login';
  static const String checkNup = '/auth/check-nup';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Barang (Master Data)
  static const String barang = '/barang';
  static const String barangDetail = '/barang'; // append with '/{id}'

  // Kategori & Satuan
  static const String kategori = '/kategori';
  static const String satuan = '/satuan';

  // Pengajuan
  static const String pengajuan = '/pengajuan';
  static const String pengajuanDetail = '/pengajuan'; // append with '/{id}'
  static const String pengajuanApprove = '/pengajuan/approve';
  static const String pengajuanReject = '/pengajuan/reject';
  static const String staffStats = '/pengajuan/staff-stats';

  // Stok (Mutasi)
  static const String stokMasuk = '/stok/masuk';
  static const String stokKeluar = '/stok/keluar';
  static const String kartuStok = '/stok/kartu-stok';

  // Notifikasi
  static const String notifikasi = '/notifikasi'; // GET /:user_id
  static const String notifikasiRead = '/notifikasi/read'; // PUT /:id
  static const String notifikasiReadAll =
      '/notifikasi/read-all'; // PUT /:user_id

  // User Profile
  static const String myProfile = '/users/profile/me'; // GET
  static const String updateMyProfile = '/users/profile/me'; // PUT
  static const String changeMyPassword =
      '/users/profile/change-password'; // PUT
}
