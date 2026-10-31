import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'location_active_dot.dart';

/// Item konfigurasi untuk [AppBottomNav].
class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
  final bool showActiveDot;

  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
    this.showActiveDot = false,
  });
}

/// Bilah Navigasi Bawah (5 Tab) resmi RAYA sesuai DESIGN.md Bagian 6.11.
/// - Tinggi 64-72 dp dengan latar surface dan batas atas surfaceBorder.
/// - Ikon garis untuk tidak aktif, ikon terisi dengan warna primaryGlow untuk tab aktif.
/// - Mendukung badge notifikasi angka pada tab Chat & Kontak, serta titik pulsa lokasi aktif (DESIGN.md 6.10).
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavItem> items;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceBorder,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  splashColor: AppColors.primary.withValues(alpha: 0.1),
                  highlightColor: Colors.transparent,
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: 'Tab ${item.label}${item.badgeCount > 0 ? ', ${item.badgeCount} belum dibaca' : ''}',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                key: ValueKey<bool>(isSelected),
                                size: 24,
                                color: isSelected
                                    ? AppColors.primaryGlow
                                    : AppColors.textMuted,
                              ),
                            ),
                            if (item.showActiveDot)
                              const Positioned(
                                top: -2,
                                right: -6,
                                child: LocationActiveDot(size: 8),
                              ),
                            if (item.badgeCount > 0)
                              Positioned(
                                top: -4,
                                right: -8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    item.badgeCount > 99
                                        ? '99+'
                                        : item.badgeCount.toString(),
                                    style: AppTextStyles.labelSmall(
                                      color: AppColors.textPrimary,
                                    ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          item.label,
                          style: AppTextStyles.labelSmall(
                            color: isSelected
                                ? AppColors.primaryGlow
                                : AppColors.textMuted,
                          ).copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
