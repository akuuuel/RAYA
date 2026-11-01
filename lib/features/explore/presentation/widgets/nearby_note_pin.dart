import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/public_status.dart';

/// Widget Pin Catatan Gaya Instagram Notes yang mengambang di atas peta.
/// Terdiri dari balon pemikiran/catatan (thought bubble) di atas,
/// dan avatar pengguna dengan ring gradien di bawahnya.
class NearbyNotePin extends StatelessWidget {
  final PublicStatus status;
  final VoidCallback onTap;
  final bool isSelected;

  const NearbyNotePin({
    super.key,
    required this.status,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = status.isMine;
    final displayName = isMine
        ? 'Catatan Anda'
        : (status.authorName.split(' ').first);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Balon Catatan Gaya Instagram Notes (Thought Bubble)
          Container(
            constraints: const BoxConstraints(maxWidth: 160, minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isMine
                  ? const Color(0xFF281E48)
                  : const Color(0xFF1E1933),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMine
                    ? AppColors.primaryGlow
                    : (isSelected ? const Color(0xFF00CEC9) : const Color(0xFF483D8B)),
                width: isSelected || isMine ? 1.8 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isMine ? AppColors.primary : const Color(0xFF00CEC9))
                      .withValues(alpha: isSelected ? 0.35 : 0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              status.text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),

          // 2. Ekor Titik Balon Pemikiran (Thought Bubble Tail Dots)
          CustomPaint(
            size: const Size(14, 8),
            painter: _ThoughtBubbleTailPainter(
              color: isMine ? AppColors.primaryGlow : const Color(0xFF483D8B),
            ),
          ),
          const SizedBox(height: 2),

          // 3. Avatar Bulat dengan Ring Gradien
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isMine
                  ? AppColors.primaryGradient
                  : const LinearGradient(
                      colors: [Color(0xFF00CEC9), Color(0xFF6C5CE7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: isMine
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : const Color(0xFF00CEC9).withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF140F24),
              ),
              child: Center(
                child: Text(
                  status.authorName.isNotEmpty ? status.authorName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // 4. Nama Pengguna
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              displayName,
              style: TextStyle(
                color: isMine ? AppColors.primaryGlow : Colors.white70,
                fontSize: 10.5,
                fontWeight: isMine ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter untuk ekor balon pemikiran (dua lingkaran kecil menurun)
class _ThoughtBubbleTailPainter extends CustomPainter {
  final Color color;
  _ThoughtBubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Titik atas agak besar
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.3), 2.2, paint);
    // Titik bawah kecil
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.8), 1.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

