import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/approval_gudang_screen.dart';
import 'presentation/screens/tambah_barang_screen.dart';
import 'presentation/screens/stok_masuk_screen.dart';
import 'presentation/screens/stok_keluar_screen.dart';
import 'presentation/screens/scan_qr_screen.dart';
import 'presentation/screens/list_notifikasi_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/buat_pengajuan_screen.dart';
import 'presentation/widgets/loading_indicator.dart';
import 'presentation/widgets/main_navigation_wrapper.dart';

class TirtaApp extends StatelessWidget {
  const TirtaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Tirta Pakuan',
      debugShowCheckedModeBanner: false,
      theme: TirtaTheme.lightTheme,
      darkTheme: TirtaTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.3),
        ),
        child: child!,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(
                child: LoadingIndicator(message: 'Memuat sesi aman...'),
              ),
            );
          }

          if (auth.isAuthenticated) {
            return const MainNavigationWrapper();
          }

          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainNavigationWrapper(),
        '/tambah-barang': (context) => const TambahBarangScreen(),
        '/stok-masuk': (context) => const StokMasukScreen(),
        '/stok-keluar': (context) => const StokKeluarScreen(),
        '/approval-gudang': (context) => const ApprovalGudangScreen(),
        '/buat-pengajuan': (context) => const BuatPengajuanScreen(),
        '/scan-qr': (context) => const ScanQrScreen(),
        '/notifikasi': (context) => const ListNotifikasiScreen(),
        '/profil': (context) => const ProfileScreen(),
      },
    );
  }
}
