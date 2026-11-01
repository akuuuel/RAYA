import '../../../auth/domain/entities/user_profile.dart';
import '../../../../core/crypto/crypto_service.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

/// Implementasi Mock Chat Repository dengan Kriptografi Riil untuk pengujian lokal terisolasi.
class MockChatRepository implements ChatRepository {
  late final String _myPrivateKey;
  late final String _myPublicKey;

  late final String _peerPrivateKey;
  late final String _peerPublicKey;

  final List<Conversation> _conversations = [];
  final Map<String, List<Message>> _messagesByConversation = {};

  MockChatRepository() {
    // Generate key pair untuk pengguna saat ini
    final myKeys = CryptoService.generateKeyPair();
    _myPrivateKey = myKeys['privateKey']!;
    _myPublicKey = myKeys['publicKey']!;

    // Generate key pair untuk kontak default (Rina Pratama)
    final peerKeys = CryptoService.generateKeyPair();
    _peerPrivateKey = peerKeys['privateKey']!;
    _peerPublicKey = peerKeys['publicKey']!;

    final rinaUser = UserProfile(
      id: 'mock-user-rina',
      email: 'rina@raya.id',
      username: 'rina_pratama',
      displayName: 'Rina Pratama',
      birthDate: DateTime(1996, 5, 12),
      isAdult: true,
    );

    const convId = 'conv-demo-1';
    final now = DateTime.now();

    // Enkripsi pesan selamat datang dari Rina menggunakan CryptoService riil
    final encryptedFromPeer = CryptoService.encrypt(
      plaintext: 'Halo! Pesan ini dienkripsi secara end-to-end.',
      senderPrivateKey: _peerPrivateKey,
      recipientPublicKey: _myPublicKey,
    );

    final initialMessage = Message(
      id: 'msg-1',
      conversationId: convId,
      senderId: rinaUser.id,
      recipientId: 'current-mock-user',
      content: 'Halo! Pesan ini dienkripsi secara end-to-end.',
      ciphertext: encryptedFromPeer['ciphertext']!,
      nonce: encryptedFromPeer['nonce']!,
      messageType: MessageType.text,
      status: MessageStatus.read,
      createdAt: now.subtract(const Duration(minutes: 5)),
      isOutgoing: false,
    );

    _messagesByConversation[convId] = [initialMessage];

    _conversations.add(
      Conversation(
        id: convId,
        otherUser: rinaUser,
        lastMessage: initialMessage,
        unreadCount: 0,
        lastMessageAt: now.subtract(const Duration(minutes: 5)),
      ),
    );
  }

  @override
  Future<String> getOrGenerateMyPrivateKey() async => _myPrivateKey;

  @override
  Future<String> getOrPublishMyPublicKey() async => _myPublicKey;

  @override
  Future<String?> getPeerPublicKey(String peerUserId) async {
    return _peerPublicKey;
  }

  @override
  Future<List<Conversation>> getConversations() async {
    return List.unmodifiable(_conversations);
  }

  @override
  Future<Conversation> getOrCreateConversation(UserProfile otherUser) async {
    final existing = _conversations.where((c) => c.otherUser.id == otherUser.id);
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final newConv = Conversation(
      id: 'conv-${DateTime.now().millisecondsSinceEpoch}',
      otherUser: otherUser,
      lastMessage: null,
      unreadCount: 0,
      lastMessageAt: DateTime.now(),
    );

    _conversations.insert(0, newConv);
    _messagesByConversation[newConv.id] = [];
    return newConv;
  }

  @override
  Future<List<Message>> getMessages(String conversationId, String peerPublicKey) async {
    final list = _messagesByConversation[conversationId] ?? [];
    return List.unmodifiable(list);
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String recipientId,
    required String text,
    required String recipientPublicKey,
    MessageType messageType = MessageType.text,
  }) async {
    // 1. Enkripsi plaintext di perangkat klien (FR-10)
    final encrypted = CryptoService.encrypt(
      plaintext: text,
      senderPrivateKey: _myPrivateKey,
      recipientPublicKey: recipientPublicKey,
    );

    final now = DateTime.now();
    final message = Message(
      id: 'msg-${now.millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: 'current-mock-user',
      recipientId: recipientId,
      content: text,
      ciphertext: encrypted['ciphertext']!,
      nonce: encrypted['nonce']!,
      messageType: messageType,
      status: MessageStatus.sent,
      createdAt: now,
      isOutgoing: true,
    );

    final list = _messagesByConversation.putIfAbsent(conversationId, () => []);
    list.add(message);

    // Perbarui metadata conversation
    final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIndex != -1) {
      final old = _conversations[convIndex];
      _conversations[convIndex] = old.copyWith(
        lastMessage: message,
        lastMessageAt: now,
      );
    }

    return message;
  }

  @override
  Future<void> markMessagesAsDelivered(String conversationId) async {}

  @override
  Future<void> markMessagesAsRead(String conversationId) async {
    final list = _messagesByConversation[conversationId];
    if (list != null) {
      for (int i = 0; i < list.length; i++) {
        if (!list[i].isOutgoing) {
          list[i] = list[i].copyWith(status: MessageStatus.read);
        }
      }
    }
  }

  @override
  Future<void> deleteMessageForEveryone(String messageId) async {
    for (final list in _messagesByConversation.values) {
      final index = list.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final old = list[index];
        list[index] = old.copyWith(
          deletedForAll: true,
          content: 'Pesan ini telah dihapus.',
        );
      }
    }
  }

  @override
  Future<void> deleteMessageForMe(String messageId) async {
    for (final list in _messagesByConversation.values) {
      list.removeWhere((m) => m.id == messageId);
    }
  }
}

