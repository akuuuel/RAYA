import '../../../auth/domain/entities/user_profile.dart';

enum ContactRequestStatus {
  pending,
  accepted,
  rejected,
  cancelled,
}

/// Entitas Permintaan Kontak sesuai FR-06 dan FR-07.
class ContactRequest {
  final String id;
  final UserProfile sender;
  final UserProfile receiver;
  final ContactRequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ContactRequest({
    required this.id,
    required this.sender,
    required this.receiver,
    this.status = ContactRequestStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  factory ContactRequest.fromJson(Map<String, dynamic> json) {
    return ContactRequest(
      id: json['id'] as String,
      sender: UserProfile.fromJson(json['sender'] as Map<String, dynamic>),
      receiver: UserProfile.fromJson(json['receiver'] as Map<String, dynamic>),
      status: ContactRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ContactRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.toJson(),
      'receiver': receiver.toJson(),
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

