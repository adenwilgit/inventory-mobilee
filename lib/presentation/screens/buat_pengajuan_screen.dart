import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stok_provider.dart';
import '../providers/pengajuan_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/models/pengajuan_model.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/custom_snackbar.dart';
import 'package:intl/intl.dart';

class BuatPengajuanScreen extends StatefulWidget {
  final int? initialBarangId;
  final PengajuanModel? editPengajuan;
  const BuatPengajuanScreen({super.key, this.initialBarangId, this.editPengajuan});

  @override
  State<BuatPengajuanScreen> createState() => _BuatPengajuanScreenState();
}

class _BuatPengajuanScreenState extends State<BuatPengajuanScreen> {
  final _catatanController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedUrgensi = 'Normal';
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  // Toggle khusus Asmen & Manager: true = Form Katalog, false = Pengajuan Saya
  bool _asmenShowForm = true;
  // Toggle status pengajuan mandiri: true = Diproses, false = Riwayat
  bool _asmenShowDiproses = true;

  // Keranjang pengajuan: Map<barangId, jumlah>
  final Map<int, int> _cart = {};

  @override
  void initState() {
    super.initState();
    if (widget.editPengajuan != null) {
      _catatanController.text = widget.editPengajuan!.catatan ?? '';
      final urg = widget.editPengajuan!.urgensi;
      if (urg.isNotEmpty) {
        _selectedUrgensi = urg[0].toUpperCase() + urg.substring(1).toLowerCase();
      }
      for (final item in widget.editPengajuan!.items) {
        _cart[item.barangId] = item.jumlah;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Capture route arguments synchronously before any async operation
      final routeArgs = ModalRoute.of(context)?.settings.arguments;
      final stokProv = Provider.of<StokProvider>(context, listen: false);
      stokProv.fetchBarangList().then((_) {
        if (widget.editPengajuan == null) {
          int? startId = widget.initialBarangId;
          if (startId == null) {
            if (routeArgs is int) {
              startId = routeArgs;
            }
          }
          if (startId != null) {
            try {
              final barang =
                  stokProv.barangList.firstWhere((b) => b.id == startId);
              if (barang.stokTersedia > 0) {
                setState(() {
                  _cart[startId!] = 1;
                });
              }
            } catch (e) {
              debugPrint('Item with ID $startId not found in list: $e');
            }
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addItemToCart(dynamic barang) {
    if (barang.stokTersedia <= 0) {
      CustomSnackBar.show(
        context: context,
        message: 'Stok "${barang.namaBarang}" habis! Tidak dapat diajukan.',
        type: SnackBarType.warning,
      );
      return;
    }

    setState(() {
      final currentQty = _cart[barang.id] ?? 0;
      if (currentQty < barang.stokTersedia) {
        _cart[barang.id] = currentQty + 1;
      } else {
        CustomSnackBar.show(
          context: context,
          message: 'Kuantitas melebihi batas stok tersedia!',
          type: SnackBarType.error,
        );
      }
    });
  }

  void _decreaseItemInCart(int barangId) {
    setState(() {
      final currentQty = _cart[barangId] ?? 0;
      if (currentQty > 1) {
        _cart[barangId] = currentQty - 1;
      } else {
        _cart.remove(barangId);
      }
    });
  }

  void _submitPengajuan() async {
    if (_cart.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'Keranjang pengajuan masih kosong!',
        type: SnackBarType.warning,
      );
      return;
    }

    final pengajuanProv =
        Provider.of<PengajuanProvider>(context, listen: false);

    final itemsPayload = _cart.entries.map((entry) {
      return {
        'barang_id': entry.key,
        'jumlah': entry.value,
      };
    }).toList();

    final bool success;
    if (widget.editPengajuan != null) {
      success = await pengajuanProv.updatePengajuan(
        id: widget.editPengajuan!.id,
        items: itemsPayload,
        catatan: _catatanController.text.trim(),
        urgensi: _selectedUrgensi,
      );
    } else {
      success = await pengajuanProv.createPengajuan(
        items: itemsPayload,
        catatan: _catatanController.text.trim(),
        urgensi: _selectedUrgensi,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context); // Tutup bottom sheet
      if (widget.editPengajuan != null) {
        Navigator.pop(context); // Tutup screen edit
      }
      CustomSnackBar.show(
        context: context,
        message: widget.editPengajuan != null
            ? 'Pengajuan barang berhasil diubah!'
            : 'Pengajuan barang berhasil dikirim ke atasan!',
        type: SnackBarType.success,
      );
      setState(() {
        _cart.clear();
        _catatanController.clear();
        _selectedUrgensi = 'Normal';
      });
    } else {
      CustomSnackBar.show(
        context: context,
        message: pengajuanProv.errorMessage ?? 'Gagal submit pengajuan.',
        type: SnackBarType.error,
      );
    }
  }

  void _showCheckoutSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final stokProv = Provider.of<StokProvider>(modalCtx);
            final pengajuanProv = Provider.of<PengajuanProvider>(modalCtx);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(modalCtx).size.height * 0.92,
              ),
              decoration: BoxDecoration(
                color: isDark ? TirtaTheme.slate900 : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Handle Bar ────────────────────────────────────────
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Header ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                TirtaTheme.primaryBlue,
                                TirtaTheme.skyBlue
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shopping_bag_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Konfirmasi Pengajuan',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                              Text(
                                '${_cart.length} jenis · ${_cart.values.fold(0, (s, v) => s + v)} unit',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() => setState(() => _cart.clear()));
                            Navigator.pop(modalCtx);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'HAPUS SEMUA',
                            style: TextStyle(
                              color: TirtaTheme.rose,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                      height: 1,
                      color:
                          isDark ? TirtaTheme.slate800 : TirtaTheme.slate100),
                  const SizedBox(height: 4),

                  // ── Scrollable Content ────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cart Items
                          ..._cart.entries.map((entry) {
                            final barang = stokProv.barangList.firstWhere(
                              (b) => b.id == entry.key,
                              orElse: () => throw Exception('not found'),
                            );

                            return Dismissible(
                              key: ValueKey(entry.key),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) {
                                setModalState(() =>
                                    setState(() => _cart.remove(entry.key)));
                                if (_cart.isEmpty) Navigator.pop(modalCtx);
                              },
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: TirtaTheme.rose,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_rounded,
                                        color: Colors.white, size: 22),
                                    SizedBox(height: 4),
                                    Text(
                                      'HAPUS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? TirtaTheme.slate800
                                      : TirtaTheme.slate50,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDark
                                        ? TirtaTheme.slate700
                                        : TirtaTheme.slate200
                                            .withValues(alpha: 0.7),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Product Image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: barang.foto != null &&
                                              barang.foto!.isNotEmpty
                                          ? Image.network(
                                              '${AppConstants.uploadUrl}/${barang.foto}',
                                              width: 68,
                                              height: 68,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _itemPlaceholder(theme, 68),
                                            )
                                          : _itemPlaceholder(theme, 68),
                                    ),
                                    const SizedBox(width: 12),

                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            barang.namaBarang,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            barang.kategori ?? '-',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.45),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: barang.stokTersedia > 0
                                                  ? TirtaTheme.green
                                                      .withValues(alpha: 0.1)
                                                  : TirtaTheme.rose
                                                      .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              barang.stokTersedia > 0
                                                  ? 'Tersedia ${barang.stokTersedia}'
                                                  : 'Stok Habis',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: barang.stokTersedia > 0
                                                    ? TirtaTheme.green
                                                    : TirtaTheme.rose,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Stepper
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? TirtaTheme.slate700
                                            : TirtaTheme.slate200
                                                .withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                                    left: Radius.circular(12)),
                                            onTap: entry.value <= 1
                                                ? null
                                                : () {
                                                    setModalState(() =>
                                                        setState(() =>
                                                            _decreaseItemInCart(
                                                                barang.id)));
                                                  },
                                            child: SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: Icon(
                                                Icons.remove,
                                                size: 14,
                                                color: entry.value <= 1
                                                    ? theme
                                                        .colorScheme.onSurface
                                                        .withValues(alpha: 0.25)
                                                    : theme
                                                        .colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 32,
                                            height: 32,
                                            alignment: Alignment.center,
                                            color: isDark
                                                ? TirtaTheme.slate800
                                                : Colors.white,
                                            child: Text(
                                              '${entry.value}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13),
                                            ),
                                          ),
                                          InkWell(
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                                    right: Radius.circular(12)),
                                            onTap: () {
                                              setModalState(() => setState(() =>
                                                  _addItemToCart(barang)));
                                            },
                                            child: const SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: Icon(Icons.add,
                                                  size: 14,
                                                  color:
                                                      TirtaTheme.primaryBlue),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 18),
                          Divider(
                              height: 1,
                              color: isDark
                                  ? TirtaTheme.slate800
                                  : TirtaTheme.slate100),
                          const SizedBox(height: 18),

                          // ── Keterangan ──────────────────────────────────
                          _sectionLabel('KETERANGAN / KEPERLUAN', theme),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _catatanController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  'Contoh: untuk keperluan unit operasional...',
                              filled: true,
                              fillColor: isDark
                                  ? TirtaTheme.slate800
                                  : TirtaTheme.slate50,
                              contentPadding: const EdgeInsets.all(14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? TirtaTheme.slate700
                                      : TirtaTheme.slate200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? TirtaTheme.slate700
                                      : TirtaTheme.slate200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: TirtaTheme.primaryBlue, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Tingkat Urgensi ──────────────────────────────
                          _sectionLabel('TINGKAT URGENSI', theme),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _urgencyCard(
                                label: 'Normal',
                                icon: Icons.check_circle_outline_rounded,
                                description: 'Tidak mendesak',
                                color: TirtaTheme.primaryBlue,
                                isSelected: _selectedUrgensi == 'Normal',
                                isDark: isDark,
                                onTap: () => setModalState(
                                  () => setState(
                                      () => _selectedUrgensi = 'Normal'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _urgencyCard(
                                label: 'Penting',
                                icon: Icons.warning_amber_rounded,
                                description: 'Segera diproses',
                                color: TirtaTheme.orange,
                                isSelected: _selectedUrgensi == 'Penting',
                                isDark: isDark,
                                onTap: () => setModalState(
                                  () => setState(
                                      () => _selectedUrgensi = 'Penting'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _urgencyCard(
                                label: 'Darurat',
                                icon: Icons.emergency_rounded,
                                description: 'Sangat mendesak',
                                color: TirtaTheme.rose,
                                isSelected: _selectedUrgensi == 'Darurat',
                                isDark: isDark,
                                onTap: () => setModalState(
                                  () => setState(
                                      () => _selectedUrgensi = 'Darurat'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Order Summary ────────────────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: TirtaTheme.primaryBlue
                                  .withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: TirtaTheme.primaryBlue
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_long_rounded,
                                    size: 16, color: TirtaTheme.primaryBlue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_cart.length} jenis · ${_cart.values.fold(0, (s, v) => s + v)} unit akan diajukan',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: TirtaTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _selectedUrgensi == 'Darurat'
                                        ? TirtaTheme.rose
                                        : _selectedUrgensi == 'Penting'
                                            ? TirtaTheme.orange
                                            : TirtaTheme.primaryBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _selectedUrgensi.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Submit Button ────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: pengajuanProv.isLoading
                                    ? null
                                    : const LinearGradient(
                                        colors: [
                                          TirtaTheme.primaryBlue,
                                          TirtaTheme.skyBlue
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                color: pengajuanProv.isLoading
                                    ? TirtaTheme.slate300
                                    : null,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: pengajuanProv.isLoading
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: TirtaTheme.primaryBlue
                                              .withValues(alpha: 0.35),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                              ),
                              child: ElevatedButton(
                                onPressed: pengajuanProv.isLoading
                                    ? null
                                    : _submitPengajuan,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: pengajuanProv.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.send_rounded, size: 18),
                                          SizedBox(width: 10),
                                          Text(
                                            'KIRIM PENGAJUAN',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _itemPlaceholder(ThemeData theme, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.inventory_2_outlined,
          color: Colors.grey.shade400, size: size * 0.38),
    );
  }

  Widget _sectionLabel(String label, ThemeData theme) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _urgencyCard({
    required String label,
    required IconData icon,
    required String description,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark ? TirtaTheme.slate700 : TirtaTheme.slate200),
              width: isSelected ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? color
                    : (isDark ? TirtaTheme.slate500 : TirtaTheme.slate400),
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? color
                      : (isDark ? TirtaTheme.slate400 : TirtaTheme.slate500),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? color.withValues(alpha: 0.7)
                      : (isDark ? TirtaTheme.slate600 : TirtaTheme.slate400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper: Warna & Label Status Pengajuan ──────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending_asisten_manager':
        return TirtaTheme.orange;
      case 'approved_asisten_manager':
      case 'pending_manager':
        return const Color(0xFF6366F1); // indigo
      case 'approved_manager':
      case 'pending_gudang':
        return TirtaTheme.primaryBlue;
      case 'selesai':
      case 'approved_gudang':
        return TirtaTheme.green;
      case 'ditolak':
      case 'rejected':
        return TirtaTheme.rose;
      default:
        return TirtaTheme.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending_asisten_manager':
        return 'Menunggu Asmen';
      case 'approved_asisten_manager':
        return 'Disetujui Asmen';
      case 'pending_manager':
        return 'Menunggu Manager';
      case 'approved_manager':
        return 'Disetujui Manager';
      case 'pending_gudang':
        return 'Menunggu Gudang';
      case 'approved_gudang':
      case 'selesai':
        return 'Selesai';
      case 'ditolak':
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  // ── Dialog: Konfirmasi Batalkan Pengajuan ──────────────────────────
  void _showCancelPengajuanDialog(PengajuanModel p) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? TirtaTheme.slate900 : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded,
                  color: Colors.amber, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Batalkan Pengajuan?',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengajuan yang dibatalkan akan dihapus permanen dari sistem.',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? TirtaTheme.slate800 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.nomorPengajuan,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tidak',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prov =
                  Provider.of<PengajuanProvider>(context, listen: false);
              final success = await prov.deletePengajuan(p.id);
              if (!mounted) return;
              if (success) {
                CustomSnackBar.show(
                  context: context,
                  message: 'Pengajuan berhasil dibatalkan!',
                  type: SnackBarType.success,
                );
              } else {
                CustomSnackBar.show(
                  context: context,
                  message: prov.errorMessage ?? 'Gagal membatalkan pengajuan.',
                  type: SnackBarType.error,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Batalkan',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  bool _isDiproses(String status) {
    return status.toLowerCase().startsWith('pending');
  }

  // ── Widget: Stacked Photos for Pengajuan Items ────────────────────
  Widget _itemPhotosStack(List<PengajuanDetailModel> items, bool isDark) {
    final theme = Theme.of(context);
    const maxShow = 3;
    final shown = items.take(maxShow).toList();
    final extra = items.length - maxShow;

    if (items.length == 1) {
      // Single item: show one larger image
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildPhoto(shown[0].foto, 52, 52, theme),
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
                    color: isDark ? TirtaTheme.slate800 : Colors.white,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: _buildPhoto(shown[i].foto, 34, 34, theme),
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
        errorBuilder: (_, __, ___) => _photoPlaceholder(w, h, theme),
      );
    }
    return _photoPlaceholder(w, h, theme);
  }

  Widget _photoPlaceholder(double w, double h, ThemeData theme) {
    return Container(
      width: w,
      height: h,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.inventory_2_outlined,
          size: w * 0.38, color: Colors.grey.shade400),
    );
  }

  // ── Widget: Approval Timeline ──────────────────────────────────────
  Widget _approvalTimeline(String status, String? rolePengaju) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRejected = status.toLowerCase().contains('reject') ||
        status.toLowerCase().contains('ditolak');
    final activeStep = _getActiveStep(status, rolePengaju);
    final steps = _buildSteps(rolePengaju);

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

              String statusLabelStep;
              Color statusLabelColor;

              if (isRejectedStep) {
                statusLabelStep = 'Ditolak';
                statusLabelColor = TirtaTheme.rose;
              } else if (isComplete) {
                statusLabelStep = 'Selesai';
                statusLabelColor = TirtaTheme.green;
              } else if (isActive) {
                statusLabelStep =
                    isLastStep ? 'Menunggu Gudang' : 'Sedang diproses';
                statusLabelColor =
                    isLastStep ? TirtaTheme.primaryBlue : TirtaTheme.orange;
              } else {
                statusLabelStep = 'Menunggu';
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
                            statusLabelStep,
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

  List<String> _buildSteps(String? rolePengaju) {
    final role = (rolePengaju ?? '').toLowerCase();
    if (role.contains('manager') && !role.contains('asisten')) {
      return ['Pengajuan', 'Gudang'];
    } else if (role.contains('asisten')) {
      return ['Pengajuan', 'Manager', 'Gudang'];
    }
    return ['Pengajuan', 'Asisten Manager', 'Manager', 'Gudang'];
  }

  int _getActiveStep(String status, String? rolePengaju) {
    final s = status.toLowerCase();
    final steps = _buildSteps(rolePengaju);
    final isRejected = s.contains('reject') || s.contains('ditolak');

    final gudangIdx = steps.length - 1;

    if (s.contains('selesai') || s.contains('approved_gudang')) {
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

  // ── Fungsi: Tampilkan Detail Pengajuan di Bottom Sheet ─────────────
  void _showDetailBottomSheet(PengajuanModel p) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _statusColor(p.status);
    final statusLabel = _statusLabel(p.status);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProv.user?.role.toLowerCase() ?? '';
    final isOwner = authProv.user != null && authProv.user!.id == p.userId;
    // canManage: owner dan status masih pending sesuai role
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: isDark ? TirtaTheme.slate900 : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Pengajuan',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: theme.colorScheme.onSurface),
                          ),
                          Text(
                            p.nomorPengajuan,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                      color: theme.colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(
                  height: 1,
                  color: isDark ? TirtaTheme.slate800 : TirtaTheme.slate100),
              const SizedBox(height: 4),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info pengajuan
                      Row(
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
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
                          const SizedBox(width: 8),
                          _urgensiChip(p.urgensi),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 12,
                                  color: isDark
                                      ? TirtaTheme.slate500
                                      : Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? TirtaTheme.slate500
                                      : Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (p.catatan != null && p.catatan!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Catatan',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? TirtaTheme.slate800
                                : TirtaTheme.slate50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isDark
                                    ? TirtaTheme.slate700
                                    : TirtaTheme.slate200
                                        .withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            p.catatan!,
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Daftar barang
                      Text(
                        'Daftar Barang',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...p.items.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: isDark
                                    ? TirtaTheme.slate800
                                    : TirtaTheme.slate200
                                        .withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildPhoto(item.foto, 52, 52, theme),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.namaBarang,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.kodeBarang,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: TirtaTheme.primaryBlue
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${item.jumlah} ${item.satuan}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: TirtaTheme.primaryBlue),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      // Approval timeline
                      _approvalTimeline(p.status, p.rolePengaju),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // ── Action Buttons: Ubah & Batalkan (pinned di bawah)
              if (canManage)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(ctx).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border(
                      top: BorderSide(
                        color:
                            isDark ? TirtaTheme.slate700 : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showCancelPengajuanDialog(p);
                          },
                          icon: const Icon(Icons.delete_forever_rounded,
                              size: 16),
                          label: const Text('Batalkan'),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BuatPengajuanScreen(editPengajuan: p),
                              ),
                            ).then((_) {
                              // Refresh list after editing
                              if (mounted) {
                                Provider.of<PengajuanProvider>(context,
                                        listen: false)
                                    .fetchPengajuans();
                              }
                            });
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Ubah'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TirtaTheme.skyBlue,
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
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Widget: Tab Toggle (Asmen only) ─────────────────────────────
  Widget _buildTabToggle(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? TirtaTheme.slate800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _tabBtn(
            label: 'Buat Pengajuan',
            icon: Icons.add_shopping_cart_rounded,
            isActive: _asmenShowForm,
            isDark: isDark,
            onTap: () => setState(() => _asmenShowForm = true),
          ),
          _tabBtn(
            label: 'Pengajuan Saya',
            icon: Icons.history_rounded,
            isActive: !_asmenShowForm,
            isDark: isDark,
            onTap: () => setState(() => _asmenShowForm = false),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn({
    required String label,
    required IconData icon,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? TirtaTheme.slate700 : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive
                    ? TirtaTheme.primaryBlue
                    : (isDark ? TirtaTheme.slate500 : Colors.grey.shade500),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? TirtaTheme.primaryBlue
                      : (isDark ? TirtaTheme.slate500 : Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget: Sub-toggle Diproses / Riwayat ───────────────────────
  Widget _buildSubToggle(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          _subToggleChip(
            label: 'Diproses',
            isActive: _asmenShowDiproses,
            activeColor: TirtaTheme.orange,
            isDark: isDark,
            onTap: () => setState(() => _asmenShowDiproses = true),
          ),
          const SizedBox(width: 8),
          _subToggleChip(
            label: 'Riwayat',
            isActive: !_asmenShowDiproses,
            activeColor: TirtaTheme.green,
            isDark: isDark,
            onTap: () => setState(() => _asmenShowDiproses = false),
          ),
        ],
      ),
    );
  }

  Widget _subToggleChip({
    required String label,
    required bool isActive,
    required Color activeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? activeColor
                : (isDark ? TirtaTheme.slate700 : TirtaTheme.slate200),
            width: isActive ? 1.6 : 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive
                ? activeColor
                : (isDark ? TirtaTheme.slate400 : Colors.grey.shade500),
          ),
        ),
      ),
    );
  }

  // ── Widget: Daftar Pengajuan Saya (Asmen mandiri) ───────────────
  Widget _buildPengajuanSayaList(
      ThemeData theme, bool isDark, List<PengajuanModel> allList, int userId) {
    // Filter: hanya pengajuan milik user ini
    final myList = allList.where((p) => p.userId == userId).toList();
    // Filter: diproses vs riwayat
    final filtered = _asmenShowDiproses
        ? myList.where((p) => _isDiproses(p.status)).toList()
        : myList.where((p) => !_isDiproses(p.status)).toList();

    // Sort descending by id (newest first)
    filtered.sort((a, b) => b.id.compareTo(a.id));

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _asmenShowDiproses
                  ? Icons.hourglass_empty_rounded
                  : Icons.inbox_rounded,
              size: 64,
              color: isDark ? TirtaTheme.slate600 : Colors.grey.shade300,
            ),
            const SizedBox(height: 14),
            Text(
              _asmenShowDiproses
                  ? 'Tidak ada pengajuan yang sedang diproses'
                  : 'Belum ada riwayat pengajuan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? TirtaTheme.slate500 : Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final p = filtered[i];
        final statusColor = _statusColor(p.status);
        final statusLabel = _statusLabel(p.status);
        String dateStr = '';
        try {
          final dt = DateTime.parse(p.tanggalPengajuan);
          dateStr =
              DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt.toLocal());
        } catch (_) {
          dateStr = p.tanggalPengajuan;
        }

        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? TirtaTheme.slate800
                  : TirtaTheme.slate200.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                _showDetailBottomSheet(p);
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // ── Item Photos Stack ──
                    if (p.items.isNotEmpty)
                      _itemPhotosStack(p.items, isDark)
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
                    // ── Info ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nomorPengajuan,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (p.items.isNotEmpty)
                            Text(
                              p.items.map((item) => item.namaBarang).join(', '),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else
                            Text(
                              p.catatan ?? '-',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (p.urgensi != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        _getUrgensiColor(p.urgensi).withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    p.urgensi.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: _getUrgensiColor(p.urgensi),
                                    ),
                                  ),
                                ),
                              if (p.urgensi != null && p.items.isNotEmpty)
                                const SizedBox(width: 6),
                              if (p.items.isNotEmpty)
                                Text(
                                  '${p.items.length} barang',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ── Status Badge ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
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
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getUrgensiColor(String? urgensi) {
    if (urgensi == 'Darurat') return TirtaTheme.rose;
    if (urgensi == 'Penting') return TirtaTheme.orange;
    return TirtaTheme.primaryBlue;
  }

  Widget _urgensiChip(String urgensi) {
    Color color;
    switch (urgensi.toLowerCase()) {
      case 'darurat':
        color = TirtaTheme.rose;
        break;
      case 'penting':
        color = TirtaTheme.orange;
        break;
      default:
        color = TirtaTheme.primaryBlue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        urgensi.toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stokProv = Provider.of<StokProvider>(context);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final pengajuanProv = Provider.of<PengajuanProvider>(context);
    final role = authProv.user?.role.toLowerCase() ?? '';
    final isAsmen =
        role == 'asisten_manager' || role == 'asmen' || role == 'manager';
    final userId = authProv.user?.id ?? 0;

    // Filter categories dynamically
    final categories = <String>['Semua'];
    for (final item in stokProv.barangList) {
      if (item.kategori != null && item.kategori!.isNotEmpty) {
        if (!categories.contains(item.kategori!)) {
          categories.add(item.kategori!);
        }
      }
    }

    // Filtered barang list
    final filteredList = stokProv.barangList.where((barang) {
      final matchesSearch = barang.namaBarang
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          barang.kodeBarang.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Semua' || barang.kategori == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    final canPop = Navigator.of(context).canPop();
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Curved Gradient Header ─────────────────────────────
          Container(
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
            child: Row(
              children: [
                if (canPop)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.editPengajuan != null
                            ? 'UBAH PENGAJUAN'
                            : 'AJUKAN BARANG',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        widget.editPengajuan != null
                            ? 'Ubah barang atau kuantitas pengajuan'
                            : (isAsmen
                                ? (_asmenShowForm
                                    ? 'Pilih barang dari katalog'
                                    : 'Riwayat pengajuan Anda')
                                : 'Pilih barang kebutuhan Anda'),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Tab Toggle (Asmen only, hide in edit mode) ──────────
          if (isAsmen && widget.editPengajuan == null) _buildTabToggle(theme, isDark),

          // ─────────────────────────────────────────────────────
          // KONTEN: Form Katalog  OR  Pengajuan Saya
          // ─────────────────────────────────────────────────────
          if (widget.editPengajuan != null || !isAsmen || _asmenShowForm) ...[
            // Search & Filters Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? TirtaTheme.slate800
                        : TirtaTheme.slate200.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Search Input
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isDark ? TirtaTheme.slate800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari barang kebutuhan Anda...',
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Pills
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? TirtaTheme.primaryBlue
                                    : (isDark
                                        ? TirtaTheme.slate800
                                        : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  cat.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Items Grid Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => stokProv.fetchBarangList(),
                color: TirtaTheme.primaryBlue,
                child: stokProv.isLoading && stokProv.barangList.isEmpty
                    ? const Center(
                        child: LoadingIndicator(message: 'Memuat katalog...'))
                    : filteredList.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.inventory_2_outlined,
                                        size: 64, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Barang tidak ditemukan',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final barang = filteredList[index];
                              final inCart = _cart[barang.id] ?? 0;
                              final isAman =
                                  barang.stokTersedia > barang.stokMinimum;
                              final isHabis = barang.stokTersedia == 0;
                              final isKritis = !isAman && !isHabis;

                              Color badgeBg;
                              Color badgeText;
                              if (isAman) {
                                badgeBg =
                                    TirtaTheme.green.withValues(alpha: 0.1);
                                badgeText = TirtaTheme.green;
                              } else if (isKritis) {
                                badgeBg =
                                    TirtaTheme.orange.withValues(alpha: 0.1);
                                badgeText = TirtaTheme.orange;
                              } else {
                                badgeBg =
                                    TirtaTheme.rose.withValues(alpha: 0.1);
                                badgeText = TirtaTheme.rose;
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDark
                                        ? TirtaTheme.slate800
                                        : TirtaTheme.slate200
                                            .withValues(alpha: 0.5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Thumbnail Image
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: barang.foto != null &&
                                                barang.foto!.isNotEmpty
                                            ? Image.network(
                                                '${AppConstants.uploadUrl}/${barang.foto}',
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Container(
                                                  color: theme.colorScheme
                                                      .surfaceContainerHighest,
                                                  child: const Icon(
                                                      Icons
                                                          .inventory_2_outlined,
                                                      color: Colors.grey),
                                                ),
                                              )
                                            : Container(
                                                width: double.infinity,
                                                color: theme.colorScheme
                                                    .surfaceContainerHighest,
                                                child: const Icon(
                                                    Icons.inventory_2_outlined,
                                                    color: Colors.grey),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'TERSEDIA ${barang.stokTersedia}',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: badgeText,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Item Info
                                    Text(
                                      barang.namaBarang,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      barang.kategori ?? '-',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Action Quantity Buttons
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (inCart > 0) ...[
                                          InkWell(
                                            onTap: inCart <= 1
                                                ? null
                                                : () => _decreaseItemInCart(
                                                    barang.id),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: inCart <= 1
                                                      ? theme
                                                          .colorScheme.onSurface
                                                          .withValues(
                                                              alpha: 0.15)
                                                      : TirtaTheme.rose,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.remove,
                                                size: 14,
                                                color: inCart <= 1
                                                    ? theme
                                                        .colorScheme.onSurface
                                                        .withValues(alpha: 0.2)
                                                    : TirtaTheme.rose,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '$inCart',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 13),
                                          ),
                                          InkWell(
                                            onTap: () => _addItemToCart(barang),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        TirtaTheme.primaryBlue),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.add,
                                                  size: 14,
                                                  color:
                                                      TirtaTheme.primaryBlue),
                                            ),
                                          ),
                                        ] else ...[
                                          const Spacer(),
                                          InkWell(
                                            onTap: () => _addItemToCart(barang),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: TirtaTheme.primaryBlue,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.add,
                                                  size: 16,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),

            // Sticky Bottom Checkout Bar
            if (_cart.isNotEmpty)
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                    top: BorderSide(
                      color:
                          isDark ? TirtaTheme.slate700 : Colors.grey.shade200,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: TirtaTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: TirtaTheme.primaryBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_cart.length} Jenis Barang',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                          Text(
                            'Total item: ${_cart.values.fold(0, (sum, element) => sum + element)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showCheckoutSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TirtaTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Checkout',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            // ── Tab: Pengajuan Saya ──────────────────────────────
            _buildSubToggle(theme, isDark),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => pengajuanProv.fetchPengajuans(),
                color: TirtaTheme.primaryBlue,
                child:
                    pengajuanProv.isLoading && pengajuanProv.pengajuans.isEmpty
                        ? const Center(
                            child: LoadingIndicator(message: 'Memuat data...'))
                        : _buildPengajuanSayaList(
                            theme, isDark, pengajuanProv.pengajuans, userId),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
