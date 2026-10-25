import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Konfigurasi ThemeData resmi RAYA sesuai DESIGN.md Bagian 2 dan Bagian 11.
/// Hanya mendukung tema gelap (dark mode only).
class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.textPrimary,
        secondary: AppColors.primaryGlow,
        onSecondary: AppColors.background,
        error: AppColors.danger,
        onError: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
        titleTextStyle: AppTextStyles.titleMedium(color: AppColors.textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s16,
        ),
        hintStyle: AppTextStyles.bodyMedium(color: AppColors.textMuted),
        labelStyle: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
        errorStyle: AppTextStyles.labelSmall(color: AppColors.danger),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
