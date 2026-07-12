import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import 'package:provider/provider.dart';
import '../../data/models/notifikasi_model.dart';
import '../widgets/custom_snackbar.dart';
import 'pengajuan_provider.dart';
import 'dashboard_provider.dart';
import 'stok_provider.dart';

class NotifikasiProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final GlobalKey<NavigatorState> navigatorKey;
  List<Notifikasi> _notifikasiList = [];
  bool _isLoading = true;
  String? _errorMessage;
  IO.Socket? _socket;

  NotifikasiProvider({required this.navigatorKey});

  List<Notifikasi> get notifikasiList => _notifikasiList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifikasiList.where((n) => n.isRead == 0).length;

  void initSocket(int userId) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(Endpoints.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('✅ [MOBILE] Socket connected');
      _socket!.emit('register', userId);
    });

    // Listen notifikasi baru
    _socket!.on('notif_baru', (data) {
      debugPrint('🔔 [MOBILE] Menerima notifikasi baru: $data');

      // Tampilkan toast notifikasi
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CustomSnackBar.show(
          context: null,
          message: data['pesan'] ?? 'Notifikasi baru',
          type: SnackBarType.info,
          style: NotificationStyle.toast,
        );

        // Refresh providers to make the app fully real-time
        final context = navigatorKey.currentContext;
        if (context != null) {
          try {
            Provider.of<PengajuanProvider>(context, listen: false).fetchPengajuans();
            Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
            Provider.of<StokProvider>(context, listen: false).fetchBarangList();
          } catch (e) {
            debugPrint('Error auto-refreshing providers: $e');
          }
        }
      });

      // Fetch notifikasi ulang agar data persis dengan server
      fetchNotifikasi(userId);
    });

    // Listen refresh data
    _socket!.on('refresh_data', (_) {
      debugPrint('🔄 [MOBILE] Menerima sinyal refresh data');
      fetchNotifikasi(userId);

      // Also refresh other data
      final context = navigatorKey.currentContext;
      if (context != null) {
        try {
          Provider.of<PengajuanProvider>(context, listen: false).fetchPengajuans();
          Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
          Provider.of<StokProvider>(context, listen: false).fetchBarangList();
        } catch (e) {
          debugPrint('Error auto-refreshing providers: $e');
        }
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('❌ [MOBILE] Socket disconnected');
    });
  }

  // Method untuk disconnect socket
  void disconnectSocket() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      debugPrint('🔌 [MOBILE] Socket disconnected and disposed');
    }
  }

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
