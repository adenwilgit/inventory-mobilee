import 'package:flutter/foundation.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../data/models/notifikasi_model.dart';

class NotifikasiProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Notifikasi> _notifikasiList = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Notifikasi> get notifikasiList => _notifikasiList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifikasiList.where((n) => n.isRead == 0).length;

  Future<void> fetchNotifikasi(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiClient.get('${Endpoints.notifikasi}/$userId');
      final data = response.data as List;
      _notifikasiList = data.map((json) => Notifikasi.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Error fetching notifikasi: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notifId) async {
    try {
      await _apiClient.put('${Endpoints.notifikasiRead}/$notifId');
      // Update local state
      final index = _notifikasiList.indexWhere((n) => n.id == notifId);
      if (index != -1) {
        _notifikasiList[index] = Notifikasi(
          id: _notifikasiList[index].id,
          userId: _notifikasiList[index].userId,
          judul: _notifikasiList[index].judul,
          pesan: _notifikasiList[index].pesan,
          tipe: _notifikasiList[index].tipe,
          relatedId: _notifikasiList[index].relatedId,
          isRead: 1,
          createdAt: _notifikasiList[index].createdAt,
          updatedAt: _notifikasiList[index].updatedAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Error marking notif as read: $e');
      }
    }
  }

  Future<void> markAllAsRead(int userId) async {
    try {
      await _apiClient.put('${Endpoints.notifikasiReadAll}/$userId');
      // Update all local notifications to read
      _notifikasiList = _notifikasiList.map((n) {
        return Notifikasi(
          id: n.id,
          userId: n.userId,
          judul: n.judul,
          pesan: n.pesan,
          tipe: n.tipe,
          relatedId: n.relatedId,
          isRead: 1,
          createdAt: n.createdAt,
          updatedAt: n.updatedAt,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Error marking all notif as read: $e');
      }
    }
  }

  Future<void> deleteNotifikasi(int notifId) async {
    try {
      await _apiClient.delete('${Endpoints.notifikasi}/$notifId');
      // Remove from local list
      _notifikasiList.removeWhere((n) => n.id == notifId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Error deleting notifikasi: $e');
      }
    }
  }
}
