import 'package:flutter/material.dart';

/// Token warna resmi RAYA sesuai DESIGN.md Bagian 3.
/// Nilai heksadesimal tidak boleh ditulis langsung di widget layar.
class AppColors {
  const AppColors._();

  // Latar dan Surface
  static const Color background = Color(0xFF07050F);
  static const Color surface = Color(0xFF15121F);
  static const Color surfaceBorder = Color(0xFF2A2538);

  // Aksen Ungu
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDeep = Color(0xFF5B21B6);
  static const Color primaryGlow = Color(0xFFA78BFA);

  // Teks
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B3C9);
  static const Color textMuted = Color(0xFF7D7790);

  // Status Fungsional
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color locationActive = Color(0xFF34D399);

  // Gradien Utama (Tombol dan Aksen)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDeep],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient verticalPrimaryGradient = LinearGradient(
    colors: [primary, primaryDeep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
