enum MessageType {
  text,
  image,
  voice,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
}

/// Entitas Pesan Chat Terenkripsi End-to-End sesuai FR-10, FR-11, FR-13, FR-16, dan FR-18.
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String recipientId;
  final String content; // Teks hasil dekripsi lokal di perangkat
  final String ciphertext; // Ciphertext terenkripsi yang disimpan di server (FR-11)
  final String nonce;
  final MessageType messageType;
  final MessageStatus status;
  final DateTime createdAt;
  final bool isOutgoing;
  final bool deletedForAll;

  /// Alias untuk content (teks sudah terdekripsi lokal) — untuk kompatibilitas dengan chat_room_screen
  String? get decryptedText => content.isNotEmpty ? content : null;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.ciphertext,
    required this.nonce,
    this.messageType = MessageType.text,
    this.status = MessageStatus.sent,
    required this.createdAt,
    required this.isOutgoing,
    this.deletedForAll = false,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? recipientId,
    String? content,
    String? ciphertext,
    String? nonce,
    MessageType? messageType,
    MessageStatus? status,
    DateTime? createdAt,
    bool? isOutgoing,
    bool? deletedForAll,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      ciphertext: ciphertext ?? this.ciphertext,
      nonce: nonce ?? this.nonce,
      messageType: messageType ?? this.messageType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      deletedForAll: deletedForAll ?? this.deletedForAll,
    );
  }
}

