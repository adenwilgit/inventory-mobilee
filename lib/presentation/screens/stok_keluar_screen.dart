import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../providers/stok_provider.dart';
import '../widgets/loading_indicator.dart';

class StokKeluarScreen extends StatefulWidget {
  final int? initialBarangId;
  const StokKeluarScreen({super.key, this.initialBarangId});

  @override
  State<StokKeluarScreen> createState() => _StokKeluarScreenState();
}

class _StokKeluarScreenState extends State<StokKeluarScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stokProv = Provider.of<StokProvider>(context, listen: false);
      stokProv.fetchBarangList();
      stokProv.fetchStokKeluar();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }



  void _showDetailModal(dynamic stokKeluar) {
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
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.remove_circle_outline,
                        color: Colors.red, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stokKeluar.namaBarang,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          stokKeluar.kodeBarang,
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
                  const Text('Jumlah Keluar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('-${stokKeluar.jumlah}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                              color: Colors.red)),
                      const SizedBox(width: 4),
                      Text(stokKeluar.satuan,
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
                      Text('${stokKeluar.stokSekarang}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 24)),
                      const SizedBox(width: 4),
                      Text(stokKeluar.satuan,
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow(
                  Icons.category, 'Kategori', stokKeluar.namaKategori ?? '-'),
              const SizedBox(height: 12),
              _buildDetailRow(
                  Icons.location_on, 'Lokasi Rak', stokKeluar.lokasiRak ?? '-'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.description, 'Keterangan',
                  stokKeluar.keterangan ?? '-'),
              const SizedBox(height: 12),
              _buildDetailRow(
                  Icons.calendar_today,
                  'Tanggal',
                  DateTime.parse(stokKeluar.tanggal)
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

    // Filter riwayat stok keluar
    final filteredList = stokProv.stokKeluarList.where((item) {
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
    final dariPengajuan = filteredList
        .where((item) => item.pengajuanId != null && item.pengajuanId! > 0)
        .length;

    // Pagination
    final totalPages = (totalTransaksi / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalTransaksi);
    final currentItems = filteredList.sublist(startIndex, endIndex);



    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text('Stok Keluar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              stokProv.fetchBarangList();
              stokProv.fetchStokKeluar();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final stokProv = Provider.of<StokProvider>(context, listen: false);
          await stokProv.fetchBarangList();
          await stokProv.fetchStokKeluar();
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
                    color: Colors.red,
                    icon: Icons.refresh,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Unit Keluar',
                    value: totalUnit,
                    color: Colors.orange,
                    icon: Icons.remove_circle_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'Dari Pengajuan',
                    value: dariPengajuan,
                    color: Colors.blue,
                    icon: Icons.checklist,
                  ),
                ),
              ],
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
                  if (stokProv.isLoading && stokProv.stokKeluarList.isEmpty)
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
                          Text('Belum ada riwayat stok keluar',
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
                              if (item.pengajuanId != null &&
                                  item.pengajuanId! > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Via Pengajuan ${item.nomorPengajuan ?? ''}',
                                    style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 2),
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
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('-${item.jumlah}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value.toString(),
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
