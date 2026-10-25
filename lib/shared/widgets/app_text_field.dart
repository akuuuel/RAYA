import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Input field resmi RAYA sesuai DESIGN.md Bagian 6.3.
/// - Menampilkan label eksplisit di atas input field.
/// - Tinggi field 56 dp dengan radius 14 dp.
/// - Border surfaceBorder (#2A2538), primary (#7C3AED) saat fokus, danger (#EF4444) saat error.
/// - Pesan error ditampilkan di bawah field.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final String? semanticsLabel;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
    this.autofillHints,
    this.semanticsLabel,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Semantics(
      label: widget.semanticsLabel ?? widget.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label di atas input (DESIGN.md 6.3)
          Text(
            widget.label,
            style: AppTextStyles.bodyMedium(
              color: hasError ? AppColors.danger : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: AppSpacing.inputHeight,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.inputBorderRadius,
              border: Border.all(
                color: hasError
                    ? AppColors.danger
                    : (_isFocused ? AppColors.primary : AppColors.surfaceBorder),
                width: (_isFocused || hasError) ? 1.5 : 1.0,
              ),
              boxShadow: _isFocused && !hasError
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              obscureText: widget.obscureText,
              readOnly: widget.readOnly,
              onTap: widget.onTap,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              autofillHints: widget.autofillHints,
              style: AppTextStyles.bodyLarge(color: AppColors.textPrimary),
              cursorColor: AppColors.primaryGlow,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                prefixIcon: widget.prefixIcon != null
                    ? IconTheme(
                        data: IconThemeData(
                          color: _isFocused ? AppColors.primaryGlow : AppColors.textMuted,
                          size: 20,
                        ),
                        child: widget.prefixIcon!,
                      )
                    : null,
                suffixIcon: widget.suffixIcon != null
                    ? IconTheme(
                        data: const IconThemeData(
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        child: widget.suffixIcon!,
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              widget.errorText!,
              style: AppTextStyles.labelSmall(color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}
