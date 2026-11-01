import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/notification_service.dart';
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
  Timer? _pollingTimer;
  final Set<String> _seenRequestIds = {};
  bool _initializedHistory = false;

  ContactsController(this._repository) : super(const ContactsState()) {
    loadContactsAndRequests();
    _startPolling();
  }

  /// Memulai sinkronisasi otomatis di latar belakang setiap 4 detik
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pollSilently();
    });
  }

  /// Sinkronisasi kontak dan permintaan masuk secara senyap tanpa menampilkan loading spinner
  Future<void> _pollSilently() async {
    try {
      final contacts = await _repository.getContacts();
      final incoming = await _repository.getIncomingRequests();
      final outgoing = await _repository.getOutgoingRequests();

      if (_initializedHistory) {
        for (final req in incoming) {
          if (!_seenRequestIds.contains(req.id)) {
            _seenRequestIds.add(req.id);
            final senderName = req.sender.displayName ?? req.sender.username ?? 'Seseorang';
            await NotificationService.instance.showNotification(
              id: req.id.hashCode,
              title: 'Permintaan Pertemanan Baru',
              body: '$senderName ingin terhubung dengan Anda di RAYA.',
              payload: 'contact_request:${req.id}',
            );
          }
        }
      } else {
        for (final req in incoming) {
          _seenRequestIds.add(req.id);
        }
        _initializedHistory = true;
      }

      state = state.copyWith(
        contacts: contacts,
        incomingRequests: incoming,
        outgoingRequests: outgoing,
      );
    } catch (_) {
      // Abaikan kegagalan polling berkala agar tidak mengganggu UI pengguna
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Memuat kontak aktif dan daftar permintaan masuk/keluar
  Future<void> loadContactsAndRequests() async {
    state = state.copyWith(status: ContactsStatus.loading, errorMessage: null);

    try {
      final contacts = await _repository.getContacts();
      final incoming = await _repository.getIncomingRequests();
      final outgoing = await _repository.getOutgoingRequests();

      for (final req in incoming) {
        _seenRequestIds.add(req.id);
      }
      _initializedHistory = true;

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
        errorMessage: _formatErrorMessage(e),
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
        errorMessage: _formatErrorMessage(e),
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
        errorMessage: _formatErrorMessage(e),
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
        errorMessage: _formatErrorMessage(e),
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
        errorMessage: _formatErrorMessage(e),
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
        errorMessage: _formatErrorMessage(e),
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
        errorMessage: _formatErrorMessage(e),
      );
    }
  }

  String _formatErrorMessage(dynamic error) {
    final raw = error.toString().toLowerCase();

    if (raw.contains('unique_pending_request') || raw.contains('23505') || raw.contains('duplicate')) {
      return 'Permintaan pertemanan sudah pernah dikirim sebelumnya. Silakan tunggu konfirmasi.';
    }

    if (raw.contains('row-level security') || raw.contains('violates row-level security')) {
      return 'Gagal memproses permintaan kontak. Izin tidak memadai.';
    }

    if (raw.contains('socketfailed') || raw.contains('failed host lookup') || raw.contains('timeout')) {
      return 'Koneksi internet bermasalah. Periksa jaringan Anda.';
    }

    final clean = error.toString().replaceFirst('Exception: ', '').trim();
    if (!clean.contains('(') && !clean.contains('{') && clean.length < 90) {
      return clean;
    }

    return 'Terjadi kendala saat memproses kontak. Silakan coba lagi.';
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
