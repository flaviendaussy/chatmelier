/// Represents a request by a friend to access a cellar.
class CellarAccessRequest {
  final String id;
  final String cellarId;
  final String? cellarName;
  final String ownerId;
  final String? ownerName;
  final String requesterId;
  final String requesterName;
  final String requesterUsername;
  final String? requesterAvatarUrl;
  final String requestedRole; // 'viewer', 'editor'
  final String status; // 'pending', 'accepted', 'rejected'
  final String? message;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const CellarAccessRequest({
    required this.id,
    required this.cellarId,
    this.cellarName,
    required this.ownerId,
    this.ownerName,
    required this.requesterId,
    required this.requesterName,
    required this.requesterUsername,
    this.requesterAvatarUrl,
    this.requestedRole = 'viewer',
    this.status = 'pending',
    this.message,
    required this.createdAt,
    this.respondedAt,
  });

  factory CellarAccessRequest.fromJson(Map<String, dynamic> json) {
    final requesterMap = json['requester'] as Map<String, dynamic>? ?? json['profiles'] as Map<String, dynamic>? ?? {};
    final cellarMap = json['cellars'] as Map<String, dynamic>? ?? {};
    final ownerMap = json['owner'] as Map<String, dynamic>? ?? {};

    return CellarAccessRequest(
      id: json['id']?.toString() ?? '',
      cellarId: json['cellar_id']?.toString() ?? '',
      cellarName: cellarMap['name'] as String? ?? json['cellar_name'] as String? ?? 'Ma Cave',
      ownerId: json['owner_id']?.toString() ?? '',
      ownerName: ownerMap['display_name'] as String? ?? json['owner_name'] as String?,
      requesterId: json['requester_id']?.toString() ?? '',
      requesterName: requesterMap['display_name'] as String? ?? json['requester_name'] as String? ?? 'Ami',
      requesterUsername: (requesterMap['username'] as String? ?? json['requester_username'] as String? ?? '').replaceAll('@', ''),
      requesterAvatarUrl: requesterMap['avatar_url'] as String? ?? json['requester_avatar_url'] as String?,
      requestedRole: json['requested_role'] as String? ?? 'viewer',
      status: json['status'] as String? ?? 'pending',
      message: json['message'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      respondedAt: json['responded_at'] != null ? DateTime.tryParse(json['responded_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cellar_id': cellarId,
        'owner_id': ownerId,
        'requester_id': requesterId,
        'requested_role': requestedRole,
        'status': status,
        if (message != null) 'message': message,
        'created_at': createdAt.toIso8601String(),
        if (respondedAt != null) 'responded_at': respondedAt?.toIso8601String(),
      };
}
