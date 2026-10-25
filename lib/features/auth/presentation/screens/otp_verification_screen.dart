import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/otp_input.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import 'complete_profile_screen.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  String _enteredCode = '';

  Future<void> _handleVerify() async {
    if (_enteredCode.length < 6) return;

    final success = await ref.read(authControllerProvider.notifier).verifyOtp(_enteredCode);
    if (!mounted) return;

    if (success) {
      final authState = ref.read(authControllerProvider);
      if (authState.status == AuthStatus.needsProfileCompletion) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(email: widget.email),
          ),
        );
      } else {
        // Pengguna lama yang profilnya sudah lengkap
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _handleResend() async {
    await ref.read(authControllerProvider.notifier).sendOtp(widget.email);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Verifikasi',
          style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMarginHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.s24),
              // Ilustrasi Gembok Kaca
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surfaceBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 44,
                  color: AppColors.primaryGlow,
                  semanticLabel: 'Ikon Verifikasi Email',
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Text(
                'Verifikasi email Anda',
                style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Kode verifikasi 6 digit telah dikirim ke:\n${widget.email}',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s32),

              // Komponen 6 Kotak OTP
              OtpInput(
                length: 6,
                errorText: authState.errorMessage,
                onChanged: (code) {
                  setState(() => _enteredCode = code);
                  if (authState.errorMessage != null) {
                    ref.read(authControllerProvider.notifier).clearError();
                  }
                },
                onCompleted: (code) {
                  setState(() => _enteredCode = code);
                  _handleVerify();
                },
                onResend: _handleResend,
              ),
              const SizedBox(height: AppSpacing.s32),

              PrimaryButton(
                text: 'Verifikasi',
                isLoading: authState.isLoading,
                isEnabled: _enteredCode.length == 6,
                onPressed: _handleVerify,
                semanticsLabel: 'Tombol verifikasi kode OTP',
              ),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }
}
