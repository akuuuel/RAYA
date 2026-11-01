import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../moderation/domain/entities/report_ticket.dart';
import '../../../moderation/presentation/screens/notification_settings_screen.dart';
import '../../../moderation/presentation/widgets/report_modal.dart';
import '../widgets/active_tracking_modal.dart';
import '../widgets/blocked_contacts_modal.dart';
import '../widgets/chat_backup_modal.dart';
import '../widgets/privacy_compliance_modal.dart';
import '../widgets/security_key_modal.dart';
import '../widgets/terms_and_privacy_modal.dart';
import 'edit_profile_screen.dart';

/// Layar Profil dan Pengaturan Resmi RAYA sesuai PRD v0.3 (FR-03, FR-04, FR-05, FR-45 s/d FR-48) & DESIGN.md 7.9.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.userProfile;
    final isAdult = user?.isAdult ?? false;

    final birthDateStr = (user != null && user.birthDate != null)
        ? DateFormat('dd MMMM yyyy', 'id_ID').format(user.birthDate!)
        : '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Profil & Pengaturan',
          style: AppTextStyles.titleMedium(color: AppColors.textPrimary).copyWith(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMarginHorizontal,
          vertical: AppSpacing.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu Profil Pengguna (DESIGN.md 7.9)
            Container(
              padding: const EdgeInsets.all(AppSpacing.s20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.cardBorderRadius,
                border: Border.all(color: AppColors.surfaceBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar Pengguna (Mendukung Foto Unggahan & Inisial Huruf)
                      _buildProfileAvatar(user),
                      const SizedBox(width: AppSpacing.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Pengguna RAYA',
                              style: AppTextStyles.titleMedium(color: AppColors.textPrimary)
                                  .copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${user?.username ?? 'username'}',
                              style: AppTextStyles.bodyMedium(color: const Color(0xFF00CEC9)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      // Tombol Atur / Edit Profil
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryGlow.withValues(alpha: 0.5)),
                          ),
                          child: const Icon(Icons.edit_rounded, color: AppColors.primaryGlow, size: 18),
                        ),
                        tooltip: 'Atur Profil',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (user?.bio != null && user!.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF140F24),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Text(
                        user.bio!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Tombol Pill "Atur Profil Lengkap"
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.primaryGlow),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryGlow),
                      label: const Text('Atur Profil (Bio, Foto, Nama)', style: TextStyle(fontSize: 13)),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),

            // Status Batas Usia 18+ (FR-04)
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
                        ? 'Tanggal Lahir: $birthDateStr\nSeluruh fitur termasuk Pantau Lokasi dan Peta Publik aktif.'
                        : 'Tanggal Lahir: $birthDateStr\nFitur Pantau Lokasi dinonaktifkan demi keselamatan anak dan remaja.',
                    style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // Grup Pengaturan: Preferensi & Notifikasi (FR-45 s/d FR-48)
            Text(
              'Preferensi & Notifikasi (FR-45 s/d FR-48)',
              style: AppTextStyles.labelLarge(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s8),
            _buildSettingsTile(
              icon: Icons.notifications_active_outlined,
              title: 'Pengaturan Notifikasi & Mode Privat',
              subtitle: 'Kelola suara pesan, getar, sembunyikan preview, dan jam tenang',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NotificationSettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.s24),

            // Grup Pengaturan: Privasi & Keamanan
            Text(
              'Privasi & Keamanan',
              style: AppTextStyles.labelLarge(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s8),
            _buildSettingsTile(
              icon: Icons.visibility_outlined,
              title: 'Siapa yang Sedang Memantau Saya (FR-27)',
              subtitle: 'Transparansi penuh sesi berbagi lokasi aktif',
              onTap: () => ActiveTrackingModal.show(context),
            ),
            _buildSettingsTile(
              icon: Icons.enhanced_encryption_outlined,
              title: 'Verifikasi Kode Keamanan (FR-12)',
              subtitle: 'Pastikan enkripsi end-to-end tidak disusupi',
              onTap: () => SecurityKeyModal.show(context),
            ),
            _buildSettingsTile(
              icon: Icons.backup_outlined,
              title: 'Cadangan Riwayat Chat (FR-19)',
              subtitle: 'Tersandi dengan kata sandi cadangan pribadi',
              onTap: () => ChatBackupModal.show(context),
            ),
            _buildSettingsTile(
              icon: Icons.block_flipped,
              title: 'Daftar Kontak Diblokir (FR-08)',
              subtitle: 'Kelola kontak yang dibatasi',
              onTap: () => BlockedContactsModal.show(context),
            ),

            const SizedBox(height: AppSpacing.s24),

            // Grup Pengaturan: Hukum & Kebijakan
            Text(
              'Kebijakan & Bantuan',
              style: AppTextStyles.labelLarge(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s8),
            _buildSettingsTile(
              icon: Icons.report_problem_outlined,
              title: 'Laporkan Masalah / Pelanggaran (FR-41)',
              subtitle: 'Kirim aduan penyalahgunaan atau bantuan moderasi',
              onTap: () {
                ReportModal.show(
                  context,
                  reportedUserId: user?.id ?? 'admin',
                  reportType: ReportType.profile,
                  targetId: 'general_support_${user?.id ?? "unknown"}',
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Kepatuhan Privasi (UU PDP No. 27/2022)',
              subtitle: 'Data minimum, tanpa pelacakan riwayat perjalanan',
              onTap: () => PrivacyComplianceModal.show(context),
            ),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: 'Ketentuan Layanan & Kebijakan Privasi',
              subtitle: 'Hak subjek data dan pemrosesan informasi',
              onTap: () => TermsAndPrivacyModal.show(context),
            ),

            const SizedBox(height: AppSpacing.s24),

            // Tombol Keluar Sesi
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
                side: const BorderSide(color: AppColors.surfaceBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.buttonBorderRadius,
                ),
              ),
              onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
              label: Text(
                'Keluar dari Sesi',
                style: AppTextStyles.labelLarge(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),

            // Tombol Hapus Akun (FR-05)
            OutlinedButton.icon(
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
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: Text(
                      'Hapus Akun Permanen?',
                      style: AppTextStyles.titleMedium(color: AppColors.danger),
                    ),
                    content: Text(
                      'Seluruh data profil, kontak, dan riwayat Anda akan dihapus permanen dari server Supabase (FR-05). Tindakan ini tidak dapat dipulihkan.',
                      style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(
                          'Hapus Permanen',
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
              icon: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
              label: Text(
                'Hapus Akun Saya (FR-05)',
                style: AppTextStyles.labelLarge(color: AppColors.danger),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGlow, size: 22),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge(color: AppColors.textPrimary).copyWith(fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.labelSmall(color: AppColors.textMuted),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildProfileAvatar(dynamic user) {
    final avatarUrl = user?.avatarUrl as String?;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('data:image')) {
        try {
          final base64Data = avatarUrl.split(',').last;
          final bytes = base64Decode(base64Data);
          return CircleAvatar(
            radius: 32,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {}
      } else if (avatarUrl.startsWith('http')) {
        return CircleAvatar(
          radius: 32,
          backgroundImage: NetworkImage(avatarUrl),
        );
      }
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(color: AppColors.primaryGlow, width: 1.5),
      ),
      child: Center(
        child: Text(
          (user?.displayName?.isNotEmpty == true
                  ? user!.displayName![0]
                  : (user?.username?.isNotEmpty == true
                      ? user!.username![0]
                      : 'R'))
              .toUpperCase(),
          style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
