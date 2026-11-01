import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../../core/crypto/crypto_service.dart';
import '../../../../core/crypto/key_storage_service.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

/// Implementasi ChatRepository dengan Supabase Realtime dan E2EE CryptoService.
class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _client;

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
    // Ambil atau buat kunci privat yang tersimpan persisten di perangkat (FR-09)
    final keys = await KeyStorageService.getOrGenerateKeyPair();

    // Pastikan kunci publik sinkron ke server
    await _client.from('user_keys').upsert({
      'user_id': _currentUserId,
      'public_key': keys['publicKey']!,
      'updated_at': DateTime.now().toIso8601String(),
    });

    return keys['privateKey']!;
  }

  @override
  Future<String> getOrPublishMyPublicKey() async {
    // Ambil kunci publik dari penyimpanan lokal yang persisten
    final localPublicKey = await KeyStorageService.getPublicKey();

    // Pastikan kunci publik di server selalu sinkron dengan kunci lokal
    await _client.from('user_keys').upsert({
      'user_id': _currentUserId,
      'public_key': localPublicKey,
      'updated_at': DateTime.now().toIso8601String(),
    });

    return localPublicKey;
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
    // Otomatis tandai pesan masuk berstatus 'sent' menjadi 'delivered' karena perangkat pengguna aktif menerima
    try {
      await _client
          .from('messages')
          .update({'status': 'delivered'})
          .eq('recipient_id', _currentUserId)
          .eq('status', 'sent');
    } catch (_) {}

    final res = await _client
        .from('conversations')
        .select('id, participant_a, participant_b, last_message_at, p_a:profiles!conversations_participant_a_fkey(*), p_b:profiles!conversations_participant_b_fkey(*)')
        .or('participant_a.eq.$_currentUserId,participant_b.eq.$_currentUserId')
        .order('last_message_at', ascending: false);

    // Ambil kunci privat saya dan semua kunci publik pengguna untuk mendekripsi pesan terakhir secara instan
    String? myPrivateKey;
    final Map<String, String> publicKeysMap = {};
    try {
      myPrivateKey = await getOrGenerateMyPrivateKey();
      final keysRes = await _client.from('user_keys').select('user_id, public_key');
      for (final row in (keysRes as List)) {
        final uid = row['user_id'] as String?;
        final pkey = row['public_key'] as String?;
        if (uid != null && pkey != null) {
          publicKeysMap[uid] = pkey;
        }
      }
    } catch (_) {}

    final List<Conversation> list = [];
    for (final json in (res as List)) {
      final pA = UserProfile.fromJson(json['p_a'] as Map<String, dynamic>);
      final pB = UserProfile.fromJson(json['p_b'] as Map<String, dynamic>);
      final otherUser = pA.id == _currentUserId ? pB : pA;
      final convId = json['id'] as String;

      // Ambil pesan terakhir
      Message? lastMessage;
      int unreadCount = 0;
      try {
        final msgRes = await _client
            .from('messages')
            .select()
            .eq('conversation_id', convId)
            .eq('deleted_for_all', false)
            .order('created_at', ascending: false)
            .limit(1);
        if ((msgRes as List).isNotEmpty) {
          final msgJson = msgRes.first as Map<String, dynamic>;
          final isOutgoing = msgJson['sender_id'] == _currentUserId;
          final ciphertext = msgJson['ciphertext'] as String? ?? '';
          final nonce = msgJson['nonce'] as String? ?? '';
          final msgType = MessageType.values.firstWhere(
            (e) => e.name == msgJson['message_type'],
            orElse: () => MessageType.text,
          );

          // Dekripsi isi pesan terakhir agar dapat ditampilkan langsung di bawah nama kontak
          String plaintext = '';
          final peerPublicKey = publicKeysMap[otherUser.id];
          if (myPrivateKey != null && peerPublicKey != null && ciphertext.isNotEmpty && nonce.isNotEmpty) {
            try {
              plaintext = CryptoService.decrypt(
                ciphertext: ciphertext,
                nonce: nonce,
                recipientPrivateKey: myPrivateKey,
                senderPublicKey: peerPublicKey,
              );
            } catch (_) {
              plaintext = '';
            }
          }

          String displayContent = 'Pesan baru';
          if (plaintext.isNotEmpty) {
            if (plaintext.startsWith('IMAGE:')) {
              final raw = plaintext.substring(6);
              final caption = raw.contains('||') ? raw.split('||').sublist(1).join('||').trim() : '';
              displayContent = caption.isNotEmpty ? '📷 $caption' : '📷 Foto';
            } else if (plaintext.startsWith('FILE:')) {
              final parts = plaintext.substring(5).split('||');
              final filename = parts.isNotEmpty ? parts[0] : 'Dokumen';
              displayContent = '📎 $filename';
            } else if (plaintext.startsWith('AUDIO:')) {
              final parts = plaintext.substring(6).split('||');
              final dur = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : '';
              displayContent = dur.isNotEmpty ? '🎙️ Pesan Suara · $dur' : '🎙️ Pesan Suara';
            } else {
              displayContent = plaintext;
            }
          } else {
            if (msgType == MessageType.image) {
              displayContent = '📷 Foto';
            } else if (msgType == MessageType.voice) {
              displayContent = '🎙️ Pesan Suara';
            } else {
              displayContent = isOutgoing ? 'Pesan terkirim' : 'Pesan masuk';
            }
          }

          lastMessage = Message(
            id: msgJson['id'] as String,
            conversationId: convId,
            senderId: msgJson['sender_id'] as String,
            recipientId: msgJson['recipient_id'] as String,
            content: displayContent,
            ciphertext: ciphertext,
            nonce: nonce,
            messageType: msgType,
            status: MessageStatus.values.firstWhere(
              (e) => e.name == msgJson['status'],
              orElse: () => MessageStatus.sent,
            ),
            createdAt: DateTime.parse(msgJson['created_at'] as String),
            isOutgoing: isOutgoing,
          );
        }

        // Hitung unread
        final unreadRes = await _client
            .from('messages')
            .select('id')
            .eq('conversation_id', convId)
            .eq('recipient_id', _currentUserId)
            .neq('status', 'read')
            .eq('deleted_for_all', false);
        unreadCount = (unreadRes as List).length;
      } catch (_) {}

      list.add(
        Conversation(
          id: convId,
          otherUser: otherUser,
          lastMessage: lastMessage,
          unreadCount: unreadCount,
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
          messageType: MessageType.values.firstWhere(
            (e) => e.name == json['message_type'],
            orElse: () => MessageType.text,
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
    MessageType messageType = MessageType.text,
  }) async {
    final myPrivateKey = await getOrGenerateMyPrivateKey();

    // 1. Enkripsi pesan (teks/gambar/suara) di perangkat (FR-10)
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
          'message_type': messageType.name,
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
      messageType: messageType,
      status: MessageStatus.sent,
      createdAt: DateTime.parse(res['created_at'] as String),
      isOutgoing: true,
    );
  }

  @override
  Future<void> markMessagesAsDelivered(String conversationId) async {
    await _client
        .from('messages')
        .update({'status': 'delivered'})
        .eq('conversation_id', conversationId)
        .eq('recipient_id', _currentUserId)
        .eq('status', 'sent');
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

