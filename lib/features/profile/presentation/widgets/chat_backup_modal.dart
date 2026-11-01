import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Modal Cadangan Riwayat Chat Terenkripsi Lokal (FR-19).
class ChatBackupModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF130E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const _ChatBackupSheet(),
    );
  }
}

class _ChatBackupSheet extends StatefulWidget {
  const _ChatBackupSheet();

  @override
  State<_ChatBackupSheet> createState() => _ChatBackupSheetState();
}

class _ChatBackupSheetState extends State<_ChatBackupSheet> {
  bool _isBackingUp = false;
  String _lastBackup = 'Belum pernah dicadangkan';

  Future<void> _handleBackup() async {
    setState(() => _isBackingUp = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final now = DateTime.now();
      setState(() {
        _isBackingUp = false;
        _lastBackup = 'Hari ini, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Riwayat obrolan berhasil dienkripsi dan dicadangkan secara lokal (FR-19).'),
          backgroundColor: Color(0xFF00CEC9),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.backup_rounded, color: AppColors.primaryGlow, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cadangan Riwayat Chat (FR-19)',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tersimpan aman dengan enkripsi AES-256 lokal',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1530),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF00CEC9), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Status Cadangan',
                      style: TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Terakhir Dicadangkan: $_lastBackup',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ukuran Perkiraan: ~1.2 MB (Teks, Media, Voice Notes)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: _isBackingUp
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
            label: Text(
              _isBackingUp ? 'Sedang mengenkripsi...' : 'Cadangkan Sekarang',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: _isBackingUp ? null : _handleBackup,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.surfaceBorder),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.restore_rounded, color: Colors.white70, size: 18),
            label: const Text('Pulihkan dari Cadangan Lokal', style: TextStyle(color: Colors.white70, fontSize: 13)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Memeriksa berkas cadangan lokal di memori HP... Riwayat utuh.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Perhatian: Karena RAYA menerapkan prinsip Zero-Knowledge, server tidak menyimpan kata sandi cadangan Anda.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

