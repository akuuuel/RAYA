import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Modal Dokumen Ketentuan Layanan & Kebijakan Privasi RAYA.
class TermsAndPrivacyModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF130E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMarginHorizontal,
            AppSpacing.s20,
            AppSpacing.screenMarginHorizontal,
            AppSpacing.s20,
          ),
          child: Column(
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
              const Row(
                children: [
                  Icon(Icons.description_rounded, color: AppColors.primaryGlow, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Ketentuan & Kebijakan Privasi',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildSection(
                      '1. Pengantar Layanan',
                      'Selamat datang di RAYA. Aplikasi ini dirancang untuk komunikasi privat terenkripsi end-to-end dan pemantauan lokasi berbasis persetujuan bersama (consent-based). Dengan menggunakan aplikasi ini, Anda menyetujui ketentuan berikut.',
                    ),
                    _buildSection(
                      '2. Batas Usia dan Keselamatan (FR-04)',
                      'Pengguna di bawah 18 tahun (anak dan remaja) dibatasi dari fitur pelacakan lokasi demi menjaga keselamatan dan perlindungan anak sesuai standar regulasi.',
                    ),
                    _buildSection(
                      '3. Enkripsi dan Kerahasiaan Pesan (FR-10, FR-11)',
                      'Seluruh percakapan dienkripsi dengan protokol kriptografi modern di perangkat pengirim dan hanya dapat dibuka oleh perangkat penerima. RAYA tidak dapat memulihkan pesan jika Anda kehilangan kunci privat lokal tanpa cadangan.',
                    ),
                    _buildSection(
                      '4. Penggunaan Lokasi dan Peta Publik (FR-20 s/d FR-34)',
                      'Berbagi lokasi langsung (Live Tracking) hanya berlangsung selama batas waktu yang disetujui (15 menit, 1 jam, atau 8 jam). Di peta Catatan Sekitar, koordinat disamarkan minimal 300 meter untuk mencegah doxxing.',
                    ),
                    _buildSection(
                      '5. Konten yang Dilarang',
                      'Dilarang menggunakan RAYA untuk pelecehan, spam, konten ilegal, ujaran kebencian, atau penipuan. Setiap pengguna berhak melaporkan pelanggaran melalui fitur Laporkan.',
                    ),
                    _buildSection(
                      '6. Kontak & Bantuan',
                      'Untuk pertanyaan mengenai hak data dan privasi, Anda dapat menghubungi tim perlindungan data kami melalui menu Bantuan & Moderasi.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF19132E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.primaryGlow, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}

