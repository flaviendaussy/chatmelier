import '../../../shared/utils/langue.dart';

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

  /// Le titre, dans la langue de celui qui lit (V2.3 · J8).
  ///
  /// La ligne garde un titre et un texte rédigés en français à l'envoi : c'est ce
  /// qu'affichent les versions précédentes de l'app. Celle-ci les rédige à l'affichage,
  /// d'après le type et les données ; un type inconnu garde le texte rangé.
  String get titreLu => _redaction().titre;

  /// Le texte, dans la langue de celui qui lit — voir [titreLu].
  String get corpsLu => _redaction().corps;

  ({String titre, String corps}) _redaction() {
    final nom = [actorName, data['requester_name']?.toString()]
            .whereType<String>()
            .map((n) => n.trim())
            .firstWhere((n) => n.isNotEmpty, orElse: () => '');
    final qui = nom.isNotEmpty ? nom : tr('Un ami', 'A friend');
    final pseudo = (data['requester_username']?.toString() ?? actorUsername ?? '').replaceAll('@', '').trim();
    final editeur = (data['requested_role'] ?? data['role'])?.toString() == 'editor';
    final cave = data['cellar_name']?.toString().trim() ?? '';
    return switch (type) {
      'friend_request' => (
          titre: tr('Nouvelle demande d\'ami 🍷', 'New friend request 🍷'),
          corps: tr('{qui} vous a envoyé une demande d\'ami pour partager vos goûts et vos caves.',
              '{qui} sent you a friend request to share your taste and your cellars.',
              {'qui': pseudo.isEmpty ? qui : '$qui (@$pseudo)'}),
        ),
      'friend_accepted' => (
          titre: tr('Demande d\'ami acceptée ! 🎉', 'Friend request accepted! 🎉'),
          corps: tr(
              '{qui} a accepté votre demande d\'ami. Vous voyez désormais sa carte des goûts, et pouvez demander l\'accès à sa cave.',
              '{qui} accepted your friend request. You can now see their taste map and ask for access to their cellar.',
              {'qui': qui}),
        ),
      'cellar_request' => (
          titre: tr('Demande d\'accès à votre cave 🍷', 'Request to access your cellar 🍷'),
          corps: tr('{qui} souhaite accéder à votre cave : {droits}.', '{qui} would like to access your cellar: {droits}.', {
            'qui': qui,
            'droits': editeur
                ? tr('ajouter et retirer des bouteilles', 'adding and removing bottles')
                : tr('consultation seule', 'view only'),
          }),
        ),
      'cellar_granted' => (
          titre: tr('Accès à la cave accordé ! 🍾', 'Cellar access granted! 🍾'),
          corps: tr('{qui} vous a ouvert sa cave{cave} : {droits}.', '{qui} gave you access to their cellar{cave}: {droits}.', {
            'qui': qui,
            'cave': cave.isEmpty ? '' : tr(' « {nom} »', ' "{nom}"', {'nom': cave}),
            'droits': editeur
                ? tr('vous pouvez ajouter et retirer des bouteilles', 'you can add and remove bottles')
                : tr('en consultation', 'view only'),
          }),
        ),
      'cellar_rejected' => (
          titre: tr('Demande d\'accès à la cave refusée', 'Cellar access request declined'),
          corps: tr('{qui} a décliné votre demande d\'accès à sa cave.', '{qui} declined your request to access their cellar.',
              {'qui': qui}),
        ),
      _ => (titre: title, corps: body),
    };
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
