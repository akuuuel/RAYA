import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/location_badge.dart';
import '../../domain/entities/public_status.dart';
import '../../../moderation/domain/entities/report_ticket.dart';
import '../../../moderation/presentation/widgets/report_modal.dart';
import '../controllers/explore_controller.dart';

/// Layar Sekitar: Peta Publik, Badge Lokasi Disamarkan (min 300m), Status 8 Jam & Laporan Pelanggaran (FR-29 s.d. FR-41 & DESIGN.md 7.7).
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  void _showCreateStatusModal(BuildContext context) {
    final statusTextController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final textLen = statusTextController.text.length;

          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.screenMarginHorizontal,
              right: AppSpacing.screenMarginHorizontal,
              top: AppSpacing.s20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.s24,
            ),
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
                  'Pasang Status Sekitar (8 Jam)',
                  style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Status berlaku 8 jam lalu otomatis dihapus (FR-32). Lokasi Anda disamarkan acak radius minimal 300m (FR-30).',
                  style: AppTextStyles.labelSmall(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.s16),

                // Input Teks Status (Max 140 karakter, FR-31)
                TextField(
                  controller: statusTextController,
                  maxLength: 140,
                  maxLines: 2,
                  autofocus: true,
                  style: AppTextStyles.bodyLarge(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Lagi ngerjain tugas di kafe ini, colokan aman.',
                    hintStyle: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                    counterText: '$textLen/140 karakter',
                    counterStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  onChanged: (_) => setModalState(() {}),
                ),
                const SizedBox(height: AppSpacing.s12),

                // Input Catatan Opsional (Max 1000 karakter, FR-31)
                TextField(
                  controller: noteController,
                  maxLength: 1000,
                  maxLines: 2,
                  style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Catatan tambahan opsional (detail tempat, info wifi, dll)...',
                    hintStyle: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                  ),
                  onPressed: textLen == 0
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          final text = statusTextController.text.trim();
                          final note = noteController.text.trim().isEmpty ? null : noteController.text.trim();

                          await ref.read(exploreControllerProvider.notifier).postStatus(
                                text: text,
                                note: note,
                              );
                        },
                  child: Text(
                    'Pasang Status Sekarang',
                    style: AppTextStyles.labelLarge(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showStatusDetailModal(BuildContext context, PublicStatus status) {
    ref.read(exploreControllerProvider.notifier).loadComments(status.id);
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final exploreState = ref.watch(exploreControllerProvider);
          final comments = exploreState.comments[status.id] ?? [];

          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.screenMarginHorizontal,
              right: AppSpacing.screenMarginHorizontal,
              top: AppSpacing.s20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.s20,
            ),
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

                // Header Profil Pemilik Status & Opsi Lapor
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: status.isMine ? AppColors.primaryGradient : null,
                        color: status.isMine ? null : const Color(0xFF2563EB),
                      ),
                      child: Center(
                        child: Text(
                          status.authorName.isNotEmpty ? status.authorName[0].toUpperCase() : 'U',
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
                            status.isMine ? '${status.authorName} (Saya)' : status.authorName,
                            style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                          ),
                          Text(
                            status.authorUsername != null ? '@${status.authorUsername}' : 'Pengguna Sekitar',
                            style: AppTextStyles.labelSmall(color: AppColors.primaryGlow),
                          ),
                        ],
                      ),
                    ),
                    // Badge Sisa Waktu 8 Jam (FR-32)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1A2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 12, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            status.remainingTimeFormatted,
                            style: AppTextStyles.labelSmall(color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                    if (!status.isMine) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.flag_outlined, color: AppColors.warning, size: 20),
                        tooltip: 'Laporkan Status (FR-41)',
                        onPressed: () {
                          ReportModal.show(
                            context,
                            reportedUserId: status.authorId,
                            reportType: ReportType.publicStatus,
                            targetId: status.id,
                          );
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),

                // Isi Status
                Text(
                  status.text,
                  style: AppTextStyles.bodyLarge(color: AppColors.textPrimary)
                      .copyWith(fontSize: 17, height: 1.4),
                ),
                if (status.note != null && status.note!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0C1B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Text(
                      status.note!,
                      style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s12),

                // Penjelasan Penyamaran Lokasi (FR-30)
                Row(
                  children: [
                    const Icon(Icons.security_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Lokasi disamarkan acak radius minimal 300m (FR-30)',
                      style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.surfaceBorder),

                // Bagian Komentar (FR-35, FR-36)
                Text(
                  'Komentar Kontak Terhubung (${comments.length})',
                  style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.s8),

                if (!status.isContact && !status.isMine)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141122),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Komentar pada status ini hanya dibuka untuk kontak yang sudah saling terhubung dengan pemilik status (FR-35).',
                      style: AppTextStyles.labelSmall(color: AppColors.textSecondary),
                    ),
                  )
                else ...[
                  if (comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Belum ada komentar dari kontak.',
                        style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                      ),
                    )
                  else
                    ...comments.map(
                      (comm) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0C1B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comm.author.displayName ?? comm.author.username ?? 'Kontak',
                                    style: AppTextStyles.labelSmall(color: AppColors.primaryGlow)
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    comm.content,
                                    style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            if (comm.canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 16, color: AppColors.textMuted),
                                onPressed: () {
                                  ref
                                      .read(exploreControllerProvider.notifier)
                                      .deleteComment(
                                        statusId: status.id,
                                        commentId: comm.id,
                                      );
                                },
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.flag_outlined,
                                    size: 16, color: AppColors.textMuted),
                                tooltip: 'Laporkan Komentar (FR-41)',
                                onPressed: () {
                                  ReportModal.show(
                                    context,
                                    reportedUserId: comm.author.id,
                                    reportType: ReportType.comment,
                                    targetId: comm.id,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.s8),
                  // Kolom Tambah Komentar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Tulis komentar untuk kontak...',
                            hintStyle: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.surfaceBorder),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppColors.primaryGlow),
                        onPressed: () {
                          final text = commentController.text.trim();
                          if (text.isEmpty) return;
                          commentController.clear();
                          ref.read(exploreControllerProvider.notifier).addComment(
                                statusId: status.id,
                                content: text,
                              );
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exploreState = ref.watch(exploreControllerProvider);
    final isPublicVisible = exploreState.isPublicVisible;
    final myStatus = exploreState.myStatus;
    final nearbyStatuses = exploreState.nearbyStatuses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Sekitar',
          style: AppTextStyles.titleMedium(color: AppColors.textPrimary).copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan status sekitar',
            onPressed: () => ref.read(exploreControllerProvider.notifier).loadExploreData(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Radius 1 km, 5 km, 10 km (FR-37 & DESIGN.md 7.7)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMarginHorizontal,
              vertical: AppSpacing.s4,
            ),
            child: Row(
              children: [1, 5, 10].map((radius) {
                final isSelected = exploreState.selectedRadiusKm == radius;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s8),
                  child: FilterChip(
                    label: Text('$radius km'),
                    selected: isSelected,
                    onSelected: (_) =>
                        ref.read(exploreControllerProvider.notifier).setRadius(radius),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary.withValues(alpha: 0.25),
                    checkmarkColor: AppColors.primaryGlow,
                    labelStyle: AppTextStyles.labelSmall(
                      color: isSelected ? AppColors.primaryGlow : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Pengaturan Visibilitas Publik (FR-29, FR-39)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMarginHorizontal,
              vertical: AppSpacing.s4,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    isPublicVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: 20,
                    color: isPublicVisible ? AppColors.locationActive : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPublicVisible ? 'Tampil di Peta Publik (Aktif)' : 'Tampil Publik Nonaktif',
                          style: AppTextStyles.labelSmall(
                            color: isPublicVisible ? AppColors.textPrimary : AppColors.textMuted,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isPublicVisible ? 'Radius acak min 300m (FR-30)' : 'Status dan badge Anda tersembunyi (FR-39)',
                          style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isPublicVisible,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      ref.read(exploreControllerProvider.notifier).togglePublicVisibility(val);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Kartu Status Saya jika sedang aktif (FR-31, FR-32, FR-33)
          if (myStatus != null && !myStatus.isExpired) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMarginHorizontal,
                vertical: AppSpacing.s4,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: const Color(0xFF19142A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryGlow),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Status Aktif Saya',
                                style: AppTextStyles.labelSmall(color: AppColors.primaryGlow)
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                myStatus.remainingTimeFormatted,
                                style: AppTextStyles.labelSmall(color: AppColors.warning),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            myStatus.text,
                            style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                      tooltip: 'Hapus status saya (FR-33)',
                      onPressed: () => ref.read(exploreControllerProvider.notifier).deleteMyStatus(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Area Tampilan Peta Gelap dengan Badge Lokasi (DESIGN.md 6.9, 7.7)
          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(AppSpacing.screenMarginHorizontal),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0916),
                    borderRadius: AppSpacing.cardBorderRadius,
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Stack(
                    children: [
                      // Titik Pusat Diri Sendiri
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trip_origin_rounded, color: AppColors.primary, size: 20),
                            SizedBox(height: 4),
                            Text(
                              'Area Sekitar Anda',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                      // Daftar Badge Lokasi Disamarkan (FR-30, FR-34)
                      if (nearbyStatuses.isEmpty)
                        const Center(
                          child: Text(
                            'Belum ada status publik dalam radius ini.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      else ...[
                        // Render badge pertama di posisi kiri atas
                        if (nearbyStatuses.isNotEmpty)
                          Positioned(
                            top: 24,
                            left: 16,
                            child: LocationBadge(
                              authorName: nearbyStatuses[0].authorName,
                              username: nearbyStatuses[0].authorUsername,
                              text: nearbyStatuses[0].text,
                              isMine: nearbyStatuses[0].isMine,
                              onTap: () => _showStatusDetailModal(context, nearbyStatuses[0]),
                            ),
                          ),
                        // Render badge kedua di posisi kanan bawah
                        if (nearbyStatuses.length > 1)
                          Positioned(
                            bottom: 80,
                            right: 16,
                            child: LocationBadge(
                              authorName: nearbyStatuses[1].authorName,
                              username: nearbyStatuses[1].authorUsername,
                              text: nearbyStatuses[1].text,
                              isMine: nearbyStatuses[1].isMine,
                              onTap: () => _showStatusDetailModal(context, nearbyStatuses[1]),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                // Tombol Mengambang "Pasang Status (8 Jam)"
                Positioned(
                  bottom: AppSpacing.s24 + 16,
                  left: AppSpacing.screenMarginHorizontal + 24,
                  right: AppSpacing.screenMarginHorizontal + 24,
                  child: FloatingActionButton.extended(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 4,
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: Text(
                      'Pasang Status (8 Jam)',
                      style: AppTextStyles.labelLarge(color: AppColors.textPrimary),
                    ),
                    onPressed: () => _showCreateStatusModal(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
