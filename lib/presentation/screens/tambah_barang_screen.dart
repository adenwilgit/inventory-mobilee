import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../providers/stok_provider.dart';
import '../providers/theme_provider.dart';
import '../../data/models/kategori_model.dart';
import '../../data/models/satuan_model.dart';
import '../widgets/custom_snackbar.dart';

class TambahBarangScreen extends StatefulWidget {
  const TambahBarangScreen({super.key});

  @override
  State<TambahBarangScreen> createState() => _TambahBarangScreenState();
}

class _TambahBarangScreenState extends State<TambahBarangScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaBarangController = TextEditingController();
  final _stokMinimumController = TextEditingController();
  final _stokAwalController = TextEditingController();
  final _lokasiController = TextEditingController();
  KategoriModel? _selectedKategori;
  SatuanModel? _selectedSatuan;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stokProv = Provider.of<StokProvider>(context, listen: false);
      if (stokProv.kategoriList.isEmpty) {
        stokProv.fetchKategoriList();
      }
      if (stokProv.satuanList.isEmpty) {
        stokProv.fetchSatuanList();
      }
    });
  }

  @override
  void dispose() {
    _namaBarangController.dispose();
    _stokMinimumController.dispose();
    _stokAwalController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategori == null) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Kategori harus dipilih!',
          type: SnackBarType.warning,
        );
      }
      return;
    }
    if (_selectedSatuan == null) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Satuan harus dipilih!',
          type: SnackBarType.warning,
        );
      }
      return;
    }

    final stokProv = Provider.of<StokProvider>(context, listen: false);
    final success = await stokProv.createBarang(
      namaBarang: _namaBarangController.text.trim(),
      stok: int.tryParse(_stokAwalController.text.trim()) ?? 0,
      stokMinimum: int.tryParse(_stokMinimumController.text.trim()) ?? 0,
      satuan: _selectedSatuan!.namaSatuan,
      kategoriId: _selectedKategori!.id,
      lokasiRak: _lokasiController.text.trim(),
    );

    if (mounted) {
      if (success) {
        CustomSnackBar.show(
          context: context,
          message: 'Barang berhasil ditambahkan!',
          type: SnackBarType.success,
        );
        Navigator.pop(context);
      } else {
        CustomSnackBar.show(
          context: context,
          message: stokProv.errorMessage ?? 'Gagal menambah barang!',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: themeProv.isDarkMode
                              ? Colors.transparent
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrasi Barang Baru',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'LENGKAPI INFORMASI BARANG DENGAN BENAR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<StokProvider>(
                builder: (context, stokProv, child) {
                  return SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Upload Image
                          Text(
                            'VISUAL BARANG',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: double.infinity,
                              height: 220,
                              decoration: BoxDecoration(
                                color: themeProv.isDarkMode
                                    ? TirtaTheme.slate800
                                    : TirtaTheme.slate100,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: themeProv.isDarkMode
                                      ? TirtaTheme.slate600
                                      : TirtaTheme.slate300,
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(32),
                                      child: Image.file(
                                        File(_selectedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 72,
                                          height: 72,
                                          decoration: BoxDecoration(
                                            color: themeProv.isDarkMode
                                                ? TirtaTheme.slate700
                                                : TirtaTheme.slate200,
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                          child: Icon(
                                            Icons.upload_outlined,
                                            size: 36,
                                            color: themeProv.isDarkMode
                                                ? TirtaTheme.slate400
                                                : TirtaTheme.slate500,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'UNGGAH FOTO',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: themeProv.isDarkMode
                                                ? TirtaTheme.slate400
                                                : TirtaTheme.slate500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Klik atau drag kesini',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: themeProv.isDarkMode
                                                ? TirtaTheme.slate500
                                                : TirtaTheme.slate400,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Nama Barang
                          _buildLabel('NAMA BARANG', theme),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _namaBarangController,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Contoh: Pipa Rucika 3 Inch',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                              ),
                              filled: true,
                              fillColor: theme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: themeProv.isDarkMode
                                      ? TirtaTheme.slate700
                                      : TirtaTheme.slate200,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: TirtaTheme.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama barang harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Kategori & Satuan
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('KATEGORI', theme),
                                    const SizedBox(height: 8),
                                    if (stokProv.kategoriList.isEmpty)
                                      const Center(
                                          child: CircularProgressIndicator())
                                    else
                                      DropdownButtonFormField<KategoriModel>(
                                        value: _selectedKategori,
                                        items: stokProv.kategoriList
                                            .map((kategori) {
                                          return DropdownMenuItem(
                                            value: kategori,
                                            child: Text(
                                              kategori.namaKategori,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedKategori = value;
                                          });
                                        },
                                        isExpanded: true,
                                        hint: Text(
                                          '-- Pilih Kategori --',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        dropdownColor: theme.cardColor,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: theme.cardColor,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: themeProv.isDarkMode
                                                  ? TirtaTheme.slate700
                                                  : TirtaTheme.slate200,
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: TirtaTheme.primaryBlue,
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('SATUAN', theme),
                                    const SizedBox(height: 8),
                                    if (stokProv.satuanList.isEmpty)
                                      const Center(
                                          child: CircularProgressIndicator())
                                    else
                                      DropdownButtonFormField<SatuanModel>(
                                        value: _selectedSatuan,
                                        items:
                                            stokProv.satuanList.map((satuan) {
                                          return DropdownMenuItem(
                                            value: satuan,
                                            child: Text(
                                              satuan.namaSatuan,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedSatuan = value;
                                          });
                                        },
                                        isExpanded: true,
                                        hint: Text(
                                          '-- Pilih Satuan --',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        dropdownColor: theme.cardColor,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: theme.cardColor,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: themeProv.isDarkMode
                                                  ? TirtaTheme.slate700
                                                  : TirtaTheme.slate200,
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: TirtaTheme.primaryBlue,
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Batas Minimum Stok & Stok Awal
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(
                                      'BATAS MINIMUM STOK',
                                      theme,
                                      isBlue: true,
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _stokMinimumController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Contoh: 10',
                                        hintStyle: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.4),
                                        ),
                                        filled: true,
                                        fillColor: theme.cardColor,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: themeProv.isDarkMode
                                                ? TirtaTheme.slate700
                                                : TirtaTheme.slate200,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: TirtaTheme.primaryBlue,
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Stok minimum harus diisi';
                                        }
                                        if (int.tryParse(value.trim()) ==
                                            null) {
                                          return 'Harus angka';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(
                                      'STOK AWAL FISIK',
                                      theme,
                                      isBlue: true,
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _stokAwalController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Contoh: 100',
                                        hintStyle: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.4),
                                        ),
                                        filled: true,
                                        fillColor: theme.cardColor,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: themeProv.isDarkMode
                                                ? TirtaTheme.slate700
                                                : TirtaTheme.slate200,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: TirtaTheme.primaryBlue,
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Stok awal harus diisi';
                                        }
                                        if (int.tryParse(value.trim()) ==
                                            null) {
                                          return 'Harus angka';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Lokasi Rak/Gudang
                          _buildLabel('LOKASI RAK / GUDANG', theme),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _lokasiController,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'CONTOH: RAK-01-A',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                              ),
                              filled: true,
                              fillColor: theme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: themeProv.isDarkMode
                                      ? TirtaTheme.slate700
                                      : TirtaTheme.slate200,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: TirtaTheme.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    TirtaTheme.primaryBlue,
                                    TirtaTheme.skyBlue,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: TirtaTheme.primaryBlue
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'REGISTRASI BARANG BARU',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme, {bool isBlue = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: isBlue
            ? TirtaTheme.primaryBlue
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}
