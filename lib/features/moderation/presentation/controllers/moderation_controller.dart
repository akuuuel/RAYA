import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../data/repositories/mock_moderation_repository.dart';
import '../../data/repositories/supabase_moderation_repository.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/report_ticket.dart';
import '../../domain/repositories/moderation_repository.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  if (AppConfig.useMock) {
    return MockModerationRepository();
  }
  return SupabaseModerationRepository();
});

class ModerationState {
  final bool isLoading;
  final NotificationSettings settings;
  final String? errorMessage;
  final String? successMessage;

  const ModerationState({
    this.isLoading = false,
    this.settings = const NotificationSettings(),
    this.errorMessage,
    this.successMessage,
  });

  ModerationState copyWith({
    bool? isLoading,
    NotificationSettings? settings,
    String? errorMessage,
    String? successMessage,
  }) {
    return ModerationState(
      isLoading: isLoading ?? this.isLoading,
      settings: settings ?? this.settings,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class ModerationController extends StateNotifier<ModerationState> {
  final ModerationRepository _repository;

  ModerationController(this._repository) : super(const ModerationState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final s = await _repository.getNotificationSettings();
      state = state.copyWith(isLoading: false, settings: s);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> updateSettings(NotificationSettings newSettings) async {
    try {
      await _repository.updateNotificationSettings(newSettings);
      state = state.copyWith(settings: newSettings);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> submitReport({
    required String reportedUserId,
    required ReportType reportType,
    required String targetId,
    required ReportReason reason,
    String? decryptedContentEvidence,
  }) async {
    try {
      final ticket = await _repository.submitReport(
        reportedUserId: reportedUserId,
        reportType: reportType,
        targetId: targetId,
        reason: reason,
        decryptedContentEvidence: decryptedContentEvidence,
      );

      final msg = ticket.isHighPriority
          ? 'Laporan prioritas tinggi telah diteruskan ke tim penanganan segera (FR-43).'
          : 'Laporan Anda telah berhasil dikirim dan akan segera ditinjau (FR-44).';

      state = state.copyWith(successMessage: msg);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final moderationControllerProvider =
    StateNotifierProvider<ModerationController, ModerationState>((ref) {
  final repo = ref.watch(moderationRepositoryProvider);
  return ModerationController(repo);
});
