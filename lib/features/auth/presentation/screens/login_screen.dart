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
  late bool _isLogin;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLoginMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email.trim());
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _localError = 'Alamat email wajib diisi.');
      return;
    }

    if (!_validateEmail(email)) {
      setState(() => _localError = 'Format email tidak valid.');
      return;
    }

    setState(() => _localError = null);

    final success = await ref.read(authControllerProvider.notifier).sendOtp(email);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: email),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final errorToDisplay = _localError ?? authState.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: Stack(
        children: [
          // Efek Cahaya Ungu Lembut (DESIGN.md Bagian 2)
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMarginHorizontal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    _isLogin ? 'Masuk ke Akun' : 'Daftar Akun Baru',
                    style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    _isLogin
                        ? 'Masukkan alamat email akun terdaftar Anda untuk menerima kode OTP verifikasi.'
                        : 'Masukkan alamat email Anda untuk menerima kode OTP 8 digit verifikasi.',
                    style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.s32),

                  AppTextField(
                    label: 'Alamat Email',
                    hint: 'nama@domain.id',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    errorText: errorToDisplay,
                    onSubmitted: (_) => _handleSendOtp(),
                    onChanged: (_) {
                      if (_localError != null) {
                        setState(() => _localError = null);
                      }
                      ref.read(authControllerProvider.notifier).clearError();
                    },
                    semanticsLabel: 'Kolom input alamat email',
                  ),
                  const Spacer(),

                  PrimaryButton(
                    text: _isLogin ? 'Masuk' : 'Daftar',
                    isLoading: authState.isLoading,
                    onPressed: _handleSendOtp,
                    semanticsLabel: _isLogin ? 'Tombol masuk akun' : 'Tombol daftar akun baru',
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  // Opsi peralihan Masuk <-> Daftar
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
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
                  const SizedBox(height: AppSpacing.s16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
