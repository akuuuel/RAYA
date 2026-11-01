import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/public_status.dart';
import 'nearby_note_pin.dart';

/// Canvas Peta Radar Realtime OLED untuk Catatan Sekitar.
/// Menampilkan latar peta vektor gelap dengan jalanan, radar konsentris,
/// dan pin-pin catatan gaya Instagram Notes yang ditempatkan secara geografis relatif.
class NearbyRadarMapCanvas extends StatefulWidget {
  final List<PublicStatus> statuses;
  final PublicStatus? myStatus;
  final Function(PublicStatus) onStatusSelected;
  final VoidCallback onMyStatusTap;
  final int radiusKm;

  const NearbyRadarMapCanvas({
    super.key,
    required this.statuses,
    this.myStatus,
    required this.onStatusSelected,
    required this.onMyStatusTap,
    required this.radiusKm,
  });

  @override
  State<NearbyRadarMapCanvas> createState() => _NearbyRadarMapCanvasState();
}

class _NearbyRadarMapCanvasState extends State<NearbyRadarMapCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerW = constraints.maxWidth / 2;
        final centerH = constraints.maxHeight / 2;
        final mapRadius = min(centerW, centerH) * 0.88;

        return InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(80),
          minScale: 0.8,
          maxScale: 2.2,
          child: Stack(
            children: [
              // 1. Gambar Grid Peta Gelap & Lingkaran Radar Realtime
              AnimatedBuilder(
                animation: _radarController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _RadarMapPainter(
                      radarAngle: _radarController.value * 2 * pi,
                      pulseValue: _radarController.value,
                    ),
                  );
                },
              ),

              // 2. Pusat Lokasi Anda Sendiri (Titik Inti Radar)
              Positioned(
                left: centerW - 55,
                top: centerH - 62,
                child: _buildMyCenterNotePin(),
              ),

              // 3. Pin Catatan Sekitar yang Mengambang (Instagram Notes Style)
              ..._buildNearbyPins(constraints.maxWidth, constraints.maxHeight, mapRadius),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyCenterNotePin() {
    final hasMyStatus = widget.myStatus != null && !widget.myStatus!.isExpired;

    return GestureDetector(
      onTap: widget.onMyStatusTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Balon Catatan Saya
          Container(
            constraints: const BoxConstraints(maxWidth: 150, minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF4834D4)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGlow, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              hasMyStatus ? widget.myStatus!.text : '+ Bagikan catatan...',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),

          // Avatar Saya dengan Indikator Radar
          Stack(
            alignment: Alignment.center,
            children: [
              // Lingkaran pulsa radar tengah
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryGlow.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 22),
                ),
              ),
              if (!hasMyStatus)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00CEC9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Anda (Pusat)',
              style: TextStyle(
                color: AppColors.primaryGlow,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNearbyPins(double width, double height, double radius) {
    final list = <Widget>[];
    final centerW = width / 2;
    final centerH = height / 2;

    // Filter status yang bukan milik saya
    final otherStatuses = widget.statuses.where((s) => !s.isMine).toList();

    // Sebarkan pin secara radial di sekitar pusat agar tidak bertumpukan
    for (int i = 0; i < otherStatuses.length; i++) {
      final status = otherStatuses[i];

      // Hitung posisi sudut dan jarak relatif di peta
      final angleStep = (2 * pi) / max(otherStatuses.length, 1);
      final angle = (i * angleStep) + 0.35; // rotasi sedikit
      final distRatio = 0.45 + ((i % 3) * 0.22); // variasi jarak radial
      final dist = radius * distRatio;

      final pinX = centerW + (cos(angle) * dist) - 75;
      final pinY = centerH + (sin(angle) * dist) - 55;

      list.add(
        Positioned(
          left: pinX,
          top: pinY,
          child: NearbyNotePin(
            status: status,
            onTap: () => widget.onStatusSelected(status),
          ),
        ),
      );
    }

    return list;
  }
}

/// Painter untuk menggambar latar belakang peta jalanan gelap dan gelombang radar
class _RadarMapPainter extends CustomPainter {
  final double radarAngle;
  final double pulseValue;

  _RadarMapPainter({
    required this.radarAngle,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) * 0.46;

    // 1. Gambar Garis-Garis Jalanan Kota Vektor Gelap (City Grid / Roads)
    final roadPaint = Paint()
      ..color = const Color(0xFF1B162E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = const Color(0xFF130E22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Garis diagonal jalan raya
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.75),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.8),
      Offset(size.width, size.height * 0.15),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.7, size.height),
      roadPaint,
    );

    // Garis grid sekunder
    for (double x = 40; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorRoadPaint);
    }
    for (double y = 40; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorRoadPaint);
    }

    // 2. Lingkaran Radar Konsentris (Realtime Range Rings)
    final ringPaint = Paint()
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final ringSteps = [0.25, 0.5, 0.75, 1.0];
    for (final step in ringSteps) {
      canvas.drawCircle(center, maxRadius * step, ringPaint);
    }

    // 3. Gelombang Pulsa Radar yang Memancar
    final pulseRadius = maxRadius * pulseValue;
    final pulsePaint = Paint()
      ..color = const Color(0xFF00CEC9).withValues(alpha: (1.0 - pulseValue) * 0.25)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, pulseRadius, pulsePaint);

    // 4. Garis Sapuan Radar yang Berputar (Radar Sweeping Beam)
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: FractionalOffset.center,
        startAngle: 0.0,
        endAngle: 2 * pi,
        colors: [
          Colors.transparent,
          const Color(0xFF6C5CE7).withValues(alpha: 0.0),
          const Color(0xFF00CEC9).withValues(alpha: 0.18),
        ],
        stops: const [0.0, 0.75, 1.0],
        transform: GradientRotation(radarAngle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // Garis jarum pemindai
    final needleEnd = Offset(
      center.dx + (cos(radarAngle) * maxRadius),
      center.dy + (sin(radarAngle) * maxRadius),
    );
    final needlePaint = Paint()
      ..color = const Color(0xFF00CEC9).withValues(alpha: 0.4)
      ..strokeWidth = 1.5;
    canvas.drawLine(center, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarMapPainter oldDelegate) {
    return oldDelegate.radarAngle != radarAngle || oldDelegate.pulseValue != pulseValue;
  }
}

