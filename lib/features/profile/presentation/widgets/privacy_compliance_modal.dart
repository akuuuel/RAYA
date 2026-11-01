import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Modal Transparansi Kepatuhan Perlindungan Data Pribadi (UU PDP No. 27/2022).
class PrivacyComplianceModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF130E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMarginHorizontal,
          AppSpacing.s20,
          AppSpacing.screenMarginHorizontal,
          AppSpacing.s24,
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00CEC9).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Color(0xFF00CEC9), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kepatuhan Privasi (UU PDP)',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Undang-Undang No. 27 Tahun 2022',
                          style: TextStyle(color: Color(0xFF00CEC9), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildPillarItem(
                icon: Icons.minimize_rounded,
                title: '1. Prinsip Minimalisasi Data (Data Minimization)',
                desc: 'RAYA hanya mengumpulkan data yang mutlak diperlukan untuk mengoperasikan obrolan dan berbagi lokasi.',
              ),
              const SizedBox(height: 12),
              _buildPillarItem(
                icon: Icons.location_off_rounded,
                title: '2. Tanpa Jejak Riwayat Lokasi (Zero Location Footprint)',
                desc: 'Titik koordinat GPS hanya dikirim saat sesi berbagi aktif dan langsung dihapus saat sesi berakhir. Server tidak pernah merekam jejak perjalanan Anda.',
              ),
              const SizedBox(height: 12),
              _buildPillarItem(
                icon: Icons.blur_on_rounded,
                title: '3. Penyamaran Lokasi Sekitar 300 Meter (FR-30)',
                desc: 'Pada peta publik Tab Sekitar, titik koordinat pengguna disamarkan acak minimal 300 meter untuk melindungi kediaman dan privasi Anda.',
              ),
              const SizedBox(height: 12),
              _buildPillarItem(
                icon: Icons.vpn_key_rounded,
                title: '4. Enkripsi Ujung-ke-Ujung (E2EE)',
                desc: 'Pesan, foto, dan rekaman suara dienkripsi dengan kunci perangkat lokal. Karyawan dan server RAYA tidak dapat membaca isi pesan Anda.',
              ),
              const SizedBox(height: 12),
              _buildPillarItem(
                icon: Icons.delete_forever_rounded,
                title: '5. Hak untuk Dihapus (Right to Erasure)',
                desc: 'Pengguna dapat menghapus akun secara permanen kapan saja melalui menu Hapus Akun Saya.',
              ),
              const SizedBox(height: 18),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00CEC9),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Saya Memahami', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildPillarItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF19142E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00CEC9), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

