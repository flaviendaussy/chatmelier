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

  /// « (7,5/10) », dans la langue de l'écran ; rien sans note.
  static String _note(Object? brut) {
    final n = brut is num ? brut : num.tryParse('${brut ?? ''}');
    if (n == null) return '';
    final texte = n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);
    return ' (${Langue.code == 'en' ? texte : texte.replaceAll('.', ',')}/10)';
  }

  /// « le 07/10 » ; rien si la date manque.
  static String _quand(Object? brut) {
    final d = DateTime.tryParse('${brut ?? ''}')?.toLocal();
    if (d == null) return '';
    final jour = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return tr(' le {jour}', ' on {jour}', {'jour': jour});
  }

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
      // La dégustation qu'un ami a faite pour vous (V2.4 · R4) : elle n'entre au journal que
      // si vous l'acceptez.
      'degustation_a_accepter' => (
          titre: tr('Une dégustation à ajouter à votre journal 🍷', 'A tasting to add to your journal 🍷'),
          corps: [
            tr('{qui} a noté avec vous {vin}{note}{quand}.', '{qui} rated {vin}{note} with you{quand}.', {
              'qui': qui,
              'vin': [data['vin'], data['millesime']].where((v) => v != null && '$v'.isNotEmpty).join(' '),
              'note': _note(data['note']),
              'quand': _quand(data['date']),
            }),
            if (data['defaut'] != null)
              tr('Bouteille défectueuse : votre palais n\'en apprendra rien.',
                  'Faulty bottle: your palate won\'t learn anything from it.'),
            if (!isRead) tr('L\'ajouter à votre journal ?', 'Add it to your journal?'),
          ].join(' '),
        ),
      // Un ami goûte un vin avec vous et vous demande de le noter vous-même (V2.4 · R4, #59).
      'invitation_a_noter' => (
          titre: tr('Un vin à noter 🍷', 'A wine to rate 🍷'),
          corps: tr('{qui} goûte {vin} avec vous{lieu} : notez-le à votre tour.', '{qui} is tasting {vin} with you{lieu}: rate it too.', {
            'qui': qui,
            'vin': vinInvite,
            'lieu': data['lieu'] is String && (data['lieu'] as String).isNotEmpty
                ? tr(' ({lieu})', ' ({lieu})', {'lieu': data['lieu']})
                : '',
          }),
        ),
      _ => (titre: title, corps: body),
    };
  }

  /// Le vin d'une invitation à noter, tel qu'il s'affiche (« Bardos Reserva 2020 »).
  String get vinInvite {
    final v = data['vin'];
    if (v is! Map) return '';
    return [v['nom'], v['millesime']].where((x) => x != null && '$x'.trim().isNotEmpty).join(' ');
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
