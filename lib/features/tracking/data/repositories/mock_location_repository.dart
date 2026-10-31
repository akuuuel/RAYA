import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/entities/location_point.dart';
import '../../domain/entities/location_session.dart';
import '../../domain/repositories/location_repository.dart';

/// Implementasi Mock Repository Pantau Lokasi untuk pengujian lokal terisolasi.
class MockLocationRepository implements LocationRepository {
  final List<LocationSession> _sessions = [];
  final Map<String, LocationPoint> _locations = {};

  final UserProfile _myProfile = UserProfile(
    id: 'current-mock-user',
    email: 'saya@raya.id',
    username: 'user_saya',
    displayName: 'Saya',
    birthDate: DateTime(1995, 1, 1),
    isAdult: true,
  );

  MockLocationRepository() {
    // Posisi awal pengguna (Monas, Jakarta)
    _locations['current-mock-user'] = LocationPoint(
      latitude: -6.175392,
      longitude: 106.827153,
      accuracy: 10.0,
      updatedAt: DateTime.now(),
    );

    // Posisi kontak Rina Pratama (Grand Indonesia, Jakarta)
    _locations['mock-user-rina'] = LocationPoint(
      latitude: -6.1950,
      longitude: 106.8230,
      accuracy: 12.0,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
    );
  }

  @override
  Future<List<LocationSession>> getActiveSessions() async {
    return List.unmodifiable(
      _sessions.where((s) => s.isActive),
    );
  }

  @override
  Future<List<LocationSession>> getIncomingRequests() async {
    return List.unmodifiable(
      _sessions.where(
        (s) =>
            s.target.id == _myProfile.id &&
            s.status == LocationSessionStatus.pending,
      ),
    );
  }

  @override
  Future<LocationSession> requestLocationSharing({
    required UserProfile targetUser,
    required bool isBidirectional,
    required LocationDurationType durationType,
  }) async {
    DateTime? expires;
    if (durationType == LocationDurationType.oneHour) {
      expires = DateTime.now().add(const Duration(hours: 1));
    } else if (durationType == LocationDurationType.eightHours) {
      expires = DateTime.now().add(const Duration(hours: 8));
    }

    final session = LocationSession(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      requester: _myProfile,
      target: targetUser,
      isBidirectional: isBidirectional,
      durationType: durationType,
      expiresAt: expires,
      status: LocationSessionStatus.active, // Langsung aktif di mock testing
      createdAt: DateTime.now(),
    );

    _sessions.add(session);
    return session;
  }

  @override
  Future<void> acceptSession(String sessionId) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final s = _sessions[index];
      _sessions[index] = s.copyWith(status: LocationSessionStatus.active);
    }
  }

  @override
  Future<void> stopSession(String sessionId) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final s = _sessions[index];
      _sessions[index] = s.copyWith(
        status: LocationSessionStatus.stopped,
        stoppedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> rejectSession(String sessionId) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final s = _sessions[index];
      _sessions[index] = s.copyWith(
        status: LocationSessionStatus.rejected,
        stoppedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> updateMyLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    _locations['current-mock-user'] = LocationPoint(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<LocationPoint?> getMyLocation() async {
    return _locations['current-mock-user'];
  }

  @override
  Future<LocationPoint?> getContactLocation(String contactUserId) async {
    // Cek apakah ada sesi aktif
    final hasActiveSession = _sessions.any(
      (s) =>
          s.isActive &&
          ((s.requester.id == contactUserId && s.isBidirectional) ||
              s.target.id == contactUserId),
    );

    if (!hasActiveSession) return null;
    return _locations[contactUserId];
  }
}

