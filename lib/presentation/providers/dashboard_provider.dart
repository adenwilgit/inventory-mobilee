import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../data/models/dashboard_model.dart';
import 'auth_provider.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  DashboardModel? _dashboardData;
  String? _errorMessage;
  AuthProvider? _authProvider;

  bool get isLoading => _isLoading;
  DashboardModel? get dashboardData => _dashboardData;
  String? get errorMessage => _errorMessage;

  // Dipanggil secara otomatis oleh ProxyProvider saat sesi Auth berubah
  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
    if (auth.isAuthenticated && _dashboardData == null) {
      fetchDashboard();
    }
  }

  // Mengambil metrik Dashboard terintegrasi dari database dan backend
  Future<void> fetchDashboard({String range = 'year'}) async {
    // Abaikan jika user belum login
    if (_authProvider == null || !_authProvider!.isAuthenticated) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        Endpoints.dashboard,
        queryParameters: {
          'chartRange': range,
          'pieRange': range,
          'topRange': range,
        },
      );

      if (response.statusCode == 200) {
        _dashboardData = DashboardModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
