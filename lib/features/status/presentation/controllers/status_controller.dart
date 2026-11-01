import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/user_status.dart';

class StatusState {
  final bool isLoading;
  final List<UserStatus> myStatuses;
  final List<UserStatus> contactStatuses;
  final Set<String> viewedStatusIds;
  final String? errorMessage;

  const StatusState({
    this.isLoading = false,
    this.myStatuses = const [],
    this.contactStatuses = const [],
    this.viewedStatusIds = const {},
    this.errorMessage,
  });

  /// Status kontak belum dilihat (terbaru di paling kiri)
  List<UserStatus> get recentUnviewedStatuses =>
      contactStatuses.where((s) => !s.isViewed).toList();

  /// Status kontak sudah dilihat (lingkaran abu-abu)
  List<UserStatus> get viewedStatuses =>
      contactStatuses.where((s) => s.isViewed).toList();

  StatusState copyWith({
    bool? isLoading,
    List<UserStatus>? myStatuses,
    List<UserStatus>? contactStatuses,
    Set<String>? viewedStatusIds,
    String? errorMessage,
  }) {
    return StatusState(
      isLoading: isLoading ?? this.isLoading,
      myStatuses: myStatuses ?? this.myStatuses,
      contactStatuses: contactStatuses ?? this.contactStatuses,
      viewedStatusIds: viewedStatusIds ?? this.viewedStatusIds,
      errorMessage: errorMessage,
    );
  }
}

class StatusController extends StateNotifier<StatusState> {
  final Ref _ref;
  static const String _viewedStorageKey = 'raya_viewed_status_ids_v2';
  static const String _myStatusCacheKey = 'raya_my_statuses_cache_v2';

  Timer? _pollingTimer;
  RealtimeChannel? _realtimeChannel;

