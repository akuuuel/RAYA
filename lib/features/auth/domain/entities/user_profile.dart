/// Entitas profil pengguna resmi RAYA sesuai FR-03 dan FR-04.
class UserProfile {
  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime birthDate;
  final bool isAdult;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.birthDate,
    required this.isAdult,
    this.createdAt,
    this.updatedAt,
  });

  /// Menghitung apakah pengguna berusia 18 tahun ke atas secara lokal
  /// (Catatan: Nilai final wajib selalu diverifikasi dan ditegakkan oleh server).
  static bool calculateLocalIsAdult(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age >= 18;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      birthDate: DateTime.parse(json['birth_date'] as String),
      isAdult: json['is_adult'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'birth_date': birthDate.toIso8601String().split('T').first,
      'is_adult': isAdult,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? avatarUrl,
    DateTime? birthDate,
    bool? isAdult,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthDate: birthDate ?? this.birthDate,
      isAdult: isAdult ?? this.isAdult,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
