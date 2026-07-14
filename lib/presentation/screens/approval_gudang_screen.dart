import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../data/models/pengajuan_model.dart';
import '../providers/pengajuan_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notifikasi_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/detail_pengajuan_sheet.dart';

class ApprovalGudangScreen extends StatefulWidget {
  const ApprovalGudangScreen({super.key});

  @override
  State<ApprovalGudangScreen> createState() => _ApprovalGudangScreenState();
}

class _ApprovalGudangScreenState extends State<ApprovalGudangScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PengajuanProvider>(context, listen: false).fetchPengajuans();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }



  void _showDetailModal(PengajuanModel pengajuan) {
    DetailPengajuanSheet.show(context, pengajuan);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pengajuanProv = Provider.of<PengajuanProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final notifProv = Provider.of<NotifikasiProvider>(context);
    final isDark = themeProv.isDarkMode;
    final role = authProv.user?.role.toLowerCase() ?? '';
    final userId = authProv.user?.id;

    // Determine title and subtitle based on role
    String headerTitle;
    String headerSubtitle;
    String pendingStatus;
    String emptyMessage;

    switch (role) {
      case 'gudang':
        headerTitle = 'PERSETUJUAN GUDANG';
        headerSubtitle = 'Persetujuan & monitoring pengajuan';
        pendingStatus = 'pending_gudang';
        emptyMessage = 'Tidak ada pengajuan yang menunggu persetujuan gudang';
        break;
      case 'asisten_manager':
        headerTitle = 'VALIDASI PENGAJUAN';
        headerSubtitle = 'Validasi pengajuan staf';
        pendingStatus = 'pending_asisten_manager';
        emptyMessage = 'Tidak ada pengajuan staf yang menunggu validasi Anda';
        break;
      case 'manager':
        headerTitle = 'VALIDASI PENGAJUAN';
        headerSubtitle = 'Validasi & monitoring pengajuan';
        pendingStatus = 'pending_manager';
        emptyMessage = 'Tidak ada pengajuan yang menunggu validasi Anda';
        break;
      default: // staff
        headerTitle = 'PENGAJUAN SAYA';
        headerSubtitle = 'Lacak status pengajuan Anda';
        pendingStatus = ''; // not used for staff
        emptyMessage = 'Belum ada pengajuan yang sedang diproses';
        break;
    }

    // Build lists based on role
    List<PengajuanModel> pendingPengajuan;
    List<PengajuanModel> historyPengajuan;

    if (role == 'staff') {
      // Staff: show only their own pengajuans
      final myPengajuans =
          pengajuanProv.pengajuans.where((p) => p.userId == userId).toList();
      // Diproses: semua yang masih dalam alur pending (belum completed/rejected)
      pendingPengajuan = myPengajuans
          .where((p) =>
              p.status.startsWith('pending') || p.status == 'pending_gudang')
          .toList();
      // Riwayat: completed ATAU rejected
      historyPengajuan = myPengajuans
          .where((p) => p.status == 'completed' || p.status == 'rejected')
          .toList();
    } else {
      // Approver roles (gudang, asisten_manager, manager)
      // Exclude their own requests (p.userId != userId) from validation list
      final othersPengajuans =
          pengajuanProv.pengajuans.where((p) => p.userId != userId).toList();
      pendingPengajuan =
          othersPengajuans.where((p) => p.status == pendingStatus).toList();
      historyPengajuan =
          othersPengajuans.where((p) => p.status != pendingStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      pendingPengajuan = pendingPengajuan.where((p) {
        final matchesNo = p.nomorPengajuan.toLowerCase().contains(q);
        final matchesCatatan = (p.catatan ?? '').toLowerCase().contains(q);
        final matchesNama = (p.namaPengaju ?? '').toLowerCase().contains(q);
        final matchesItems = p.items.any((item) =>
            item.namaBarang.toLowerCase().contains(q) ||
            item.kodeBarang.toLowerCase().contains(q));
        return matchesNo || matchesCatatan || matchesNama || matchesItems;
      }).toList();

      historyPengajuan = historyPengajuan.where((p) {
        final matchesNo = p.nomorPengajuan.toLowerCase().contains(q);
        final matchesCatatan = (p.catatan ?? '').toLowerCase().contains(q);
        final matchesNama = (p.namaPengaju ?? '').toLowerCase().contains(q);
        final matchesItems = p.items.any((item) =>
            item.namaBarang.toLowerCase().contains(q) ||
            item.kodeBarang.toLowerCase().contains(q));
        return matchesNo || matchesCatatan || matchesNama || matchesItems;
      }).toList();
    }

    // Urutkan berdasarkan ID descending (terbaru di atas)
    pendingPengajuan.sort((a, b) => b.id.compareTo(a.id));
    historyPengajuan.sort((a, b) => b.id.compareTo(a.id));

    // Tab labels
    final tab1Label = role == 'staff' ? 'DIPROSES' : 'MENUNGGU';
    const tab2Label = 'RIWAYAT';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _CurvedGradientHeader(
            user: authProv.user,
            role: role,
            notifProv: notifProv,
            themeProv: themeProv,
            theme: theme,
            title: headerTitle,
            subtitle: headerSubtitle,
          ),
          // Search Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            color: theme.scaffoldBackgroundColor,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? TirtaTheme.slate800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? TirtaTheme.slate700
                      : TirtaTheme.slate200.withValues(alpha: 0.5),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari no. pengajuan, barang, catatan...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? TirtaTheme.slate800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? TirtaTheme.slate700
                    : TirtaTheme.slate200.withValues(alpha: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark ? TirtaTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: isDark ? Colors.white : TirtaTheme.primaryBlue,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(text: tab1Label),
                const Tab(text: tab2Label),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: () => pengajuanProv.fetchPengajuans(),
                  color: TirtaTheme.primaryBlue,
                  child: pengajuanProv.isLoading &&
                          pengajuanProv.pengajuans.isEmpty
                      ? const Center(
                          child:
                              LoadingIndicator(message: 'Memuat pengajuan...'))
                      : pendingPengajuan.isEmpty
                          ? _EmptyState(
                              icon: Icons.check_circle_outline_rounded,
                              title: (role == 'staff')
                                  ? 'Belum Ada Pengajuan'
                                  : 'Semua Beres!',
                              message: emptyMessage,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                              itemCount: pendingPengajuan.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final pengajuan = pendingPengajuan[index];
                                return _PengajuanCard(
                                  pengajuan: pengajuan,
                                  onTap: () => _showDetailModal(pengajuan),
                                );
                              },
                            ),
                ),
                RefreshIndicator(
                  onRefresh: () => pengajuanProv.fetchPengajuans(),
                  color: TirtaTheme.primaryBlue,
                  child: pengajuanProv.isLoading &&
                          pengajuanProv.pengajuans.isEmpty
                      ? const Center(
                          child: LoadingIndicator(message: 'Memuat riwayat...'))
                      : historyPengajuan.isEmpty
                          ? const _EmptyState(
                              icon: Icons.history_rounded,
                              title: 'Belum Ada Riwayat',
                              message:
                                  'Tidak ada pengajuan yang telah disetujui atau ditolak',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                              itemCount: historyPengajuan.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final pengajuan = historyPengajuan[index];
                                return _PengajuanCard(
                                  pengajuan: pengajuan,
                                  onTap: () => _showDetailModal(pengajuan),
                                  isHistory: true,
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: isDark ? TirtaTheme.slate800 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 44,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pengajuan Card ──────────────────────────────────────────────────────────
class _PengajuanCard extends StatelessWidget {
  final PengajuanModel pengajuan;
  final VoidCallback onTap;
  final bool isHistory;

  const _PengajuanCard({
    required this.pengajuan,
    required this.onTap,
    this.isHistory = false,
  });

  Widget _buildThumbnail(String? foto, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderBg = isDark ? TirtaTheme.slate800 : Colors.grey.shade100;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey;

    if (foto != null && foto.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          '${AppConstants.uploadUrl}/$foto',
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: placeholderBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.inventory_2_outlined, color: iconColor, size: 24),
          ),
        ),
      );
    }

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: placeholderBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.inventory_2_outlined, color: iconColor, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalBarang = pengajuan.totalBarang ?? pengajuan.items.length;
    final firstFoto =
        pengajuan.items.isNotEmpty ? pengajuan.items.first.foto : null;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
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
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pengajuan.nomorPengajuan,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: pengajuan.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(firstFoto, context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pengajuan.namaPengaju ?? '-',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              DateTime.parse(pengajuan.tanggalPengajuan)
                                  .toLocal()
                                  .toString()
                                  .substring(0, 10),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _UrgensiBadge(urgensi: pengajuan.urgensi),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: TirtaTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 15, color: TirtaTheme.primaryBlue),
                      const SizedBox(width: 5),
                      Text(
                        '$totalBarang barang',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: TirtaTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status & Urgensi Badge ──────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'pending_gudang':
        bg = TirtaTheme.primaryBlue.withValues(alpha: 0.12);
        fg = isDark ? TirtaTheme.skyBlue : TirtaTheme.primaryBlue;
        label = 'MENUNGGU GUDANG';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'pending_asisten_manager':
        bg = Colors.orange.withValues(alpha: 0.12);
        fg = Colors.orange.shade700;
        label = 'MENUNGGU ASMEN';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'pending_manager':
        bg = Colors.purple.withValues(alpha: 0.12);
        fg = Colors.purple.shade600;
        label = 'MENUNGGU MANAGER';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'approved_gudang':
      case 'completed':
        bg = TirtaTheme.green.withValues(alpha: 0.12);
        fg = TirtaTheme.green;
        label = 'SELESAI';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        bg = TirtaTheme.rose.withValues(alpha: 0.12);
        fg = TirtaTheme.rose;
        label = 'DITOLAK';
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.12);
        fg = Colors.grey;
        label = status.toUpperCase();
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 9,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgensiBadge extends StatelessWidget {
  final String urgensi;
  const _UrgensiBadge({required this.urgensi});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    final value = urgensi.toLowerCase();
    if (value.contains('darurat') ||
        value.contains('urgent') ||
        value.contains('high')) {
      bg = TirtaTheme.rose.withValues(alpha: 0.12);
      fg = TirtaTheme.rose;
      icon = Icons.report_problem_rounded;
      label = 'DARURAT';
    } else if (value.contains('penting') ||
        value.contains('medium') ||
        value.contains('sedang')) {
      bg = TirtaTheme.orange.withValues(alpha: 0.12);
      fg = TirtaTheme.orange;
      icon = Icons.priority_high_rounded;
      label = 'PENTING';
    } else {
      bg = TirtaTheme.green.withValues(alpha: 0.12);
      fg = TirtaTheme.green;
      icon = Icons.check_circle_rounded;
      label = 'NORMAL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 9,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
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
  final String title;
  final String subtitle;

  const _CurvedGradientHeader({
    required this.user,
    required this.role,
    required this.notifProv,
    required this.themeProv,
    required this.theme,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    final isDark = themeProv.isDarkMode;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, statusBarHeight + 14, 20, 16),
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
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
