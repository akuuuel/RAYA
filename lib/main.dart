import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/controllers/auth_state.dart';
import 'features/auth/presentation/screens/complete_profile_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/navigation/presentation/screens/main_navigation_screen.dart';
import 'shared/widgets/primary_button.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Supabase client jika tidak menggunakan mode mock terisolasi
  if (!AppConfig.useMock) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

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

    Widget homeWidget;
    switch (authState.status) {
      case AuthStatus.authenticated:
        homeWidget = const MainNavigationScreen();
        break;
      case AuthStatus.needsProfileCompletion:
        homeWidget = CompleteProfileScreen(email: authState.email ?? '');
        break;
      case AuthStatus.loading:
        homeWidget = const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
        break;
      default:
        homeWidget = const SplashScreen();
        break;
    }

    return MaterialApp(
      title: 'RAYA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: homeWidget,
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
                text: 'Daftar Akun Baru',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
                semanticsLabel: 'Tombol Mulai Pendaftaran Akun RAYA',
              ),
              const SizedBox(height: AppSpacing.s12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.buttonBorderRadius,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(isLoginMode: true),
                    ),
                  );
                },
                child: Text(
                  'Sudah punya akun? Masuk',
                  style: AppTextStyles.labelLarge(color: AppColors.primaryGlow),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }
}
