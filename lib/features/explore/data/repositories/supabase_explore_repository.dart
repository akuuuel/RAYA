import 'dart:math';
import 'package:flutter/foundation.dart';
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

  Future<Map<String, dynamic>> _fetchProfile(String userId) async {
    try {
      final res = await _client
          .from('profiles')
          .select('id, display_name, username, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      return (res as Map<String, dynamic>?) ?? {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<bool> getPublicVisibility() async {
    try {
      final res = await _client
          .from('public_profiles_settings')
          .select('is_public_visible')
          .eq('user_id', _currentUserId)
          .maybeSingle();

      if (res == null) return false;
      return res['is_public_visible'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setPublicVisibility(bool isVisible) async {
    try {
      await _client.from('public_profiles_settings').upsert({
        'user_id': _currentUserId,
        'is_public_visible': isVisible,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[ExploreRepo] setPublicVisibility error: $e');
    }
  }

  @override
  Future<List<PublicStatus>> getNearbyStatuses({
    required double latitude,
    required double longitude,
    required int radiusKm,
  }) async {
    final nowIso = DateTime.now().toIso8601String();

    // 1. Ambil kontak pengguna saat ini
    List<String> contactUserIds = [];
    try {
      final contactsRes = await _client
          .from('contacts')
          .select('contact_user_id')
          .eq('user_id', _currentUserId);
      contactUserIds = (contactsRes as List)
          .map((c) => c['contact_user_id'] as String)
          .toList();
    } catch (_) {}

    // 2. Ambil baris status publik yang masih aktif
    List<dynamic> rows = [];
    try {
      final res = await _client
          .from('public_statuses')
          .select('*, profiles!public_statuses_user_id_fkey(*)')
          .eq('is_active', true)
          .gt('expires_at', nowIso)
          .order('created_at', ascending: false);
      rows = res as List;
    } catch (_) {
      try {
        final res = await _client
            .from('public_statuses')
            .select()
            .eq('is_active', true)
            .gt('expires_at', nowIso)
            .order('created_at', ascending: false);
        rows = res as List;
      } catch (e) {
        debugPrint('[ExploreRepo] getNearbyStatuses fallback error: $e');
      }
    }

    // 3. Ambil data profil jika belum ter-join
    final userIdsToFetch = rows
        .where((r) => r['profiles'] == null && r['user_id'] != null)
        .map((r) => r['user_id'] as String)
        .toSet()
        .toList();

    final Map<String, Map<String, dynamic>> profilesMap = {};
    if (userIdsToFetch.isNotEmpty) {
      try {
        final pRes = await _client
            .from('profiles')
            .select('id, display_name, username, avatar_url')
            .inFilter('id', userIdsToFetch);
        for (final p in (pRes as List)) {
          profilesMap[p['id'] as String] = p as Map<String, dynamic>;
        }
      } catch (_) {}
    }

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row as Map<String, dynamic>);
      final uId = map['user_id'] as String;
      if (map['profiles'] == null && profilesMap.containsKey(uId)) {
        map['profiles'] = profilesMap[uId];
      }

      return PublicStatus.fromJson(
        map,
        currentUserId: _currentUserId,
        contactUserIds: contactUserIds,
      );
    }).toList();
  }

  @override
  Future<PublicStatus?> getMyActiveStatus() async {
    final nowIso = DateTime.now().toIso8601String();
    Map<String, dynamic>? row;

    try {
      final res = await _client
          .from('public_statuses')
          .select('*, profiles!public_statuses_user_id_fkey(*)')
          .eq('user_id', _currentUserId)
          .eq('is_active', true)
          .gt('expires_at', nowIso)
          .order('created_at', ascending: false)
          .maybeSingle();
      row = res;
    } catch (_) {
      try {
        final res = await _client
            .from('public_statuses')
            .select()
            .eq('user_id', _currentUserId)
            .eq('is_active', true)
            .gt('expires_at', nowIso)
            .order('created_at', ascending: false)
            .maybeSingle();
        if (res != null) {
          final profile = await _fetchProfile(_currentUserId);
          row = Map<String, dynamic>.from(res);
          row['profiles'] = profile;
        }
      } catch (e) {
        debugPrint('[ExploreRepo] getMyActiveStatus fallback error: $e');
      }
    }

    if (row == null) return null;
    return PublicStatus.fromJson(row, currentUserId: _currentUserId);
  }

  @override
  Future<PublicStatus> postStatus({
    required String text,
    String? note,
    String? imageUrl,
    required double latitude,
    required double longitude,
  }) async {
    final uId = _currentUserId;

    // 1. Pastikan visibilitas publik aktif terlebih dahulu
    await setPublicVisibility(true);

    // 2. Nonaktifkan status lama milik pengguna
    try {
      await _client
          .from('public_statuses')
          .update({'is_active': false})
          .eq('user_id', uId)
          .eq('is_active', true);
    } catch (e) {
      debugPrint('[ExploreRepo] Deactivate old status error: $e');
    }

    // 3. Fuzzing lokasi acak minimal 300 meter (UU PDP / FR-30)
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    final distanceMeters = 300.0 + (random.nextDouble() * 300.0);
    final deltaLat = (distanceMeters * cos(angle)) / 111000.0;
    final deltaLng = (distanceMeters * sin(angle)) /
        (111000.0 * cos(latitude * pi / 180.0));

    final fuzzedLat = latitude + deltaLat;
    final fuzzedLng = longitude + deltaLng;
    final expires = DateTime.now().add(const Duration(hours: 8)).toIso8601String();

    // 4. Insert baris baru ke public_statuses
    Map<String, dynamic> insertedRow;
    try {
      final res = await _client
          .from('public_statuses')
          .insert({
            'user_id': uId,
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
      insertedRow = res;
    } catch (_) {
      // Fallback tanpa join PostgREST
      final res = await _client
          .from('public_statuses')
          .insert({
            'user_id': uId,
            'text': text.length > 140 ? text.substring(0, 140) : text,
            'note': note,
            'image_url': imageUrl,
            'fuzzed_latitude': fuzzedLat,
            'fuzzed_longitude': fuzzedLng,
            'expires_at': expires,
            'is_active': true,
          })
          .select()
          .single();
      final myProfile = await _fetchProfile(uId);
      insertedRow = Map<String, dynamic>.from(res);
      insertedRow['profiles'] = myProfile;
    }

    debugPrint('[ExploreRepo] Catatan publik berhasil diposting: ${insertedRow['id']}');
    return PublicStatus.fromJson(insertedRow, currentUserId: uId);
  }

  @override
  Future<void> deleteMyStatus({String? statusId}) async {
    final uId = _currentUserId;
    debugPrint('[ExploreRepo] Menghapus catatan: statusId=$statusId, userId=$uId');

    // 1. Hapus komentar terkait terlebih dahulu
    try {
      if (statusId != null && statusId.isNotEmpty) {
        await _client.from('status_comments').delete().eq('status_id', statusId);
      }
    } catch (_) {}

    // 2. Nonaktifkan status (update is_active = false)
    try {
      if (statusId != null && statusId.isNotEmpty) {
        await _client
            .from('public_statuses')
            .update({'is_active': false})
            .eq('id', statusId)
            .eq('user_id', uId);
      } else {
        await _client
            .from('public_statuses')
            .update({'is_active': false})
            .eq('user_id', uId);
      }
    } catch (e) {
      debugPrint('[ExploreRepo] Update is_active false failed: $e');
    }

    // 3. Hapus baris fisik dari database
    try {
      if (statusId != null && statusId.isNotEmpty) {
        await _client
            .from('public_statuses')
            .delete()
            .eq('id', statusId)
            .eq('user_id', uId);
      } else {
        await _client
            .from('public_statuses')
            .delete()
            .eq('user_id', uId);
      }
      debugPrint('[ExploreRepo] Berhasil menghapus baris dari public_statuses');
    } catch (e) {
      debugPrint('[ExploreRepo] Delete row failed: $e');
    }
  }

  @override
  Future<List<StatusComment>> getComments(String statusId) async {
    final statusRes = await _client
        .from('public_statuses')
        .select('user_id')
        .eq('id', statusId)
        .maybeSingle();

    final statusOwnerId = statusRes?['user_id'] as String?;

    List<dynamic> rows = [];
    try {
      final res = await _client
          .from('status_comments')
          .select('*, profiles!status_comments_author_id_fkey(*)')
          .eq('status_id', statusId)
          .order('created_at', ascending: true);
      rows = res as List;
    } catch (_) {
      try {
        final res = await _client
            .from('status_comments')
            .select()
            .eq('status_id', statusId)
            .order('created_at', ascending: true);
        rows = res as List;
      } catch (_) {}
    }

    // Ambil data profil jika belum ter-join
    final authorIds = rows
        .where((r) => r['profiles'] == null && r['author_id'] != null)
        .map((r) => r['author_id'] as String)
        .toSet()
        .toList();

    final Map<String, Map<String, dynamic>> profilesMap = {};
    if (authorIds.isNotEmpty) {
      try {
        final pRes = await _client
            .from('profiles')
            .select('id, display_name, username, avatar_url')
            .inFilter('id', authorIds);
        for (final p in (pRes as List)) {
          profilesMap[p['id'] as String] = p as Map<String, dynamic>;
        }
      } catch (_) {}
    }

    return rows.map((json) {
      final map = Map<String, dynamic>.from(json as Map<String, dynamic>);
      final aId = map['author_id'] as String;
      if (map['profiles'] == null && profilesMap.containsKey(aId)) {
        map['profiles'] = profilesMap[aId];
      }

      return StatusComment.fromJson(
        map,
        currentUserId: _currentUserId,
        statusOwnerId: statusOwnerId,
      );
    }).toList();
  }

  @override
  Future<StatusComment> addComment({
    required String statusId,
    required String content,
  }) async {
    final uId = _currentUserId;

    Map<String, dynamic> row;
    try {
      final res = await _client
          .from('status_comments')
          .insert({
            'status_id': statusId,
            'author_id': uId,
            'content': content.trim(),
          })
          .select('*, profiles!status_comments_author_id_fkey(*)')
          .single();
      row = res;
    } catch (_) {
      final res = await _client
          .from('status_comments')
          .insert({
            'status_id': statusId,
            'author_id': uId,
            'content': content.trim(),
          })
          .select()
          .single();
      final myProfile = await _fetchProfile(uId);
      row = Map<String, dynamic>.from(res);
      row['profiles'] = myProfile;
    }

    return StatusComment.fromJson(row, currentUserId: uId);
  }

  @override
  Future<void> deleteComment(String commentId) async {
    try {
      await _client.from('status_comments').delete().eq('id', commentId);
    } catch (e) {
      debugPrint('[ExploreRepo] deleteComment error: $e');
    }
  }
}
