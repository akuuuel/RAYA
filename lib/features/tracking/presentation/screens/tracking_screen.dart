import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/location_active_dot.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../contacts/presentation/controllers/contacts_controller.dart';
import '../../domain/entities/location_session.dart';
import '../controllers/tracking_controller.dart';

/// Layar Pantau Lokasi Pribadi (FR-20 s.d. FR-28 & DESIGN.md 7.6).
/// Dibatasi ketat hanya untuk pengguna berusia 18 tahun ke atas.
class TrackingScreen extends ConsumerWidget {
  final bool isAdult;
  final VoidCallback onGoToContacts;

  const TrackingScreen({
    super.key,
    required this.isAdult,
    required this.onGoToContacts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isAdult) {
      return _buildUnderageLockedView();
    }

    final trackingState = ref.watch(trackingControllerProvider);
    final activeSessions = trackingState.activeSessions;
    final incomingRequests = trackingState.incomingRequests;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Pantau Lokasi',
              style: AppTextStyles.titleMedium(color: AppColors.textPrimary).copyWith(fontSize: 20),
            ),
            if (trackingState.isSharingActive) ...[
              const SizedBox(width: AppSpacing.s12),
              const LocationActiveDot(size: 10),
              const SizedBox(width: 6),
              Text(
                'Berbagi Aktif (FR-25)',
                style: AppTextStyles.labelSmall(color: AppColors.locationActive),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Panduan Privasi Lokasi',
            onPressed: () => _showPrivacyInfoModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenMarginHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Permintaan Pantau Masuk (FR-21, FR-22)
            if (incomingRequests.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1728),
                  borderRadius: AppSpacing.cardBorderRadius,
                  border: Border.all(color: AppColors.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.share_location_rounded, color: AppColors.primaryGlow, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Permintaan Pantau Masuk (${incomingRequests.length})',
                          style: AppTextStyles.titleMedium(color: AppColors.primaryGlow),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...incomingRequests.map((req) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            req.requester.displayName ?? req.requester.username ?? 'Kontak',
                            style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            'Durasi: ${req.durationLabel} • ${req.isBidirectional ? "Dua Arah" : "Satu Arah"}',
                            style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => ref
                                    .read(trackingControllerProvider.notifier)
                                    .rejectSession(req.id),
                                child: const Text('Tolak'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textPrimary,
                                ),
                                onPressed: () => ref
                                    .read(trackingControllerProvider.notifier)
                                    .acceptSession(req.id),
                                child: const Text('Setujui (FR-22)'),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
            ],

            // Banner Edukasi Kontrol Penuh Pengguna
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.cardBorderRadius,
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.locationActive,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Text(
                      'Lokasi hanya dibagikan atas persetujuan Anda dan dapat dihentikan sewaktu-waktu (FR-24).',
                      style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s20),

            // Mock Tampilan Peta Gelap
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F0C1B),
                borderRadius: AppSpacing.cardBorderRadius,
                border: Border.all(
                  color: trackingState.isSharingActive ? AppColors.locationActive : AppColors.surfaceBorder,
                  width: trackingState.isSharingActive ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      decoration: BoxDecoration(
                        color: trackingState.isSharingActive
                            ? AppColors.locationActive.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        size: 36,
                        color: trackingState.isSharingActive ? AppColors.locationActive : AppColors.primaryGlow,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Text(
                      trackingState.isSharingActive
                          ? 'Peta Pantau Aktif'
                          : 'Peta Pantau Belum Aktif',
                      style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      trackingState.isSharingActive
                          ? '${activeSessions.length} sesi berbagi sedang berlangsung'
                          : 'Hanya titik terakhir yang disimpan (FR-28)',
                      style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // Sesi Pantau Aktif (FR-26, FR-27)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sesi Pantau Aktif (${activeSessions.length})',
                  style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                ),
                TextButton.icon(
                  onPressed: () => _showRequestSharingModal(context, ref),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: const Text('Minta Pantau'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),

            if (activeSessions.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.cardBorderRadius,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      'Tidak ada kontak yang sedang memantau atau Anda pantau.',
                      style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGlow,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.buttonBorderRadius,
                        ),
                      ),
                      onPressed: () => _showRequestSharingModal(context, ref),
                      icon: const Icon(Icons.share_location_rounded, size: 18),
                      label: const Text('Minta Pantau ke Kontak'),
                    ),
                  ],
                ),
              )
            else
              ...activeSessions.map((session) {
                final targetUser = session.target;
                final loc = trackingState.contactLocations[targetUser.id];
                final updateTime = loc != null
                    ? DateFormat('HH:mm').format(loc.updatedAt)
                    : '-';

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.s12),
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.cardBorderRadius,
                    border: Border.all(color: AppColors.locationActive),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: Center(
                              child: Text(
                                (targetUser.displayName?.isNotEmpty == true
                                        ? targetUser.displayName![0]
                                        : targetUser.username?[0] ?? 'K')
                                    .toUpperCase(),
                                style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  targetUser.displayName ?? targetUser.username ?? 'Kontak',
                                  style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                                ),
                                Text(
                                  'Pembaruan terakhir: $updateTime (FR-26)',
                                  style: AppTextStyles.labelSmall(color: AppColors.locationActive),
                                ),
                                Text(
                                  'Durasi: ${session.durationLabel} • ${session.isBidirectional ? "Dua Arah" : "Satu Arah"}',
                                  style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                          side: const BorderSide(color: AppColors.danger),
                          foregroundColor: AppColors.danger,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(trackingControllerProvider.notifier)
                              .stopSession(session.id);
                        },
                        icon: const Icon(Icons.stop_circle_outlined, size: 18),
                        label: const Text('Hentikan Berbagi (FR-24)'),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showRequestSharingModal(BuildContext context, WidgetRef ref) {
    final contacts = ref.read(contactsControllerProvider).contacts;

    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda belum memiliki kontak. Tambahkan kontak terlebih dahulu.'),
        ),
      );
      onGoToContacts();
      return;
    }

