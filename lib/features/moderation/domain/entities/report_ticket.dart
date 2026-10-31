enum ReportType {
  profile,
  message,
  publicStatus,
  comment,
}

enum ReportReason {
  spam,
  harassment,
  fraud,
  threatViolence,
  childExploitation,
  privacyViolation,
}

extension ReportReasonExtension on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.spam:
        return 'Spam atau Pesan Massal';
      case ReportReason.harassment:
        return 'Pelecehan atau Perilaku Mengganggu';
      case ReportReason.fraud:
        return 'Penipuan atau Akun Palsu';
      case ReportReason.threatViolence:
        return 'Ancaman atau Kekerasan (Prioritas Tinggi)';
      case ReportReason.childExploitation:
        return 'Eksploitasi / Konten Terkait Anak (Prioritas Tinggi)';
      case ReportReason.privacyViolation:
        return 'Pelanggaran Privasi Tanpa Izin';
    }
  }

  /// Menandai prioritas tinggi sesuai FR-43
  bool get isHighPriority {
    return this == ReportReason.threatViolence ||
        this == ReportReason.childExploitation;
  }
}

/// Entitas Laporan Pelanggaran sesuai FR-41, FR-42, FR-43, dan FR-44.
class ReportTicket {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final ReportType reportType;
  final String targetId;
  final ReportReason reason;
  final bool isHighPriority;
  final String? decryptedContentEvidence;
  final String status;
  final DateTime createdAt;

  const ReportTicket({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reportType,
    required this.targetId,
    required this.reason,
    required this.isHighPriority,
    this.decryptedContentEvidence,
    this.status = 'submitted',
    required this.createdAt,
  });

  factory ReportTicket.fromJson(Map<String, dynamic> json) {
    ReportType type = ReportType.profile;
    if (json['report_type'] == 'message') type = ReportType.message;
    if (json['report_type'] == 'public_status') type = ReportType.publicStatus;
    if (json['report_type'] == 'comment') type = ReportType.comment;

    ReportReason reason = ReportReason.spam;
    final rStr = json['reason'] as String?;
    for (final r in ReportReason.values) {
      if (r.name == rStr) {
        reason = r;
        break;
      }
    }

    return ReportTicket(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      reportedUserId: json['reported_user_id'] as String,
      reportType: type,
      targetId: json['target_id'] as String,
      reason: reason,
      isHighPriority: json['is_high_priority'] as bool? ?? false,
      decryptedContentEvidence: json['decrypted_content_evidence'] as String?,
      status: json['status'] as String? ?? 'submitted',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reported_user_id': reportedUserId,
      'report_type': reportType.name,
      'target_id': targetId,
      'reason': reason.name,
      'is_high_priority': isHighPriority,
      'decrypted_content_evidence': decryptedContentEvidence,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

