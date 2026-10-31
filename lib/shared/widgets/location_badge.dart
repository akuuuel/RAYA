import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Badge Lokasi di Peta Publik sesuai DESIGN.md Bagian 6.9 dan PRD v0.3 FR-30, FR-34, FR-38.
/// - Berbentuk pil dengan radius penuh (capsule).
/// - Latar surface dengan garis tepi primary tipis dan cahaya lembut primaryGlow.
/// - Berisi avatar kecil, username/nama, dan teks status singkat.
/// - Ukuran sentuh minimal 44 dp, tidak pernah menampilkan koordinat presisi (FR-30, FR-38).
class LocationBadge extends StatelessWidget {
  final String authorName;
  final String? username;
  final String text;
  final VoidCallback onTap;
  final bool isMine;
  final bool hasActiveStatus;

  const LocationBadge({
    super.key,
    required this.authorName,
    this.username,
    required this.text,
    required this.onTap,
    this.isMine = false,
    this.hasActiveStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Badge lokasi dari $authorName: $text',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
              maxWidth: 240,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isMine ? AppColors.primaryGlow : AppColors.primary,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isMine ? AppColors.primaryGlow : AppColors.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar kecil
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isMine
                        ? AppColors.primaryGradient
                        : const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          ),
                  ),
                  child: Center(
                    child: Text(
                      authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),

                // Teks singkat status & nama
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMine ? 'Status Saya' : (username != null ? '@$username' : authorName),
                        style: AppTextStyles.labelSmall(
                          color: isMine ? AppColors.primaryGlow : AppColors.textPrimary,
                        ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        text,
                        style: AppTextStyles.labelSmall(color: AppColors.textSecondary)
                            .copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

