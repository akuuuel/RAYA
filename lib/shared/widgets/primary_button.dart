import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Tombol Utama RAYA sesuai DESIGN.md Bagian 6.1 dan Bagian 9.
/// - Lebar penuh (atau fleksibel), tinggi 56 dp.
/// - Gradien [AppColors.primary] ke [AppColors.primaryDeep].
/// - Radius 16 dp.
/// - Status: Normal, Ditekan (skala 0.98), Nonaktif (opasitas 40%), Memuat (CircularProgressIndicator).
class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final String? semanticsLabel;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.semanticsLabel,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  bool get _canTap => widget.isEnabled && !widget.isLoading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = widget.isEnabled ? 1.0 : 0.4;

    return Semantics(
      button: true,
      enabled: _canTap,
      label: widget.semanticsLabel ?? widget.text,
      child: AnimatedScale(
        scale: _isPressed && _canTap ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: Opacity(
          opacity: effectiveOpacity,
          child: Container(
            width: widget.width ?? double.infinity,
            height: AppSpacing.buttonHeight,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppSpacing.buttonBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: AppSpacing.buttonBorderRadius,
                onHighlightChanged: (highlighted) {
                  if (_canTap && mounted) {
                    setState(() => _isPressed = highlighted);
                  }
                },
                onTap: _canTap ? widget.onPressed : null,
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textPrimary,
                            ),
                          ),
                        )
                      : Text(
                          widget.text,
                          style: AppTextStyles.labelLarge(
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
