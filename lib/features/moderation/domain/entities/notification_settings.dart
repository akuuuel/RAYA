/// Entitas Pengaturan Notifikasi sesuai FR-46 dan FR-47.
class NotificationSettings {
  final bool chatMessages;
  final bool contactRequests;
  final bool locationTracking;
  final bool statusComments;
  final bool privateMode; // FR-47: Isi pesan tidak ditampilkan di bilah notifikasi

  const NotificationSettings({
    this.chatMessages = true,
    this.contactRequests = true,
    this.locationTracking = true,
    this.statusComments = true,
    this.privateMode = false,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      chatMessages: json['chat_messages'] as bool? ?? true,
      contactRequests: json['contact_requests'] as bool? ?? true,
      locationTracking: json['location_tracking'] as bool? ?? true,
      statusComments: json['status_comments'] as bool? ?? true,
      privateMode: json['private_mode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_messages': chatMessages,
      'contact_requests': contactRequests,
      'location_tracking': locationTracking,
      'status_comments': statusComments,
      'private_mode': privateMode,
    };
  }

  NotificationSettings copyWith({
    bool? chatMessages,
    bool? contactRequests,
    bool? locationTracking,
    bool? statusComments,
    bool? privateMode,
  }) {
    return NotificationSettings(
      chatMessages: chatMessages ?? this.chatMessages,
      contactRequests: contactRequests ?? this.contactRequests,
      locationTracking: locationTracking ?? this.locationTracking,
      statusComments: statusComments ?? this.statusComments,
      privateMode: privateMode ?? this.privateMode,
    );
  }
}

