import '../../../auth/domain/entities/user_profile.dart';
import '../entities/conversation.dart';
import '../entities/message.dart';

/// Kontrak Repository Chat Terenkripsi End-to-End sesuai FR-09 s.d. FR-18.
abstract class ChatRepository {
  /// Mengambil kunci privat perangkat saya (tersimpan aman di perangkat)
  Future<String> getOrGenerateMyPrivateKey();

  /// Mengambil atau mengunggah kunci publik saya ke server
  Future<String> getOrPublishMyPublicKey();

  /// Mengambil kunci publik kontak untuk mengenkripsi pesan
  Future<String?> getPeerPublicKey(String peerUserId);

  /// Mengambil daftar percakapan aktif
  Future<List<Conversation>> getConversations();

  /// Membuat atau mengambil percakapan yang sudah ada dengan kontak
  Future<Conversation> getOrCreateConversation(UserProfile otherUser);

  /// Mengambil riwayat pesan dalam percakapan (didekripsi di perangkat)
  Future<List<Message>> getMessages(String conversationId, String peerPublicKey);

  /// Mengenkripsi pesan di perangkat dan mengirim ciphertext ke server (FR-10, FR-11, FR-13)
  /// Mendukung tipe teks, gambar, dan pesan suara.
  Future<Message> sendMessage({
    required String conversationId,
    required String recipientId,
    required String text,
    required String recipientPublicKey,
    MessageType messageType = MessageType.text,
  });

  /// Menandai pesan sebagai terkirim/diterima (delivered) saat lawan membuka chat
  Future<void> markMessagesAsDelivered(String conversationId);

  /// Menandai pesan sebagai terbaca (FR-16)
  Future<void> markMessagesAsRead(String conversationId);

  /// Menghapus pesan untuk semua pihak dalam batas 15 menit (FR-18)
  Future<void> deleteMessageForEveryone(String messageId);

  /// Menghapus pesan hanya untuk diri sendiri
  Future<void> deleteMessageForMe(String messageId);
}

