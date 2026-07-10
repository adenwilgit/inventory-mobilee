import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/notifikasi_provider.dart';
import 'presentation/providers/pengajuan_provider.dart';
import 'presentation/providers/stok_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'core/utils/storage_helper.dart';

// GlobalKey untuk Navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Pastikan binding Flutter terinisialisasi
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi date formatting untuk Bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Kunci orientasi layar ke Potret
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cek status login sebelumnya secara aman
  final storage = StorageHelper();
  final token = await storage.getToken();
  final hasSession = token != null;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(hasSession: hasSession)..checkSession(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (_, auth, dashboard) =>
              (dashboard ?? DashboardProvider())..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PengajuanProvider>(
          create: (_) => PengajuanProvider(),
          update: (_, auth, pengajuan) =>
              (pengajuan ?? PengajuanProvider())..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, StokProvider>(
          create: (_) => StokProvider(),
          update: (_, auth, stok) => (stok ?? StokProvider())..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotifikasiProvider>(
          create: (_) => NotifikasiProvider(navigatorKey: navigatorKey),
          update: (_, auth, notifProv) {
            final notif = notifProv ?? NotifikasiProvider(navigatorKey: navigatorKey);
            
            if (auth.isAuthenticated && auth.user != null) {
              // Init socket jika belum terhubung
              notif.initSocket(auth.user!.id);
              // Fetch notifikasi
              notif.fetchNotifikasi(auth.user!.id);
            } else {
              // Disconnect socket jika logout
              notif.disconnectSocket();
            }
            
            return notif;
          },
        ),
      ],
      child: const TirtaApp(),
    ),
  );
}
