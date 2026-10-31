import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/report_ticket.dart';
import '../../domain/repositories/moderation_repository.dart';

/// Implementasi Mock Moderation Repository untuk pengujian unit terisolasi.
class MockModerationRepository implements ModerationRepository {
  final List<ReportTicket> _reports = [];
  NotificationSettings _settings = const NotificationSettings();

  @override
  Future<ReportTicket> submitReport({
    required String reportedUserId,
    required ReportType reportType,
    required String targetId,
    required ReportReason reason,
    String? decryptedContentEvidence,
  }) async {
    final ticket = ReportTicket(
      id: 'rep-${DateTime.now().millisecondsSinceEpoch}',
      reporterId: 'current-mock-user',
      reportedUserId: reportedUserId,
      reportType: reportType,
      targetId: targetId,
      reason: reason,
      isHighPriority: reason.isHighPriority, // FR-43
      decryptedContentEvidence: decryptedContentEvidence, // FR-42
      status: 'submitted',
      createdAt: DateTime.now(),
    );

    _reports.add(ticket);
    return ticket;
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    return _settings;
  }

  @override
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    _settings = settings;
  }

  List<ReportTicket> get submittedReports => List.unmodifiable(_reports);
}

