import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../moderation/domain/entities/report_ticket.dart';
import '../../../moderation/presentation/widgets/report_modal.dart';
import '../../domain/entities/public_status.dart';
import '../controllers/explore_controller.dart';
import 'create_nearby_note_modal.dart';

/// Modal Tampilan Detail Catatan Pengguna Sekitar Gaya Instagram Notes.
/// Menampilkan catatan lengkap, tombol hapus & ganti catatan (jika milik sendiri),
/// dan kolom komentar untuk orang lain (pemilik tidak bisa mengomentari catatan sendiri).
class NearbyNoteDetailModal {
  static void show(BuildContext context, WidgetRef ref, PublicStatus status) {
    ref.read(exploreControllerProvider.notifier).loadComments(status.id);
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF130E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final exploreState = ref.watch(exploreControllerProvider);
          final comments = exploreState.comments[status.id] ?? [];

          final client = Supabase.instance.client;
          final currentUid = client.auth.currentUser?.id;
          final isOwner = status.isMine ||
              (currentUid != null && currentUid == status.userId) ||
              (exploreState.myStatus != null && exploreState.myStatus!.id == status.id);

          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.screenMarginHorizontal,
              right: AppSpacing.screenMarginHorizontal,
              top: AppSpacing.s20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.s20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
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
                  const SizedBox(height: 16),

                  // Header: Avatar, Nama, Waktu & Tombol Lapor
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: status.isMine
                              ? AppColors.primaryGradient
                              : const LinearGradient(
                                  colors: [Color(0xFF00CEC9), Color(0xFF6C5CE7)],
                                ),
                        ),
                        child: Center(
                          child: Text(
                            status.authorName.isNotEmpty ? status.authorName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.isMine ? '${status.authorName} (Saya)' : status.authorName,
                              style: AppTextStyles.titleMedium(color: AppColors.textPrimary)
                                  .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              status.authorUsername != null
                                  ? '@${status.authorUsername}'
                                  : 'Pengguna Sekitar',
                              style: const TextStyle(color: Color(0xFF00CEC9), fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      // Badge Sisa Waktu 8 Jam
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1A35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 13, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              status.remainingTimeFormatted,
                              style: const TextStyle(color: AppColors.warning, fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                      if (!status.isMine) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.flag_outlined, color: AppColors.textMuted, size: 20),
                          tooltip: 'Laporkan Catatan',
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
                  const SizedBox(height: 18),

                  // ==========================================================
                  // KARTU BALON CATATAN GAYA INSTAGRAM NOTES
                  // ==========================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1736),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: status.isMine ? AppColors.primaryGlow : const Color(0xFF00CEC9),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (status.isMine ? AppColors.primary : const Color(0xFF00CEC9))
                              .withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.maps_ugc_rounded, size: 16, color: Color(0xFF00CEC9)),
                            const SizedBox(width: 6),
                            Text(
                              'Catatan Sekitar (Peta)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          status.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        if (status.note != null && status.note!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF130E24),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status.note!,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info Keamanan Lokasi Disamarkan
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Lokasi disamarkan minimal 300 meter untuk melindungi privasi Anda (UU PDP No. 27/2022).',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),

                  // ==========================================================
                  // KONTROL CATATAN SAYA: HAPUS & TAMBAH/GANTI BARU
                  // ==========================================================
                  if (isOwner) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Tombol Tambah / Ganti Catatan Baru
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.edit_note_rounded, size: 18),
                            label: const Text('Ganti Catatan'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              CreateNearbyNoteModal.show(context, ref);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Tombol Hapus Catatan
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: const Text('Hapus Catatan'),
                            onPressed: () {
                              _confirmDeleteNote(context, ctx, ref, status.id);
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Catatan ini dipasang oleh ${status.authorName}. Hanya pemilik yang dapat menghapus catatan mereka.',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ),
                  ],

                  const Divider(height: 28, color: AppColors.surfaceBorder),

                  // ==========================================================
                  // BAGIAN KOMENTAR PENGGUNA SEKITAR
                  // ==========================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Komentar (${comments.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00CEC9).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Publik Sekitar',
                          style: TextStyle(color: Color(0xFF00CEC9), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Daftar Komentar yang Sudah Masuk
                  if (comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Belum ada komentar pada catatan ini.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...comments.map(
                      (comm) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18122C),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comm.author.displayName ?? comm.author.username ?? 'Pengguna Sekitar',
                                    style: const TextStyle(
                                      color: Color(0xFF00CEC9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    comm.content,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            if (comm.canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 16, color: AppColors.textMuted),
                                onPressed: () {
                                  ref.read(exploreControllerProvider.notifier).deleteComment(
                                        statusId: status.id,
                                        commentId: comm.id,
                                      );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // ==========================================================
                  // ATURAN INPUT KOMENTAR:
                  // - Pemilik Catatan (isOwner): TIDAK BISA KOMEN SENDIRI
                  // - Pengguna Lain (!isOwner): BISA MENGETIK & MENGIRIM KOMENTAR
                  // ==========================================================
                  if (isOwner)
                    // Pemilik: Tampilkan banner informasi bahwa tidak bisa komen sendiri
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF19142A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryGlow),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Anda adalah pemilik catatan ini. Anda tidak dapat mengomentari catatan sendiri.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // Pengguna Lain: Kolom Input Kirim Komentar
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Tulis komentar untuk ${status.authorName}...',
                              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFF18122C),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.surfaceBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.surfaceBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF00CEC9)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF00CEC9)),
                          tooltip: 'Kirim komentar',
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
              ),
            ),
          );
        },
      ),
    );
  }

  static void _confirmDeleteNote(
    BuildContext parentContext,
    BuildContext modalContext,
    WidgetRef ref,
    String statusId,
  ) {
    showDialog(
      context: parentContext,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: const Color(0xFF19142A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Catatan Sekitar?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Catatan Anda akan segera dihapus dari peta dan tidak dapat dilihat lagi oleh pengguna sekitar.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              Navigator.pop(modalContext);
              try {
                await ref.read(exploreControllerProvider.notifier).deleteMyStatus(statusId: statusId);
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Catatan sekitar Anda berhasil dihapus dari peta.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              } catch (e) {
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus catatan: ${e.toString()}'),
                      backgroundColor: Colors.red.shade900,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus Sekarang'),
          ),
        ],
      ),
    );
  }
}
