/// Entitas Status Publik dan Badge Lokasi Disamarkan sesuai FR-30 s.d. FR-34.
class PublicStatus {
  final String id;
  final String userId;
  final String authorName;
  final String? authorUsername;
  final String text; // Maksimal 140 karakter (FR-31)
  final String? note; // Catatan opsional maksimal 1.000 karakter (FR-31)
  final String? imageUrl;
  final double fuzzedLatitude; // Koordinat acak min 300 meter (FR-30)
  final double fuzzedLongitude;
  final DateTime createdAt;
  final DateTime expiresAt; // Berlaku 8 jam sejak dipasang (FR-32)
  final bool isMine;
  final bool isContact; // Khusus kontak terhubung untuk izin komentar (FR-35)

  const PublicStatus({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorUsername,
    required this.text,
    this.note,
    this.imageUrl,
    required this.fuzzedLatitude,
    required this.fuzzedLongitude,
    required this.createdAt,
    required this.expiresAt,
    this.isMine = false,
    this.isContact = false,
  });

  /// Cek apakah status sudah kedaluwarsa setelah 8 jam (FR-32)
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Alias untuk userId — ID pengguna pemilik status (untuk laporan moderation)
  String get authorId => userId;

  /// Format sisa waktu masa berlaku 8 jam (contoh: "Sisa 5 jam 12 menit")
  String get remainingTimeFormatted {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 'Status telah berakhir';

    final diff = expiresAt.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours > 0) {
      return 'Sisa $hours jam $minutes menit';
    } else {
      return 'Sisa $minutes menit';
    }
  }

  factory PublicStatus.fromJson(Map<String, dynamic> json, {String? currentUserId, List<String>? contactUserIds}) {
    final uId = json['user_id'] as String;
    final isMine = currentUserId != null && uId == currentUserId;
    final isContact = contactUserIds != null && contactUserIds.contains(uId);

    final profile = json['profiles'] as Map<String, dynamic>?;

    return PublicStatus(
      id: json['id'] as String,
      userId: uId,
      authorName: profile?['display_name'] as String? ?? 'Pengguna Sekitar',
      authorUsername: profile?['username'] as String?,
      text: json['text'] as String,
      note: json['note'] as String?,
      imageUrl: json['image_url'] as String?,
      fuzzedLatitude: (json['fuzzed_latitude'] as num).toDouble(),
      fuzzedLongitude: (json['fuzzed_longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isMine: isMine,
      isContact: isContact,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'text': text,
      'note': note,
      'image_url': imageUrl,
      'fuzzed_latitude': fuzzedLatitude,
      'fuzzed_longitude': fuzzedLongitude,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

