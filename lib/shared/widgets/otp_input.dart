import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Komponen Input Kode OTP 6 Digit sesuai DESIGN.md Bagian 6.4.
/// - 6 kotak individual (44 x 52 dp), radius 12 dp.
/// - Perpindahan fokus otomatis, dukungan paste 6 digit, dan oneTimeCode autofill.
/// - Garis tepi primary saat aktif/terisi, danger saat error.
/// - Hitung mundur kirim ulang 60 detik.
class OtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onResend;
  final String? errorText;
  final int resendCountdownSeconds;

  const OtpInput({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.onResend,
    this.errorText,
    this.resendCountdownSeconds = 60,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _secondsRemaining = widget.resendCountdownSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = widget.resendCountdownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    // Tangani paste multi-digit
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < widget.length && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final nextIndex = digits.length < widget.length ? digits.length : widget.length - 1;
      _focusNodes[nextIndex].requestFocus();

      _notifyChanges();
      return;
    }

    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    _notifyChanges();
  }

  void _notifyChanges() {
    final code = _currentCode;
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  void _handleResend() {
    if (_secondsRemaining == 0) {
      widget.onResend?.call();
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              final isFilled = _controllers[index].text.isNotEmpty;
              final isFocused = _focusNodes[index].hasFocus;

              return SizedBox(
                width: AppSpacing.otpBoxWidth,
                height: AppSpacing.otpBoxHeight,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.otpBorderRadius,
                    border: Border.all(
                      color: hasError
                          ? AppColors.danger
                          : (isFocused || isFilled
                              ? AppColors.primary
                              : AppColors.surfaceBorder),
                      width: (isFocused || hasError) ? 1.5 : 1.0,
                    ),
                    boxShadow: isFocused && !hasError
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.backspace &&
                          _controllers[index].text.isEmpty &&
                          index > 0) {
                        _focusNodes[index - 1].requestFocus();
                        _controllers[index - 1].clear();
                        _notifyChanges();
                      }
                    },
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      textInputAction: index == widget.length - 1
                          ? TextInputAction.done
                          : TextInputAction.next,
                      style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
                      cursorColor: AppColors.primaryGlow,
                      maxLength: 1,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                      onChanged: (val) => _onDigitChanged(index, val),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (hasError) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              widget.errorText!,
              style: AppTextStyles.labelSmall(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.s24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tidak menerima kode? ',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
              ),
              if (_secondsRemaining > 0)
                Text(
                  'Kirim ulang (${_secondsRemaining}d)',
                  style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                )
              else
                InkWell(
                  onTap: _handleResend,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Kirim ulang',
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.primaryGlow,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
