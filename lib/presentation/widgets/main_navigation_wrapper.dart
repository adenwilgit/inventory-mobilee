import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/barang_screen.dart';
import '../screens/scan_qr_screen.dart';
import '../screens/approval_gudang_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/buat_pengajuan_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final role = user?.role.toLowerCase() ?? '';

    List<Widget> getPages() {
      if (role == 'gudang') {
        return [
          const DashboardScreen(),
          BarangScreen(isActive: _selectedIndex == 1),
          ScanQrScreen(isActive: _selectedIndex == 2),
          const ApprovalGudangScreen(),
          const ProfileScreen(),
        ];
      } else if (role == 'staff') {
        // Staff: Beranda, Ajukan (BuatPengajuanScreen), Mutasi, Profil. Scan QR ditiadakan.
        return [
          const DashboardScreen(),
          const BuatPengajuanScreen(),
          const ApprovalGudangScreen(),
          const ProfileScreen(),
        ];
      } else if (role == 'asisten_manager') {
        // Asisten Manager: Beranda, Ajukan, Validasi, Profil. Tanpa Scan QR.
        return [
          const DashboardScreen(),
          const BuatPengajuanScreen(),
          const ApprovalGudangScreen(),
          const ProfileScreen(),
        ];
      } else if (role == 'manager') {
        // Manager: Beranda, Ajukan, Validasi, Profil
        return [
          const DashboardScreen(),
          const BuatPengajuanScreen(),
          const ApprovalGudangScreen(),
          const ProfileScreen(),
        ];
      } else {
        // role lainnya
        return [
          const DashboardScreen(),
          const BuatPengajuanScreen(),
          ScanQrScreen(isActive: _selectedIndex == 2),
          const ApprovalGudangScreen(),
          const ProfileScreen(),
        ];
      }
    }

    final pages = getPages();

    // Pastikan _selectedIndex tidak out of bounds jika role berubah
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    Widget buildBottomBar() {
      if (role == 'gudang') {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Beranda',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2_rounded,
              label: 'Barang',
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [TirtaTheme.primaryBlue, TirtaTheme.skyBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: TirtaTheme.primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.swap_vert_outlined,
              activeIcon: Icons.swap_vertical_circle_rounded,
              label: 'Validasi',
            ),
            _buildNavItem(
              index: 4,
              icon: Icons.person_outline,
              activeIcon: Icons.person_rounded,
              label: 'Profil',
            ),
          ],
        );
      } else if (role == 'staff') {
        // Staff bottom nav (tanpa Scan QR di tengah, tombol Ajukan menggantikan Katalog)
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Beranda',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.note_add_outlined,
              activeIcon: Icons.note_add_rounded,
              label: 'Ajukan',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment_rounded,
              label: 'Pengajuan Saya',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.person_outline,
              activeIcon: Icons.person_rounded,
              label: 'Profil',
            ),
          ],
        );
      } else if (role == 'asisten_manager') {
        // Asmen bottom nav: 4 menu tanpa Scan QR
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Beranda',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.note_add_outlined,
              activeIcon: Icons.note_add_rounded,
              label: 'Ajukan',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.swap_vert_outlined,
              activeIcon: Icons.swap_vertical_circle_rounded,
              label: 'Validasi',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.person_outline,
              activeIcon: Icons.person_rounded,
              label: 'Profil',
            ),
          ],
        );
      } else if (role == 'manager') {
        // Manager bottom nav: 4 menu
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Beranda',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.note_add_outlined,
              activeIcon: Icons.note_add_rounded,
              label: 'Ajukan',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.swap_vert_outlined,
              activeIcon: Icons.swap_vertical_circle_rounded,
              label: 'Validasi',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.person_outline,
              activeIcon: Icons.person_rounded,
              label: 'Profil',
            ),
          ],
        );
      } else {
        // Manager bottom nav (dengan Scan QR di tengah)
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Beranda',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.note_add_outlined,
              activeIcon: Icons.note_add_rounded,
              label: 'Ajukan',
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [TirtaTheme.primaryBlue, TirtaTheme.skyBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: TirtaTheme.primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.swap_vert_outlined,
              activeIcon: Icons.swap_vertical_circle_rounded,
              label: 'Validasi',
            ),
            _buildNavItem(
              index: 4,
              icon: Icons.person_outline,
              activeIcon: Icons.person_rounded,
              label: 'Profil',
            ),
          ],
        );
      }
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: buildBottomBar(),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected
                ? (isDark ? TirtaTheme.skyBlue : TirtaTheme.primaryBlue)
                : TirtaTheme.slate500,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isSelected
                  ? (isDark ? TirtaTheme.skyBlue : TirtaTheme.primaryBlue)
                  : TirtaTheme.slate500,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
