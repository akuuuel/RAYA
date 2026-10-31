import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../data/repositories/mock_location_repository.dart';
import '../../data/repositories/supabase_location_repository.dart';
import '../../domain/entities/location_point.dart';
import '../../domain/entities/location_session.dart';
import '../../domain/repositories/location_repository.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  if (AppConfig.useMock) {
    return MockLocationRepository();
  }
  return SupabaseLocationRepository();
});

class TrackingState {
  final bool isLoading;
  final List<LocationSession> activeSessions;
  final List<LocationSession> incomingRequests;
  final LocationPoint? myLocation;
  final Map<String, LocationPoint> contactLocations;
  final String? errorMessage;
  final String? successMessage;

  const TrackingState({
    this.isLoading = false,
    this.activeSessions = const [],
    this.incomingRequests = const [],
    this.myLocation,
    this.contactLocations = const {},
    this.errorMessage,
    this.successMessage,
  });

  bool get isSharingActive => activeSessions.isNotEmpty;

  TrackingState copyWith({
    bool? isLoading,
    List<LocationSession>? activeSessions,
    List<LocationSession>? incomingRequests,
    LocationPoint? myLocation,
    Map<String, LocationPoint>? contactLocations,
    String? errorMessage,
    String? successMessage,
  }) {
    return TrackingState(
      isLoading: isLoading ?? this.isLoading,
      activeSessions: activeSessions ?? this.activeSessions,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      myLocation: myLocation ?? this.myLocation,
      contactLocations: contactLocations ?? this.contactLocations,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class TrackingController extends StateNotifier<TrackingState> {
  final LocationRepository _repository;

  TrackingController(this._repository) : super(const TrackingState()) {
    loadSessionsAndLocations();
  }

  Future<void> loadSessionsAndLocations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final active = await _repository.getActiveSessions();
      final incoming = await _repository.getIncomingRequests();
      final myLoc = await _repository.getMyLocation();

      final Map<String, LocationPoint> contactLocs = {};
      for (final session in active) {
        final contactId = session.target.id;
        final loc = await _repository.getContactLocation(contactId);
        if (loc != null) {
          contactLocs[contactId] = loc;
        }
      }

      state = state.copyWith(
        isLoading: false,
        activeSessions: active,
        incomingRequests: incoming,
        myLocation: myLoc,
        contactLocations: contactLocs,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> requestSharing({
    required UserProfile targetUser,
    required bool isBidirectional,
    required LocationDurationType durationType,
  }) async {
    try {
      await _repository.requestLocationSharing(
        targetUser: targetUser,
        isBidirectional: isBidirectional,
        durationType: durationType,
      );
      await loadSessionsAndLocations();
      state = state.copyWith(
        successMessage: 'Permintaan pantau lokasi berhasil dikirim.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> acceptSession(String sessionId) async {
    try {
      await _repository.acceptSession(sessionId);
      await loadSessionsAndLocations();
      state = state.copyWith(
        successMessage: 'Berbagi lokasi disetujui.',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> stopSession(String sessionId) async {
    try {
      await _repository.stopSession(sessionId);
      await loadSessionsAndLocations();
      state = state.copyWith(
        successMessage: 'Berbagi lokasi telah dihentikan (FR-24).',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> rejectSession(String sessionId) async {
    try {
      await _repository.rejectSession(sessionId);
      await loadSessionsAndLocations();
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final trackingControllerProvider =
    StateNotifierProvider<TrackingController, TrackingState>((ref) {
  final repo = ref.watch(locationRepositoryProvider);
  return TrackingController(repo);
});
