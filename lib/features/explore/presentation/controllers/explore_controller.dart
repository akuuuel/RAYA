import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../data/repositories/mock_explore_repository.dart';
import '../../data/repositories/supabase_explore_repository.dart';
import '../../domain/entities/public_status.dart';
import '../../domain/entities/status_comment.dart';
import '../../domain/repositories/explore_repository.dart';

final exploreRepositoryProvider = Provider<ExploreRepository>((ref) {
  if (AppConfig.useMock) {
    return MockExploreRepository();
  }
  return SupabaseExploreRepository();
});

class ExploreState {
  final bool isLoading;
  final bool isPublicVisible;
  final int selectedRadiusKm;
  final PublicStatus? myStatus;
  final List<PublicStatus> nearbyStatuses;
  final Map<String, List<StatusComment>> comments;
  final String? errorMessage;
  final String? successMessage;

  const ExploreState({
    this.isLoading = false,
    this.isPublicVisible = false,
    this.selectedRadiusKm = 5,
    this.myStatus,
    this.nearbyStatuses = const [],
    this.comments = const {},
    this.errorMessage,
    this.successMessage,
  });

  ExploreState copyWith({
    bool? isLoading,
    bool? isPublicVisible,
    int? selectedRadiusKm,
    PublicStatus? myStatus,
    bool clearMyStatus = false,
    List<PublicStatus>? nearbyStatuses,
    Map<String, List<StatusComment>>? comments,
    String? errorMessage,
    String? successMessage,
  }) {
    return ExploreState(
      isLoading: isLoading ?? this.isLoading,
      isPublicVisible: isPublicVisible ?? this.isPublicVisible,
      selectedRadiusKm: selectedRadiusKm ?? this.selectedRadiusKm,
      myStatus: clearMyStatus ? null : (myStatus ?? this.myStatus),
      nearbyStatuses: nearbyStatuses ?? this.nearbyStatuses,
      comments: comments ?? this.comments,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class ExploreController extends StateNotifier<ExploreState> {
  final ExploreRepository _repository;

  ExploreController(this._repository) : super(const ExploreState()) {
    loadExploreData();
  }

  Future<void> loadExploreData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final isVisible = await _repository.getPublicVisibility();
      final myStatus = await _repository.getMyActiveStatus();
      final nearby = await _repository.getNearbyStatuses(
        latitude: -6.175392,
        longitude: 106.827153,
        radiusKm: state.selectedRadiusKm,
      );

      state = state.copyWith(
        isLoading: false,
        isPublicVisible: isVisible,
        myStatus: myStatus,
        clearMyStatus: myStatus == null,
        nearbyStatuses: nearby,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setRadius(int radiusKm) {
    state = state.copyWith(selectedRadiusKm: radiusKm);
    loadExploreData();
  }

  Future<void> togglePublicVisibility(bool isVisible) async {
    try {
      await _repository.setPublicVisibility(isVisible);
      state = state.copyWith(
        isPublicVisible: isVisible,
        successMessage: isVisible
            ? 'Lokasi Anda disamarkan minimal 300m di peta publik (FR-30).'
            : 'Tampil di peta publik dimatikan (FR-39).',
      );
      loadExploreData();
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> postStatus({
    required String text,
    String? note,
    String? imageUrl,
  }) async {
    try {
      final newStatus = await _repository.postStatus(
        text: text,
        note: note,
        imageUrl: imageUrl,
        latitude: -6.175392, // Posisi simulasi pengguna
        longitude: 106.827153,
      );

      state = state.copyWith(
        myStatus: newStatus,
        isPublicVisible: true,
        successMessage: 'Status publik berhasil dipasang selama 8 jam (FR-32).',
      );
      await loadExploreData();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> deleteMyStatus() async {
    try {
      await _repository.deleteMyStatus();
      state = state.copyWith(
        clearMyStatus: true,
        successMessage: 'Status publik telah dihapus (FR-33).',
      );
      await loadExploreData();
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadComments(String statusId) async {
    try {
      final commentsList = await _repository.getComments(statusId);
      final newMap = Map<String, List<StatusComment>>.from(state.comments);
      newMap[statusId] = commentsList;
      state = state.copyWith(comments: newMap);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> addComment({
    required String statusId,
    required String content,
  }) async {
    try {
      final comment = await _repository.addComment(
        statusId: statusId,
        content: content,
      );

      final newMap = Map<String, List<StatusComment>>.from(state.comments);
      final currentList = List<StatusComment>.from(newMap[statusId] ?? []);
      currentList.add(comment);
      newMap[statusId] = currentList;

      state = state.copyWith(
        comments: newMap,
        successMessage: 'Komentar terkirim ke pemilik status (FR-35).',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> deleteComment({
    required String statusId,
    required String commentId,
  }) async {
    try {
      await _repository.deleteComment(commentId);
      final newMap = Map<String, List<StatusComment>>.from(state.comments);
      final currentList = List<StatusComment>.from(newMap[statusId] ?? []);
      currentList.removeWhere((c) => c.id == commentId);
      newMap[statusId] = currentList;

      state = state.copyWith(
        comments: newMap,
        successMessage: 'Komentar dihapus (FR-36).',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

final exploreControllerProvider =
    StateNotifierProvider<ExploreController, ExploreState>((ref) {
  final repo = ref.watch(exploreRepositoryProvider);
  return ExploreController(repo);
});
