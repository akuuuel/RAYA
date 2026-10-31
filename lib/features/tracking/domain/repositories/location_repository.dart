import '../../../auth/domain/entities/user_profile.dart';
import '../entities/location_point.dart';
import '../entities/location_session.dart';

/// Kontrak Repository Pantau Lokasi Pribadi sesuai FR-20 s.d. FR-28.
abstract class LocationRepository {
  /// Mengambil sesi pantau lokasi yang sedang aktif (FR-26)
  Future<List<LocationSession>> getActiveSessions();

  /// Mengambil daftar permintaan pantau masuk dari kontak (FR-21, FR-22)
  Future<List<LocationSession>> getIncomingRequests();

  /// Mengirim permintaan pantau ke kontak (FR-21, FR-23)
  Future<LocationSession> requestLocationSharing({
    required UserProfile targetUser,
    required bool isBidirectional,
    required LocationDurationType durationType,
  });

  /// Menyetujui permintaan pantau (FR-22)
  Future<void> acceptSession(String sessionId);

  /// Menghentikan sesi berbagi lokasi (FR-24, FR-28)
  Future<void> stopSession(String sessionId);

  /// Menolak permintaan pantau
  Future<void> rejectSession(String sessionId);

  /// Memperbarui posisi koordinat pengguna saat ini (FR-26, FR-28)
  Future<void> updateMyLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
  });

  /// Mengambil posisi terakhir pengguna saat ini
  Future<LocationPoint?> getMyLocation();

  /// Mengambil posisi terakhir kontak yang sedang berbagi lokasi
  Future<LocationPoint?> getContactLocation(String contactUserId);
}