    UserProfile? selectedContact = contacts.first.contactUser;
    LocationDurationType selectedDuration = LocationDurationType.oneHour;
    bool isBidirectional = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMarginHorizontal),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Text(
                  'Minta Pantau Lokasi (18+)',
                  style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Penerima harus menyetujui sebelum lokasi dibagikan (FR-22).',
                  style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.s16),

                // Pilih Kontak
                Text('Pilih Kontak:', style: AppTextStyles.titleMedium(color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserProfile>(
                  value: selectedContact,
                  dropdownColor: AppColors.surface,
                  style: AppTextStyles.bodyLarge(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: contacts
                      .map((c) => DropdownMenuItem(
                            value: c.contactUser,
                            child: Text(c.displayName),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedContact = val);
                  },
                ),
                const SizedBox(height: AppSpacing.s16),

                // Pilih Durasi (FR-23)
                Text('Pilih Durasi:', style: AppTextStyles.titleMedium(color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDurationChip(
                      label: '1 Jam',
                      isSelected: selectedDuration == LocationDurationType.oneHour,
                      onTap: () => setModalState(() => selectedDuration = LocationDurationType.oneHour),
                    ),
                    const SizedBox(width: 8),
                    _buildDurationChip(
                      label: '8 Jam',
                      isSelected: selectedDuration == LocationDurationType.eightHours,
                      onTap: () => setModalState(() => selectedDuration = LocationDurationType.eightHours),
                    ),
                    const SizedBox(width: 8),
                    _buildDurationChip(
                      label: 'Manual',
                      isSelected: selectedDuration == LocationDurationType.manual,
                      onTap: () => setModalState(() => selectedDuration = LocationDurationType.manual),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),

                // Pilih Arah (FR-21)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Berbagi Dua Arah (Saling Pantau)',
                    style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    'Kedua pihak saling melihat posisi (FR-21)',
                    style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                  ),
                  value: isBidirectional,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setModalState(() => isBidirectional = val),
                ),
                const SizedBox(height: AppSpacing.s20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                  ),
                  onPressed: () async {
                    if (selectedContact == null) return;
                    Navigator.pop(ctx);
                    await ref.read(trackingControllerProvider.notifier).requestSharing(
                          targetUser: selectedContact!,
                          isBidirectional: isBidirectional,
                          durationType: selectedDuration,
                        );
                  },
                  child: Text(
                    'Kirim Permintaan Pantau',
                    style: AppTextStyles.labelLarge(color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDurationChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.3),
      labelStyle: AppTextStyles.labelSmall(
        color: isSelected ? AppColors.primaryGlow : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
      ),
    );
  }

  void _showPrivacyInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMarginHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            Text(
              'Privasi Pantau Lokasi RAYA',
              style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              '• Berbagi lokasi bersifat dua arah dan harus disetujui kedua pihak (FR-22).\n• Tidak ada riwayat perjalanan yang disimpan, hanya titik terakhir (FR-28).\n• Sesi berbagi dapat dihentikan kapan saja secara manual (FR-24).\n• Khusus pengguna berusia 18 tahun ke atas (FR-20).',
              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s24),
          ],
        ),
      ),
    );
  }

  Widget _buildUnderageLockedView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pantau Lokasi',
          style: AppTextStyles.titleMedium(color: AppColors.textPrimary).copyWith(fontSize: 20),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenMarginHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.warning, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  size: 46,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Text(
                'Fitur Khusus Dewasa (18+)',
                style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                'Sesuai ketentuan keamanan dan privasi RAYA (FR-20), fitur berbagi dan pantau lokasi langsung dua arah hanya tersedia bagi pengguna yang berusia 18 tahun ke atas.\n\nAnda tetap dapat menikmati seluruh fitur chat terenkripsi dan berkirim pesan dengan kontak terpercaya Anda.',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s32),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.cardBorderRadius,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primaryGlow, size: 24),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        'Kebijakan perlindungan privasi anak dan remaja (UU PDP No. 27/2022).',
                        style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
