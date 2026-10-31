import '../../../auth/domain/entities/user_profile.dart';

/// Entitas Komentar Status Publik sesuai FR-35 dan FR-36.
/// Hanya dapat dibuat oleh kontak yang sudah saling terhubung dengan pemilik status.
class StatusComment {
  final String id;
  final String statusId;
  final UserProfile author;
  final String content;
  final DateTime createdAt;
  final bool canDelete; // FR-36: pemilik status atau penulis komentar dapat menghapus

  const StatusComment({
    required this.id,
    required this.statusId,
    required this.author,
    required this.content,
    required this.createdAt,
    this.canDelete = false,
  });

  factory StatusComment.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    String? statusOwnerId,
  }) {
    final authorProfile = UserProfile.fromJson(
      json['profiles'] as Map<String, dynamic>,
    );

    final isAuthor = currentUserId != null && authorProfile.id == currentUserId;
    final isOwner = currentUserId != null && statusOwnerId == currentUserId;

    return StatusComment(
      id: json['id'] as String,
      statusId: json['status_id'] as String,
      author: authorProfile,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      canDelete: isAuthor || isOwner,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status_id': statusId,
      'author': author.toJson(),
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

