import '../entities/notification_settings.dart';
import '../entities/report_ticket.dart';

/// Kontrak Repository Moderasi dan Notifikasi sesuai FR-41 s.d. FR-47.
abstract class ModerationRepository {
  /// Mengirimkan laporan pelanggaran profil, pesan, status, atau komentar (FR-41, FR-42, FR-43)
  Future<ReportTicket> submitReport({
    required String reportedUserId,
    required ReportType reportType,
    required String targetId,
    required ReportReason reason,
    String? decryptedContentEvidence, // FR-42
  });

  /// Mengambil pengaturan notifikasi pengguna (FR-47)
  Future<NotificationSettings> getNotificationSettings();

  /// Memperbarui pengaturan notifikasi pengguna (FR-47)
  Future<void> updateNotificationSettings(NotificationSettings settings);
}

