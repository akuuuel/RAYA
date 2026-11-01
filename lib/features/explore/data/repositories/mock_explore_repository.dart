import 'dart:math';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/entities/public_status.dart';
import '../../domain/entities/status_comment.dart';
import '../../domain/repositories/explore_repository.dart';

/// Implementasi Mock Repository Peta Publik dan Status 8 Jam untuk pengujian terisolasi.
class MockExploreRepository implements ExploreRepository {
  bool _isPublicVisible = false;
  PublicStatus? _myStatus;
  final List<PublicStatus> _nearbyStatuses = [];
  final Map<String, List<StatusComment>> _commentsByStatus = {};

  final UserProfile _myProfile = UserProfile(
    id: 'current-mock-user',
    email: 'saya@raya.id',
    username: 'user_saya',
    displayName: 'Saya',
    birthDate: DateTime(1995, 1, 1),
    isAdult: true,
  );

  MockExploreRepository() {
    final now = DateTime.now();

    // Data status publik sekitar simulasi (FR-30, FR-31, FR-32)
    final rinaStatus = PublicStatus(
      id: 'status-rina-1',
      userId: 'mock-user-rina',
      authorName: 'Rina Pratama',
      authorUsername: 'rina_pratama',
      text: 'Lagi ngerjain tugas di kafe ini, colokan aman.',
      note: 'Tempatnya tenang di lantai 2, wifi 50 Mbps.',
      fuzzedLatitude: -6.1980,
      fuzzedLongitude: 106.8260,
      createdAt: now.subtract(const Duration(hours: 2)),
      expiresAt: now.add(const Duration(hours: 6)), // 8 jam sejak dibuat
      isMine: false,
      isContact: true, // Rina adalah kontak terhubung
    );

    final budiStatus = PublicStatus(
      id: 'status-budi-1',
      userId: 'mock-user-budi',
      authorName: 'Budi Santoso',
      authorUsername: 'budi_santoso',
      text: 'Antrean tiket bioskop lumayan panjang tapi lancar.',
      fuzzedLatitude: -6.2100,
      fuzzedLongitude: 106.8350,
      createdAt: now.subtract(const Duration(hours: 1)),
      expiresAt: now.add(const Duration(hours: 7)),
      isMine: false,
      isContact: false,
    );

    _nearbyStatuses.addAll([rinaStatus, budiStatus]);

    // Komentar pada status Rina dari kontak (FR-35)
    _commentsByStatus[rinaStatus.id] = [
      StatusComment(
        id: 'comm-1',
        statusId: rinaStatus.id,
        author: _myProfile,
        content: 'Masih ada meja kosong di dekat jendela?',
        createdAt: now.subtract(const Duration(minutes: 45)),
        canDelete: true,
      ),
    ];
  }

  @override
  Future<bool> getPublicVisibility() async => _isPublicVisible;

  @override
  Future<void> setPublicVisibility(bool isVisible) async {
    _isPublicVisible = isVisible;
  }

  @override
  Future<List<PublicStatus>> getNearbyStatuses({
    required double latitude,
    required double longitude,
    required int radiusKm,
  }) async {
    final now = DateTime.now();
    final list = <PublicStatus>[];

    if (_isPublicVisible && _myStatus != null && !_myStatus!.isExpired) {
      list.add(_myStatus!);
    }

    list.addAll(_nearbyStatuses.where((s) => !s.isExpired));
    return List.unmodifiable(list);
  }

  @override
  Future<PublicStatus?> getMyActiveStatus() async {
    if (_myStatus != null && _myStatus!.isExpired) {
      _myStatus = null;
    }
    return _myStatus;
  }

  @override
  Future<PublicStatus> postStatus({
    required String text,
    String? note,
    String? imageUrl,
    required double latitude,
    required double longitude,
  }) async {
    // Penyamaran acak radius minimal 300 meter (FR-30)
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    final distanceMeters = 300.0 + (random.nextDouble() * 300.0);
    final deltaLat = (distanceMeters * cos(angle)) / 111000.0;
    final deltaLng = (distanceMeters * sin(angle)) /
        (111000.0 * cos(latitude * pi / 180.0));

    final fuzzedLat = latitude + deltaLat;
    final fuzzedLng = longitude + deltaLng;

    final now = DateTime.now();
    final expires = now.add(const Duration(hours: 8)); // Berlaku 8 jam (FR-32)

    final newStatus = PublicStatus(
      id: 'status-my-${now.millisecondsSinceEpoch}',
      userId: _myProfile.id,
      authorName: _myProfile.displayName ?? 'Saya',
      authorUsername: _myProfile.username,
      text: text.length > 140 ? text.substring(0, 140) : text,
      note: note,
      imageUrl: imageUrl,
      fuzzedLatitude: fuzzedLat,
      fuzzedLongitude: fuzzedLng,
      createdAt: now,
      expiresAt: expires,
      isMine: true,
      isContact: true,
    );

    _myStatus = newStatus;
    _isPublicVisible = true; // Otomatis aktifkan tampil publik saat pasang status
    return newStatus;
  }

  @override
  Future<void> deleteMyStatus({String? statusId}) async {
    if (statusId != null) {
      _nearbyStatuses.removeWhere((s) => s.id == statusId);
    }
    _myStatus = null;
  }

  @override
  Future<List<StatusComment>> getComments(String statusId) async {
    final list = _commentsByStatus[statusId] ?? [];
    return List.unmodifiable(list);
  }

  @override
  Future<StatusComment> addComment({
    required String statusId,
    required String content,
  }) async {
    final newComm = StatusComment(
      id: 'comm-${DateTime.now().millisecondsSinceEpoch}',
      statusId: statusId,
      author: _myProfile,
      content: content.trim(),
      createdAt: DateTime.now(),
      canDelete: true,
    );

    final list = _commentsByStatus.putIfAbsent(statusId, () => []);
    list.add(newComm);
    return newComm;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    for (final list in _commentsByStatus.values) {
      list.removeWhere((c) => c.id == commentId);
    }
  }
}

