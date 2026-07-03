import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../providers/stok_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/custom_snackbar.dart';

class StokMasukScreen extends StatefulWidget {
  final int? initialBarangId;
  const StokMasukScreen({super.key, this.initialBarangId});

  @override
  State<StokMasukScreen> createState() => _StokMasukScreenState();
}

class _StokMasukScreenState extends State<StokMasukScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  int? _selectedBarangId;
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedBarangId = widget.initialBarangId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stokProv = Provider.of<StokProvider>(context, listen: false);
      stokProv.fetchBarangList();
      stokProv.fetchStokMasuk();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _jumlahController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _selectedBarangId = null;
    _jumlahController.clear();
    _keteranganController.clear();
    setState(() {});
  }

  Future<void> _submitStokMasuk() async {
    if (_selectedBarangId == null || _jumlahController.text.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'Pilih barang dan masukkan jumlah!',
        type: SnackBarType.warning,
      );
      return;
    }

    final jumlah = int.tryParse(_jumlahController.text);
    if (jumlah == null || jumlah <= 0) {
      CustomSnackBar.show(
        context: context,
        message: 'Jumlah harus angka valid > 0!',
        type: SnackBarType.warning,
      );
      return;
    }

    final stokProv = Provider.of<StokProvider>(context, listen: false);
    final success = await stokProv.inputStokMasuk(
      barangId: _selectedBarangId!,
      jumlah: jumlah,
      keterangan: _keteranganController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      CustomSnackBar.show(
        context: context,
        message: 'Stok masuk berhasil disimpan!',
        type: SnackBarType.success,
      );
      _resetForm();
      stokProv.fetchStokMasuk();
    } else {
      CustomSnackBar.show(
        context: context,
        message: stokProv.errorMessage ?? 'Gagal menyimpan stok masuk!',
        type: SnackBarType.error,
      );
    }
  }

  void _showDetailModal(dynamic stokMasuk) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add_circle_outline,
                        color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stokMasuk.namaBarang,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          stokMasuk.kodeBarang,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jumlah Masuk',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('+${stokMasuk.jumlah}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                              color: Colors.green)),
                      const SizedBox(width: 4),
                      Text(stokMasuk.satuan,
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Stok Sekarang',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${stokMasuk.stokSekarang}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 24)),
                      const SizedBox(width: 4),
                      Text(stokMasuk.satuan,
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow(
                  Icons.category, 'Kategori', stokMasuk.namaKategori ?? '-'),
              const SizedBox(height: 12),
              _buildDetailRow(
                  Icons.description, 'Keterangan', stokMasuk.keterangan ?? '-'),
              const SizedBox(height: 12),
              _buildDetailRow(
                  Icons.calendar_today,
                  'Tanggal',
                  DateTime.parse(stokMasuk.tanggal)
                      .toLocal()
                      .toString()
                      .substring(0, 16)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Tutup',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stokProv = Provider.of<StokProvider>(context);
    final barangList = stokProv.barangList;

    // Filter riwayat stok masuk
    final filteredList = stokProv.stokMasukList.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.namaBarang
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item.kodeBarang.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Hitung total
    final totalTransaksi = filteredList.length;
    final totalUnit =
        filteredList.fold<int>(0, (sum, item) => sum + item.jumlah);

    // Pagination
    final totalPages = (totalTransaksi / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalTransaksi);
    final currentItems = filteredList.sublist(startIndex, endIndex);

    // Recent items for quick select
    final recentBarangIds =
        stokProv.stokMasukList.take(20).map((e) => e.barangId).toSet().toList();
    final recentBarang = barangList
        .where((b) => recentBarangIds.contains(b.id))
        .take(4)
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Stok Masuk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              stokProv.fetchBarangList();
              stokProv.fetchStokMasuk();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final stokProv = Provider.of<StokProvider>(context, listen: false);
          await stokProv.fetchBarangList();
          await stokProv.fetchStokMasuk();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Transaksi',
                    value: totalTransaksi,
                    color: Colors.blue,
                    icon: Icons.refresh,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Unit Masuk',
                    value: totalUnit,
                    color: Colors.green,
                    icon: Icons.add_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Form Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.add_circle_outline,
                            color: Colors.green, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text('Tambah Stok Masuk',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Select Recent
                  if (recentBarang.isNotEmpty) ...[
                    const Text('Input Cepat',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recentBarang.map((barang) {
                        final isSelected = _selectedBarangId == barang.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBarangId = barang.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green.shade50
                                  : theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.grey.shade300),
                            ),
                            child: Text(
                              barang.namaBarang,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.green
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Select Barang
                  DropdownButtonFormField<int>(
                    value: _selectedBarangId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Pilih Barang',
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? theme.cardColor
                          : Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    items: barangList.map((barang) {
                      return DropdownMenuItem<int>(
                        value: barang.id,
                        child: Text(barang.namaBarang,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBarangId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Jumlah
                  TextField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Jumlah',
                      hintText: '0',
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? theme.cardColor
                          : Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Keterangan
                  TextField(
                    controller: _keteranganController,
                    maxLines: 3,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Keterangan',
                      hintText: 'Catatan (opsional)',
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? theme.cardColor
                          : Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: stokProv.isLoading ? null : _submitStokMasuk,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: stokProv.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Simpan Stok Masuk',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Riwayat Section
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                                _currentPage = 1;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari barang...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              filled: true,
                              fillColor: theme.brightness == Brightness.dark
                                  ? theme.cardColor
                                  : Colors.grey.shade50,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (stokProv.isLoading && stokProv.stokMasukList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: LoadingIndicator(message: 'Memuat riwayat...'),
                    )
                  else if (currentItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Belum ada riwayat stok masuk',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: currentItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = currentItems[index];
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              image: item.foto != null && item.foto!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                          '${AppConstants.uploadUrl}/${item.foto}'),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: item.foto == null || item.foto!.isEmpty
                                ? const Icon(Icons.inventory_2_outlined,
                                    color: Colors.grey)
                                : null,
                          ),
                          title: Text(item.namaBarang,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.kodeBarang,
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                DateTime.parse(item.tanggal)
                                    .toLocal()
                                    .toString()
                                    .substring(0, 16),
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('+${item.jumlah}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 14)),
                          ),
                          onTap: () => _showDetailModal(item),
                        );
                      },
                    ),

                    // Pagination
                    if (totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${startIndex + 1} - $endIndex dari $totalTransaksi',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12)),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _currentPage > 1
                                      ? () => setState(() => _currentPage--)
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                  color: Colors.grey.shade600,
                                ),
                                Text('$_currentPage / $totalPages',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                IconButton(
                                  onPressed: _currentPage < totalPages
                                      ? () => setState(() => _currentPage++)
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;

  const _SummaryCard(
      {required this.title,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value.toString(),
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
