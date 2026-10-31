import '../../../auth/domain/entities/user_profile.dart';

/// Entitas Kontak resmi RAYA sesuai FR-06, FR-07, dan FR-08.
class Contact {
  final String id;
  final String userId;
  final UserProfile contactUser;
  final String? alias;
  final bool isBlocked;
  final DateTime createdAt;

  const Contact({
    required this.id,
    required this.userId,
    required this.contactUser,
    this.alias,
    this.isBlocked = false,
    required this.createdAt,
  });

  String get displayName =>
      alias ?? contactUser.displayName ?? contactUser.username ?? 'Kontak';

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contactUser: UserProfile.fromJson(
        json['contact_user'] as Map<String, dynamic>,
      ),
      alias: json['alias'] as String?,
      isBlocked: json['is_blocked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'contact_user': contactUser.toJson(),
      'alias': alias,
      'is_blocked': isBlocked,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Contact copyWith({
    String? id,
    String? userId,
    UserProfile? contactUser,
    String? alias,
    bool? isBlocked,
    DateTime? createdAt,
  }) {
    return Contact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contactUser: contactUser ?? this.contactUser,
      alias: alias ?? this.alias,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

