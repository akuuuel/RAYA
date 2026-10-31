import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/moderation_controller.dart';

/// Layar Pengaturan Preferensi Notifikasi sesuai FR-46 dan FR-47.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moderationState = ref.watch(moderationControllerProvider);
    final settings = moderationState.settings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pengaturan Notifikasi',
          style: AppTextStyles.titleMedium(color: AppColors.textPrimary).copyWith(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenMarginHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori Notifikasi (FR-46)',
              style: AppTextStyles.labelLarge(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s12),

            _buildSwitchTile(
              title: 'Pesan Chat Baru',
              subtitle: 'Notifikasi saat ada pesan masuk terenkripsi',
              value: settings.chatMessages,
              onChanged: (val) {
                ref
                    .read(moderationControllerProvider.notifier)
                    .updateSettings(settings.copyWith(chatMessages: val));
              },
            ),
            _buildSwitchTile(
              title: 'Permintaan Kontak',
              subtitle: 'Notifikasi permintaan pertemanan dari pengguna lain',
              value: settings.contactRequests,
              onChanged: (val) {
                ref
                    .read(moderationControllerProvider.notifier)
                    .updateSettings(settings.copyWith(contactRequests: val));
              },
            ),
            _buildSwitchTile(
              title: 'Pantau Lokasi (18+)',
              subtitle: 'Notifikasi permohonan dan perubahan sesi berbagi lokasi',
              value: settings.locationTracking,
              onChanged: (val) {
                ref
                    .read(moderationControllerProvider.notifier)
                    .updateSettings(settings.copyWith(locationTracking: val));
              },
            ),
            _buildSwitchTile(
              title: 'Komentar Status',
              subtitle: 'Notifikasi saat kontak berkomentar di status 8 jam Anda',
              value: settings.statusComments,
              onChanged: (val) {
                ref
                    .read(moderationControllerProvider.notifier)
                    .updateSettings(settings.copyWith(statusComments: val));
              },
            ),

            const SizedBox(height: AppSpacing.s24),
            Text(
              'Privasi Notifikasi (FR-47)',
              style: AppTextStyles.labelLarge(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s12),

            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.cardBorderRadius,
                border: Border.all(
                  color: settings.privateMode ? AppColors.primaryGlow : AppColors.surfaceBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: AppColors.primaryGlow, size: 22),
                      const SizedBox(width: AppSpacing.s8),
                      Text(
                        'Mode Privat Notifikasi (FR-47)',
                        style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      Switch(
                        value: settings.privateMode,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          ref
                              .read(moderationControllerProvider.notifier)
                              .updateSettings(settings.copyWith(privateMode: val));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Jika aktif, notifikasi di layar kunci dan bilah status hanya menampilkan "Anda menerima pesan baru" tanpa menampilkan isi teks pesan demi menjaga kerahasiaan Anda.',
                    style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium(color: AppColors.textPrimary)
                      .copyWith(fontSize: 15),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

