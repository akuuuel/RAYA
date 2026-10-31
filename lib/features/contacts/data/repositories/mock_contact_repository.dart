import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/entities/contact.dart';
import '../../domain/entities/contact_request.dart';
import '../../domain/repositories/contact_repository.dart';

/// Implementasi Mock Repository Kontak untuk pengujian unit terisolasi.
class MockContactRepository implements ContactRepository {
  final List<Contact> _contacts = [];
  final List<ContactRequest> _incomingRequests = [];
  final List<ContactRequest> _outgoingRequests = [];

  // Data pengguna tiruan untuk simulasi pencarian kontak
  final List<UserProfile> _mockDirectory = [
    UserProfile(
      id: 'mock-user-rina',
      email: 'rina@raya.id',
      username: 'rina_pratama',
      displayName: 'Rina Pratama',
      birthDate: DateTime(1996, 5, 12),
      isAdult: true,
    ),
    UserProfile(
      id: 'mock-user-budi',
      email: 'budi@raya.id',
      username: 'budi_santoso',
      displayName: 'Budi Santoso',
      birthDate: DateTime(2002, 8, 20),
      isAdult: true,
    ),
    UserProfile(
      id: 'mock-user-dimas',
      email: 'dimas@raya.id',
      username: 'dimas_junior',
      displayName: 'Dimas Kurniawan',
      birthDate: DateTime(2010, 3, 15),
      isAdult: false,
    ),
  ];

  MockContactRepository() {
    // Sediakan satu kontak default dan satu permintaan masuk untuk demonstrasi
    final defaultContactUser = _mockDirectory[0]; // Rina Pratama
    _contacts.add(
      Contact(
        id: 'contact-rel-1',
        userId: 'current-mock-user',
        contactUser: defaultContactUser,
        isBlocked: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    );

    final incomingUser = _mockDirectory[1]; // Budi Santoso
    _incomingRequests.add(
      ContactRequest(
        id: 'req-in-1',
        sender: incomingUser,
        receiver: UserProfile(
          id: 'current-mock-user',
          email: 'saya@raya.id',
          username: 'user_saya',
          displayName: 'Saya',
          birthDate: DateTime(1995, 1, 1),
          isAdult: true,
        ),
        status: ContactRequestStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    );
  }

  @override
  Future<List<Contact>> getContacts() async {
    return List.unmodifiable(_contacts);
  }

  @override
  Future<List<ContactRequest>> getIncomingRequests() async {
    return List.unmodifiable(
      _incomingRequests.where((r) => r.status == ContactRequestStatus.pending),
    );
  }

  @override
  Future<List<ContactRequest>> getOutgoingRequests() async {
    return List.unmodifiable(
      _outgoingRequests.where((r) => r.status == ContactRequestStatus.pending),
    );
  }

  @override
  Future<UserProfile?> searchUser(String query) async {
    final sanitized = query.trim().toLowerCase().replaceAll('@', '');
    if (sanitized.isEmpty) return null;

    try {
      return _mockDirectory.firstWhere(
        (u) =>
            u.username?.toLowerCase() == sanitized ||
            u.email.toLowerCase() == sanitized,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> sendContactRequest(String targetUserId) async {
    final targetUser = _mockDirectory.firstWhere(
      (u) => u.id == targetUserId,
      orElse: () => throw Exception('Pengguna tidak ditemukan.'),
    );

    // Cek apakah sudah berteman
    if (_contacts.any((c) => c.contactUser.id == targetUserId)) {
      throw Exception('Pengguna ini sudah menjadi kontak Anda.');
    }

    // Cek apakah permintaan sudah pernah dikirim
    if (_outgoingRequests.any((r) => r.receiver.id == targetUserId && r.status == ContactRequestStatus.pending)) {
      throw Exception('Permintaan pertemanan sudah dikirim sebelumnya.');
    }

    final newReq = ContactRequest(
      id: 'req-${DateTime.now().millisecondsSinceEpoch}',
      sender: UserProfile(
        id: 'current-mock-user',
        email: 'saya@raya.id',
        username: 'user_saya',
        displayName: 'Saya',
        birthDate: DateTime(1995, 1, 1),
        isAdult: true,
      ),
      receiver: targetUser,
      status: ContactRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    _outgoingRequests.add(newReq);
  }

  @override
  Future<void> acceptContactRequest(String requestId) async {
    final index = _incomingRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      throw Exception('Permintaan kontak tidak ditemukan.');
    }

    final req = _incomingRequests[index];
    _incomingRequests.removeAt(index);

    // Tambahkan ke kontak
    _contacts.add(
      Contact(
        id: 'contact-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current-mock-user',
        contactUser: req.sender,
        isBlocked: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> rejectContactRequest(String requestId) async {
    final index = _incomingRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _incomingRequests.removeAt(index);
    }
  }

  @override
  Future<void> removeContact(String contactId) async {
    _contacts.removeWhere((c) => c.id == contactId);
  }

  @override
  Future<void> toggleBlockContact(String contactId, bool isBlocked) async {
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      final old = _contacts[index];
      _contacts[index] = old.copyWith(isBlocked: isBlocked);
    }
  }
}

