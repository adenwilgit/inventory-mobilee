import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../data/models/pengajuan_model.dart';
import '../providers/pengajuan_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/custom_snackbar.dart';
import '../screens/buat_pengajuan_screen.dart';

class DetailPengajuanSheet extends StatefulWidget {
  final PengajuanModel pengajuanHeader;
  final ScrollController? scrollController;

  const DetailPengajuanSheet({
    super.key,
    required this.pengajuanHeader,
    this.scrollController,
  });

  static Future<bool?> show(BuildContext context, PengajuanModel pengajuan) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => DetailPengajuanSheet(
          pengajuanHeader: pengajuan,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  State<DetailPengajuanSheet> createState() => _DetailPengajuanSheetState();
}

class _DetailPengajuanSheetState extends State<DetailPengajuanSheet> {
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

  Future<void> _handleApprove(PengajuanModel pengajuan) async {
    final navigator = Navigator.of(context);
    final pengajuanProv = Provider.of<PengajuanProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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

    if (confirmed == true) {
      final success = await pengajuanProv.approvePengajuan(pengajuan.id);
      if (success) {
        navigator.pop(true); // Close sheet with success result
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pengajuan berhasil disetujui!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 8,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pengajuanProv.errorMessage ?? 'Gagal menyetujui pengajuan!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 8,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(PengajuanModel pengajuan) async {
    final navigator = Navigator.of(context);
    final pengajuanProv = Provider.of<PengajuanProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    final alasanController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
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

    if (confirmed == true) {
      final success = await pengajuanProv.rejectPengajuan(
          pengajuan.id, alasanController.text.trim());

      if (success) {
        navigator.pop(true); // Close sheet with success result
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pengajuan berhasil ditolak.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 8,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pengajuanProv.errorMessage ?? 'Gagal menolak pengajuan!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 8,
          ),
        );
      }
    }
  }

  void _showCancelConfirmation(PengajuanModel p) async {
    final navigator = Navigator.of(context);
    final prov = Provider.of<PengajuanProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'Batalkan Pengajuan?',
        message: 'Pengajuan yang dibatalkan akan dihapus permanen dari sistem.',
        nomorPengajuan: p.nomorPengajuan,
        confirmLabel: 'Ya, Batalkan',
        confirmColor: Colors.red,
        icon: Icons.warning_rounded,
        iconColor: Colors.amber,
      ),
    );

    if (confirmed == true) {
      final success = await prov.deletePengajuan(p.id);
      if (success) {
        navigator.pop(true); // Close sheet with success result
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pengajuan berhasil dibatalkan!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 8,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    prov.errorMessage ?? 'Gagal membatalkan pengajuan.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 8,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = _loadedPengajuan ?? widget.pengajuanHeader;
    
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProv.user?.role.toLowerCase() ?? '';
    final userId = authProv.user?.id ?? 0;
    
    // check approval roles
    final bool isApprover = userRole == 'gudang' ||
        userRole == 'asisten_manager' ||
        userRole == 'manager' ||
        userRole == 'admin';

    // check ownership
    final isOwner = authProv.user != null && userId == p.userId;

    // isPending: needs approval and role matches
    bool isPending = false;
    if (isApprover && !isOwner) {
      if (userRole == 'gudang' && p.status == 'pending_gudang') isPending = true;
      if (userRole == 'asisten_manager' && p.status == 'pending_asisten_manager') isPending = true;
      if (userRole == 'manager' && p.status == 'pending_manager') isPending = true;
      if (userRole == 'admin' && p.status.startsWith('pending')) isPending = true;
    }

    // canManage: owner can edit/delete if pending initial step
    final bool canManage = isOwner &&
        (p.status == 'pending_asisten_manager' ||
            (userRole == 'asisten_manager' && p.status == 'pending_manager') ||
            (userRole == 'manager' && p.status == 'pending_gudang'));

    String dateStr = '';
    try {
      final dt = DateTime.parse(p.tanggalPengajuan);
      dateStr = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt.toLocal());
    } catch (_) {
      dateStr = p.tanggalPengajuan;
    }

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

          // ── Scrollable content
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
                                  label: const Text('Coba Lagi')),
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
                          (isPending || canManage)
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
                                          errorBuilder: (context, error,
                                                  stackTrace) =>
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
                                dateStr,
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
                        child: OutlinedButton(
                          onPressed: () {
                            _handleReject(p);
                          },
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
                          child: const Text('Tolak'),
                        ),
                      ),
                      SizedBox(
                        width: isNarrow
                            ? double.infinity
                            : (constraints.maxWidth - 12) * 2 / 3,
                        child: ElevatedButton(
                          onPressed: () {
                            _handleApprove(p);
                          },
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
                          child: const Text('Setujui'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          // ── Action Buttons for Owner (pinned di bawah, di luar scroll)
          if (canManage)
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _showCancelConfirmation(p);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        side: BorderSide(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      child: const Text('Batalkan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BuatPengajuanScreen(editPengajuan: p),
                          ),
                        );
                        if (!context.mounted) return;
                        if (result == true) {
                          CustomSnackBar.show(
                            context: context,
                            message: 'Pengajuan berhasil diubah!',
                            type: SnackBarType.success,
                          );
                        }
                        _fetchDetail();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TirtaTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      child: const Text('Ubah'),
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

// ─── Status Badge ────────────────────────────────────────────────────────────
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

    switch (status.toLowerCase()) {
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
      case 'selesai':
        bg = TirtaTheme.green.withValues(alpha: 0.12);
        fg = TirtaTheme.green;
        label = 'SELESAI';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
      case 'ditolak':
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

// ─── Urgensi Badge ───────────────────────────────────────────────────────────
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

// ─── Approval Timeline ───────────────────────────────────────────────────────
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
    final isRejected = s.contains('reject') || s.contains('ditolak');
    final gudangIdx = steps.length - 1;

    if (s.contains('completed') || s == 'approved_gudang' || s == 'selesai') {
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

    return 1; // fallback
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    final isRejected = status.toLowerCase().contains('reject') ||
        status.toLowerCase().contains('ditolak');
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
