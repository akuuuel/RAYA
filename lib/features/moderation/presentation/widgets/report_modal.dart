import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/report_ticket.dart';
import '../controllers/moderation_controller.dart';

/// Modal Dialog Pelaporan Pelanggaran sesuai FR-41, FR-42, dan FR-43.
class ReportModal extends ConsumerStatefulWidget {
  final String reportedUserId;
  final ReportType reportType;
  final String targetId;
  final String? messagePlaintext; // Diisi jika melaporkan pesan chat (FR-42)

  const ReportModal({
    super.key,
    required this.reportedUserId,
    required this.reportType,
    required this.targetId,
    this.messagePlaintext,
  });

  static Future<void> show(
    BuildContext context, {
    required String reportedUserId,
    required ReportType reportType,
    required String targetId,
    String? messagePlaintext,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ReportModal(
        reportedUserId: reportedUserId,
        reportType: reportType,
        targetId: targetId,
        messagePlaintext: messagePlaintext,
      ),
    );
  }

  @override
  ConsumerState<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends ConsumerState<ReportModal> {
  ReportReason _selectedReason = ReportReason.harassment;
  bool _consentAttachDecrypted = true;

  @override
  Widget build(BuildContext context) {
    final isHighPriority = _selectedReason.isHighPriority;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenMarginHorizontal,
        right: AppSpacing.screenMarginHorizontal,
        top: AppSpacing.s20,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s24,
      ),
      child: SingleChildScrollView(
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
            Row(
              children: [
                const Icon(Icons.report_problem_rounded, color: AppColors.danger, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Laporkan Pelanggaran (FR-41)',
                  style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Pilih alasan laporan untuk ditinjau oleh tim kami demi menjaga keamanan komunitas RAYA.',
              style: AppTextStyles.labelSmall(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s16),

            // Pilihan Alasan Pelaporan
            ...ReportReason.values.map((reason) {
              final isSelected = _selectedReason == reason;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFF0F0C1B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                  ),
                ),
                child: RadioListTile<ReportReason>(
                  value: reason,
                  groupValue: _selectedReason,
                  title: Text(
                    reason.label,
                    style: AppTextStyles.bodyMedium(
                      color: reason.isHighPriority ? AppColors.danger : AppColors.textPrimary,
                    ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
                  ),
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
              );
            }),

            // Banner Indikator Prioritas Tinggi (FR-43)
            if (isHighPriority) ...[
              const SizedBox(height: AppSpacing.s8),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prioritas Tinggi: Laporan ini segera diteruskan ke tim penanganan darurat (FR-43).',
                        style: AppTextStyles.labelSmall(color: AppColors.danger)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Konfirmasi Dekripsi Pesan Terenkripsi (FR-42)
            if (widget.reportType == ReportType.message && widget.messagePlaintext != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141122),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Persetujuan Bukti Teks Terenkripsi (FR-42):',
                      style: AppTextStyles.labelSmall(color: AppColors.primaryGlow)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Karena enkripsi end-to-end, server tidak dapat membaca pesan Anda. Salinan pesan akan didekripsi langsung dari perangkat Anda atas persetujuan Anda sebagai bukti laporan.',
                      style: AppTextStyles.labelSmall(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _consentAttachDecrypted,
                      title: Text(
                        'Sertakan salinan teks: "${widget.messagePlaintext}"',
                        style: AppTextStyles.labelSmall(color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _consentAttachDecrypted = val ?? false);
                      },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.s20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isHighPriority ? AppColors.danger : AppColors.primary,
                minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.buttonBorderRadius,
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);

                final evidence = (widget.reportType == ReportType.message && _consentAttachDecrypted)
                    ? widget.messagePlaintext
                    : null;

                final success = await ref
                    .read(moderationControllerProvider.notifier)
                    .submitReport(
                      reportedUserId: widget.reportedUserId,
                      reportType: widget.reportType,
                      targetId: widget.targetId,
                      reason: _selectedReason,
                      decryptedContentEvidence: evidence,
                    );

                if (context.mounted && success) {
                  final state = ref.read(moderationControllerProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.successMessage ?? 'Laporan berhasil dikirim.'),
                      backgroundColor: isHighPriority ? AppColors.danger : AppColors.primary,
                    ),
                  );
                }
              },
              child: Text(
                isHighPriority ? 'Kirim Laporan Prioritas Tinggi' : 'Kirim Laporan',
                style: AppTextStyles.labelLarge(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

