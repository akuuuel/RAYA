import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../data/repositories/mock_contact_repository.dart';
import '../../data/repositories/supabase_contact_repository.dart';
import '../../domain/repositories/contact_repository.dart';
import 'contacts_state.dart';

/// Provider repository kontak.
/// Otomatis beralih ke SupabaseContactRepository saat useMock false.
final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  if (AppConfig.useMock) {
    return MockContactRepository();
  }
  return SupabaseContactRepository();
});

class ContactsController extends StateNotifier<ContactsState> {
  final ContactRepository _repository;

  ContactsController(this._repository) : super(const ContactsState()) {
    loadContactsAndRequests();
  }

  /// Memuat kontak aktif dan daftar permintaan masuk/keluar
  Future<void> loadContactsAndRequests() async {
    state = state.copyWith(status: ContactsStatus.loading, errorMessage: null);

    try {
      final contacts = await _repository.getContacts();
      final incoming = await _repository.getIncomingRequests();
      final outgoing = await _repository.getOutgoingRequests();

      state = state.copyWith(
        status: ContactsStatus.success,
        contacts: contacts,
        incomingRequests: incoming,
        outgoingRequests: outgoing,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: ContactsStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Mencari pengguna berdasarkan username atau email unik (FR-06)
  Future<void> searchUser(String query) async {
    final sanitized = query.trim();
    if (sanitized.isEmpty) {
      state = state.copyWith(clearSearchResult: true, isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true, errorMessage: null);

    try {
      final user = await _repository.searchUser(sanitized);
      state = state.copyWith(
        searchResult: user,
        clearSearchResult: user == null,
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearSearch() {
    state = state.copyWith(clearSearchResult: true, isSearching: false);
  }

  /// Mengirim permintaan kontak baru (FR-06)
  Future<bool> sendContactRequest(String targetUserId) async {
    try {
      await _repository.sendContactRequest(targetUserId);
      await loadContactsAndRequests();
      state = state.copyWith(
        successMessage: 'Permintaan pertemanan berhasil dikirim.',
        clearSearchResult: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Menerima permintaan kontak masuk (FR-07)
  Future<void> acceptRequest(String requestId) async {
    try {
      await _repository.acceptContactRequest(requestId);
      await loadContactsAndRequests();
      state = state.copyWith(
        successMessage: 'Permintaan kontak diterima.',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Menolak permintaan kontak masuk (FR-07)
  Future<void> rejectRequest(String requestId) async {
    try {
      await _repository.rejectContactRequest(requestId);
      await loadContactsAndRequests();
      state = state.copyWith(
        successMessage: 'Permintaan kontak ditolak.',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Menghapus kontak (FR-08)
  Future<void> removeContact(String contactId) async {
    try {
      await _repository.removeContact(contactId);
      await loadContactsAndRequests();
      state = state.copyWith(
        successMessage: 'Kontak berhasil dihapus.',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Memblokir atau membuka blokir kontak (FR-08)
  Future<void> toggleBlock(String contactId, bool isBlocked) async {
    try {
      await _repository.toggleBlockContact(contactId, isBlocked);
      await loadContactsAndRequests();
      state = state.copyWith(
        successMessage: isBlocked ? 'Kontak telah diblokir.' : 'Blokir kontak dibuka.',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

final contactsControllerProvider =
    StateNotifierProvider<ContactsController, ContactsState>((ref) {
  final repo = ref.watch(contactRepositoryProvider);
  return ContactsController(repo);
});
