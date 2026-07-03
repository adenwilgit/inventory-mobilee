import 'package:dio/dio.dart';
import '../../config/constants.dart';
import '../utils/storage_helper.dart';

class ApiClient {
  final Dio _dio;
  final StorageHelper _storage = StorageHelper();

  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.baseUrl,
            connectTimeout:
                const Duration(milliseconds: AppConstants.connectTimeoutMs),
            receiveTimeout:
                const Duration(milliseconds: AppConstants.receiveTimeoutMs),
            contentType: 'application/json',
          ),
        ) {
    _initializeInterceptors();
  }

  void _initializeInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ambil token JWT dari Secure Storage secara aman
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] =
                'Bearer $token'; // Format "Bearer <token>"
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Logik auto-logout jika token kedaluwarsa (401/403)
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            _storage.clearSession();
            // Catatan: Rute akan dialihkan otomatis ke login oleh AuthProvider
          }
          return handler.next(e);
        },
      ),
    );
  }

  // Wrapper GET request
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Wrapper POST request
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Wrapper PUT request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Wrapper DELETE request
  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Standardisasi Format Error
  Exception _handleError(DioException error) {
    final response = error.response;
    if (response != null && response.data != null) {
      final message = response.data['message'] ?? 'Terjadi kesalahan sistem';
      return Exception(message);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return Exception('Koneksi internet terputus (Timeout)');
      case DioExceptionType.receiveTimeout:
        return Exception('Server lambat merespons (Receive Timeout)');
      default:
        return Exception('Gagal menghubungi server. Periksa jaringan Anda.');
    }
  }
}
