enum InviteStatus { pending, accepted, declined, revoked }
enum InviteRole { viewer, editor }

class CellarInvite {
  final String id;
  final String cellarId;
  final String invitedBy;
  final String? invitedUserId;
  final String? invitedEmail;
  final InviteRole role;
  final InviteStatus status;
  final String inviteCode;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? cellarName;
  final String? invitedByName;

  const CellarInvite({
    required this.id,
    required this.cellarId,
    required this.invitedBy,
    this.invitedUserId,
    this.invitedEmail,
    required this.role,
    required this.status,
    required this.inviteCode,
    required this.createdAt,
    this.respondedAt,
    this.cellarName,
    this.invitedByName,
  });

  factory CellarInvite.fromJson(Map<String, dynamic> json) => CellarInvite(
    id: json['id'] as String? ?? '',
    cellarId: json['cellar_id'] as String? ?? '',
    invitedBy: json['invited_by'] as String? ?? '',
    invitedUserId: json['invited_user_id'] as String?,
    invitedEmail: json['invited_email'] as String?,
    role: json['role'] == 'editor' ? InviteRole.editor : InviteRole.viewer,
    status: _parseStatus(json['status'] as String? ?? 'pending'),
    inviteCode: json['invite_code'] as String? ?? '',
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    respondedAt: json['responded_at'] != null ? DateTime.tryParse(json['responded_at'].toString()) : null,
    cellarName: (json['cellars'] as Map<String, dynamic>?)?['name'] as String?,
    invitedByName: (json['profiles'] as Map<String, dynamic>?)?['display_name'] as String?,
  );

  static InviteStatus _parseStatus(String s) {
    switch (s) {
      case 'accepted': return InviteStatus.accepted;
      case 'declined': return InviteStatus.declined;
      case 'revoked': return InviteStatus.revoked;
      default: return InviteStatus.pending;
    }
  }

  bool get isPending => status == InviteStatus.pending;
  bool get isReadOnly => role == InviteRole.viewer;
}
