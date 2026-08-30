/// Represents an in-app social / cellar notification.
class UserNotification {
  final String id;
  final String userId;
  final String? actorId;
  final String? actorName;
  final String? actorUsername;
  final String? actorAvatarUrl;
  final String type; // 'friend_request', 'friend_accepted', 'cellar_request', 'cellar_granted', 'cellar_rejected'
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const UserNotification({
    required this.id,
    required this.userId,
    this.actorId,
    this.actorName,
    this.actorUsername,
    this.actorAvatarUrl,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    final actorMap = json['actor'] as Map<String, dynamic>? ?? json['profiles'] as Map<String, dynamic>? ?? {};

    return UserNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      actorId: json['actor_id']?.toString() ?? actorMap['id']?.toString(),
      actorName: actorMap['display_name'] as String? ?? json['actor_name'] as String?,
      actorUsername: (actorMap['username'] as String? ?? json['actor_username'] as String? ?? '').replaceAll('@', ''),
      actorAvatarUrl: actorMap['avatar_url'] as String? ?? json['actor_avatar_url'] as String?,
      type: json['type'] as String? ?? 'friend_request',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? const {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        if (actorId != null) 'actor_id': actorId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };
}
