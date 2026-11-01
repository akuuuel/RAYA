import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/location_service.dart';
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
  final double userLatitude;
  final double userLongitude;
  final bool hasRealLocation;
  final PublicStatus? myStatus;
  final List<PublicStatus> nearbyStatuses;
  final Map<String, List<StatusComment>> comments;
  final String? errorMessage;
  final String? successMessage;

  const ExploreState({
    this.isLoading = false,
    this.isPublicVisible = false,
    this.selectedRadiusKm = 5,
    this.userLatitude = LocationService.defaultLatitude,
    this.userLongitude = LocationService.defaultLongitude,
    this.hasRealLocation = false,
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
    double? userLatitude,
    double? userLongitude,
    bool? hasRealLocation,
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
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      hasRealLocation: hasRealLocation ?? this.hasRealLocation,
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
    initExploreWithLocation();
  }

  /// Inisialisasi: minta izin lokasi GPS dan ambil titik koordinat fisik asli perangkat
  Future<void> initExploreWithLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    double lat = state.userLatitude;
    double lng = state.userLongitude;
    bool gotRealLoc = false;

    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) {
        lat = pos.latitude;
        lng = pos.longitude;
        gotRealLoc = true;
      }
    } catch (_) {}

    state = state.copyWith(
      userLatitude: lat,
      userLongitude: lng,
      hasRealLocation: gotRealLoc,
    );

    await loadExploreData();
  }

  Future<void> loadExploreData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Perbarui koordinat jika GPS sudah siap
      final pos = LocationService.instance.lastKnownPosition;
      double lat = pos?.latitude ?? state.userLatitude;
      double lng = pos?.longitude ?? state.userLongitude;

      final isVisible = await _repository.getPublicVisibility();
      final myStatus = await _repository.getMyActiveStatus();
      final nearby = await _repository.getNearbyStatuses(
        latitude: lat,
        longitude: lng,
        radiusKm: state.selectedRadiusKm,
      );

      state = state.copyWith(
        isLoading: false,
        isPublicVisible: isVisible,
        userLatitude: lat,
        userLongitude: lng,
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
    // Pastikan state loading untuk feedback UI
    state = state.copyWith(isLoading: false, errorMessage: null, successMessage: null);

    try {
      // Gunakan lokasi fisik asli perangkat (atau fallback jika GPS belum tersedia)
      final pos = await LocationService.instance.getCurrentPosition();
      final lat = pos?.latitude ?? state.userLatitude;
      final lng = pos?.longitude ?? state.userLongitude;

      final newStatus = await _repository.postStatus(
        text: text,
        note: note,
        imageUrl: imageUrl,
        latitude: lat,
        longitude: lng,
      );

      state = state.copyWith(
        myStatus: newStatus,
        userLatitude: lat,
        userLongitude: lng,
        isPublicVisible: true,
        successMessage: 'Catatan publik berhasil dipasang selama 8 jam (FR-32).',
      );
      // Muat ulang data agar pin muncul di peta
      await loadExploreData();
      return true;
    } catch (e) {
      final errMsg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(errorMessage: errMsg);
      return false;
    }
  }

  Future<void> deleteMyStatus({String? statusId}) async {
    try {
      await _repository.deleteMyStatus(statusId: statusId);

      // Hapus seketika dari state lokal agar tidak ada delay UI
      final updatedNearby = state.nearbyStatuses
          .where((s) => statusId != null ? s.id != statusId : !s.isMine)
          .toList();

      state = state.copyWith(
        clearMyStatus: true,
        nearbyStatuses: updatedNearby,
        successMessage: 'Catatan publik telah dihapus (FR-33).',
      );
      // Muat ulang agar konsisten dengan database
      await loadExploreData();
    } catch (e) {
      final errMsg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(errorMessage: errMsg);
      // Re-throw agar UI dapat menampilkan error spesifik
      rethrow;
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
        successMessage: 'Komentar terkirim ke pemilik catatan (FR-35).',
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
