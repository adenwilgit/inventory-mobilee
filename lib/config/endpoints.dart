import 'constants.dart';

class Endpoints {
  static String get barang => '${AppConstants.baseUrl}/barang';
  static String get kategori => '${AppConstants.baseUrl}/kategori';
  static String get satuan => '${AppConstants.baseUrl}/satuan';
  static String get stokMasuk => '${AppConstants.baseUrl}/stok/masuk';
  static String get stokKeluar => '${AppConstants.baseUrl}/stok/keluar';
  static String get pengajuan => '${AppConstants.baseUrl}/pengajuan';
}
