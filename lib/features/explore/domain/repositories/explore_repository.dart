import '../entities/public_status.dart';
import '../entities/status_comment.dart';

/// Kontrak Repository Peta Publik dan Status 8 Jam sesuai FR-29 s.d. FR-40.
abstract class ExploreRepository {
  /// Mengambil status pengaturan tampil di publik (FR-29)
  Future<bool> getPublicVisibility();

  /// Mengaktifkan atau menonaktifkan tampil di publik (FR-29, FR-39)
  Future<void> setPublicVisibility(bool isVisible);

  /// Mengambil daftar status publik dalam radius tertentu (FR-30, FR-37)
  Future<List<PublicStatus>> getNearbyStatuses({
    required double latitude,
    required double longitude,
    required int radiusKm,
  });

  /// Mengambil status aktif milik pengguna saat ini
  Future<PublicStatus?> getMyActiveStatus();

  /// Memasang atau memperbarui status publik berlaku 8 jam (FR-31, FR-32, FR-33)
  /// Posisi otomatis disamarkan acak radius minimal 300 meter (FR-30).
  Future<PublicStatus> postStatus({
    required String text,
    String? note,
    String? imageUrl,
    required double latitude,
    required double longitude,
  });

  /// Menghapus status publik milik sendiri (FR-33)
  Future<void> deleteMyStatus({String? statusId});

  /// Mengambil komentar pada status (hanya untuk kontak terhubung, FR-35)
  Future<List<StatusComment>> getComments(String statusId);

  /// Menambahkan komentar pada status kontak terhubung (FR-35)
  Future<StatusComment> addComment({
    required String statusId,
    required String content,
  });

  /// Menghapus komentar (oleh pemilik status atau penulis komentar, FR-36)
  Future<void> deleteComment(String commentId);
}

