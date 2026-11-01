import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Layar Tampilan Foto Penuh (Full Screen Image Viewer) dengan kemampuan pinch-to-zoom,
/// pan, dan double tap to zoom tanpa library pihak ketiga yang berat.
class ImageViewerScreen extends StatefulWidget {
  final String? base64Data;
  final String? imageUrl;
  final String? caption;
  final String senderName;
  final DateTime? timestamp;

  const ImageViewerScreen({
    super.key,
    this.base64Data,
    this.imageUrl,
    this.caption,
    required this.senderName,
    this.timestamp,
  });

  static void show(
    BuildContext context, {
    String? base64Data,
    String? imageUrl,
    String? caption,
    required String senderName,
    DateTime? timestamp,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) => ImageViewerScreen(
          base64Data: base64Data,
          imageUrl: imageUrl,
          caption: caption,
          senderName: senderName,
          timestamp: timestamp,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    Matrix4 endMatrix;
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    if (currentScale > 1.2) {
      // Reset zoom ke ukuran awal (1.0x)
      endMatrix = Matrix4.identity();
    } else {
      // Zoom 2.5x ke titik tap
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      endMatrix = Matrix4.identity()
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        ..scale(2.5);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurveTween(curve: Curves.easeOutCubic).animate(_animationController));

    _animationController.forward(from: 0).then((_) {
      _transformationController.value = endMatrix;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (widget.base64Data != null && widget.base64Data!.isNotEmpty) {
      try {
        final bytes = base64Decode(widget.base64Data!);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 60),
          ),
        );
      } catch (_) {
        imageWidget = const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 60),
        );
      }
    } else if (widget.imageUrl != null && widget.imageUrl!.startsWith('http')) {
      imageWidget = Image.network(
        widget.imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 60),
        ),
      );
    } else if (widget.imageUrl != null && File(widget.imageUrl!).existsSync()) {
      imageWidget = Image.file(
        File(widget.imageUrl!),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 60),
        ),
      );
    } else {
      imageWidget = const Center(
        child: Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 60),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gambar interaktif dengan zoom & pan
          GestureDetector(
            onTap: () {
              setState(() => _showControls = !_showControls);
            },
            onDoubleTapDown: (details) => _doubleTapDetails = details,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.8,
              maxScale: 5.0,
              clipBehavior: Clip.none,
              child: Center(child: imageWidget),
            ),
          ),

          // Header Bar Kontrol Atas (Tombol Tutup, Nama Pengirim, Info)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                right: 16,
                bottom: 12,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.senderName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.timestamp != null)
                          Text(
                            'Foto Terenkripsi E2EE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer Bar Bawah (Caption jika ada)
          if (widget.caption != null && widget.caption!.isNotEmpty)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showControls ? 0 : -140,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  left: 20,
                  right: 20,
                  top: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Text(
                  widget.caption!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

