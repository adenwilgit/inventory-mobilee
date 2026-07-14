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
import '../widgets/custom_snackbar.dart';

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

  Future<void> _handleApprove(PengajuanModel pengajuan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: 'Setujui Pengajuan',
        message: 'Stok akan langsung dikurangi setelah disetujui.',
        nomorPengajuan: pengajuan.nomorPengajuan,
        confirmLabel: 'Ya, Setujui',
        confirmColor: Colors.green,
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      ),
    );

    if (confirmed == true && mounted) {
      final pengajuanProv =
          Provider.of<PengajuanProvider>(context, listen: false);
      final success = await pengajuanProv.approvePengajuan(pengajuan.id);

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: success
              ? 'Pengajuan berhasil disetujui!'
              : (pengajuanProv.errorMessage ?? 'Gagal menyetujui pengajuan!'),
          type: success ? SnackBarType.success : SnackBarType.error,
        );
      }
    }
  }

  Future<void> _handleReject(PengajuanModel pengajuan) async {
    final alasanController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.cancel_outlined,
                              color: Colors.red, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Tolak Pengajuan',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Masukkan alasan penolakan untuk pengajuan ini.',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: alasanController,
                      maxLines: 3,
                      onChanged: (value) {
                        setDialogState(() {}); // Trigger rebuild
                      },
                      decoration: InputDecoration(
                        hintText: 'Tulis alasan penolakan...',
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? TirtaTheme.slate800
                            : Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: alasanController.text.trim().isEmpty
                                ? null
                                : () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                              disabledBackgroundColor: Colors.red.shade200,
                            ),
                            child: const Text('Tolak',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      final pengajuanProv =
          Provider.of<PengajuanProvider>(context, listen: false);
      final success = await pengajuanProv.rejectPengajuan(
          pengajuan.id, alasanController.text.trim());

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: success
              ? 'Pengajuan berhasil ditolak.'
              : (pengajuanProv.errorMessage ?? 'Gagal menolak pengajuan!'),
          type: success ? SnackBarType.warning : SnackBarType.error,
        );
      }
    }
  }

  void _showDetailModal(PengajuanModel pengajuan) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final role = authProv.user?.role.toLowerCase() ?? '';
    // Staff cannot approve/reject
    final isApprover =
        role == 'gudang' || role == 'asisten_manager' || role == 'manager';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => _DetailModalContent(
          pengajuanHeader: pengajuan,
          scrollController: scrollController,
          onApprove: isApprover ? _handleApprove : null,
          onReject: isApprover ? _handleReject : null,
        ),
      ),
    );
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
      pendingPengajuan = pengajuanProv.pengajuans
          .where((p) => p.status == pendingStatus)
          .toList();
      historyPengajuan = pengajuanProv.pengajuans
          .where((p) => p.status != pendingStatus)
          .toList();
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
                Tab(text: tab2Label),
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

class _ApprovalTimeline extends StatelessWidget {
  final String status;
  final String? rolePengaju;

  const _ApprovalTimeline({required this.status, this.rolePengaju});

  /// Kembalikan daftar step berdasarkan role pengaju.
  /// Staff (null/staff)  → [Pengajuan, Asisten Manager, Manager, Gudang]
  /// Asisten Manager     → [Pengajuan, Manager, Gudang]
  /// Manager             → [Pengajuan, Gudang]
  List<String> _buildSteps() {
    final role = (rolePengaju ?? '').toLowerCase();
    if (role.contains('manager') && !role.contains('asisten')) {
      return ['Pengajuan', 'Gudang'];
    } else if (role.contains('asisten')) {
      return ['Pengajuan', 'Manager', 'Gudang'];
    }
    // staff / default → semua step
    return ['Pengajuan', 'Asisten Manager', 'Manager', 'Gudang'];
  }

