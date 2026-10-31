import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/report_ticket.dart';
import '../../domain/repositories/moderation_repository.dart';

/// Implementasi ModerationRepository menggunakan Supabase Database & RLS.
class SupabaseModerationRepository implements ModerationRepository {
  final SupabaseClient _client;

  SupabaseModerationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi pengguna tidak aktif. Silakan masuk kembali.');
    }
    return user.id;
  }

  @override
  Future<ReportTicket> submitReport({
    required String reportedUserId,
    required ReportType reportType,
    required String targetId,
    required ReportReason reason,
    String? decryptedContentEvidence,
  }) async {
    String typeStr = 'profile';
    if (reportType == ReportType.message) typeStr = 'message';
    if (reportType == ReportType.publicStatus) typeStr = 'public_status';
    if (reportType == ReportType.comment) typeStr = 'comment';

    final res = await _client
        .from('reports')
        .insert({
          'reporter_id': _currentUserId,
          'reported_user_id': reportedUserId,
          'report_type': typeStr,
          'target_id': targetId,
          'reason': reason.name,
          'is_high_priority': reason.isHighPriority, // FR-43
          'decrypted_content_evidence': decryptedContentEvidence, // FR-42
          'status': 'submitted',
        })
        .select()
        .single();

    return ReportTicket.fromJson(res);
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    final res = await _client
        .from('notification_settings')
        .select()
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (res == null) {
      return const NotificationSettings();
    }
    return NotificationSettings.fromJson(res);
  }

  @override
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    await _client.from('notification_settings').upsert({
      'user_id': _currentUserId,
      ...settings.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}

