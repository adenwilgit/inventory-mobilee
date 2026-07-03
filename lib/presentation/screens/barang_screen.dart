import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../providers/stok_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notifikasi_provider.dart';
import '../providers/theme_provider.dart';
import '../../data/models/barang_model.dart';
import '../widgets/loading_indicator.dart';
import 'stok_masuk_screen.dart';
import 'stok_keluar_screen.dart';
import 'buat_pengajuan_screen.dart';

class BarangScreen extends StatefulWidget {
  final bool isActive;
  const BarangScreen({super.key, this.isActive = true});

  @override
  State<BarangScreen> createState() => _BarangScreenState();
}

class _BarangScreenState extends State<BarangScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _kategoriFilter = 'all';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StokProvider>(context, listen: false).fetchBarangList();
    });
  }

  @override
  void didUpdateWidget(covariant BarangScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (!widget.isActive) {
        _searchController.clear();
        setState(() {
          _kategoriFilter = 'all';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stokProv = Provider.of<StokProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final barangList = stokProv.barangList;
    final categories = <String>{};

    for (final item in barangList) {
      if (item.kategori != null && item.kategori!.isNotEmpty) {
        categories.add(item.kategori!);
      }
    }

    final filteredBarang = barangList.where((barang) {
      final searchLower = _searchController.text.toLowerCase();
      final matchesSearch =
          barang.namaBarang.toLowerCase().contains(searchLower) ||
              barang.kodeBarang.toLowerCase().contains(searchLower);
      final matchesKategori =
          _kategoriFilter == 'all' || barang.kategori == _kategoriFilter;

      return matchesSearch && matchesKategori;
    }).toList();

    final totalAman =
        barangList.where((b) => b.stokTersedia > b.stokMinimum).length;
    final totalKritis = barangList
        .where((b) => b.stokTersedia > 0 && b.stokTersedia <= b.stokMinimum)
        .length;
    final totalHabis = barangList.where((b) => b.stokTersedia == 0).length;

    final role = authProv.user?.role.toLowerCase() ?? '';
    final isGudang = role == 'gudang';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: isGudang
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/tambah-barang');
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'TAMBAH BARANG',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
              ),
              backgroundColor: TirtaTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 4,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh both barang list and notifications
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final stokProv = Provider.of<StokProvider>(context, listen: false);
          final notifProv =
              Provider.of<NotifikasiProvider>(context, listen: false);
          await stokProv.fetchBarangList();
          if (auth.user != null) {
            await notifProv.fetchNotifikasi(auth.user!.id);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CurvedGradientHeader(
                user: authProv.user,
                role: authProv.user?.role.toLowerCase() ?? '',
                notifProv: Provider.of<NotifikasiProvider>(context),
                themeProv: themeProv,
                theme: theme,
                title: 'KATALOG BARANG',
                subtitle: 'Manajemen & monitoring stok',
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  width < 380 ? 1 : 2,
                  16,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2,
                      children: [
                        _buildSummaryCard(
                            'SEMUA BARANG',
                            barangList.length,
                            TirtaTheme.blueSoft,
                            TirtaTheme.primaryBlue,
                            Icons.widgets_outlined,
                            theme: theme,
                            themeProv: themeProv),
                        _buildSummaryCard(
                            'STOK AMAN',
                            totalAman,
                            TirtaTheme.greenSoft,
                            TirtaTheme.green,
                            Icons.auto_awesome_outlined,
                            theme: theme,
                            themeProv: themeProv),
                        _buildSummaryCard(
                            'STOK MENIPIS',
                            totalKritis,
                            TirtaTheme.orangeSoft,
                            TirtaTheme.orange,
                            Icons.warning_amber_outlined,
                            theme: theme,
                            themeProv: themeProv),
                        _buildSummaryCard(
                            'STOK HABIS',
                            totalHabis,
                            TirtaTheme.redSoft,
                            TirtaTheme.rose,
                            Icons.inventory_2_outlined,
                            theme: theme,
                            themeProv: themeProv),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: themeProv.isDarkMode
                              ? TirtaTheme.slate800
                              : TirtaTheme.slate200.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau kode barang...',
                          hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4)),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 8),
                            child: Icon(Icons.search,
                                size: 22,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6)),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: themeProv.isDarkMode
                                    ? TirtaTheme.slate800
                                    : TirtaTheme.slate200
                                        .withValues(alpha: 0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isDense: true,
                                icon: Icon(Icons.expand_more,
                                    size: 20,
                                    color: theme.colorScheme.onSurface),
                                value: _kategoriFilter,
                                dropdownColor: theme.cardColor,
                                items: [
                                  DropdownMenuItem(
                                      value: 'all',
                                      child: Text('SEMUA KATEGORI',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.2,
                                              color: theme
                                                  .colorScheme.onSurface))),
                                  ...categories
                                      .map((category) => DropdownMenuItem(
                                            value: category,
                                            child: Text(category.toUpperCase(),
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.2,
                                                    color: theme.colorScheme
                                                        .onSurface)),
                                          )),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _kategoriFilter = value ?? 'all';
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeProv.isDarkMode
                                  ? TirtaTheme.slate800
                                  : TirtaTheme.slate200.withValues(alpha: 0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.list,
                                    color: _isGridView
                                        ? theme.colorScheme.onSurface
                                            .withValues(alpha: 0.4)
                                        : TirtaTheme.primaryBlue,
                                    size: 24),
                                onPressed: () {
                                  setState(() {
                                    _isGridView = false;
                                  });
                                },
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.1),
                              ),
                              IconButton(
                                icon: Icon(Icons.grid_view_outlined,
                                    color: _isGridView
                                        ? TirtaTheme.primaryBlue
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.4),
                                    size: 24),
                                onPressed: () {
                                  setState(() {
                                    _isGridView = true;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 0),
                    stokProv.isLoading
                        ? const Center(
                            child: LoadingIndicator(
                                message: 'Memuat daftar barang...'))
                        : filteredBarang.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_2_outlined,
                                        size: 80,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.3)),
                                    const SizedBox(height: 20),
                                    Text(
                                      barangList.isEmpty
                                          ? 'Belum ada barang tersedia.'
                                          : 'Tidak ada barang dengan filter ini.',
                                      style: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                          fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : _buildItemsList(filteredBarang, authProv,
                                theme: theme, themeProv: themeProv),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, int value, Color bgColor, Color textColor, IconData icon,
      {required ThemeData theme, required ThemeProvider themeProv}) {
    final isDark = themeProv.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
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
              color: textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
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

  Widget _buildItemsList(List<BarangModel> items, AuthProvider authProv,
      {required ThemeData theme, required ThemeProvider themeProv}) {
    if (_isGridView) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
        children: items
            .map((barang) => _buildItemCard(barang, authProv, true,
                theme: theme, themeProv: themeProv))
            .toList(),
      );
    } else {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => _buildItemCard(
            items[index], authProv, false,
            theme: theme, themeProv: themeProv),
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemCount: items.length,
      );
    }
  }

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
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: width * 0.4,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildItemCard(
      BarangModel barang, AuthProvider authProv, bool isGridView,
      {required ThemeData theme, required ThemeProvider themeProv}) {
    final isAman = barang.stokTersedia > barang.stokMinimum;
    final isHabis = barang.stokTersedia == 0;
    final isKritis = !isAman && !isHabis;
    final isDark = themeProv.isDarkMode;

    late Color statusColor;
    late String statusLabel;

    if (isAman) {
      statusColor = TirtaTheme.green;
      statusLabel = 'STOK AMAN';
    } else if (isKritis) {
      statusColor = TirtaTheme.orange;
      statusLabel = 'STOK MENIPIS';
    } else {
      statusColor = TirtaTheme.rose;
      statusLabel = 'STOK HABIS';
    }

    if (isGridView) {
      return GestureDetector(
        onTap: () => _showDetailModal(context, barang, theme, themeProv,
            statusColor, statusLabel, isAman),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
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
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    _buildImageWidget(barang.foto, double.infinity, 90, theme),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 8,
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                barang.namaBarang,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                barang.kodeBarang,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${barang.stokTersedia} ${barang.satuan}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isAman ? TirtaTheme.primaryBlue : statusColor,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => _showDetailModal(context, barang, theme, themeProv,
            statusColor, statusLabel, isAman),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.cardColor,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImageWidget(barang.foto, 64, 64, theme),
              ),
              const SizedBox(width: 12),
              // Right: Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 8,
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${barang.stokTersedia} ${barang.satuan}',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isAman ? TirtaTheme.primaryBlue : statusColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      barang.namaBarang,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kode: ${barang.kodeBarang} • Kategori: ${barang.kategori ?? '-'}',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                size: 22,
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showQRModal(BuildContext context, BarangModel barang, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  barang.namaBarang,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Kode: ${barang.kodeBarang}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: barang.qrCode != null
                      ? Image.memory(
                          base64Decode(barang.qrCode!.split(',').last),
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        )
                      : QrImageView(
                          data: '{"kode_barang":"${barang.kodeBarang}"}',
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TirtaTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetailModal(
    BuildContext context,
    BarangModel barang,
    ThemeData theme,
    ThemeProvider themeProv,
    Color statusColor,
    String statusLabel,
    bool isAman,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _buildImageWidget(
                              barang.foto, double.infinity, 200, theme),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Item Name
                      Text(
                        barang.namaBarang,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Detail Info Grid
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                                'Kode Barang', barang.kodeBarang, theme),
                            Divider(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.08),
                              height: 16,
                            ),
                            _buildDetailRow(
                                'Kategori', barang.kategori ?? '-', theme),
                            Divider(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.08),
                              height: 16,
                            ),
                            _buildDetailRow('Satuan', barang.satuan, theme),
                            Divider(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.08),
                              height: 16,
                            ),
                            _buildDetailRow(
                                'Lokasi Rak', barang.lokasiRak ?? '-', theme),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      //==================== STOCK INFO ====================
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withValues(alpha: .08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .03),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              /// STOK TERSEDIA
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: TirtaTheme.primaryBlue
                                              .withValues(alpha: .10),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.inventory_2_outlined,
                                          size: 12,
                                          color: TirtaTheme.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "STOK TERSEDIA",
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade600,
                                          letterSpacing: .4,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "${barang.stokTersedia}",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: TirtaTheme.primaryBlue,
                                        ),
                                      ),
                                      Text(
                                        barang.satuan,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: Colors.grey.withValues(alpha: .15),
                              ),

                              /// STOK MINIMUM
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: TirtaTheme.orange
                                              .withValues(alpha: .10),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.flag_outlined,
                                          size: 12,
                                          color: TirtaTheme.orange,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "STOK MINIMUM",
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade600,
                                          letterSpacing: .4,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "${barang.stokMinimum}",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: TirtaTheme.orange,
                                        ),
                                      ),
                                      Text(
                                        barang.satuan,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      //================ ACTION BUTTONS ================

                      Builder(
                        builder: (context) {
                          final authProv = Provider.of<AuthProvider>(context, listen: false);
                          final userRole = authProv.user?.role.toLowerCase() ?? '';
                          final isGudangRole = userRole == 'gudang';

                          if (isGudangRole) {
                            // Gudang: Stok Masuk + Stok Keluar
                            return Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StokMasukScreen(
                                              initialBarangId: barang.id),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffF2FFFA),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: TirtaTheme.green.withValues(alpha: .35),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: TirtaTheme.green,
                                              borderRadius: BorderRadius.circular(9),
                                            ),
                                            child: const Icon(
                                              Icons.download_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: const [
                                                Text(
                                                  "STOK MASUK",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12,
                                                    color: TirtaTheme.green,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  "Tambah stok barang",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StokKeluarScreen(
                                              initialBarangId: barang.id),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffFFF5F5),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: TirtaTheme.rose.withValues(alpha: .35),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: TirtaTheme.rose,
                                              borderRadius: BorderRadius.circular(9),
                                            ),
                                            child: const Icon(
                                              Icons.upload_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: const [
                                                Text(
                                                  "STOK KELUAR",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12,
                                                    color: TirtaTheme.rose,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  "Mutasi stok barang",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Staff & others: Buat Pengajuan button
                            return SizedBox(
                              width: double.infinity,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BuatPengajuanScreen(
                                          initialBarangId: barang.id),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TirtaTheme.primaryBlue.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: TirtaTheme.primaryBlue.withValues(alpha: .35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: TirtaTheme.primaryBlue,
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        child: const Icon(
                                          Icons.note_add_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              "BUAT PENGAJUAN",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                                color: TirtaTheme.primaryBlue,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              "Ajukan permintaan barang ini",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // QR Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _showQRModal(context, barang, theme),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: TirtaTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.qr_code_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Lihat QR Code",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
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
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
            color: (isDark ? Colors.black : TirtaTheme.primaryBlue).withValues(alpha: 0.1),
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
