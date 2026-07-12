import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // URL Server Backend (from .env file)
  static String get baseUrl =>
      dotenv.env['API_URL'] ??
      'https://inventory-backend-production-b052.up.railway.app/api';
  static String get uploadUrl =>
      dotenv.env['UPLOAD_URL'] ??
      'https://inventory-backend-production-b052.up.railway.app/uploads';
  static String? get socketUrl => dotenv.env['SOCKET_URL'];

  // Timeout koneksi
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 30000;

  // Nama kunci Secure Storage
  static const String tokenKey = 'jwt_auth_token';
  static const String userKey = 'user_profile_data';
}
