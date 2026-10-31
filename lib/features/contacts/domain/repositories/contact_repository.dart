import '../../../auth/domain/entities/user_profile.dart';
import '../entities/contact.dart';
import '../entities/contact_request.dart';

/// Kontrak Repository Manajemen Kontak sesuai FR-06, FR-07, dan FR-08.
abstract class ContactRepository {
  /// Mengambil daftar kontak milik pengguna
  Future<List<Contact>> getContacts();

  /// Mengambil daftar permintaan kontak masuk
  Future<List<ContactRequest>> getIncomingRequests();

  /// Mengambil daftar permintaan kontak yang dikirim oleh pengguna
  Future<List<ContactRequest>> getOutgoingRequests();

  /// Mencari pengguna berdasarkan username atau email unik (FR-06)
  Future<UserProfile?> searchUser(String query);

  /// Mengirim permintaan pertemanan ke pengguna lain (FR-06)
  Future<void> sendContactRequest(String targetUserId);

  /// Menerima permintaan pertemanan (FR-07)
  Future<void> acceptContactRequest(String requestId);

  /// Menolak permintaan pertemanan (FR-07)
  Future<void> rejectContactRequest(String requestId);

  /// Menghapus kontak dari daftar (FR-08)
  Future<void> removeContact(String contactId);

  /// Memblokir atau membuka blokir kontak (FR-08)
  Future<void> toggleBlockContact(String contactId, bool isBlocked);
}

