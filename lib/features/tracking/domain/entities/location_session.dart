import '../../../auth/domain/entities/user_profile.dart';

enum LocationDurationType {
  oneHour,
  eightHours,
  manual,
}

enum LocationSessionStatus {
  pending,
  active,
  stopped,
  rejected,
}

/// Sesi Berbagi Lokasi Pribadi sesuai FR-21 s.d. FR-28.
class LocationSession {
  final String id;
  final UserProfile requester;
  final UserProfile target;
  final bool isBidirectional;
  final LocationDurationType durationType;
  final DateTime? expiresAt;
  final LocationSessionStatus status;
  final DateTime createdAt;
  final DateTime? stoppedAt;

  const LocationSession({
    required this.id,
    required this.requester,
    required this.target,
    this.isBidirectional = true,
    this.durationType = LocationDurationType.oneHour,
    this.expiresAt,
    this.status = LocationSessionStatus.pending,
    required this.createdAt,
    this.stoppedAt,
  });

  bool get isActive => status == LocationSessionStatus.active &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  String get durationLabel {
    switch (durationType) {
      case LocationDurationType.oneHour:
        return '1 Jam';
      case LocationDurationType.eightHours:
        return '8 Jam';
      case LocationDurationType.manual:
        return 'Hingga Dimatikan';
    }
  }

  factory LocationSession.fromJson(Map<String, dynamic> json) {
    LocationDurationType duration = LocationDurationType.oneHour;
    if (json['duration_type'] == '8_hours') {
      duration = LocationDurationType.eightHours;
    } else if (json['duration_type'] == 'manual') {
      duration = LocationDurationType.manual;
    }

    LocationSessionStatus status = LocationSessionStatus.pending;
    if (json['status'] == 'active') {
      status = LocationSessionStatus.active;
    } else if (json['status'] == 'stopped') {
      status = LocationSessionStatus.stopped;
    } else if (json['status'] == 'rejected') {
      status = LocationSessionStatus.rejected;
    }

    return LocationSession(
      id: json['id'] as String,
      requester: UserProfile.fromJson(json['requester'] as Map<String, dynamic>),
      target: UserProfile.fromJson(json['target'] as Map<String, dynamic>),
      isBidirectional: json['is_bidirectional'] as bool? ?? true,
      durationType: duration,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      status: status,
      createdAt: DateTime.parse(json['created_at'] as String),
      stoppedAt: json['stopped_at'] != null
          ? DateTime.parse(json['stopped_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    String dType = '1_hour';
    if (durationType == LocationDurationType.eightHours) dType = '8_hours';
    if (durationType == LocationDurationType.manual) dType = 'manual';

    return {
      'id': id,
      'requester': requester.toJson(),
      'target': target.toJson(),
      'is_bidirectional': isBidirectional,
      'duration_type': dType,
      'expires_at': expiresAt?.toIso8601String(),
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'stopped_at': stoppedAt?.toIso8601String(),
    };
  }

  LocationSession copyWith({
    String? id,
    UserProfile? requester,
    UserProfile? target,
    bool? isBidirectional,
    LocationDurationType? durationType,
    DateTime? expiresAt,
    LocationSessionStatus? status,
    DateTime? createdAt,
    DateTime? stoppedAt,
  }) {
    return LocationSession(
      id: id ?? this.id,
      requester: requester ?? this.requester,
      target: target ?? this.target,
      isBidirectional: isBidirectional ?? this.isBidirectional,
      durationType: durationType ?? this.durationType,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      stoppedAt: stoppedAt ?? this.stoppedAt,
    );
  }
}

