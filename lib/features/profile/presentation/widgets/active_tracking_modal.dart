import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../tracking/presentation/controllers/tracking_controller.dart';

/// Modal Tampilan Transparansi: Siapa yang Sedang Memantau Lokasi Saya (FR-27).
/// Sesuai mandat UU PDP No. 27/2022: Pengguna berhak tahu secara langsung sesi pemantauan aktif
/// dan dapat mencabut izin berbagi lokasi kapan saja dengan sekali klik.
class ActiveTrackingModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF130E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final trackingState = ref.watch(trackingControllerProvider);
          final activeSessions = trackingState.activeSessions;

          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMarginHorizontal,
              AppSpacing.s20,
              AppSpacing.screenMarginHorizontal,
              AppSpacing.s24,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activeSessions.isNotEmpty
                            ? AppColors.warning.withValues(alpha: 0.2)
                            : AppColors.success.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        activeSessions.isNotEmpty
                            ? Icons.radar_rounded
                            : Icons.check_circle_outline_rounded,
                        color: activeSessions.isNotEmpty
                            ? AppColors.warning
                            : AppColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Siapa yang Memantau Saya',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            activeSessions.isNotEmpty
                              ? '${activeSessions.length} sesi berbagi lokasi aktif saat ini'
                              : 'Tidak ada sesi berbagi lokasi aktif',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (activeSessions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1530),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.shield_rounded, color: AppColors.success, size: 36),
                        SizedBox(height: 8),
                        Text(
                          'Lokasi Anda Aman & Terlindungi',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tidak ada kontak yang sedang memantau koordinat GPS Anda. Anda selalu memegang kendali penuh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else ...[
                  ...activeSessions.map((session) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1736),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryGlow.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: const Center(
                              child: Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.target.displayName ?? session.target.username ?? 'Kontak Terhubung',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  session.expiresAt != null
                                      ? 'Berakhir: ${session.expiresAt!.hour.toString().padLeft(2, '0')}:${session.expiresAt!.minute.toString().padLeft(2, '0')}'
                                      : 'Durasi: ${session.durationLabel}',
                                  style: const TextStyle(color: Color(0xFF00CEC9), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              ref.read(trackingControllerProvider.notifier).stopSession(session.id);
                            },
                            child: const Text('Hentikan', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      for (final s in activeSessions) {
                        ref.read(trackingControllerProvider.notifier).stopSession(s.id);
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Semua sesi berbagi lokasi telah dihentikan.'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    },
                    child: const Text(
                      'Hentikan Semua Pemantauan Seketika',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                const Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: AppColors.textMuted, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Kepatuhan UU PDP No. 27/2022: Pelacakan tanpa izin atau riwayat jejak perjalanan tidak pernah disimpan di server.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

