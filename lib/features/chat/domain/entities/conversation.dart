import '../../../auth/domain/entities/user_profile.dart';
import 'message.dart';

/// Entitas Percakapan 1-on-1 sesuai PRD v0.3 Bagian 7.5 & 8.3.
class Conversation {
  final String id;
  final UserProfile otherUser;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime lastMessageAt;
  final bool isTyping;

  const Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    required this.lastMessageAt,
    this.isTyping = false,
  });

  Conversation copyWith({
    String? id,
    UserProfile? otherUser,
    Message? lastMessage,
    int? unreadCount,
    DateTime? lastMessageAt,
    bool? isTyping,
  }) {
    return Conversation(
      id: id ?? this.id,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