  StatusController(this._ref) : super(const StatusState()) {
    _initStatuses();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    if (_realtimeChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_realtimeChannel!);
      } catch (_) {}
      _realtimeChannel = null;
    }
    super.dispose();
  }

  Future<void> _initStatuses() async {
    state = state.copyWith(isLoading: true);
    await _syncStatuses();
    state = state.copyWith(isLoading: false);
    _startRealtimeSubscription();
    // Polling cadangan setiap 10 detik
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _syncStatuses();
    });
  }

  void _startRealtimeSubscription() {
    try {
      final client = Supabase.instance.client;
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = client
          .channel('user_statuses_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_statuses',
            callback: (payload) {
              debugPrint('[Status] Postgres change: ${payload.eventType}');
              _syncStatuses();
            },
          )
          .onBroadcast(
            event: 'status_posted',
            callback: (payload) {
              debugPrint('[Status] Broadcast received: $payload');
              _syncStatuses();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('[Status] Realtime subscription error: $e');
    }
  }

  /// Sinkronisasi status dari Supabase ke state lokal
  Future<void> _syncStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final viewedList = prefs.getStringList(_viewedStorageKey) ?? [];
    final viewedIds = viewedList.toSet();

    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;
    if (currentUser == null) return;

    List<UserStatus> remoteMyStatuses = [];
    List<UserStatus> remoteContactStatuses = [];

    try {
      // Query: ambil semua status aktif yang bisa dilihat (RLS handle filtering)
      // Ini termasuk status saya + status kontak (berkat RLS dua policy SELECT)
      final rows = await client
          .from('user_statuses')
          .select('id, user_id, caption, media_data, media_url, bg_color, created_at, expires_at, is_active')
          .eq('is_active', true)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      debugPrint('[Status] Fetched ${(rows as List).length} statuses from Supabase');

      // Kumpulkan user_id unik untuk fetch profil sekaligus
      final userIds = (rows as List)
          .map((r) => r['user_id'] as String)
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> profilesMap = {};
      if (userIds.isNotEmpty) {
        try {
          final pRes = await client
              .from('profiles')
              .select('id, display_name, username, avatar_url')
              .inFilter('id', userIds);
          for (final p in (pRes as List)) {
            profilesMap[p['id'] as String] = p as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('[Status] Error fetching profiles: $e');
        }
      }

      for (final row in rows) {
        final uId = row['user_id'] as String;
        final profile = profilesMap[uId];
        final isMine = uId == currentUser.id;

        final statusId = row['id'] as String;
        final isViewed = isMine || viewedIds.contains(statusId);

        final rawBgColor = row['bg_color'];
        final bgColor = rawBgColor is int
            ? rawBgColor
            : (rawBgColor is String ? int.tryParse(rawBgColor) ?? 0xFF6C5CE7 : 0xFF6C5CE7);

        final rawMediaData = row['media_data'] as String?;
        final rawMediaUrl = row['media_url'] as String?;

        final authorName = isMine
            ? 'Status Saya'
            : (profile?['display_name'] as String? ??
                profile?['username'] as String? ??
                'Kontak');

        final status = UserStatus(
          id: statusId,
          userId: uId,
          userName: authorName,
          userAvatarUrl: profile?['avatar_url'] as String?,
          caption: row['caption'] as String? ?? '',
          mediaBase64: rawMediaData,
          mediaUrl: rawMediaUrl,
          bgColorValue: bgColor,
          createdAt: DateTime.parse(row['created_at'] as String),
          isViewed: isViewed,
        );

        if (isMine) {
          remoteMyStatuses.add(status);
        } else {
          remoteContactStatuses.add(status);
        }
      }
    } catch (e) {
      debugPrint('[Status] _syncStatuses error: $e');
      state = state.copyWith(errorMessage: e.toString());
      // Fallback: muat dari cache lokal jika Supabase gagal
      await _loadFromLocalCache(viewedIds);
      return;
    }

    // Jika status saya dari server kosong, cek cache lokal
    if (remoteMyStatuses.isEmpty) {
      final cached = await _loadMyStatusesFromCache();
      // Gunakan cache jika ada dan belum expired
      final validCached = cached.where((s) => !s.isExpired).toList();
      if (validCached.isNotEmpty) {
        remoteMyStatuses = validCached;
      }
    }

    // Simpan cache status saya ke lokal untuk offline fallback
    if (remoteMyStatuses.isNotEmpty) {
      await _saveMyStatusesToCache(remoteMyStatuses);
    }

    state = state.copyWith(
      myStatuses: remoteMyStatuses,
      contactStatuses: _sortByViewedAndTime(remoteContactStatuses, viewedIds),
      viewedStatusIds: viewedIds,
      errorMessage: null,
    );
  }

  List<UserStatus> _sortByViewedAndTime(
      List<UserStatus> list, Set<String> viewedIds) {
    // Tandai isViewed sesuai viewedIds terbaru
    final updated = list.map((s) {
      return s.copyWith(isViewed: viewedIds.contains(s.id));
    }).toList();

    final unviewed = updated.where((s) => !s.isViewed).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final viewed = updated.where((s) => s.isViewed).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return [...unviewed, ...viewed];
  }

  // ============================================================
  // POST STATUS TEKS
  // ============================================================
  Future<void> postTextStatus(String text, int bgColorValue) async {
    final authState = _ref.read(authControllerProvider);
    final myProfile = authState.userProfile;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) throw Exception('Belum login');

    final now = DateTime.now();

    try {
      // Nonaktifkan status lama terlebih dahulu
      await client
          .from('user_statuses')
          .update({'is_active': false})
          .eq('user_id', user.id)
          .eq('is_active', true);

      // Insert status baru
      final res = await client.from('user_statuses').insert({
        'user_id': user.id,
        'caption': text,
        'bg_color': bgColorValue,
        'expires_at': now.add(const Duration(hours: 24)).toIso8601String(),
        'is_active': true,
      }).select('id').single();

      debugPrint('[Status] Inserted text status: ${res['id']}');

      // Broadcast agar HP lain langsung refresh
      try {
        _realtimeChannel?.sendBroadcastMessage(
          event: 'status_posted',
          payload: {'user_id': user.id, 'type': 'text'},
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('[Status] postTextStatus ERROR: $e');
      state = state.copyWith(errorMessage: 'Gagal memposting status: $e');
      rethrow;
    }

    // Optimistic update lokal
    final newStatus = UserStatus(
      id: 'pending_${now.millisecondsSinceEpoch}',
      userId: user.id,
      userName: 'Status Saya',
      userAvatarUrl: myProfile?.avatarUrl,
      caption: text,
      bgColorValue: bgColorValue,
      createdAt: now,
      isViewed: true,
    );
    state = state.copyWith(myStatuses: [newStatus, ...state.myStatuses]);

    // Sync dari server untuk mendapatkan ID asli
    await _syncStatuses();
  }

  // ============================================================
  // POST STATUS GAMBAR
  // ============================================================
  Future<void> postImageStatus(String base64Image, String? caption) async {
    final authState = _ref.read(authControllerProvider);
    final myProfile = authState.userProfile;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) throw Exception('Belum login');

    final now = DateTime.now();
    final cap = caption ?? '';

    try {
      // Nonaktifkan status lama
      await client
          .from('user_statuses')
          .update({'is_active': false})
          .eq('user_id', user.id)
          .eq('is_active', true);

      // Coba upload ke Supabase Storage terlebih dahulu
      String? uploadedUrl;
      try {
        final bytes = base64Decode(base64Image);
        final fileName = 'status_${user.id}_${now.millisecondsSinceEpoch}.jpg';
        await client.storage.from('status-media').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
        uploadedUrl = client.storage.from('status-media').getPublicUrl(fileName);
        debugPrint('[Status] Uploaded image to Storage: $uploadedUrl');
      } catch (storageErr) {
        debugPrint('[Status] Storage upload failed, fallback to base64: $storageErr');
        // Fallback: simpan base64 langsung (bekerja tapi besar)
        uploadedUrl = null;
      }

      final res = await client.from('user_statuses').insert({
        'user_id': user.id,
        'caption': cap,
        'media_data': uploadedUrl == null ? base64Image : null,
        'media_url': uploadedUrl,
        'bg_color': 0xFF140F24,
        'expires_at': now.add(const Duration(hours: 24)).toIso8601String(),
        'is_active': true,
      }).select('id').single();

      debugPrint('[Status] Inserted image status: ${res['id']}');

      try {
        _realtimeChannel?.sendBroadcastMessage(
          event: 'status_posted',
          payload: {'user_id': user.id, 'type': 'image'},
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('[Status] postImageStatus ERROR: $e');
      state = state.copyWith(errorMessage: 'Gagal memposting status foto: $e');
      rethrow;
    }

    // Optimistic update
    final newStatus = UserStatus(
      id: 'pending_${now.millisecondsSinceEpoch}',
      userId: user.id,
      userName: 'Status Saya',
      userAvatarUrl: myProfile?.avatarUrl,
      caption: cap,
      mediaBase64: base64Image,
      bgColorValue: 0xFF140F24,
      createdAt: now,
      isViewed: true,
    );
    state = state.copyWith(myStatuses: [newStatus, ...state.myStatuses]);

    await _syncStatuses();
  }

  // ============================================================
  // HAPUS STATUS
  // ============================================================
  Future<void> deleteMyStatus(String statusId) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      await client
          .from('user_statuses')
          .delete()
          .eq('id', statusId)
          .eq('user_id', user.id);
      debugPrint('[Status] Deleted status: $statusId');

      try {
        _realtimeChannel?.sendBroadcastMessage(
          event: 'status_posted',
          payload: {'user_id': user.id, 'deleted_id': statusId},
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('[Status] deleteMyStatus ERROR: $e');
      // Coba update is_active = false sebagai fallback
      try {
        await client
            .from('user_statuses')
            .update({'is_active': false})
            .eq('id', statusId)
            .eq('user_id', user.id);
      } catch (_) {}
    }

    final updated = state.myStatuses.where((s) => s.id != statusId).toList();
    state = state.copyWith(myStatuses: updated);
    await _saveMyStatusesToCache(updated);
    await _syncStatuses();
  }

  // ============================================================
  // TANDAI STATUS SUDAH DILIHAT
  // ============================================================
  Future<void> markAsViewed(String statusId) async {
    if (state.viewedStatusIds.contains(statusId)) return;

    final updatedViewed = {...state.viewedStatusIds, statusId};

    final updatedContacts = state.contactStatuses.map((s) {
      if (s.id == statusId) {
        return s.copyWith(isViewed: true, viewCount: s.viewCount + 1);
      }
      return s;
    }).toList();

    state = state.copyWith(
      viewedStatusIds: updatedViewed,
      contactStatuses: _sortByViewedAndTime(updatedContacts, updatedViewed),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_viewedStorageKey, updatedViewed.toList());
  }

  // ============================================================
  // CACHE LOKAL
  // ============================================================
  Future<List<UserStatus>> _loadMyStatusesFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_myStatusCacheKey) ?? [];
    final result = <UserStatus>[];
    for (final raw in rawList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        result.add(UserStatus.fromJson(map));
      } catch (_) {}
    }
    return result;
  }

  Future<void> _saveMyStatusesToCache(List<UserStatus> list) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = list.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_myStatusCacheKey, rawList);
  }

  Future<void> _loadFromLocalCache(Set<String> viewedIds) async {
    final cached = await _loadMyStatusesFromCache();
    final valid = cached.where((s) => !s.isExpired).toList();
    try {
      state = state.copyWith(
        myStatuses: valid,
        viewedStatusIds: viewedIds,
      );
    } catch (_) {
      // StateNotifier sudah di-dispose, abaikan
    }
  }

  Future<void> refresh() async {
    await _syncStatuses();
  }
}

final statusControllerProvider =
    StateNotifierProvider<StatusController, StatusState>((ref) {
  return StatusController(ref);
});
