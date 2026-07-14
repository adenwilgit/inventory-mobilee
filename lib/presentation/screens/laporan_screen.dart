import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/storage_helper.dart';
import '../../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

// ─── Model sederhana untuk jenis laporan ─────────────────────────────────────
class _JenisLaporan {
  final String value;
  final String label;
  final String desc;
  final IconData icon;
  final List<Color> gradient;

  const _JenisLaporan({
    required this.value,
    required this.label,
    required this.desc,
    required this.icon,
    required this.gradient,
  });
}

// ─── Screen Utama ─────────────────────────────────────────────────────────────
class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();

  String _selectedJenis = 'stok';
  DateTime? _startDate;
  DateTime? _endDate;

  List<dynamic> _data = [];
  bool _loading = false;
  bool _loaded = false;
  String? _errorMessage;
  bool _exportLoading = false;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_JenisLaporan> _getReportTypes(String role) {
    final list = <_JenisLaporan>[
      const _JenisLaporan(
        value: 'stok',
        label: 'Stok Saat Ini',
        desc: 'Posisi stok barang terkini',
        icon: Icons.inventory_2_rounded,
        gradient: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
      ),
    ];
    if (role == 'admin' || role == 'gudang') {
      list.add(const _JenisLaporan(
        value: 'masuk',
        label: 'Barang Masuk',
        desc: 'Penerimaan dari supplier',
        icon: Icons.trending_up_rounded,
        gradient: [Color(0xFF10B981), Color(0xFF14B8A6)],
      ));
    }
    list.add(const _JenisLaporan(
      value: 'keluar',
      label: 'Barang Keluar',
      desc: 'Pengeluaran per pengajuan',
      icon: Icons.trending_down_rounded,
      gradient: [Color(0xFFF43F5E), Color(0xFFEC4899)],
    ));
    return list;
  }

  void _setPreset(int days) {
    final now = DateTime.now();
    setState(() {
      _endDate = now;
      _startDate = now.subtract(Duration(days: days));
    });
  }

  void _setPresetThisMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
    });
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatDateDisplay(DateTime dt) {
    const bulan = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: TirtaTheme.primaryBlue,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _fetchLaporan() async {
    if (_selectedJenis != 'stok' && (_startDate == null || _endDate == null)) {
      _showError('Pilih rentang tanggal terlebih dahulu.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _loaded = false;
    });

    try {
      final dynamic response;
      if (_selectedJenis == 'stok') {
        response = await _api.get(Endpoints.laporanStok);
      } else {
        final endpoint = _selectedJenis == 'masuk'
            ? Endpoints.laporanMasuk
            : Endpoints.laporanKeluar;
        response = await _api.get(endpoint, queryParameters: {
          'start': _formatDate(_startDate!),
          'end': _formatDate(_endDate!),
        });
      }

      setState(() {
        _data = response.data as List<dynamic>;
        _loaded = true;
        _loading = false;
        _searchQuery = '';
        _searchController.clear();
      });
      _animController.forward(from: 0);
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _handleExport(String format) async {
    if (_selectedJenis != 'stok' && (_startDate == null || _endDate == null)) {
      _showError('Pilih rentang tanggal terlebih dahulu sebelum export.');
      return;
    }
    setState(() => _exportLoading = true);

    try {
      // Tentukan endpoint
      String endpoint;
      String fileExt = format == 'excel' ? 'xlsx' : 'pdf';
      Map<String, dynamic>? queryParams;

      if (_selectedJenis == 'stok') {
        endpoint = format == 'excel'
            ? Endpoints.exportExcelStok
            : Endpoints.exportPdfStok;
      } else if (_selectedJenis == 'masuk') {
        endpoint = format == 'excel'
            ? Endpoints.exportExcelMasuk
            : Endpoints.exportPdfMasuk;
        queryParams = {
          'start': _formatDate(_startDate!),
          'end': _formatDate(_endDate!),
        };
      } else {
        endpoint = format == 'excel'
            ? Endpoints.exportExcelKeluar
            : Endpoints.exportPdfKeluar;
        queryParams = {
          'start': _formatDate(_startDate!),
          'end': _formatDate(_endDate!),
        };
      }

      // Nama file
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll('T', '_')
          .replaceAll(':', '-')
          .substring(0, 19);
      final fileName =
          'laporan_${_selectedJenis}_$ts.$fileExt';

      // Download via Dio langsung (pakai responseType bytes)
      final storage = StorageHelper();
      final token = await storage.getToken();
      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      final response = await dio.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      // Simpan file ke direktori Downloads / dokumen
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.data as List<int>);

      setState(() => _exportLoading = false);

      if (mounted) {
        // Tampilkan snackbar sukses + tombol buka file
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File $fileName berhasil disimpan!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(filePath),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      setState(() => _exportLoading = false);
      _showError('Gagal mengekspor laporan: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  List<dynamic> get _filteredData {
    if (_searchQuery.isEmpty) return _data;
    final q = _searchQuery.toLowerCase();
    return _data.where((item) {
      return item.toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = auth.user?.role.toLowerCase() ?? '';
    final reportTypes = _getReportTypes(role);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ─── AppBar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            elevation: 0,
            backgroundColor: TirtaTheme.primaryBlue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [TirtaTheme.primaryBlue, TirtaTheme.skyBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.bar_chart_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Laporan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Data & analisis inventaris',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Pilih Jenis Laporan ─────────────────────────────────
                  Text(
                    'Pilih Jenis Laporan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: reportTypes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final jenis = reportTypes[i];
                        final isSelected = _selectedJenis == jenis.value;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedJenis = jenis.value;
                              _loaded = false;
                              _data = [];
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 130,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: jenis.gradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : theme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: theme.dividerColor,
                                      width: 1.5,
                                    ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: jenis.gradient[0]
                                            .withValues(alpha: 0.4),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  jenis.icon,
                                  color: isSelected
                                      ? Colors.white
                                      : jenis.gradient[0],
                                  size: 28,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      jenis.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: isSelected
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      jenis.desc,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isSelected
                                            ? Colors.white70
                                            : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ─── Filter Tanggal (hanya tampil kalau bukan stok) ──────
                  if (_selectedJenis != 'stok') ...[
                    const SizedBox(height: 20),
                    Text(
                      'Filter Tanggal',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tombol Preset Cepat
                    Row(
                      children: [
                        _PresetButton(
                          label: '7 Hari',
                          onTap: () => _setPreset(7),
                        ),
                        const SizedBox(width: 8),
                        _PresetButton(
                          label: '30 Hari',
                          onTap: () => _setPreset(30),
                        ),
                        const SizedBox(width: 8),
                        _PresetButton(
                          label: 'Bulan Ini',
                          onTap: () => _setPresetThisMonth(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // DatePicker manual
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerCard(
                            label: 'Dari Tanggal',
                            date: _startDate,
                            onTap: () => _pickDate(true),
                            formatDisplay: _formatDateDisplay,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DatePickerCard(
                            label: 'Sampai Tanggal',
                            date: _endDate,
                            onTap: () => _pickDate(false),
                            formatDisplay: _formatDateDisplay,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ─── Tombol Tampilkan Laporan ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _fetchLaporan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TirtaTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search_rounded),
                      label: Text(
                        _loading ? 'Memuat...' : 'Tampilkan Laporan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  // ─── Error ───────────────────────────────────────────────
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ─── Hasil Laporan ───────────────────────────────────────
                  if (_loaded) ...[
                    const SizedBox(height: 24),

                    // Info bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hasil Laporan',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${_filteredData.length} dari ${_data.length} data',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: TirtaTheme.blueSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_data.length} item',
                            style: const TextStyle(
                              color: TirtaTheme.primaryBlue,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Cari data laporan...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.cardColor,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tombol Export Excel & PDF
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportLoading ? null : () => _handleExport('excel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.table_view_rounded, size: 18),
                            label: const Text(
                              'Export Excel',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportLoading ? null : () => _handleExport('pdf'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF43F5E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                            label: const Text(
                              'Export PDF',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_exportLoading) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(
                        color: TirtaTheme.primaryBlue,
                        backgroundColor: TirtaTheme.blueSoft,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Data list
                    if (_filteredData.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                size: 60,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada data ditemukan',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredData.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final item =
                                _filteredData[i] as Map<String, dynamic>;
                            return _LaporanCard(
                              item: item,
                              jenis: _selectedJenis,
                              theme: theme,
                              themeProv: themeProv,
                              index: i,
                            );
                          },
                        ),
                      ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget Tombol Preset Tanggal ─────────────────────────────────────────────
class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: TirtaTheme.blueSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: TirtaTheme.primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Widget DatePicker Card ───────────────────────────────────────────────────
class _DatePickerCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final String Function(DateTime) formatDisplay;
  final ThemeData theme;

  const _DatePickerCard({
    required this.label,
    required this.date,
    required this.onTap,
    required this.formatDisplay,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: date != null
                ? TirtaTheme.primaryBlue.withValues(alpha: 0.5)
                : theme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: date != null
                  ? TirtaTheme.primaryBlue
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    date != null ? formatDisplay(date!) : 'Pilih tanggal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: date != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget Card Data Laporan ─────────────────────────────────────────────────
class _LaporanCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String jenis;
  final ThemeData theme;
  final ThemeProvider themeProv;
  final int index;

  const _LaporanCard({
    required this.item,
    required this.jenis,
    required this.theme,
    required this.themeProv,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final namaBarang = item['nama_barang']?.toString() ?? '-';
    final kodeBarang = item['kode_barang']?.toString() ?? '-';
    final satuan = item['satuan']?.toString() ?? 'Pcs';

    Widget trailing;
    Widget subtitle;

    if (jenis == 'stok') {
      final stok = item['stok'] ?? 0;
      final stokInt = stok is int ? stok : int.tryParse(stok.toString()) ?? 0;
      Color stokColor;
      if (stokInt <= 0) {
        stokColor = Colors.red;
      } else if (stokInt <= 10) {
        stokColor = Colors.orange;
      } else {
        stokColor = Colors.green;
      }
      trailing = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$stokInt',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: stokColor,
            ),
          ),
          Text(
            satuan,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
      subtitle = Text(
        kodeBarang,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    } else if (jenis == 'masuk') {
      final jumlah = item['jumlah'] ?? 0;
      final keterangan = item['keterangan']?.toString() ?? '-';
      final tanggal = item['tanggal']?.toString().substring(0, 10) ?? '-';
      trailing = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle_rounded,
                  color: Colors.green, size: 14),
              const SizedBox(width: 4),
              Text(
                '$jumlah $satuan',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          Text(
            tanggal,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
      subtitle = Text(
        keterangan,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      // keluar
      final jumlah = item['jumlah'] ?? 0;
      final pemohon = item['pemohon']?.toString() ?? '-';
      final unit = item['unit']?.toString() ?? '-';
      final tanggal = item['tanggal']?.toString().substring(0, 10) ?? '-';
      trailing = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.remove_circle_rounded,
                  color: Colors.red, size: 14),
              const SizedBox(width: 4),
              Text(
                '$jumlah $satuan',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          Text(
            tanggal,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
      subtitle = Text(
        '$pemohon · $unit',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: themeProv.isDarkMode
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nomor urut
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: TirtaTheme.blueSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: TirtaTheme.primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaBarang,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                subtitle,
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
