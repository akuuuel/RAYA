import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../../core/crypto/crypto_service.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

/// Implementasi ChatRepository dengan Supabase Realtime dan E2EE CryptoService.
class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _client;
  String? _cachedPrivateKey;

  SupabaseChatRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi pengguna tidak aktif. Silakan masuk kembali.');
    }
    return user.id;
  }

  @override
  Future<String> getOrGenerateMyPrivateKey() async {
    if (_cachedPrivateKey != null) return _cachedPrivateKey!;

    // Buat pasangan kunci baru jika belum ada
    final keys = CryptoService.generateKeyPair();
    _cachedPrivateKey = keys['privateKey']!;

    // Simpan kunci publik ke database
    await _client.from('user_keys').upsert({
      'user_id': _currentUserId,
      'public_key': keys['publicKey']!,
      'updated_at': DateTime.now().toIso8601String(),
    });

    return _cachedPrivateKey!;
  }

  @override
  Future<String> getOrPublishMyPublicKey() async {
    final res = await _client
        .from('user_keys')
        .select('public_key')
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (res != null && res['public_key'] != null) {
      return res['public_key'] as String;
    }

    final keys = CryptoService.generateKeyPair();
    _cachedPrivateKey = keys['privateKey']!;

    await _client.from('user_keys').upsert({
      'user_id': _currentUserId,
      'public_key': keys['publicKey']!,
      'updated_at': DateTime.now().toIso8601String(),
    });

    return keys['publicKey']!;
  }

  @override
  Future<String?> getPeerPublicKey(String peerUserId) async {
    final res = await _client
        .from('user_keys')
        .select('public_key')
        .eq('user_id', peerUserId)
        .maybeSingle();

    if (res == null || res['public_key'] == null) return null;
    return res['public_key'] as String;
  }

  @override
  Future<List<Conversation>> getConversations() async {
    final res = await _client
        .from('conversations')
        .select('id, participant_a, participant_b, last_message_at, p_a:profiles!conversations_participant_a_fkey(*), p_b:profiles!conversations_participant_b_fkey(*)')
        .or('participant_a.eq.$_currentUserId,participant_b.eq.$_currentUserId')
        .order('last_message_at', ascending: false);

    final List<Conversation> list = [];
    for (final json in (res as List)) {
      final pA = UserProfile.fromJson(json['p_a'] as Map<String, dynamic>);
      final pB = UserProfile.fromJson(json['p_b'] as Map<String, dynamic>);
      final otherUser = pA.id == _currentUserId ? pB : pA;

      list.add(
        Conversation(
          id: json['id'] as String,
          otherUser: otherUser,
          lastMessageAt: DateTime.parse(json['last_message_at'] as String),
        ),
      );
    }
    return list;
  }

  @override
  Future<Conversation> getOrCreateConversation(UserProfile otherUser) async {
    // Cari apakah percakapan sudah ada
    final existing = await _client
        .from('conversations')
        .select('id, participant_a, participant_b, last_message_at')
        .or('and(participant_a.eq.$_currentUserId,participant_b.eq.${otherUser.id}),and(participant_a.eq.${otherUser.id},participant_b.eq.$_currentUserId)')
        .maybeSingle();

    if (existing != null) {
      return Conversation(
        id: existing['id'] as String,
        otherUser: otherUser,
        lastMessageAt: DateTime.parse(existing['last_message_at'] as String),
      );
    }

    // Buat percakapan baru
    final newRes = await _client
        .from('conversations')
        .insert({
          'participant_a': _currentUserId,
          'participant_b': otherUser.id,
        })
        .select()
        .single();

    return Conversation(
      id: newRes['id'] as String,
      otherUser: otherUser,
      lastMessageAt: DateTime.parse(newRes['last_message_at'] as String),
    );
  }

  @override
  Future<List<Message>> getMessages(String conversationId, String peerPublicKey) async {
    final myPrivateKey = await getOrGenerateMyPrivateKey();

    final res = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    final List<Message> list = [];
    for (final json in (res as List)) {
      final isOutgoing = json['sender_id'] == _currentUserId;
      final ciphertext = json['ciphertext'] as String;
      final nonce = json['nonce'] as String;
      final deletedForAll = json['deleted_for_all'] as bool? ?? false;

      String plaintext = 'Pesan terenkripsi';
      if (deletedForAll) {
        plaintext = 'Pesan ini telah dihapus.';
      } else {
        try {
          plaintext = CryptoService.decrypt(
            ciphertext: ciphertext,
            nonce: nonce,
            recipientPrivateKey: myPrivateKey,
            senderPublicKey: peerPublicKey,
          );
        } catch (_) {
          plaintext = '[Gagal mendekripsi pesan]';
        }
      }

      list.add(
        Message(
          id: json['id'] as String,
          conversationId: conversationId,
          senderId: json['sender_id'] as String,
          recipientId: json['recipient_id'] as String,
          content: plaintext,
          ciphertext: ciphertext,
          nonce: nonce,
          status: MessageStatus.values.firstWhere(
            (e) => e.name == json['status'],
            orElse: () => MessageStatus.sent,
          ),
          createdAt: DateTime.parse(json['created_at'] as String),
          isOutgoing: isOutgoing,
          deletedForAll: deletedForAll,
        ),
      );
    }
    return list;
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String recipientId,
    required String text,
    required String recipientPublicKey,
  }) async {
    final myPrivateKey = await getOrGenerateMyPrivateKey();

    // 1. Enkripsi pesan teks di perangkat (FR-10)
    final encrypted = CryptoService.encrypt(
      plaintext: text,
      senderPrivateKey: myPrivateKey,
      recipientPublicKey: recipientPublicKey,
    );

    // 2. Kirim ciphertext ke server (FR-11)
    final res = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': _currentUserId,
          'recipient_id': recipientId,
          'ciphertext': encrypted['ciphertext']!,
          'nonce': encrypted['nonce']!,
          'message_type': 'text',
          'status': 'sent',
        })
        .select()
        .single();

    return Message(
      id: res['id'] as String,
      conversationId: conversationId,
      senderId: _currentUserId,
      recipientId: recipientId,
      content: text,
      ciphertext: encrypted['ciphertext']!,
      nonce: encrypted['nonce']!,
      status: MessageStatus.sent,
      createdAt: DateTime.parse(res['created_at'] as String),
      isOutgoing: true,
    );
  }

  @override
  Future<void> markMessagesAsRead(String conversationId) async {
    await _client
        .from('messages')
        .update({'status': 'read'})
        .eq('conversation_id', conversationId)
        .eq('recipient_id', _currentUserId);
  }

  @override
  Future<void> deleteMessageForEveryone(String messageId) async {
    await _client
        .from('messages')
        .update({'deleted_for_all': true})
        .eq('id', messageId)
        .eq('sender_id', _currentUserId);
  }

  @override
  Future<void> deleteMessageForMe(String messageId) async {
    await _client
        .from('messages')
        .update({'deleted_by_sender': true})
        .eq('id', messageId)
        .eq('sender_id', _currentUserId);
  }
}

