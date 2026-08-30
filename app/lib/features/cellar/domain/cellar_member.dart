class CellarMember {
  final String cellarId;
  final String userId;
  final String role; // viewer, editor, admin
  final DateTime invitedAt;
  final String? displayName;
  final String? avatarUrl;

  const CellarMember({
    required this.cellarId,
    required this.userId,
    required this.role,
    required this.invitedAt,
    this.displayName,
    this.avatarUrl,
  });

  factory CellarMember.fromJson(Map<String, dynamic> json) => CellarMember(
    cellarId: json['cellar_id'] as String? ?? '',
    userId: json['user_id'] as String? ?? '',
    role: json['role'] as String? ?? 'editor',
    invitedAt: json['invited_at'] != null ? DateTime.tryParse(json['invited_at'].toString()) ?? DateTime.now() : DateTime.now(),
    displayName: (json['profiles'] as Map<String, dynamic>?)?['display_name'] as String?,
    avatarUrl: (json['profiles'] as Map<String, dynamic>?)?['avatar_url'] as String?,
  );

  bool get isAdmin => role == 'admin';
  bool get isEditor => role == 'editor' || role == 'admin';
  bool get isViewer => role == 'viewer';
}
