import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Gaya teks resmi RAYA menggunakan Plus Jakarta Sans sesuai DESIGN.md Bagian 4.
class AppTextStyles {
  const AppTextStyles._();

  /// Judul layar onboarding (32 sp, Bold 700)
  static TextStyle displayLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.25,
    );
  }

  /// Judul layar login dan verifikasi (24 sp, Bold 700)
  static TextStyle headlineMedium({Color color = AppColors.textPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.3,
    );
  }

  /// Nama kontak, judul kartu (16 sp, Semibold 600)
  static TextStyle titleMedium({Color color = AppColors.textPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.4,
    );
  }

  /// Isi pesan, teks utama (16 sp, Regular 400)
  static TextStyle bodyLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.5,
    );
  }

  /// Subjudul, deskripsi (14 sp, Regular 400)
  static TextStyle bodyMedium({Color color = AppColors.textSecondary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.45,
    );
  }

  /// Teks tombol utama & sekunder (16 sp, Semibold 600)
  static TextStyle labelLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.2,
    );
  }

  /// Waktu, keterangan kecil (12 sp, Medium 500)
  static TextStyle labelSmall({Color color = AppColors.textMuted}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.3,
    );
  }
}
