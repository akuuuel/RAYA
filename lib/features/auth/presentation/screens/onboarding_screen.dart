import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = const [
    {
      'title': 'Selamat datang di RAYA',
      'highlight': 'Tetap Terhubung',
      'description': 'Chat, berbagi lokasi, dan kabar singkat, dalam satu tempat yang aman.',
      'icon': 'chat',
    },
    {
      'title': 'Pesanmu terenkripsi',
      'highlight': 'End-to-End',
      'description': 'Hanya kamu dan penerimamu yang bisa membacanya. Privasi data terjaga sepenuhnya.',
      'icon': 'lock',
    },
    {
      'title': 'Kamu yang memutuskan',
      'highlight': 'Kendali Penuh',
      'description': 'Lokasi hanya dibagikan saat kamu setuju dan dapat dihentikan kapan saja.',
      'icon': 'location',
    },
  ];

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Efek Cahaya Ungu di Sudut Atas (DESIGN.md Bagian 2)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGlow.withValues(alpha: 0.15),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMarginHorizontal,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        IconData iconData = Icons.chat_bubble_outline_rounded;
                        if (slide['icon'] == 'lock') {
                          iconData = Icons.lock_outline_rounded;
                        } else if (slide['icon'] == 'location') {
                          iconData = Icons.location_on_outlined;
                        }

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(),
                            // Ilustrasi Placeholder Bergaya Kaca (DESIGN.md 6.12)
                            Center(
                              child: Container(
                                width: 140,
                                height: 140,
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
                                      blurRadius: 32,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  iconData,
                                  size: 64,
                                  color: AppColors.primaryGlow,
                                  semanticLabel: slide['title'],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              slide['title']!,
                              style: AppTextStyles.displayLarge(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              slide['highlight']!,
                              style: AppTextStyles.displayLarge(
                                color: AppColors.primaryGlow,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s16),
                            Text(
                              slide['description']!,
                              style: AppTextStyles.bodyMedium(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s32),
                          ],
                        );
                      },
                    ),
                  ),

                  // Dot Pagination (DESIGN.md 6.7)
                  Row(
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: AppSpacing.s8),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.surfaceBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.s32),

                  // Tombol Aksi
                  PrimaryButton(
                    text: _currentPage == _slides.length - 1 ? 'Mulai' : 'Lanjut',
                    onPressed: _onNext,
                    semanticsLabel: _currentPage == _slides.length - 1
                        ? 'Mulai pendaftaran aplikasi'
                        : 'Lanjut ke slide berikutnya',
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  if (_currentPage < _slides.length - 1)
                    SizedBox(
                      height: AppSpacing.minTouchTarget,
                      child: TextButton(
                        onPressed: _goToLogin,
                        child: Text(
                          'Lewati',
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: AppSpacing.minTouchTarget),
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
