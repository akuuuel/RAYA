import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/entities/location_point.dart';
import '../../domain/entities/location_session.dart';
import '../../domain/repositories/location_repository.dart';

/// Implementasi LocationRepository menggunakan Supabase Postgres & RLS.
class SupabaseLocationRepository implements LocationRepository {
  final SupabaseClient _client;

  SupabaseLocationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi pengguna tidak aktif. Silakan masuk kembali.');
    }
    return user.id;
  }

  @override
  Future<List<LocationSession>> getActiveSessions() async {
    final res = await _client
        .from('location_sessions')
        .select('*, requester:profiles!location_sessions_requester_id_fkey(*), target:profiles!location_sessions_target_id_fkey(*)')
        .eq('status', 'active')
        .or('requester_id.eq.$_currentUserId,target_id.eq.$_currentUserId')
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => LocationSession.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LocationSession>> getIncomingRequests() async {
    final res = await _client
        .from('location_sessions')
        .select('*, requester:profiles!location_sessions_requester_id_fkey(*), target:profiles!location_sessions_target_id_fkey(*)')
        .eq('status', 'pending')
        .eq('target_id', _currentUserId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((json) => LocationSession.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LocationSession> requestLocationSharing({
    required UserProfile targetUser,
    required bool isBidirectional,
    required LocationDurationType durationType,
  }) async {
    DateTime? expires;
    String dType = '1_hour';
    if (durationType == LocationDurationType.oneHour) {
      expires = DateTime.now().add(const Duration(hours: 1));
      dType = '1_hour';
    } else if (durationType == LocationDurationType.eightHours) {
      expires = DateTime.now().add(const Duration(hours: 8));
      dType = '8_hours';
    } else {
      dType = 'manual';
    }

    final res = await _client
        .from('location_sessions')
        .insert({
          'requester_id': _currentUserId,
          'target_id': targetUser.id,
          'is_bidirectional': isBidirectional,
          'duration_type': dType,
          'expires_at': expires?.toIso8601String(),
          'status': 'pending',
        })
        .select('*, requester:profiles!location_sessions_requester_id_fkey(*), target:profiles!location_sessions_target_id_fkey(*)')
        .single();

    return LocationSession.fromJson(res);
  }

  @override
  Future<void> acceptSession(String sessionId) async {
    await _client
        .from('location_sessions')
        .update({'status': 'active'})
        .eq('id', sessionId);
  }

  @override
  Future<void> stopSession(String sessionId) async {
    await _client
        .from('location_sessions')
        .update({
          'status': 'stopped',
          'stopped_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId);
  }

  @override
  Future<void> rejectSession(String sessionId) async {
    await _client
        .from('location_sessions')
        .update({
          'status': 'rejected',
          'stopped_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId);
  }

  @override
  Future<void> updateMyLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    await _client.from('user_locations').upsert({
      'user_id': _currentUserId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<LocationPoint?> getMyLocation() async {
    final res = await _client
        .from('user_locations')
        .select()
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (res == null) return null;
    return LocationPoint.fromJson(res);
  }

  @override
  Future<LocationPoint?> getContactLocation(String contactUserId) async {
    final res = await _client
        .from('user_locations')
        .select()
        .eq('user_id', contactUserId)
        .maybeSingle();

    if (res == null) return null;
    return LocationPoint.fromJson(res);
  }
}

