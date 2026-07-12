import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/storage_helper.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final StorageHelper _storage = StorageHelper();

  bool _isLoading = false;
  bool _isCheckingNup = false;
  bool _isAuthenticated = false;
  UserModel? _user;
  String? _errorMessage;
  String? _previewNama;
  String? _previewRole;
  String? _previewError;

  AuthProvider({required bool hasSession}) {
    _isAuthenticated = hasSession;
  }

  bool get isLoading => _isLoading;
  bool get isCheckingNup => _isCheckingNup;
  bool get isAuthenticated => _isAuthenticated;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get previewNama => _previewNama;
  String? get previewRole => _previewRole;
  String? get previewError => _previewError;

  // Cek validitas sesi aktif di Storage saat startup
  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedUser = await _storage.getUser();
      final token = await _storage.getToken();

      if (savedUser != null && token != null) {
        _user = savedUser;
        _isAuthenticated = true;
        // Fetch full profile after session check
        await fetchMyProfile();
      } else {
        _isAuthenticated = false;
        _user = null;
        _previewNama = null;
        _previewRole = null;
        _previewError = null;
        _isCheckingNup = false;
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Aksi login NUP & Password
  Future<bool> login(String nup, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        Endpoints.login,
        data: {
          'nup': nup,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final userModel =
            UserModel.fromJson(data['user'] as Map<String, dynamic>);

        // Blokir role Admin & Super Admin di Mobile
        final roleLower = userModel.role.toLowerCase();
        final namaLower = userModel.nama.toLowerCase();
        if (roleLower == 'admin' ||
            roleLower.contains('super') ||
            namaLower.contains('super')) {
          _errorMessage =
              '❌ Role ${userModel.role} tidak dapat mengakses aplikasi mobile. Gunakan website admin untuk akses penuh.';
          return false;
        }

        // Simpan sesi secara aman
        await _storage.saveToken(token);
        await _storage.saveUser(userModel);

        _user = userModel;
        _isAuthenticated = true;
        // Fetch full profile after login
        await fetchMyProfile();
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

  Future<void> checkNup(String nup) async {
    final clean = nup.trim();
    if (clean.isEmpty) {
      _previewNama = null;
      _previewRole = null;
      _previewError = null;
      _isCheckingNup = false;
      notifyListeners();
      return;
    }

    _isCheckingNup = true;
    _previewError = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('${Endpoints.checkNup}/$clean');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final role = (data['role'] as String?)?.toLowerCase() ?? '';
        final nama = (data['nama'] as String?)?.toLowerCase() ?? '';

        // Blokir Super Admin & Admin - cek dari NAMA atau ROLE field
        if (nama.contains('super') ||
            role.contains('super') ||
            role.contains('admin')) {
          _previewNama = null;
          _previewRole = null;
          _previewError =
              '${data['role']} tidak dapat mengakses aplikasi mobile. Silakan gunakan website admin untuk akses penuh.';
        } else {
          _previewNama = data['nama'] as String?;
          _previewRole = data['role'] as String?;
          _previewError = null;
        }
      } else {
        _previewNama = null;
        _previewRole = null;
        _previewError = 'NUP tidak ditemukan';
      }
    } catch (e) {
      _previewNama = null;
      _previewRole = null;
      _previewError = null;
    } finally {
      _isCheckingNup = false;
      notifyListeners();
    }
  }

  // Aksi Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _storage.clearSession();
    _user = null;
    _isAuthenticated = false;
    _previewNama = null;
    _previewRole = null;
    _previewError = null;
    _isCheckingNup = false;
    _isLoading = false;
    notifyListeners();
  }

  // Ambil profil saya secara lengkap
  Future<void> fetchMyProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(Endpoints.myProfile);
      if (response.statusCode == 200) {
        final userModel =
            UserModel.fromJson(response.data as Map<String, dynamic>);
        _user = userModel;
        await _storage.saveUser(userModel);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update profil saya
  Future<bool> updateMyProfile(String nama, String? noTelp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.put(
        Endpoints.updateMyProfile,
        data: {
          'nama': nama,
          'no_telp': noTelp,
        },
      );

      if (response.statusCode == 200) {
        await fetchMyProfile();
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

  // Ganti password saya
  Future<bool> changeMyPassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.put(
        Endpoints.changeMyPassword,
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) {
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
