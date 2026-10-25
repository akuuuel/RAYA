import 'package:flutter/material.dart';

/// Skala spasi dan radius resmi RAYA sesuai DESIGN.md Bagian 5.
class AppSpacing {
  const AppSpacing._();

  // Skala Spasi (kelipatan 4)
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;

  // Standar Layout Layar
  static const double screenMarginHorizontal = 24.0;
  static const double formFieldSpacing = 16.0;
  static const double sectionSpacing = 32.0;

  // Radius Sudut
  static const double radiusButton = 16.0;
  static const double radiusInput = 14.0;
  static const double radiusOtp = 12.0;
  static const double radiusCard = 20.0;
  static const double radiusBottomSheet = 28.0;
  static const double radiusPill = 999.0;

  // Ukuran Komponen Kunci
  static const double buttonHeight = 56.0;
  static const double inputHeight = 56.0;
  static const double minTouchTarget = 44.0;
  static const double otpBoxWidth = 44.0;
  static const double otpBoxHeight = 52.0;

  // BorderRadius Helpers
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(radiusButton);
  static final BorderRadius inputBorderRadius = BorderRadius.circular(radiusInput);
  static final BorderRadius otpBorderRadius = BorderRadius.circular(radiusOtp);
  static final BorderRadius cardBorderRadius = BorderRadius.circular(radiusCard);
  static const BorderRadius bottomSheetBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(radiusBottomSheet),
    topRight: Radius.circular(radiusBottomSheet),
  );
  static final BorderRadius pillBorderRadius = BorderRadius.circular(radiusPill);
}
