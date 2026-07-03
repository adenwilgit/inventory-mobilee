import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../data/models/pengajuan_model.dart';
import 'auth_provider.dart';

class PengajuanProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  List<PengajuanModel> _pengajuans = [];
  PengajuanModel? _selectedPengajuan;
  String? _errorMessage;
  AuthProvider? _authProvider;

  bool get isLoading => _isLoading;
  List<PengajuanModel> get pengajuans => _pengajuans;
  PengajuanModel? get selectedPengajuan => _selectedPengajuan;
  String? get errorMessage => _errorMessage;

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
    if (auth.isAuthenticated && _pengajuans.isEmpty) {
      fetchPengajuans();
    }
  }

  // Mengambil daftar pengajuan real-time (Otomatis terfilter oleh query backend sesuai Role & Unit)
  Future<void> fetchPengajuans() async {
    if (_authProvider == null || !_authProvider!.isAuthenticated) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(Endpoints.pengajuan);
      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>;
        _pengajuans = list.map((json) => PengajuanModel.fromJson(json as Map<String, dynamic>)).toList();
        
        // Fetch details in background for pending items
        _fetchDetailsInBg();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all items detail in the background to populate item count and details
  void _fetchDetailsInBg() {
    for (int i = 0; i < _pengajuans.length; i++) {
      final p = _pengajuans[i];
      _apiClient.get('${Endpoints.pengajuanDetail}/${p.id}').then((response) {
        if (response.statusCode == 200) {
          final list = response.data as List<dynamic>;
          if (list.isNotEmpty) {
            final detailed = PengajuanModel.fromJson(list[0] as Map<String, dynamic>, list);
            final idx = _pengajuans.indexWhere((item) => item.id == p.id);
            if (idx != -1) {
              _pengajuans[idx] = detailed;
              notifyListeners();
            }
          }
        }
      }).catchError((err) {
        debugPrint('Error fetching background detail for ${p.id}: $err');
      });
    }
  }

  // Mengambil detail lengkap pengajuan berdasarkan ID
  Future<void> fetchPengajuanById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('${Endpoints.pengajuanDetail}/$id');
      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>;
        if (list.isNotEmpty) {
          // JSON pertama berisi data pengajuan utama, list utuh untuk detail item
          final detailed = PengajuanModel.fromJson(list[0] as Map<String, dynamic>, list);
          _selectedPengajuan = detailed;
          
          // Update list cache as well
          final idx = _pengajuans.indexWhere((p) => p.id == id);
          if (idx != -1) {
            _pengajuans[idx] = detailed;
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Membuat Pengajuan Baru (Staff)
  Future<bool> createPengajuan({
    required List<Map<String, dynamic>> items,
    required String catatan,
    required String urgensi,
  }) async {
    if (_authProvider == null || _authProvider!.user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _authProvider!.user!;
      final response = await _apiClient.post(
        Endpoints.pengajuan,
        data: {
          'user_id': user.id,
          'role': user.role.toLowerCase(),
          'urgensi': urgensi.toLowerCase(),
          'catatan': catatan,
          'items': items, // Format: {'barang_id': x, 'jumlah': y}
        },
      );

      if (response.statusCode == 200) {
        fetchPengajuans(); // Refresh list
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

  // Aksi Persetujuan Pengajuan (Asmen L1, Manager L2, Gudang L3)
  Future<bool> approvePengajuan(int pengajuanId) async {
    if (_authProvider == null || _authProvider!.user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _authProvider!.user!;
      final response = await _apiClient.post(
        Endpoints.pengajuanApprove,
        data: {
          'pengajuan_id': pengajuanId,
          'user_id': user.id,
          'role': user.role.toLowerCase(),
        },
      );

      if (response.statusCode == 200) {
        fetchPengajuans(); // Refresh daftar utama
        if (_selectedPengajuan?.id == pengajuanId) {
          fetchPengajuanById(pengajuanId); // Refresh detail aktif
        }
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

  // Aksi Penolakan Pengajuan (Asmen, Manager, Gudang dengan Catatan Alasan)
  Future<bool> rejectPengajuan(int pengajuanId, String alasan) async {
    if (_authProvider == null || _authProvider!.user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _authProvider!.user!;
      final response = await _apiClient.post(
        Endpoints.pengajuanReject,
        data: {
          'pengajuan_id': pengajuanId,
          'user_id': user.id,
          'role': user.role.toLowerCase(),
          'catatan': alasan,
        },
      );

      if (response.statusCode == 200) {
        fetchPengajuans();
        if (_selectedPengajuan?.id == pengajuanId) {
          fetchPengajuanById(pengajuanId);
        }
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
}
