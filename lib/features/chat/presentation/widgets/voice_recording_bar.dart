import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Bar status perekaman suara terisolasi.
/// Mengelola timer durasi secara mandiri agar tidak me-rebuild ListView pesan
/// dan mencegah pesan bergeser posisinya saat merekam suara.
class VoiceRecordingBar extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(int duration) onSend;

  const VoiceRecordingBar({
    super.key,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<VoiceRecordingBar> createState() => _VoiceRecordingBarState();
}

class _VoiceRecordingBarState extends State<VoiceRecordingBar> {
  int _duration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _duration++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_duration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_duration % 60).toString().padLeft(2, '0');

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            tooltip: 'Batal rekam',
            onPressed: widget.onCancel,
          ),
          const SizedBox(width: 4),
          // Titik merah berkedip indikator aktif rekam
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          // Animasi visualizer bar suara
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(14, (i) {
                final barHeight = 8.0 + ((i + _duration) % 4) * 6.0;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 3,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGlow.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: AppColors.textPrimary, size: 20),
              tooltip: 'Kirim rekaman suara',
              onPressed: () => widget.onSend(_duration),
            ),
          ),
        ],
      ),
    );
  }
}

