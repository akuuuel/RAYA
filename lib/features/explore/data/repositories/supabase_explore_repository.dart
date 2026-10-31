import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/public_status.dart';
import '../../domain/entities/status_comment.dart';
import '../../domain/repositories/explore_repository.dart';

/// Implementasi ExploreRepository menggunakan Supabase Postgres, RLS, dan Fuzzing Lokasi (FR-30).
class SupabaseExploreRepository implements ExploreRepository {
  final SupabaseClient _client;

  SupabaseExploreRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi pengguna tidak aktif. Silakan masuk kembali.');
    }
    return user.id;
  }

  @override
  Future<bool> getPublicVisibility() async {
    final res = await _client
        .from('public_profiles_settings')
        .select('is_public_visible')
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (res == null) return false;
    return res['is_public_visible'] as bool? ?? false;
  }

  @override
  Future<void> setPublicVisibility(bool isVisible) async {
    await _client.from('public_profiles_settings').upsert({
      'user_id': _currentUserId,
      'is_public_visible': isVisible,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<PublicStatus>> getNearbyStatuses({
    required double latitude,
    required double longitude,
    required int radiusKm,
  }) async {
    // Ambil daftar ID kontak terhubung milik pengguna saat ini
    final contactsRes = await _client
        .from('contacts')
        .select('contact_user_id')
        .eq('user_id', _currentUserId);

    final contactUserIds = (contactsRes as List)
        .map((c) => c['contact_user_id'] as String)
        .toList();

    final nowIso = DateTime.now().toIso8601String();

    final res = await _client
        .from('public_statuses')
        .select('*, profiles!public_statuses_user_id_fkey(*)')
        .eq('is_active', true)
        .gt('expires_at', nowIso)
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => PublicStatus.fromJson(
              json as Map<String, dynamic>,
              currentUserId: _currentUserId,
              contactUserIds: contactUserIds,
            ))
        .toList();
  }

  @override
  Future<PublicStatus?> getMyActiveStatus() async {
    final nowIso = DateTime.now().toIso8601String();

    final res = await _client
        .from('public_statuses')
        .select('*, profiles!public_statuses_user_id_fkey(*)')
        .eq('user_id', _currentUserId)
        .eq('is_active', true)
        .gt('expires_at', nowIso)
        .maybeSingle();

    if (res == null) return null;
    return PublicStatus.fromJson(res, currentUserId: _currentUserId);
  }

  @override
  Future<PublicStatus> postStatus({
    required String text,
    String? note,
    String? imageUrl,
    required double latitude,
    required double longitude,
  }) async {
    // 1. Algoritma Penyamaran Lokasi Acak Radius Min 300 Meter (FR-30)
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    final distanceMeters = 300.0 + (random.nextDouble() * 300.0);
    final deltaLat = (distanceMeters * cos(angle)) / 111000.0;
    final deltaLng = (distanceMeters * sin(angle)) /
        (111000.0 * cos(latitude * pi / 180.0));

    final fuzzedLat = latitude + deltaLat;
    final fuzzedLng = longitude + deltaLng;

    // 2. Nonaktifkan status aktif lama jika ada (penggantian status memulai ulang masa 8 jam, FR-33)
    await _client
        .from('public_statuses')
        .update({'is_active': false})
        .eq('user_id', _currentUserId)
        .eq('is_active', true);

    // 3. Simpan status baru dengan masa berlaku 8 jam (FR-32)
    final expires = DateTime.now().add(const Duration(hours: 8)).toIso8601String();

    final res = await _client
        .from('public_statuses')
        .insert({
          'user_id': _currentUserId,
          'text': text.length > 140 ? text.substring(0, 140) : text,
          'note': note,
          'image_url': imageUrl,
          'fuzzed_latitude': fuzzedLat,
          'fuzzed_longitude': fuzzedLng,
          'expires_at': expires,
          'is_active': true,
        })
        .select('*, profiles!public_statuses_user_id_fkey(*)')
        .single();

    // 4. Pastikan visibilitas publik diaktifkan
    await setPublicVisibility(true);

    return PublicStatus.fromJson(res, currentUserId: _currentUserId);
  }

  @override
  Future<void> deleteMyStatus() async {
    await _client
        .from('public_statuses')
        .update({'is_active': false})
        .eq('user_id', _currentUserId)
        .eq('is_active', true);
  }

  @override
  Future<List<StatusComment>> getComments(String statusId) async {
    final statusRes = await _client
        .from('public_statuses')
        .select('user_id')
        .eq('id', statusId)
        .maybeSingle();

    final statusOwnerId = statusRes?['user_id'] as String?;

    final res = await _client
        .from('status_comments')
        .select('*, profiles!status_comments_author_id_fkey(*)')
        .eq('status_id', statusId)
        .order('created_at', ascending: true);

    return (res as List)
        .map((json) => StatusComment.fromJson(
              json as Map<String, dynamic>,
              currentUserId: _currentUserId,
              statusOwnerId: statusOwnerId,
            ))
        .toList();
  }

  @override
  Future<StatusComment> addComment({
    required String statusId,
    required String content,
  }) async {
    final res = await _client
        .from('status_comments')
        .insert({
          'status_id': statusId,
          'author_id': _currentUserId,
          'content': content.trim(),
        })
        .select('*, profiles!status_comments_author_id_fkey(*)')
        .single();

    return StatusComment.fromJson(res, currentUserId: _currentUserId);
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _client.from('status_comments').delete().eq('id', commentId);
  }
}

