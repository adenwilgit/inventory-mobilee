import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/notifikasi_provider.dart';
import '../providers/pengajuan_provider.dart';
import '../providers/stok_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/loading_indicator.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final notifProv = Provider.of<NotifikasiProvider>(context);
    final user = auth.user;
    final role = user?.role.toLowerCase() ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          if (role == 'gudang') {
            final dashboardProv =
                Provider.of<DashboardProvider>(context, listen: false);
            final pengajuanProv =
                Provider.of<PengajuanProvider>(context, listen: false);
            await dashboardProv.fetchDashboard();
            await pengajuanProv.fetchPengajuans();
          } else {
            final pengajuanProv =
                Provider.of<PengajuanProvider>(context, listen: false);
            await pengajuanProv.fetchPengajuans();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CurvedGradientHeader(
                user: user,
                role: role,
                notifProv: notifProv,
                themeProv: themeProv,
                theme: theme,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (role == 'staff')
                      _StaffDashboard(theme: theme)
                    else if (role == 'asisten_manager')
                      _AsistenManagerDashboard(theme: theme)
                    else if (role == 'manager')
                      _ManagerDashboard(theme: theme)
                    else if (role == 'gudang')
                      _GudangDashboard(theme: theme)
                    else
                      _DefaultDashboard(theme: theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurvedGradientHeader extends StatelessWidget {
  final dynamic user;
  final String role;
  final NotifikasiProvider notifProv;
  final ThemeProvider themeProv;
  final ThemeData theme;

  const _CurvedGradientHeader({
    required this.user,
    required this.role,
    required this.notifProv,
    required this.themeProv,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    final isDark = themeProv.isDarkMode;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, statusBarHeight + 12, 20, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [TirtaTheme.primaryBlue, TirtaTheme.skyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : TirtaTheme.primaryBlue)
                .withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: App title + actions
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'public/logo-premium.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.water_drop,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SISTEM INVENTARIS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PDAM',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              // Theme Toggle
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    themeProv.isDarkMode
                        ? Icons.sunny
                        : Icons.nightlight_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => themeProv.toggleTheme(),
                ),
              ),
              const SizedBox(width: 6),
              // Notifications
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Badge(
                  offset: const Offset(-2, 2),
                  label: Text(
                    '${notifProv.unreadCount}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: TirtaTheme.rose,
                  isLabelVisible: notifProv.unreadCount > 0,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/notifikasi'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: User avatar + name
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ProfileScreen(showBackButton: true),
                  ),
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user?.nama.isNotEmpty == true
                          ? user!.nama[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Halo,',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      user?.nama ?? 'User',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Staff Dashboard
class _StaffDashboard extends StatelessWidget {
  final ThemeData theme;
  const _StaffDashboard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###', 'id_ID');
    return Consumer<PengajuanProvider>(
      builder: (context, pengajuanProvider, _) {
        if (pengajuanProvider.isLoading) {
          return const SizedBox(
            height: 300,
            child: LoadingIndicator(message: 'Memuat data...'),
          );
        }

        final myPengajuan = pengajuanProvider.pengajuans;
        final total = myPengajuan.length;
        final pending =
            myPengajuan.where((p) => p.status.startsWith('pending')).length;
        final approved =
            myPengajuan.where((p) => p.status == 'completed').length;
        final rejected =
            myPengajuan.where((p) => p.status == 'rejected').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatsGrid(
              stats: [
                _StatItem(
                  icon: Icons.description_rounded,
                  title: 'Total Diajukan',
                  value: numberFormat.format(total),
                  color: theme.primaryColor,
                ),
                _StatItem(
                  icon: Icons.pending_actions_rounded,
                  title: 'Proses',
                  value: numberFormat.format(pending),
                  color: Colors.orange,
                ),
                _StatItem(
                  icon: Icons.check_circle_rounded,
                  title: 'Selesai',
                  value: numberFormat.format(approved),
                  color: Colors.green,
                ),
                _StatItem(
                  icon: Icons.cancel_rounded,
                  title: 'Ditolak',
                  value: numberFormat.format(rejected),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Banner Buat Pengajuan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [TirtaTheme.primaryBlue, TirtaTheme.skyBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: TirtaTheme.primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.note_add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Minta / Ajukan Barang',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Buat pengajuan barang operasional',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/buat-pengajuan');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: TirtaTheme.primaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'BUAT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _RecentList(
              title: 'Pengajuan Terbaru',
              items: myPengajuan.take(5).toList(),
              theme: theme,
            ),
          ],
        );
      },
    );
  }
}

// Asisten Manager Dashboard
class _AsistenManagerDashboard extends StatelessWidget {
  final ThemeData theme;
  const _AsistenManagerDashboard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###', 'id_ID');
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;
    return Consumer<PengajuanProvider>(
      builder: (context, pengajuanProvider, _) {
        if (pengajuanProvider.isLoading) {
          return const SizedBox(
            height: 300,
            child: LoadingIndicator(message: 'Memuat data...'),
          );
        }

        final allPengajuan = pengajuanProvider.pengajuans;
        final pendingAsmen = allPengajuan
            .where((p) => p.status == 'pending_asisten_manager')
            .length;

        final totalStafPengajuan =
            allPengajuan.where((p) => p.userId != userId).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik Pengajuan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 1),
            _StatsGrid(
              stats: [
                _StatItem(
                  icon: Icons.pending_actions_rounded,
                  title: 'Menunggu Validasi',
                  value: numberFormat.format(pendingAsmen),
                  color: TirtaTheme.primaryBlue,
                ),
                _StatItem(
                  icon: Icons.people_outline_rounded,
                  title: 'Pengajuan Staf',
                  value: numberFormat.format(totalStafPengajuan),
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Banner buat pengajuan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [TirtaTheme.primaryBlue, TirtaTheme.skyBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: TirtaTheme.primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.note_add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Buat Pengajuan Baru',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Ajukan permintaan barang operasional',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/buat-pengajuan');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: TirtaTheme.primaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'BUAT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _RecentList(
              title: 'Menunggu Validasi',
              items: allPengajuan
                  .where((p) => p.status == 'pending_asisten_manager')
                  .take(5)
                  .toList(),
              theme: theme,
            ),
          ],
        );
      },
    );
  }
}

// Manager Dashboard
class _ManagerDashboard extends StatelessWidget {
  final ThemeData theme;
  const _ManagerDashboard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###', 'id_ID');
    return Consumer<PengajuanProvider>(
      builder: (context, pengajuanProvider, _) {
        if (pengajuanProvider.isLoading) {
          return const SizedBox(
            height: 300,
            child: LoadingIndicator(message: 'Memuat data...'),
          );
        }

        final allPengajuan = pengajuanProvider.pengajuans;
        final pendingManager =
            allPengajuan.where((p) => p.status == 'pending_manager').length;
        final completed =
            allPengajuan.where((p) => p.status == 'completed').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatsGrid(
              stats: [
                _StatItem(
                  icon: Icons.pending_actions_rounded,
                  title: 'Menunggu Manager',
                  value: numberFormat.format(pendingManager),
                  color: theme.primaryColor,
                ),
                _StatItem(
                  icon: Icons.check_circle_rounded,
                  title: 'Selesai',
                  value: numberFormat.format(completed),
                  color: Colors.green,
                ),
                _StatItem(
                  icon: Icons.list_alt_rounded,
                  title: 'Total Pengajuan',
                  value: numberFormat.format(allPengajuan.length),
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _RecentList(
              title: 'Semua Pengajuan',
              items: allPengajuan.take(5).toList(),
              theme: theme,
            ),
          ],
        );
      },
    );
  }
}

// Gudang Dashboard
class _GudangDashboard extends StatelessWidget {
  final ThemeData theme;
  const _GudangDashboard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final numberFormat = NumberFormat('#,###', 'id_ID');
    return Consumer3<DashboardProvider, PengajuanProvider, StokProvider>(
      builder:
          (context, dashboardProvider, pengajuanProvider, stokProvider, _) {
        if (dashboardProvider.isLoading) {
          return const SizedBox(
            height: 400,
            child: LoadingIndicator(message: 'Sinkronisasi data...'),
          );
        }

        if (dashboardProvider.dashboardData == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                dashboardProvider.errorMessage ?? 'Gagal memuat dashboard',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }

        final data = dashboardProvider.dashboardData!;
        final pendingGudang = pengajuanProvider.pengajuans
            .where((p) => p.status == 'pending_gudang')
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatsGrid(
              stats: [
                _StatItem(
                  icon: Icons.category_rounded,
                  title: 'Stok Tersedia',
                  value: numberFormat.format(data.summary.totalStok),
                  color: Colors.blue,
                ),
                _StatItem(
                  icon: Icons.error_rounded,
                  title: 'Stok Kritis',
                  value: numberFormat.format(data.summary.stokKritis),
                  color: Colors.red,
                ),
                _StatItem(
                  icon: Icons.checklist_rtl_rounded,
                  title: 'Antrean Rilis',
                  value: numberFormat.format(pendingGudang),
                  color: Colors.orange,
                ),
                _StatItem(
                  icon: Icons.grid_view_rounded,
                  title: 'Total Item',
                  value: numberFormat.format(data.summary.totalBarang),
                  color: Colors.green,
                ),
              ],
            ),
            SizedBox(
              height: width < 380 ? 18 : 24,
            ),
            Text(
              'Aksi Cepat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 0),
            _QuickActionsGrid(theme: theme),
            SizedBox(
              height: width < 380 ? 2 : 4,
            ),
            if (data.stokRendah.isNotEmpty) ...[
              Text(
                'Peringatan Stok Kritis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(
                height: width < 380 ? 6 : 10,
              ),
              ...data.stokRendah.take(3).map((item) {
                return _WarningCard(item: item, theme: theme);
              }),
            ],
            SizedBox(
              height: width < 380 ? 18 : 22,
            ),
            Text(
              'Mutasi Stok Terbaru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(
              height: width < 380 ? 6 : 10,
            ),
            ...data.mutasiTerbaru.take(5).map((mutasi) {
              return _MutasiCard(mutasi: mutasi, theme: theme);
            }),
          ],
        );
      },
    );
  }
}

// Default Dashboard
class _DefaultDashboard extends StatelessWidget {
  final ThemeData theme;
  const _DefaultDashboard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text('Dashboard tidak tersedia untuk role ini'),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: width < 380 ? 1.95 : 2.2,
      children: stats.map((stat) => _StatCard(stat: stat)).toList(),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  _StatItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context);
    final isDark = cardTheme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? TirtaTheme.slate800
              : TirtaTheme.slate200.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              stat.icon,
              color: stat.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cardTheme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  final String title;
  final List items;
  final ThemeData theme;
  final bool showTimeline;

  const _RecentList({
    required this.title,
    required this.items,
    required this.theme,
    this.showTimeline = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cardTheme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardTheme.cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                'Belum ada data',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            return _ListItemCard(
                item: item, theme: theme, showTimeline: showTimeline);
          }),
      ],
    );
  }
}

class _ListItemCard extends StatelessWidget {
  final dynamic item;
  final ThemeData theme;
  final bool showTimeline;

  const _ListItemCard({
    required this.item,
    required this.theme,
    this.showTimeline = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context);
    final isDark = cardTheme.brightness == Brightness.dark;

    // Get items list (PengajuanDetailModel list)
    final items = (item.items as List?) ?? [];
    final hasItems = items.isNotEmpty;

    final statusColor = _getStatusColor(item.status as String?);
    final statusLabel = _getStatusLabel(item.status as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? TirtaTheme.slate800
              : TirtaTheme.slate200.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── Item Photos (stacked thumbnails) ─────────────────────────
              if (hasItems)
                _ItemPhotosStack(items: items, isDark: isDark)
              else
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.description_rounded,
                      color: theme.primaryColor, size: 22),
                ),

              const SizedBox(width: 12),

              // ── Info ──────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nomorPengajuan ?? 'No. Pengajuan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: cardTheme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (hasItems)
                      Text(
                        items.map((i) => i.namaBarang as String).join(', '),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        item.catatan ?? '-',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        // Urgensi badge
                        if (item.urgensi != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getUrgensiColor(item.urgensi as String?)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (item.urgensi as String? ?? '').toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color:
                                    _getUrgensiColor(item.urgensi as String?),
                              ),
                            ),
                          ),
                        if (item.urgensi != null && hasItems)
                          const SizedBox(width: 6),
                        if (hasItems)
                          Text(
                            '${items.length} barang',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cardTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── Status Badge ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (showTimeline) ...[
            const SizedBox(height: 12),
            _ApprovalTimeline(
              status: item.status as String? ?? '',
              rolePengaju: item.rolePengaju as String?,
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    if (status.contains('pending')) return TirtaTheme.orange;
    if (status == 'completed') return TirtaTheme.green;
    if (status == 'rejected') return TirtaTheme.rose;
    return Colors.grey;
  }

  String _getStatusLabel(String? status) {
    if (status == null) return '-';
    if (status == 'pending_asisten_manager') return 'Menunggu Asmen';
    if (status == 'pending_manager') return 'Menunggu Manager';
    if (status == 'pending_gudang') return 'Menunggu Gudang';
    if (status == 'completed') return 'Selesai';
    if (status == 'rejected') return 'Ditolak';
    return status;
  }

  Color _getUrgensiColor(String? urgensi) {
    if (urgensi == 'Darurat') return TirtaTheme.rose;
    if (urgensi == 'Penting') return TirtaTheme.orange;
    return TirtaTheme.primaryBlue;
  }
}

/// Stacked/overlapping thumbnails for items in a pengajuan
class _ItemPhotosStack extends StatelessWidget {
  final List items;
  final bool isDark;

  const _ItemPhotosStack({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxShow = 3;
    final shown = items.take(maxShow).toList();
    final extra = items.length - maxShow;

    if (items.length == 1) {
      // Single item: show one larger image
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildPhoto(shown[0].foto as String?, 52, 52, theme),
      );
    }

    // Multiple items: overlapping stack
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * 14.0,
              top: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? TirtaTheme.slate900 : Colors.white,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: _buildPhoto(shown[i].foto as String?, 34, 34, theme),
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: TirtaTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhoto(String? foto, double w, double h, ThemeData theme) {
    if (foto != null && foto.isNotEmpty) {
      return Image.network(
        '${AppConstants.uploadUrl}/$foto',
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(w, h, theme),
      );
    }
    return _placeholder(w, h, theme);
  }

  Widget _placeholder(double w, double h, ThemeData theme) {
    return Container(
      width: w,
      height: h,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.inventory_2_outlined,
          size: w * 0.4, color: Colors.grey.shade400),
    );
  }
}

// ─── Approval Timeline ──────────────────────────────────────────────────────
class _ApprovalTimeline extends StatelessWidget {
  final String status;
  final String? rolePengaju;

  const _ApprovalTimeline({required this.status, this.rolePengaju});

  List<String> _buildSteps() {
    final role = (rolePengaju ?? '').toLowerCase();
    if (role.contains('manager') && !role.contains('asisten')) {
      return ['Pengajuan', 'Gudang'];
    } else if (role.contains('asisten')) {
      return ['Pengajuan', 'Manager', 'Gudang'];
    }
    return ['Pengajuan', 'Asisten Manager', 'Manager', 'Gudang'];
  }

  int _activeStep(List<String> steps) {
    final s = status.toLowerCase();
    final isRejected = s.contains('reject');

    final gudangIdx = steps.length - 1;

    if (s.contains('completed') || s == 'approved_gudang') {
      return steps.length;
    }

    if (s.contains('pending_gudang')) {
      return gudangIdx;
    }

    if (s.contains('pending_manager')) {
      final idx = steps.indexWhere((e) =>
          e.toLowerCase().contains('manager') &&
          !e.toLowerCase().contains('asisten'));
      return idx >= 0 ? idx : gudangIdx - 1;
    }

    if (s.contains('pending_asisten')) {
      final idx = steps.indexWhere((e) => e.toLowerCase().contains('asisten'));
      return idx >= 0 ? idx : 1;
    }

    if (isRejected) {
      return gudangIdx;
    }

    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    final isRejected = status.toLowerCase().contains('reject');
    final activeStep = _activeStep(steps);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? TirtaTheme.slate800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isRejected
                ? TirtaTheme.rose.withValues(alpha: 0.5)
                : (isDark
                    ? TirtaTheme.slate700
                    : TirtaTheme.slate200.withValues(alpha: 0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map_rounded,
                  size: 16, color: isDark ? Colors.grey : Colors.blueGrey),
              const SizedBox(width: 8),
              Text('Peta Persetujuan Digital',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: theme.colorScheme.onSurface)),
              const Spacer(),
              if (isRejected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: TirtaTheme.rose.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('DITOLAK',
                      style: TextStyle(
                          color: TirtaTheme.rose,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          letterSpacing: 0.3)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(steps.length, (index) {
              final isComplete = index < activeStep;
              final isActive = !isRejected &&
                  index == activeStep &&
                  activeStep < steps.length;
              final isRejectedStep = isRejected && index == activeStep;
              final isLastStep = index == steps.length - 1;

              Color dotColor;
              Color textColor;
              Widget dotChild;

              if (isRejectedStep) {
                dotColor = TirtaTheme.rose;
                textColor = TirtaTheme.rose;
                dotChild = const Icon(Icons.close_rounded,
                    size: 10, color: Colors.white);
              } else if (isComplete) {
                dotColor = TirtaTheme.green;
                textColor = TirtaTheme.green;
                dotChild = const Icon(Icons.check_rounded,
                    size: 10, color: Colors.white);
              } else if (isActive) {
                dotColor =
                    isLastStep ? TirtaTheme.primaryBlue : TirtaTheme.orange;
                textColor =
                    isLastStep ? TirtaTheme.primaryBlue : TirtaTheme.orange;
                dotChild = TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 0.3),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: child,
                  ),
                  child:
                      const Icon(Icons.circle, size: 10, color: Colors.white),
                );
              } else {
                dotColor = isDark ? TirtaTheme.slate700 : Colors.grey.shade300;
                textColor =
                    isDark ? Colors.grey.shade500 : Colors.grey.shade600;
                dotChild =
                    const Icon(Icons.circle, size: 10, color: Colors.white);
              }

              String statusLabel;
              Color statusLabelColor;

              if (isRejectedStep) {
                statusLabel = 'Ditolak';
                statusLabelColor = TirtaTheme.rose;
              } else if (isComplete) {
                statusLabel = 'Selesai';
                statusLabelColor = TirtaTheme.green;
              } else if (isActive) {
                statusLabel =
                    isLastStep ? 'Menunggu Gudang' : 'Sedang diproses';
                statusLabelColor =
                    isLastStep ? TirtaTheme.primaryBlue : TirtaTheme.orange;
              } else {
                statusLabel = 'Menunggu';
                statusLabelColor =
                    isDark ? Colors.grey.shade600 : Colors.grey.shade500;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: isLastStep ? 0 : 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: dotChild),
                        ),
                        if (!isLastStep)
                          Container(
                            width: 2,
                            height: 40,
                            margin: const EdgeInsets.only(top: 4),
                            color: isDark
                                ? TirtaTheme.slate700
                                : Colors.grey.shade300,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[index],
                              style: TextStyle(
                                  fontWeight:
                                      isComplete || isActive || isRejectedStep
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                  fontSize: 13,
                                  color:
                                      isComplete || isActive || isRejectedStep
                                          ? textColor
                                          : (isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade700))),
                          const SizedBox(height: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color: statusLabelColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final dynamic item;
  final ThemeData theme;

  const _WarningCard({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context);
    final isDark = cardTheme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.error_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaBarang,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cardTheme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Rak: ${item.rak ?? "-"} • Min: ${item.stokMinimum}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${item.stok}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MutasiCard extends StatelessWidget {
  final dynamic mutasi;
  final ThemeData theme;

  const _MutasiCard({required this.mutasi, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isMasuk = mutasi.jenis == 'masuk';
    final String? foto = mutasi.foto;
    final hasPhoto = foto != null && foto.isNotEmpty;
    final cardTheme = Theme.of(context);
    final isDark = cardTheme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? TirtaTheme.slate800
              : TirtaTheme.slate200.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image or fallback icon
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasPhoto
                ? Image.network(
                    '${AppConstants.uploadUrl}/$foto',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isMasuk
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isMasuk
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: isMasuk ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 44,
                        height: 44,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isMasuk
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isMasuk
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isMasuk ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mutasi.namaBarang,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cardTheme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${mutasi.keterangan ?? "-"} • ${mutasi.tanggal.substring(0, 10)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isMasuk
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${isMasuk ? "+" : "-"}${mutasi.jumlah}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isMasuk ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final ThemeData theme;
  const _QuickActionsGrid({required this.theme});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 10,
      childAspectRatio: width < 380 ? 1.55 : 1.70,
      children: [
        _QuickActionCard(
          icon: Icons.document_scanner_rounded,
          title: 'Scan Barang',
          subtitle: 'Barcode / QR',
          color: TirtaTheme.primaryBlue,
          onTap: () {
            Navigator.pushNamed(context, '/scan-qr');
          },
        ),
        _QuickActionCard(
          icon: Icons.task_alt_rounded,
          title: 'Persetujuan',
          subtitle: 'Rilis Stok',
          color: const Color(0xFF8B5CF6),
          onTap: () {
            Navigator.pushNamed(context, '/approval-gudang');
          },
        ),
        _QuickActionCard(
          icon: Icons.move_to_inbox_rounded,
          title: 'Stok Masuk',
          subtitle: 'Inbound Data',
          color: TirtaTheme.emerald,
          onTap: () {
            Navigator.pushNamed(context, '/stok-masuk');
          },
        ),
        _QuickActionCard(
          icon: Icons.outbox_rounded,
          title: 'Stok Keluar',
          subtitle: 'Outbound',
          color: TirtaTheme.rose,
          onTap: () {
            Navigator.pushNamed(context, '/stok-keluar');
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context);
    final isDark = cardTheme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cardTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? TirtaTheme.slate800
                : TirtaTheme.slate200.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: cardTheme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
