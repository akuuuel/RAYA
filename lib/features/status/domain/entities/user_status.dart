import 'dart:convert';

/// Entitas Pembaruan Status / Cerita Pengguna (Story/Status 24 Jam)
class UserStatus {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String? caption;
  final String? mediaBase64;
  final String? mediaUrl;
  final int bgColorValue;
  final DateTime createdAt;
  final bool isViewed;
  final int viewCount;

  const UserStatus({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.caption,
    this.mediaBase64,
    this.mediaUrl,
    this.bgColorValue = 0xFF6C5CE7,
    required this.createdAt,
    this.isViewed = false,
    this.viewCount = 0,
  });

  bool get isExpired {
    return DateTime.now().difference(createdAt).inHours >= 24;
  }

  bool get isPhoto => (mediaBase64 != null && mediaBase64!.isNotEmpty) || (mediaUrl != null && mediaUrl!.isNotEmpty);

  UserStatus copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? caption,
    String? mediaBase64,
    String? mediaUrl,
    int? bgColorValue,
    DateTime? createdAt,
    bool? isViewed,
    int? viewCount,
  }) {
    return UserStatus(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      caption: caption ?? this.caption,
      mediaBase64: mediaBase64 ?? this.mediaBase64,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      bgColorValue: bgColorValue ?? this.bgColorValue,
      createdAt: createdAt ?? this.createdAt,
      isViewed: isViewed ?? this.isViewed,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'caption': caption,
      'media_base64': mediaBase64,
      'media_url': mediaUrl,
      'bg_color_value': bgColorValue,
      'created_at': createdAt.toIso8601String(),
      'view_count': viewCount,
    };
  }

  factory UserStatus.fromJson(Map<String, dynamic> json, {bool isViewed = false}) {
    return UserStatus(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Pengguna',
      userAvatarUrl: json['user_avatar_url'] as String?,
      caption: json['caption'] as String?,
      mediaBase64: json['media_base64'] as String?,
      mediaUrl: json['media_url'] as String?,
      bgColorValue: json['bg_color_value'] as int? ?? 0xFF6C5CE7,
      createdAt: DateTime.parse(json['created_at'] as String),
      isViewed: isViewed,
      viewCount: json['view_count'] as int? ?? 0,
    );
  }
}

