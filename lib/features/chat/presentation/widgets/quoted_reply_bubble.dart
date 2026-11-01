import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Kotak Kutipan Balasan Pesan (Quoted Reply Preview) di dalam bubble chat.
class QuotedReplyBubble extends StatelessWidget {
  final String senderName;
  final String contentSnippet;
  final bool isOutgoing;

  const QuotedReplyBubble({
    super.key,
    required this.senderName,
    required this.contentSnippet,
    required this.isOutgoing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isOutgoing
            ? Colors.black.withValues(alpha: 0.25)
            : const Color(0xFF0F0C1B),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isOutgoing ? Colors.white : const Color(0xFF00CEC9),
            width: 3.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            senderName,
            style: TextStyle(
              color: isOutgoing ? Colors.white : const Color(0xFF00CEC9),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            contentSnippet,
            style: TextStyle(
              color: isOutgoing ? Colors.white70 : AppColors.textSecondary,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

