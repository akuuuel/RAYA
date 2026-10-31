import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Indikator Berbagi Lokasi Aktif sesuai DESIGN.md Bagian 6.10 dan Bagian 9.
/// - Titik kecil warna [AppColors.locationActive] (#34D399) dengan animasi pulsa lembut (1,5 detik).
/// - Menghormati pengaturan kurangi gerakan sistem.
class LocationActiveDot extends StatefulWidget {
  final double size;

  const LocationActiveDot({
    super.key,
    this.size = 10.0,
  });

  @override
  State<LocationActiveDot> createState() => _LocationActiveDotState();
}

class _LocationActiveDotState extends State<LocationActiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          color: AppColors.locationActive,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size * _pulseAnimation.value,
          height: widget.size * _pulseAnimation.value,
          decoration: BoxDecoration(
            color: AppColors.locationActive,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.locationActive.withValues(alpha: 0.4),
                blurRadius: 8 * _pulseAnimation.value,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

