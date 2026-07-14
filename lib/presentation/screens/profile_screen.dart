import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/custom_snackbar.dart';
import 'laporan_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;
  const ProfileScreen({super.key, this.showBackButton = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditingProfile = false;
  bool isEditingPassword = false;

  // Controllers untuk edit profil
  final TextEditingController namaController = TextEditingController();
  final TextEditingController noTelpController = TextEditingController();

  // Controllers untuk ubah password
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final _formProfileKey = GlobalKey<FormState>();
  final _formPasswordKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user != null) {
      namaController.text = user.nama;
      noTelpController.text = user.noTelp ?? '';
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    noTelpController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Widget buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    Color? bgColor,
    Color? iconColor,
  }) {
    bgColor ??= TirtaTheme.blueSoft;
    iconColor ??= TirtaTheme.primaryBlue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final UserModel? user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: LoadingIndicator(message: 'Memuat profil...')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Curved Gradient Header ──
          _buildProfileHeader(context, user, theme, themeProv),
          // ── Scrollable Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Informasi Pribadi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(28),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Pribadi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Data pribadi Anda',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (isEditingProfile)
                          Form(
                            key: _formProfileKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: namaController,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Nama Lengkap',
                                    prefixIcon:
                                        const Icon(Icons.badge_outlined),
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Nama wajib diisi'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: noTelpController,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 15,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: 'Nomor Telepon',
                                    prefixIcon:
                                        const Icon(Icons.phone_outlined),
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(
                                              () => isEditingProfile = false);
                                          namaController.text = user.nama;
                                          noTelpController.text =
                                              user.noTelp ?? '';
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Text(
                                          'Batal',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (_formProfileKey.currentState!
                                              .validate()) {
                                            final success =
                                                await auth.updateMyProfile(
                                              namaController.text,
                                              noTelpController.text.isEmpty
                                                  ? null
                                                  : noTelpController.text,
                                            );
                                            if (success && context.mounted) {
                                              CustomSnackBar.show(
                                                context: context,
                                                message:
                                                    'Profil berhasil diupdate',
                                                type: SnackBarType.success,
                                              );
                                              setState(() =>
                                                  isEditingProfile = false);
                                            } else if (auth.errorMessage !=
                                                    null &&
                                                context.mounted) {
                                              CustomSnackBar.show(
                                                context: context,
                                                message: auth.errorMessage!,
                                                type: SnackBarType.error,
                                              );
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              TirtaTheme.primaryBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'Simpan',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        else ...[
                          buildInfoItem(
                            icon: Icons.badge_outlined,
                            label: 'Nama Lengkap',
                            value: user.nama,
                            theme: theme,
                          ),
                          const SizedBox(height: 4),
                          buildInfoItem(
                            icon: Icons.qr_code_outlined,
                            label: 'NUP (Nomor Induk Pegawai)',
                            value: user.nup,
                            bgColor: TirtaTheme.blueSoft,
                            iconColor: TirtaTheme.primaryBlue,
                            theme: theme,
                          ),
                          const SizedBox(height: 4),
                          if (user.email != null)
                            buildInfoItem(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: user.email!,
                              bgColor: TirtaTheme.blueSoft,
                              iconColor: TirtaTheme.primaryBlue,
                              theme: theme,
                            ),
                          const SizedBox(height: 4),
                          buildInfoItem(
                            icon: Icons.phone_outlined,
                            label: 'Nomor Telepon',
                            value: user.noTelp ?? '-',
                            bgColor: TirtaTheme.greenSoft,
                            iconColor: TirtaTheme.green,
                            theme: theme,
                          ),
                          const SizedBox(height: 4),
                          if (user.jabatan != null)
                            buildInfoItem(
                              icon: Icons.work_outline,
                              label: 'Jabatan',
                              value: user.jabatan!,
                              bgColor: TirtaTheme.orangeSoft,
                              iconColor: TirtaTheme.orange,
                              theme: theme,
                            ),
                          const SizedBox(height: 4),
                          if (user.departemen != null)
                            buildInfoItem(
                              icon: Icons.apartment_outlined,
                              label: 'Departemen',
                              value: user.departemen!,
                              bgColor: TirtaTheme.redSoft,
                              iconColor: TirtaTheme.rose,
                              theme: theme,
                            ),
                          const SizedBox(height: 4),
                          if (user.subDepartemen != null)
                            buildInfoItem(
                              icon: Icons.domain_outlined,
                              label: 'Sub Departemen',
                              value: user.subDepartemen!,
                              bgColor: TirtaTheme.orangeSoft,
                              iconColor: TirtaTheme.orange,
                              theme: theme,
                            ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 150,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    setState(() => isEditingProfile = true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  foregroundColor: TirtaTheme.primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                label: const Text(
                                  'Edit Profil',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ubah Password - BUTTON ALIGNED WITH LABEL
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(28),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Ubah Kata Sandi',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isEditingPassword)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: TirtaTheme.primaryBlue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ganti kata sandi Anda',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isEditingPassword)
                              ElevatedButton.icon(
                                onPressed: () =>
                                    setState(() => isEditingPassword = true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  foregroundColor: TirtaTheme.primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                icon: const Icon(Icons.key_outlined, size: 18),
                                label: const Text(
                                  'Ubah Sandi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (isEditingPassword)
                          Form(
                            key: _formPasswordKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: oldPasswordController,
                                  obscureText: true,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Kata Sandi Lama',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Kata sandi lama wajib diisi'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: newPasswordController,
                                  obscureText: true,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Kata Sandi Baru',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    hintText: 'Minimal 6 karakter',
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value?.isEmpty ?? true)
                                      return 'Kata sandi baru wajib diisi';
                                    if (value!.length < 6)
                                      return 'Kata sandi minimal 6 karakter';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: true,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Konfirmasi Kata Sandi Baru',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value?.isEmpty ?? true)
                                      return 'Konfirmasi sandi wajib diisi';
                                    if (value != newPasswordController.text) {
                                      return 'Konfirmasi sandi tidak sesuai';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(
                                              () => isEditingPassword = false);
                                          oldPasswordController.clear();
                                          newPasswordController.clear();
                                          confirmPasswordController.clear();
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Text(
                                          'Batal',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (_formPasswordKey.currentState!
                                              .validate()) {
                                            final success =
                                                await auth.changeMyPassword(
                                              oldPasswordController.text,
                                              newPasswordController.text,
                                            );
                                            if (success && context.mounted) {
                                              CustomSnackBar.show(
                                                context: context,
                                                message:
                                                    'Kata sandi berhasil diubah',
                                                type: SnackBarType.success,
                                              );
                                              setState(() =>
                                                  isEditingPassword = false);
                                              oldPasswordController.clear();
                                              newPasswordController.clear();
                                              confirmPasswordController.clear();
                                            } else if (auth.errorMessage !=
                                                    null &&
                                                context.mounted) {
                                              CustomSnackBar.show(
                                                context: context,
                                                message: auth.errorMessage!,
                                                type: SnackBarType.error,
                                              );
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              TirtaTheme.primaryBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'Simpan Sandi',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tanggal Registrasi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(28),
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
                    child: buildInfoItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Tanggal Bergabung',
                      value: user.createdAt != null
                          ? user.createdAt!.substring(0, 10)
                          : '-',
                      bgColor: TirtaTheme.blueSoft,
                      iconColor: TirtaTheme.primaryBlue,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Menu Laporan (hanya untuk role yg punya akses) ──────
                  Builder(builder: (context) {
                    final role = Provider.of<AuthProvider>(context, listen: false).user?.role.toLowerCase() ?? '';
                    if (role == 'staff') return const SizedBox.shrink();
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LaporanScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  TirtaTheme.primaryBlue,
                                  TirtaTheme.skyBlue
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: TirtaTheme.primaryBlue
                                      .withValues(alpha: 0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.bar_chart_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Laporan',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        'Stok, barang masuk & keluar',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Tampilkan konfirmasi sebelum logout
                        final confirm = await showDialog<bool>(
                          context: context,
                          barrierDismissible:
                              false, // Prevent closing when clicking outside
                          builder: (context) => PopScope(
                            canPop: false, // Prevent closing via back button
                            child: Dialog(
                              backgroundColor: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: TirtaTheme.rose
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.logout_outlined,
                                        color: TirtaTheme.rose,
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Yakin Ingin Keluar?',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Anda akan keluar dari akun Tirta Pakuan.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                            ),
                                            child: const Text(
                                              'Batal',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: TirtaTheme.rose,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: const Text(
                                              'Keluar',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          await auth.logout();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TirtaTheme.rose,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.logout_outlined),
                      label: const Text(
                        'Keluar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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
  }

  Widget _buildProfileHeader(
    BuildContext context,
    dynamic user,
    ThemeData theme,
    ThemeProvider themeProv,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    final isDark = themeProv.isDarkMode;

    String getRoleLabel(String r) {
      if (r == 'gudang') return 'Staff Gudang';
      if (r == 'asisten_manager') return 'Asisten Manager';
      if (r == 'manager') return 'Manager';
      if (r == 'staff') return 'Staff';
      return r;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, statusBarHeight + 12, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [TirtaTheme.primaryBlue, TirtaTheme.skyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : TirtaTheme.primaryBlue)
                .withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: back button + title + theme toggle
          Row(
            children: [
              if (widget.showBackButton)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              if (widget.showBackButton) const SizedBox(width: 10),
              const Text(
                'PROFIL SAYA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          // Avatar + name + role row
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6), width: 2),
                ),
                child: Center(
                  child: Text(
                    user?.nama?.isNotEmpty == true
                        ? user!.nama[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nama ?? 'User',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (user?.email != null)
                      Text(
                        user!.email!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  getRoleLabel(user?.role ?? '').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
