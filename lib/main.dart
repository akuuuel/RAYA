import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/controllers/auth_state.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'shared/widgets/primary_button.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  runApp(
    const ProviderScope(
      child: RayaApp(),
    ),
  );
}

class RayaApp extends ConsumerWidget {
  const RayaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'RAYA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authState.status == AuthStatus.authenticated
          ? const HomePlaceholderScreen()
          : const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMarginHorizontal,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Efek Glow / Brand RAYA
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGlow.withValues(alpha: 0.35),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.textPrimary,
                    size: 44,
                    semanticLabel: 'Ikon Keamanan RAYA',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Text(
                'RAYA',
                style: AppTextStyles.displayLarge(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Tetap Terhubung',
                style: AppTextStyles.bodyMedium(color: AppColors.primaryGlow),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Mulai',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
                semanticsLabel: 'Tombol Mulai Aplikasi RAYA',
              ),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tampilan Beranda Sementara untuk memvalidasi status login dan penguncian fitur usia 18+.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.userProfile;
    final isAdult = user?.isAdult ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'RAYA',
          style: AppTextStyles.titleMedium(color: AppColors.primaryGlow),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenMarginHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${user?.displayName ?? 'Pengguna'}!',
                style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                '@${user?.username ?? 'user'}',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s24),

              // Status Verifikasi Usia 18+ (FR-04)
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.cardBorderRadius,
                  border: Border.all(
                    color: isAdult ? AppColors.success : AppColors.warning,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAdult ? Icons.verified_user_rounded : Icons.info_outline_rounded,
                          color: isAdult ? AppColors.success : AppColors.warning,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          isAdult ? 'Status Usia: Dewasa (18+)' : 'Status Usia: Di Bawah 18 Tahun',
                          style: AppTextStyles.titleMedium(
                            color: isAdult ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      isAdult
                          ? 'Seluruh fitur termasuk Pantau Lokasi dan Peta Publik aktif.'
                          : 'Fitur Pantau Lokasi dan Peta Publik terkunci untuk keamanan akun di bawah umur.',
                      style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Tombol Hapus Akun (FR-05)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.buttonBorderRadius,
                  ),
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: Text(
                        'Hapus Akun?',
                        style: AppTextStyles.titleMedium(color: AppColors.danger),
                      ),
                      content: Text(
                        'Seluruh data pribadi Anda akan dihapus permanen dari server. Tindakan ini tidak dapat dibatalkan.',
                        style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            'Hapus',
                            style: AppTextStyles.labelLarge(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref.read(authControllerProvider.notifier).deleteAccount();
                  }
                },
                child: Text(
                  'Hapus Akun Saya (FR-05)',
                  style: AppTextStyles.labelLarge(color: AppColors.danger),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
      ),
    );
  }
}
