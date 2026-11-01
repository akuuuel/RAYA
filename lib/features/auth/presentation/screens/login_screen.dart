import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool isLoginMode;

  const LoginScreen({
    super.key,
    this.isLoginMode = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late bool _isLogin;
  bool _useOtpMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLoginMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email.trim());
  }

  Future<void> _handleAction() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _localError = 'Alamat email wajib diisi.');
      return;
    }

    if (!_validateEmail(email)) {
      setState(() => _localError = 'Format email tidak valid.');
      return;
    }

    // Mode Masuk via OTP (Cadangan jika lupa password)
    if (_useOtpMode) {
      setState(() => _localError = null);
      final success = await ref.read(authControllerProvider.notifier).sendOtp(
            email,
            shouldCreateUser: !_isLogin,
          );
      if (!mounted) return;
      if (success) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(email: email),
          ),
        );
      }
      return;
    }

    // Validasi Password
    if (password.isEmpty) {
      setState(() => _localError = 'Kata sandi wajib diisi.');
      return;
    }

    if (password.length < 6) {
      setState(() => _localError = 'Kata sandi minimal 6 karakter.');
      return;
    }

    // Jika mode Daftar Akun Baru: cek konfirmasi password
    if (!_isLogin) {
      final confirmPassword = _confirmPasswordController.text;
      if (password != confirmPassword) {
        setState(() => _localError = 'Konfirmasi kata sandi tidak cocok.');
        return;
      }

      setState(() => _localError = null);
      final success = await ref.read(authControllerProvider.notifier).signUpWithPassword(
            email: email,
            password: password,
          );
      if (!mounted) return;
      if (success) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(email: email),
          ),
        );
      }
      return;
    }

    // Mode Masuk Akun Lama via Email + Password (Instan)
    setState(() => _localError = null);
    final success = await ref.read(authControllerProvider.notifier).signInWithPassword(
          email: email,
          password: password,
        );
    if (!mounted) return;

    if (success) {
      // Kembali ke awal / langsung ke beranda
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final errorToDisplay = _localError ?? authState.errorMessage;

    String title;
    String subtitle;
    String buttonText;

    if (_useOtpMode) {
      title = 'Masuk dengan Kode OTP';
      subtitle = 'Masukkan email untuk menerima kode OTP verifikasi.';
      buttonText = 'Kirim Kode OTP';
    } else if (_isLogin) {
      title = 'Masuk ke Akun';
      subtitle = 'Masukkan email dan kata sandi Anda untuk masuk langsung.';
      buttonText = 'Masuk';
    } else {
      title = 'Daftar Akun Baru';
      subtitle = 'Buat akun dengan email dan kata sandi untuk terhubung di RAYA.';
      buttonText = 'Daftar';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: Stack(
        children: [
          // Efek Cahaya Ungu Lembut
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGlow.withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMarginHorizontal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    title,
                    style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.s24),

                  // Field Alamat Email
                  AppTextField(
                    label: 'Alamat Email',
                    hint: 'nama@domain.id',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: _useOtpMode ? TextInputAction.done : TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    errorText: errorToDisplay,
                    onSubmitted: (_) {
                      if (_useOtpMode) _handleAction();
                    },
                    onChanged: (_) {
                      if (_localError != null) setState(() => _localError = null);
                      ref.read(authControllerProvider.notifier).clearError();
                    },
                    semanticsLabel: 'Kolom input alamat email',
                  ),

                  // Field Kata Sandi (jika bukan mode OTP)
                  if (!_useOtpMode) ...[
                    const SizedBox(height: AppSpacing.s16),
                    AppTextField(
                      label: 'Kata Sandi',
                      hint: 'Minimal 6 karakter',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      onSubmitted: (_) {
                        if (_isLogin) _handleAction();
                      },
                      onChanged: (_) {
                        if (_localError != null) setState(() => _localError = null);
                        ref.read(authControllerProvider.notifier).clearError();
                      },
                      semanticsLabel: 'Kolom input kata sandi',
                    ),
                  ],

                  // Field Konfirmasi Kata Sandi (khusus pendaftaran)
                  if (!_isLogin && !_useOtpMode) ...[
                    const SizedBox(height: AppSpacing.s16),
                    AppTextField(
                      label: 'Ulangi Kata Sandi',
                      hint: 'Masukkan ulang kata sandi',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      onSubmitted: (_) => _handleAction(),
                      onChanged: (_) {
                        if (_localError != null) setState(() => _localError = null);
                        ref.read(authControllerProvider.notifier).clearError();
                      },
                      semanticsLabel: 'Kolom input konfirmasi kata sandi',
                    ),
                  ],

                  // Opsi Lupa Password / Masuk dengan OTP (saat mode login)
                  if (_isLogin) ...[
                    const SizedBox(height: AppSpacing.s8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _useOtpMode = !_useOtpMode;
                            _localError = null;
                          });
                          ref.read(authControllerProvider.notifier).clearError();
                        },
                        child: Text(
                          _useOtpMode ? 'Masuk dengan Kata Sandi' : 'Lupa kata sandi? Masuk via OTP',
                          style: AppTextStyles.bodyMedium(color: AppColors.primaryGlow),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.s24),

                  // Tombol Aksi Utama
                  PrimaryButton(
                    text: buttonText,
                    isLoading: authState.isLoading,
                    onPressed: _handleAction,
                    semanticsLabel: 'Tombol $buttonText',
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  // Tombol Alih Mode Daftar <-> Masuk
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _useOtpMode = false;
                          _localError = null;
                        });
                        ref.read(authControllerProvider.notifier).clearError();
                      },
                      child: Text(
                        _isLogin
                            ? 'Belum punya akun? Daftar sekarang'
                            : 'Sudah punya akun? Masuk',
                        style: AppTextStyles.bodyMedium(color: AppColors.primaryGlow),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