  /// Indeks step yang sedang aktif/saat ini (0-based dalam _buildSteps).
  /// - step 0 (Pengajuan) selalu selesai jika ada status apapun
  /// - step aktif = step yang "sedang menunggu" atau "ditolak"
  int _activeStep(List<String> steps) {
    final s = status.toLowerCase();
    final isRejected = s.contains('reject');

    // Posisi Gudang selalu index terakhir
    final gudangIdx = steps.length - 1;

    if (s.contains('completed') || s == 'approved_gudang') {
      // Semua selesai → semua step completed (return > last index)
      return steps.length;
    }

    if (s.contains('pending_gudang')) {
      // Gudang belum setuju → aktif di step Gudang
      return gudangIdx;
    }

    if (s.contains('pending_manager')) {
      // Menunggu Manager
      final idx = steps.indexWhere((e) =>
          e.toLowerCase().contains('manager') &&
          !e.toLowerCase().contains('asisten'));
      return idx >= 0 ? idx : gudangIdx - 1;
    }

    if (s.contains('pending_asisten')) {
      // Menunggu Asisten Manager
      final idx = steps.indexWhere((e) => e.toLowerCase().contains('asisten'));
      return idx >= 0 ? idx : 1;
    }

    if (isRejected) {
      return gudangIdx;
    }

    return 1; // fallback
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

// ─── Item Card ───────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final PengajuanDetailModel item;
  const _ItemCard({required this.item});

  Widget _buildImageWidget(
      String? foto, double width, double height, ThemeData theme) {
    if (foto != null && foto.isNotEmpty) {
      return Image.network(
        '${AppConstants.uploadUrl}/$foto',
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildImagePlaceholder(width, height, theme),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    } else {
      return _buildImagePlaceholder(width, height, theme);
    }
  }

  Widget _buildImagePlaceholder(double width, double height, ThemeData theme) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TirtaTheme.primaryBlue.withValues(alpha: 0.15),
            TirtaTheme.skyBlue.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          item.namaBarang.isNotEmpty ? item.namaBarang[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: TirtaTheme.primaryBlue,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? TirtaTheme.slate800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? TirtaTheme.slate700
              : TirtaTheme.slate200.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Foto barang
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImageWidget(item.foto, 52, 52, theme),
          ),
          const SizedBox(width: 12),
          // Info barang
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaBarang,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: theme.colorScheme.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.kodeBarang,
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
                if (item.lokasiRak != null && item.lokasiRak!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4)),
                      const SizedBox(width: 3),
                      Text(item.lokasiRak!,
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Jumlah
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: TirtaTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${item.jumlah} ${item.satuan}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: TirtaTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Stok: ${item.stokTersedia}',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Detail Modal ────────────────────────────────────────────────────────────
class _DetailModalContent extends StatefulWidget {
  final PengajuanModel pengajuanHeader;
  final ScrollController scrollController;
  final Function(PengajuanModel)? onApprove;
  final Function(PengajuanModel)? onReject;

  const _DetailModalContent({
    required this.pengajuanHeader,
    required this.scrollController,
    this.onApprove,
    this.onReject,
  });

  @override
  State<_DetailModalContent> createState() => _DetailModalContentState();
}

class _DetailModalContentState extends State<_DetailModalContent> {
  bool _isLoading = true;
  PengajuanModel? _loadedPengajuan;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final provider = Provider.of<PengajuanProvider>(context, listen: false);
      await provider.fetchPengajuanById(widget.pengajuanHeader.id);
      if (mounted) {
        setState(() {
          _loadedPengajuan = provider.selectedPengajuan;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = _loadedPengajuan ?? widget.pengajuanHeader;
    // Only show action buttons if this role can approve AND status matches
    final canAct = widget.onApprove != null && widget.onReject != null;
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProv.user?.role.toLowerCase() ?? '';
    String rolePendingStatus;
    switch (userRole) {
      case 'gudang':
        rolePendingStatus = 'pending_gudang';
        break;
      case 'asisten_manager':
        rolePendingStatus = 'pending_asisten_manager';
        break;
      case 'manager':
        rolePendingStatus = 'pending_manager';
        break;
      default:
        rolePendingStatus = '';
        break;
    }
    final isPending = canAct && p.status == rolePendingStatus;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // ── Scrollable content (header + timeline + items semuanya scroll)
          Expanded(
            child: _isLoading
                ? const Center(
                    child: LoadingIndicator(message: 'Memuat detail barang...'))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade300, size: 48),
                              const SizedBox(height: 12),
                              Text(_errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                    _errorMessage = null;
                                  });
                                  _fetchDetail();
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        controller: widget.scrollController,
                        padding: EdgeInsets.fromLTRB(
                          20,
                          16,
                          20,
                          isPending
                              ? 8
                              : (MediaQuery.of(context).padding.bottom + 16),
                        ),
                        children: [
                          // ── Header (thumbnail + nomor + pengaju)
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  color: Colors.grey.shade100,
                                  child: p.items.isNotEmpty &&
                                          p.items.first.foto != null &&
                                          p.items.first.foto!.isNotEmpty
                                      ? Image.network(
                                          '${AppConstants.uploadUrl}/${p.items.first.foto}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                            Icons.inventory_2_outlined,
                                            color: Colors.blueGrey,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.inventory_2_outlined,
                                          color: Colors.blueGrey,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nomorPengajuan,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'oleh ${p.namaPengaju ?? '-'}${p.deptPengaju != null ? ' • ${p.deptPengaju}' : ''}',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // ── Badge row
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatusBadge(status: p.status),
                              const SizedBox(width: 8),
                              _UrgensiBadge(urgensi: p.urgensi),
                              const Spacer(),
                              Text(
                                DateTime.parse(p.tanggalPengajuan)
                                    .toLocal()
                                    .toString()
                                    .substring(0, 16),
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 11),
                              ),
                            ],
                          ),

                          // ── Approval Timeline
                          const SizedBox(height: 18),
                          _ApprovalTimeline(
                              status: p.status, rolePengaju: p.rolePengaju),

                          Divider(
                            height: 32,
                            color: isDark
                                ? TirtaTheme.slate700
                                : Colors.grey.shade200,
                          ),

                          // ── Catatan
                          if (p.catatan != null && p.catatan!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? TirtaTheme.slate800
                                    : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? TirtaTheme.slate700
                                      : Colors.amber.shade200,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.sticky_note_2_outlined,
                                      color: Colors.amber.shade600, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(p.catatan!,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.amber.shade200
                                                : Colors.amber.shade900)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Items header
                          Row(
                            children: [
                              const Text(
                                'Barang yang Diajukan',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: TirtaTheme.primaryBlue
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${p.items.length} item',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: TirtaTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (p.items.isEmpty)
                            const Center(
                                child: Text('Tidak ada barang dalam pengajuan'))
                          else
                            ...p.items.map((item) => _ItemCard(item: item)),

                          const SizedBox(height: 8),
                        ],
                      ),
          ),

          // ── Action Buttons (pinned di bawah, di luar scroll)
          if (isPending)
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  top: BorderSide(
                    color: isDark ? TirtaTheme.slate700 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: isNarrow
                            ? double.infinity
                            : (constraints.maxWidth - 12) / 3,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onReject?.call(p);
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Tolak'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side:
                                const BorderSide(color: Colors.red, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isNarrow
                            ? double.infinity
                            : (constraints.maxWidth - 12) * 2 / 3,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onApprove?.call(p);
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Setujui'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Confirm Dialog ──────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String nomorPengajuan;
  final String confirmLabel;
  final Color confirmColor;
  final IconData icon;
  final Color iconColor;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.nomorPengajuan,
    required this.confirmLabel,
    required this.confirmColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 8),
            Text(
              nomorPengajuan,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
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
