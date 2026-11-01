import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/entities/contact.dart';
import '../../domain/entities/contact_request.dart';
import '../../domain/repositories/contact_repository.dart';

/// Implementasi ContactRepository menggunakan Supabase Database & Realtime.
class SupabaseContactRepository implements ContactRepository {
  final SupabaseClient _client;

  SupabaseContactRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi pengguna tidak aktif. Silakan masuk kembali.');
    }
    return user.id;
  }

  @override
  Future<List<Contact>> getContacts() async {
    final res = await _client
        .from('contacts')
        .select('id, user_id, alias, is_blocked, created_at, contact_user:profiles!contacts_contact_user_id_fkey(*)')
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => Contact.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ContactRequest>> getIncomingRequests() async {
    final res = await _client
        .from('contact_requests')
        .select('id, status, created_at, updated_at, sender:profiles!contact_requests_sender_id_fkey(*), receiver:profiles!contact_requests_receiver_id_fkey(*)')
        .eq('receiver_id', _currentUserId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => ContactRequest.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ContactRequest>> getOutgoingRequests() async {
    final res = await _client
        .from('contact_requests')
        .select('id, status, created_at, updated_at, sender:profiles!contact_requests_sender_id_fkey(*), receiver:profiles!contact_requests_receiver_id_fkey(*)')
        .eq('sender_id', _currentUserId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => ContactRequest.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<UserProfile?> searchUser(String query) async {
    final sanitized = query.trim().toLowerCase().replaceAll('@', '');
    if (sanitized.isEmpty) return null;

    final res = await _client
        .from('profiles')
        .select()
        .or('username.ilike.$sanitized,email.ilike.$sanitized')
        .neq('id', _currentUserId)
        .maybeSingle();

    if (res == null) return null;
    return UserProfile.fromJson(res);
  }

  @override
  Future<void> sendContactRequest(String targetUserId) async {
    if (targetUserId == _currentUserId) {
      throw Exception('Anda tidak dapat menambahkan akun sendiri.');
    }

    // 1. Cek apakah sudah berteman di tabel contacts
    final existingContact = await _client
        .from('contacts')
        .select('id')
        .eq('user_id', _currentUserId)
        .eq('contact_user_id', targetUserId)
        .maybeSingle();

    if (existingContact != null) {
      throw Exception('Pengguna ini sudah menjadi kontak Anda.');
    }

    // 2. Cek apakah ada permintaan pertemanan dari arah sebaliknya yang masih pending
    final reverseReq = await _client
        .from('contact_requests')
        .select('id, status')
        .eq('sender_id', targetUserId)
        .eq('receiver_id', _currentUserId)
        .eq('status', 'pending')
        .maybeSingle();

    if (reverseReq != null) {
      await acceptContactRequest(reverseReq['id'] as String);
      return;
    }

    // 3. Cek apakah sudah pernah ada permintaan dari saya ke target
    final existingReq = await _client
        .from('contact_requests')
        .select('id, status')
        .eq('sender_id', _currentUserId)
        .eq('receiver_id', targetUserId)
        .maybeSingle();

    if (existingReq != null) {
      final status = existingReq['status'] as String;
      if (status == 'pending') {
        throw Exception('Permintaan pertemanan sudah dikirim sebelumnya dan sedang menunggu konfirmasi.');
      } else if (status == 'accepted') {
        throw Exception('Pengguna ini sudah menjadi kontak Anda.');
      } else {
        // Status sebelumnya rejected / cancelled: hidupkan kembali menjadi pending
        await _client.from('contact_requests').update({
          'status': 'pending',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existingReq['id']);
        return;
      }
    }

    // 4. Jika baru pertama kali, buat baris baru
    await _client.from('contact_requests').insert({
      'sender_id': _currentUserId,
      'receiver_id': targetUserId,
      'status': 'pending',
    });
  }

  @override
  Future<void> acceptContactRequest(String requestId) async {
    await _client.from('contact_requests').update({
      'status': 'accepted',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  @override
  Future<void> rejectContactRequest(String requestId) async {
    await _client.from('contact_requests').update({
      'status': 'rejected',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  @override
  Future<void> removeContact(String contactId) async {
    await _client.from('contacts').delete().eq('id', contactId);
  }

  @override
  Future<void> toggleBlockContact(String contactId, bool isBlocked) async {
    await _client
        .from('contacts')
        .update({'is_blocked': isBlocked})
        .eq('id', contactId);
  }
}

