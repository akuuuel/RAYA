import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Controller untuk status "sedang mengetik" di room chat.
/// Menggunakan Supabase Realtime Broadcast channel sehingga tidak perlu tabel baru.
class TypingController {
  final String conversationId;
  final String currentUserId;
  RealtimeChannel? _channel;
  Timer? _typingTimer;
  bool _isTypingSent = false;

  // Callback dipanggil saat status mengetik lawan chat berubah
  final void Function(bool isTyping) onPeerTypingChanged;

  TypingController({
    required this.conversationId,
    required this.currentUserId,
    required this.onPeerTypingChanged,
  });

  void init() {
    _channel = Supabase.instance.client
        .channel('typing:$conversationId')
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final userId = payload['user_id'] as String?;
            final typing = payload['is_typing'] as bool? ?? false;
            if (userId != null && userId != currentUserId) {
              onPeerTypingChanged(typing);
            }
          },
        )
        .subscribe();
  }

  /// Dipanggil setiap karakter diketik
  void onTyping() {
    if (!_isTypingSent) {
      _isTypingSent = true;
      _sendTypingStatus(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _isTypingSent = false;
      _sendTypingStatus(false);
    });
  }

  void _sendTypingStatus(bool isTyping) {
    _channel?.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': currentUserId, 'is_typing': isTyping},
    );
  }

  void stopTyping() {
    _typingTimer?.cancel();
    if (_isTypingSent) {
      _isTypingSent = false;
      _sendTypingStatus(false);
    }
  }

  void dispose() {
    stopTyping();
    _typingTimer?.cancel();
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
  }
}
