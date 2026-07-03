import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/auth_provider.dart';
import '../providers/stok_provider.dart';
import '../../config/constants.dart';

import '../widgets/custom_input.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/custom_snackbar.dart';

class ScanQrScreen extends StatefulWidget {
  final bool isActive;
  const ScanQrScreen({super.key, this.isActive = true});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  late MobileScannerController _scannerController;

  bool _isProcessing = false;
  Key _scannerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      autoStart: false,
    );
    if (widget.isActive) {
      _startScanner();
    }
  }

  @override
  void didUpdateWidget(covariant ScanQrScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startScanner();
      } else {
        _stopScanner();
      }
    }
  }

  Future<void> _startScanner() async {
    try {
      await _scannerController.start();
    } catch (e) {
      debugPrint('Error starting scanner: $e');
    }
  }

  Future<void> _stopScanner() async {
    try {
      await _scannerController.stop();
    } catch (e) {
      debugPrint('Error stopping scanner: $e');
    }
  }

  Future<void> _restartScanner() async {
    try {
      _scannerController.stop();
      _scannerController.dispose();
    } catch (e) {
      // Ignore errors during stop/dispose
    }

    setState(() {
      _scannerKey = UniqueKey();
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        autoStart: false,
      );
      _isProcessing = false;
    });

    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isActive) {
          _startScanner();
        }
      });
    }
  }

  @override
  void dispose() {
    try {
      _scannerController.dispose();
    } catch (e) {
      // Ignore
    }
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    String? kodeBarang = "";
    final decodedText = barcodes.first.rawValue;
    if (decodedText == null) return;

    // Parse JSON jika QR code berisi JSON seperti di web
    if (decodedText.startsWith("{")) {
      try {
        final parsed = json.decode(decodedText);
        kodeBarang = parsed['kode_barang'] ?? parsed['kodeBarang'];
      } catch (e) {
        kodeBarang = decodedText;
      }
    } else {
      kodeBarang = decodedText;
    }

    if (kodeBarang == null || kodeBarang.trim().isEmpty) return;

    await _processBarcode(kodeBarang.trim());
  }

  Future<void> _processBarcode(String kodeBarang) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final stokProv = Provider.of<StokProvider>(context, listen: false);
    final match = await stokProv.queryBarangByCode(kodeBarang);

    if (!mounted) return;

    if (match != null) {
      // Temukan barang! Tampilkan Bottom Sheet Aksi Gudang
      try {
        _scannerController.stop();
      } catch (e) {
        // Ignore if scanner already stopped
      }
      _showBarangActionSheet(match);
    } else {
      // Tidak terdaftar
      CustomSnackBar.show(
        context: context,
        message: stokProv.errorMessage ?? 'Barang tidak ditemukan.',
        type: SnackBarType.warning,
      );
      // Tunggu 2 detik sebelum memindai lagi
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showManualInputDialog() {
    final TextEditingController kodeController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Input Kode Barang',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan kode barang secara manual',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: kodeController,
                decoration: InputDecoration(
                  labelText: 'Kode Barang',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final kode = kodeController.text.trim();
                        if (kode.isEmpty) {
                          CustomSnackBar.show(
                            context: context,
                            message: 'Kode barang tidak boleh kosong!',
                            type: SnackBarType.warning,
                          );
                          return;
                        }
                        Navigator.pop(context);
                        await _processBarcode(kode);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Cari Barang'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBarangActionSheet(dynamic barang) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final role = authProv.user?.role.toLowerCase() ?? '';
    final isGudang = role == 'gudang';

    if (!isGudang) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? theme.cardColor : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: barang.foto != null && barang.foto!.isNotEmpty
                            ? Image.network(
                                '${AppConstants.uploadUrl}/${barang.foto}',
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 64,
                                  height: 64,
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.inventory_2_outlined,
                                      size: 28, color: Colors.grey),
                                ),
                              )
                            : Container(
                                width: 64,
                                height: 64,
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.inventory_2_outlined,
                                    size: 28, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              barang.namaBarang,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              'Kode: ${barang.kodeBarang} • Rak: ${barang.lokasiRak ?? "-"}',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12),
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
                      const Text('Kategori:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${barang.kategori ?? "-"}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Stok Tersedia:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${barang.stokTersedia ?? barang.stok ?? 0} ${barang.satuan}',
                        style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/buat-pengajuan', arguments: barang.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.note_add_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Ajukan Barang Ini',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ).then((_) {
        if (mounted && widget.isActive) {
          _startScanner();
        }
        setState(() {
          _isProcessing = false;
        });
      });
      return;
    }

    final qtyController = TextEditingController();
    final ketController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
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
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: barang.foto != null && barang.foto!.isNotEmpty
                              ? Image.network(
                                  '${AppConstants.uploadUrl}/${barang.foto}',
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 64,
                                    height: 64,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.inventory_2_outlined,
                                        size: 28, color: Colors.grey),
                                  ),
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      width: 64,
                                      height: 64,
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: 64,
                                  height: 64,
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.inventory_2_outlined,
                                      size: 28, color: Colors.grey),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                barang.namaBarang,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                'Kode: ${barang.kodeBarang} • Rak: ${barang.lokasiRak ?? "-"}',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 12),
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
                        const Text('Stok Saat Ini:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${barang.stok} ${barang.satuan}',
                          style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Form Input Cepat
                    CustomInput(
                      label: 'Jumlah Kuantitas',
                      hint: 'Masukkan jumlah',
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                    ),
                    CustomInput(
                      label: 'Catatan Mutasi',
                      hint: 'Contoh: Supplier PO / Penyesuaian fisik',
                      controller: ketController,
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _executeMutasi(barang.id,
                            qtyController.text, ketController.text, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(width: 6),
                            Text('Stok Masuk',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pengurangan stok (Stok Keluar) harus diajukan secara resmi melalui menu Pengajuan Barang.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.orange.shade200 : Colors.orange.shade800,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Hidupkan scanner lagi saat Bottom Sheet ditutup jika halaman masih aktif
      if (mounted && widget.isActive) {
        _startScanner();
      }
      setState(() {
        _isProcessing = false;
      });
    });
  }

  void _executeMutasi(
      int barangId, String qtyStr, String ket, bool isMasuk) async {
    final qty = int.tryParse(qtyStr);
    if (qty == null || qty <= 0) {
      CustomSnackBar.show(
        context: context,
        message: 'Jumlah kuantitas harus angka valid > 0!',
        type: SnackBarType.warning,
      );
      return;
    }

    final stokProv = Provider.of<StokProvider>(context, listen: false);
    final success = isMasuk
        ? await stokProv.inputStokMasuk(
            barangId: barangId, jumlah: qty, keterangan: ket.trim())
        : await stokProv.inputStokKeluar(
            barangId: barangId, jumlah: qty, keterangan: ket.trim());

    if (!mounted) return;

    Navigator.pop(context); // Tutup bottom sheet

    if (success) {
      CustomSnackBar.show(
        context: context,
        message:
            'Pencatatan Stok ${isMasuk ? "Masuk" : "Keluar"} berhasil disinkronkan ke database!',
        type: SnackBarType.success,
      );
    } else {
      CustomSnackBar.show(
        context: context,
        message: stokProv.errorMessage ?? 'Gagal memperbarui stok.',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final role = user?.role.toLowerCase() ?? '';

    // Proteksi Keamanan Logis: Gudang, Admin, Staff, Asmen, Manager diizinkan
    final isAllowed = role == 'gudang' ||
        role == 'admin' ||
        role == 'staff' ||
        role == 'asisten_manager' ||
        role == 'manager';

    if (!isAllowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan QR Code')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gpp_bad, color: Colors.redAccent, size: 64),
                SizedBox(height: 16),
                Text(
                  'Akses Ditolak',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Fitur memindai (Scan QR Code) hanya diizinkan untuk peran yang terdaftar di sistem.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isGudang = role == 'gudang';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(isGudang ? 'Pemindai Barang Gudang' : 'Scan QR Code Barang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartScanner,
            tooltip: 'Refresh Kamera',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            key: _scannerKey,
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              final isPermissionDenied =
                  error.errorCode == MobileScannerErrorCode.permissionDenied;

              return Container(
                color: Colors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPermissionDenied
                              ? Icons.no_photography
                              : Icons.error_outline,
                          color: Colors.red,
                          size: 72,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isPermissionDenied
                              ? 'Izin Kamera Belum Diizinkan'
                              : 'Gagal memulai kamera',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (isPermissionDenied) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cara Mengatasi:',
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '• Buka Settings → Apps → Inventaris → Permissions',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  '• Aktifkan izin "Camera"',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  '• Kembali dan tekan "Coba Lagi"',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ] else if (kIsWeb) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.yellow.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.yellow.withValues(alpha: 0.3)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tips untuk Web:',
                                  style: TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '• Pastikan Anda mengizinkan akses kamera',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  '• Gunakan HTTPS (bukan HTTP)',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  '• Klik tombol refresh di kanan atas',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                             error.errorDetails?.message ?? error.toString(),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _restartScanner,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => _showManualInputDialog(),
                          icon: const Icon(Icons.keyboard, color: Colors.white70),
                          label: const Text(
                            'Input Kode Manual',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.75), width: 3),
                borderRadius: BorderRadius.circular(24),
                color: Colors.black.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                isGudang
                    ? 'Arahkan kamera ke QR Code barang pada rak atau material untuk merekam Stok Masuk / Stok Keluar secara cepat.'
                    : 'Arahkan kamera ke QR Code barang pada rak atau material untuk melihat informasi detail atau mengajukan barang.',
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Siap memindai',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pastikan QR Code terlihat jelas di dalam kotak scanner.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showManualInputDialog(),
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Input Kode Manual'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const LoadingIndicator(
                  message: 'Mencari barang di database...',
                  color: Colors.white),
            ),
        ],
      ),
    );
  }
}
