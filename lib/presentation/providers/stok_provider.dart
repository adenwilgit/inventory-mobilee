import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../data/models/barang_model.dart';
import '../../data/models/stok_model.dart';
import '../../data/models/kategori_model.dart';
import '../../data/models/satuan_model.dart';
import 'auth_provider.dart';

class StokProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  List<BarangModel> _barangList = [];
  List<StokMasukModel> _stokMasukList = [];
  List<StokKeluarModel> _stokKeluarList = [];
  List<KategoriModel> _kategoriList = [];
  List<SatuanModel> _satuanList = [];
  BarangModel? _scannedBarang;
  String? _errorMessage;
  AuthProvider? _authProvider;

  bool get isLoading => _isLoading;
  List<BarangModel> get barangList => _barangList;
  List<StokMasukModel> get stokMasukList => _stokMasukList;
  List<StokKeluarModel> get stokKeluarList => _stokKeluarList;
  List<KategoriModel> get kategoriList => _kategoriList;
  List<SatuanModel> get satuanList => _satuanList;
  BarangModel? get scannedBarang => _scannedBarang;
  String? get errorMessage => _errorMessage;

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
    if (auth.isAuthenticated) {
      fetchBarangList(); // Always fetch fresh on auth update
      fetchKategoriList(); // Always fetch fresh
      fetchSatuanList(); // Always fetch fresh
    }
  }

  // Fetch categories from backend
  Future<void> fetchKategoriList() async {
    if (_authProvider == null || !_authProvider!.isAuthenticated) return;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('📡 Fetching kategori from ${Endpoints.kategori}...');
      final response = await _apiClient.get(Endpoints.kategori);
      debugPrint('📡 Kategori response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>;
        debugPrint('📡 Kategori data received: $list');
        _kategoriList = list
            .map((json) => KategoriModel.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('📡 Kategori list length: ${_kategoriList.length}');
      }
    } catch (e, stack) {
      debugPrint('❌ Error fetching kategori: $e');
      debugPrint('❌ Stack trace: $stack');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  // Fetch units from backend
  Future<void> fetchSatuanList() async {
    if (_authProvider == null || !_authProvider!.isAuthenticated) return;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('📡 Fetching satuan from ${Endpoints.satuan}...');
      final response = await _apiClient.get(Endpoints.satuan);
      debugPrint('📡 Satuan response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>;
        debugPrint('📡 Satuan data received: $list');
        _satuanList = list
            .map((json) => SatuanModel.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('📡 Satuan list length: ${_satuanList.length}');
      }
    } catch (e, stack) {
      debugPrint('❌ Error fetching satuan: $e');
      debugPrint('❌ Stack trace: $stack');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  // Mengambil daftar seluruh barang master dari server
  Future<void> fetchBarangList() async {
    if (_authProvider == null || !_authProvider!.isAuthenticated) {
      debugPrint(
          '⚠️ StokProvider: fetchBarangList dipanggil tapi user belum terautentikasi');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint(
          '📡 StokProvider: Mengambil data barang dari ${Endpoints.barang}...');
      final response = await _apiClient.get(Endpoints.barang);
      debugPrint('📡 StokProvider: Status Response = ${response.statusCode}');
      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>;
        debugPrint(
            '📡 StokProvider: Diterima ${list.length} item data mentah.');
        _barangList = list.map((json) {
          try {
            return BarangModel.fromJson(json as Map<String, dynamic>);
          } catch (modelErr) {
            debugPrint(
                '❌ StokProvider: Gagal memparsing satu barang: $modelErr. Data = $json');
            rethrow;
          }
        }).toList();
        debugPrint(
            '✅ StokProvider: Berhasil memparsing ${_barangList.length} barang.');
      } else {
        _errorMessage = 'Gagal memuat barang (Status: ${response.statusCode})';
      }
    } catch (e, stack) {
      debugPrint('❌ StokProvider Error: $e');
      debugPrint('❌ StokProvider StackTrace: $stack');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menerjemahkan scan QR Code/Barcode menjadi data barang detail
  Future<BarangModel?> queryBarangByCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    _scannedBarang = null;
    notifyListeners();

    try {
      // Mengambil daftar barang dan mencocokkan kode (atau via endpoint detail)
      if (_barangList.isEmpty) {
        await fetchBarangList();
      }

      final match = _barangList.firstWhere(
        (b) => b.kodeBarang.toLowerCase() == code.trim().toLowerCase(),
      );

      _scannedBarang = match;
      return match;
    } catch (e) {
      _errorMessage = 'Barang dengan kode "$code" tidak terdaftar di sistem';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mencatat Stok Masuk (Penerimaan Barang)
  Future<bool> inputStokMasuk({
    required int barangId,
    required int jumlah,
    required String keterangan,
  }) async {
    if (_authProvider == null || _authProvider!.user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        Endpoints.stokMasuk,
        data: {
          'barang_id': barangId,
          'jumlah': jumlah,
          'keterangan': keterangan,
          'user_id': _authProvider!.user!.id,
        },
      );

      if (response.statusCode == 200) {
        await fetchBarangList(); // Refresh list barang
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mencatat Stok Keluar (Pengeluaran Barang Manual / Penyesuaian)
  Future<bool> inputStokKeluar({
    required int barangId,
    required int jumlah,
    required String keterangan,
  }) async {
    if (_authProvider == null || _authProvider!.user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        Endpoints.stokKeluar,
        data: {
          'barang_id': barangId,
          'jumlah': jumlah,
          'keterangan': keterangan,
          'user_id': _authProvider!.user!.id,
        },
      );

      if (response.statusCode == 200) {
        await fetchBarangList(); // Refresh list barang
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menambahkan barang baru (multipart agar gambar terkirim)
  Future<bool> createBarang({
    required String namaBarang,
    String? kodeBarang,
    required int stok,
    required int stokMinimum,
    required String satuan,
    required int kategoriId,
    String? lokasiRak,
    String? imagePath,
  }) async {
    if (_authProvider == null || _authProvider!.user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'nama_barang': namaBarang,
        'kode_barang': kodeBarang,
        'stok': stok,
        'stok_minimum': stokMinimum,
        'satuan': satuan,
        'kategori_id': kategoriId,
        'lokasi_rak': lokasiRak,
      });

      if (imagePath != null && imagePath.isNotEmpty) {
        formData.files.add(MapEntry(
          'foto',
          await MultipartFile.fromFile(imagePath, filename: 'foto.jpg'),
        ));
      }

      final response = await _apiClient.postMultipart(
        Endpoints.barang,
        data: formData,
      );

      if (response.statusCode == 200) {
        await fetchBarangList();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update barang (multipart agar gambar bisa diubah)
  Future<bool> updateBarang({
    required int id,
    required String namaBarang,
    required int stok,
    required int stokMinimum,
    required String satuan,
    required int kategoriId,
    String? lokasiRak,
    String? imagePath,
  }) async {
    if (_authProvider == null || _authProvider!.user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'nama_barang': namaBarang,
        'stok': stok,
        'stok_minimum': stokMinimum,
        'satuan': satuan,
        'kategori_id': kategoriId,
        'lokasi_rak': lokasiRak ?? '',
      });

      if (imagePath != null && imagePath.isNotEmpty) {
        formData.files.add(MapEntry(
          'foto',
          await MultipartFile.fromFile(imagePath, filename: 'foto.jpg'),
        ));
      }

      final response = await _apiClient.putMultipart(
        '${Endpoints.barang}/$id',
        data: formData,
      );

      if (response.statusCode == 200) {
        await fetchBarangList();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hapus (nonaktifkan) barang
  Future<bool> deleteBarang(int id) async {
    if (_authProvider == null || _authProvider!.user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.delete('${Endpoints.barang}/$id');

      if (response.statusCode == 200) {
        await fetchBarangList();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengambil riwayat Stok Masuk
  Future<void> fetchStokMasuk() async {
    if (_authProvider == null || !_authProvider!.isAuthenticated) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(Endpoints.stokMasuk);
      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>;
        _stokMasukList = list
            .map(
                (json) => StokMasukModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengambil riwayat Stok Keluar
  Future<void> fetchStokKeluar() async {
    if (_authProvider == null || !_authProvider!.isAuthenticated) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(Endpoints.stokKeluar);
      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>;
        _stokKeluarList = list
            .map((json) =>
                StokKeluarModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
