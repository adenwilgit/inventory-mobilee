import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nupController = TextEditingController();
  final _passwordController = TextEditingController();
  Timer? _nupDebounce;
  bool _hasResetLoginState = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated && !_hasResetLoginState) {
      _hasResetLoginState = true;
      _nupController.clear();
      _passwordController.clear();
      // Defer checkNup to after build to avoid calling notifyListeners
      // while widgets are being built (prevents "setState during build").
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<AuthProvider>(context, listen: false).checkNup('');
        }
      });
    }
  }

  @override
  void dispose() {
    _nupDebounce?.cancel();
    _nupController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onNupChanged(String value) {
    _nupDebounce?.cancel();
    _nupDebounce = Timer(const Duration(milliseconds: 500), () {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        Provider.of<AuthProvider>(context, listen: false).checkNup('');
      } else if (trimmed.length >= 2) {
        Provider.of<AuthProvider>(context, listen: false).checkNup(trimmed);
      }
    });
  }

  Future<void> _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.login(
        _nupController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        CustomSnackBar.show(
          context: context,
          message: 'Login berhasil! Selamat datang.',
          type: SnackBarType.success,
        );
        // Tunggu sebentar agar snackbar terlihat sebelum navigasi
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        CustomSnackBar.show(
          context: context,
          message:
              auth.errorMessage ?? 'Login gagal. Periksa NUP & Password Anda.',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final accentColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'public/logo-premium.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.water_drop,
                            size: 80,
                            color: accentColor,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'AKSES ',
                          style: GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade900,
                            letterSpacing: -1.4,
                          ),
                        ),
                        TextSpan(
                          text: 'MASUK',
                          style: GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: -1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SILAKAN MASUK UNTUK MENGELOLA DATA INVENTARIS GUDANG PDAM TIRTA PAKUAN BOGOR.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.7,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 26,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomInput(
                            label: 'NUP Pegawai',
                            hint: 'Masukkan NUP Anda',
                            controller: _nupController,
                            prefixIcon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            onChanged: _onNupChanged,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'NUP wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          if (auth.isCheckingNup)
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 4, bottom: 6),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Memeriksa NUP...',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (auth.previewNama != null &&
                              auth.previewRole != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 18),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor,
                                    accentColor.withValues(alpha: 0.92),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        auth.previewNama!
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          auth.previewNama!.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          auth.previewRole!.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_nupController.text.trim().isNotEmpty &&
                              auth.previewError != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 18),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    auth.previewError!.contains('Super Admin')
                                        ? Colors.red.shade50
                                        : Colors.orange.shade50,
                                border: Border.all(
                                  color:
                                      auth.previewError!.contains('Super Admin')
                                          ? Colors.red.shade300
                                          : Colors.orange.shade300,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    auth.previewError!.contains('Super Admin')
                                        ? Icons.error_outline
                                        : Icons.warning_outlined,
                                    color: auth.previewError!
                                            .contains('Super Admin')
                                        ? Colors.red.shade600
                                        : Colors.orange.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      auth.previewError!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: auth.previewError!
                                                .contains('Super Admin')
                                            ? Colors.red.shade700
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          CustomInput(
                            label: 'Kata Sandi',
                            hint: 'Masukkan kata sandi Anda',
                            controller: _passwordController,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kata sandi wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 26),
                          CustomButton(
                            text: 'MASUK KE SISTEM',
                            isLoading: auth.isLoading,
                            onTap: _submitLogin,
                            color: accentColor,
                            textColor: Colors.white,
                            icon: Icons.arrow_forward,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '© 2026 PDAM TIRTA PAKUAN BOGOR',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
