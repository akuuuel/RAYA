import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message.dart';

/// Banner Pratayang Balasan Pesan (Reply Preview) di atas bilah input obrolan.
class ReplyPreviewBar extends StatelessWidget {
  final Message replyMessage;
  final String peerName;
  final VoidCallback onCancel;

  const ReplyPreviewBar({
    super.key,
    required this.replyMessage,
    required this.peerName,
    required this.onCancel,
  });

  String _getPreviewText() {
    final raw = replyMessage.content;
    if (raw.startsWith('REPLY:')) {
      final parts = raw.substring(6).split('||');
      if (parts.length > 2) {
        return _formatSnippet(parts.sublist(2).join('||'));
      }
    }
    return _formatSnippet(raw);
  }

  String _formatSnippet(String raw) {
    if (raw.startsWith('IMAGE:')) {
      final parts = raw.substring(6).split('||');
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        return '📷 ${parts[1].trim()}';
      }
      return '📷 Foto';
    }
    if (raw.startsWith('FILE:')) {
      final parts = raw.substring(5).split('||');
      final fileName = parts.isNotEmpty ? parts[0] : 'Dokumen';
      return '📄 $fileName';
    }
    if (raw.startsWith('AUDIO:')) {
      return '🎤 Pesan Suara';
    }
    if (replyMessage.messageType == MessageType.image) return '📷 Foto';
    if (replyMessage.messageType == MessageType.voice) return '🎤 Pesan Suara';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final senderName = replyMessage.isOutgoing ? 'Anda' : peerName;
    final snippet = _getPreviewText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF16112A),
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.reply_rounded, color: AppColors.primaryGlow, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Membalas $senderName',
                  style: const TextStyle(
                    color: AppColors.primaryGlow,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  snippet,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
            tooltip: 'Batal balas',
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

