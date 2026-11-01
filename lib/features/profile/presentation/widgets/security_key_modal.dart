import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/crypto/key_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Modal Verifikasi Kunci Kriptografi & Kode Keamanan End-to-End (FR-12).
class SecurityKeyModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF130E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => FutureBuilder<String>(
        future: KeyStorageService.getPublicKey(),
        builder: (context, snapshot) {
          final publicKey = snapshot.data ?? 'Memuat kunci enkripsi...';

          // Format fingerprint 12 digit (6 blok @ 4 karakter)
          String fingerprint = '---- ---- ---- ---- ---- ----';
          if (publicKey.length >= 24) {
            final clean = publicKey.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
            final chunks = <String>[];
            for (var i = 0; i < 24 && i < clean.length; i += 4) {
              chunks.add(clean.substring(i, i + 4));
            }
            fingerprint = chunks.join('  ');
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMarginHorizontal,
              AppSpacing.s20,
              AppSpacing.screenMarginHorizontal,
              AppSpacing.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.enhanced_encryption_rounded, color: AppColors.primaryGlow, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kode Keamanan Perangkat (FR-12)',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Setiap percakapan di RAYA dilindungi enkripsi kurva eliptik X25519. Kunci privat hanya tersimpan di perangkat HP Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Fingerprint Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0C1B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'SIDIK JARI KEAMANAN ANDA',
                        style: TextStyle(
                          color: Color(0xFF00CEC9),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        fingerprint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tombol Salin Kunci Publik
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF00CEC9)),
                  label: const Text('Salin Kunci Identitas Publik', style: TextStyle(color: Color(0xFF00CEC9), fontSize: 13)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: publicKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kunci publik disalin ke papan klip.'),
                        backgroundColor: Color(0xFF00CEC9),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, size: 13, color: AppColors.success),
                    SizedBox(width: 6),
                    Text(
                      'Zero-Knowledge: Server Supabase tidak dapat membaca kunci privat Anda.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
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

