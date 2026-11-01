import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/user_status.dart';
import '../controllers/status_controller.dart';

/// Layar Pemutar Cerita / Story Viewer Fullscreen (Instagram & WhatsApp style)
class StoryViewerScreen extends ConsumerStatefulWidget {
  final List<UserStatus> statuses;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.statuses,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animController;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _playStory();
  }

  void _playStory() {
    final current = widget.statuses[_currentIndex];
    // Tandai status sebagai dilihat secara otomatis
    ref.read(statusControllerProvider.notifier).markAsViewed(current.id);

    _animController.reset();
    _animController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.statuses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _playStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _playStory();
    } else {
      _animController.reset();
      _animController.forward();
    }
  }

  void _pause() {
    _isPaused = true;
    _animController.stop();
  }

  void _resume() {
    _isPaused = false;
    _animController.forward();
  }

  void _confirmDeleteStatus(UserStatus status) {
    _pause();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Status Ini?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Status Anda akan dihapus untuk semua orang dan tidak dapat dilihat lagi.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resume();
            },
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(statusControllerProvider.notifier).deleteMyStatus(status.id);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Status berhasil dihapus'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatStatusTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else {
      return DateFormat('dd MMM, HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.statuses[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth * 0.35) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            // Konten Cerita: Gambar atau Teks Berwarna
            Positioned.fill(
              child: _buildStoryContent(status),
            ),

            // Indikator Progress Bar & Informasi Pengguna
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    // Segmented Progress Bars di Atas
                    Row(
                      children: List.generate(widget.statuses.length, (i) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedBuilder(
                              animation: _animController,
                              builder: (context, _) {
                                double progress = 0.0;
                                if (i < _currentIndex) {
                                  progress = 1.0;
                                } else if (i == _currentIndex) {
                                  progress = _animController.value;
                                }

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    minHeight: 2.5,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),

                    // Header Info Pengguna & Tombol Tutup
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: Center(
                            child: Text(
                              status.userName.isNotEmpty
                                  ? status.userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _formatStatusTime(status.createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tombol Hapus khusus jika ini status milik saya
                        Consumer(
                          builder: (context, ref, _) {
                            final myStatuses = ref.watch(statusControllerProvider).myStatuses;
                            final isMyStatus = myStatuses.any((s) => s.id == status.id);
                            if (isMyStatus) {
                              return IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                                tooltip: 'Hapus status ini',
                                onPressed: () => _confirmDeleteStatus(status),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(UserStatus status) {
    if (status.isPhoto) {
      ImageProvider? imgProvider;
      if (status.mediaBase64 != null && status.mediaBase64!.isNotEmpty) {
        try {
          final bytes = base64Decode(status.mediaBase64!);
          imgProvider = MemoryImage(bytes);
        } catch (_) {}
      } else if (status.mediaUrl != null) {
        imgProvider = NetworkImage(status.mediaUrl!);
      }

      return Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imgProvider != null)
              Image(
                image: imgProvider,
                fit: BoxFit.contain,
              )
            else
              const Center(
                child: Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 48),
              ),
            if (status.caption != null && status.caption!.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.caption!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Status Teks dengan Background Warna Menarik
    return Container(
      color: Color(status.bgColorValue),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Text(
          status.caption ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

