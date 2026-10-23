import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/utils/langue.dart';

/// Ce qu'est devenue chaque invitation à noter reçue sur ce téléphone : la dégustation
/// écrite pour elle, et la note une fois donnée.
///
/// Flavien, 22/10 : « comme j'ai déjà cliqué et déjà effectué la dégustation, je ne dois pas
/// pouvoir recliquer ». L'invitation restait « Noter ce vin », et un second clic écrivait
/// une seconde dégustation du même verre. Elle dit maintenant « Noté · 8/10 » ; commencée
/// puis abandonnée, elle rouvre la même dégustation au lieu d'en créer une autre.
class InvitationNotee {
  final String tastingId;
  final double? note;
  final String? defaut;
  final bool terminee;

  const InvitationNotee({required this.tastingId, this.note, this.defaut, this.terminee = false});

  Map<String, dynamic> toJson() => {
        'tasting_id': tastingId,
        if (note != null) 'note': note,
        if (defaut != null) 'defaut': defaut,
        'terminee': terminee,
      };

  static InvitationNotee? fromJson(dynamic j) {
    if (j is! Map || j['tasting_id'] == null) return null;
    return InvitationNotee(
      tastingId: j['tasting_id'].toString(),
      note: (j['note'] as num?)?.toDouble(),
      defaut: j['defaut']?.toString(),
      terminee: j['terminee'] == true,
    );
  }

  /// « Noté · 8/10 », « Noté · défaut » : ce que la boîte affiche à la place du bouton.
  String get libelle {
    if (defaut != null) return tr('Noté · défaut', 'Rated · faulty');
    final n = note;
    if (n == null) return tr('Noté', 'Rated');
    return tr('Noté · {n}/10', 'Rated · {n}/10', {'n': n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1)});
  }
}

class InvitationsNotees {
  InvitationsNotees._();

  static const _cle = 'chatmelier_invitations_notees_v1';

  static Future<Map<String, InvitationNotee>> lire() async {
    try {
      final brut = (await SharedPreferences.getInstance()).getString(_cle);
      if (brut == null) return {};
      final j = jsonDecode(brut);
      if (j is! Map) return {};
      return {
        for (final e in j.entries)
          if (InvitationNotee.fromJson(e.value) case final v?) e.key.toString(): v,
      };
    } catch (_) {
      return {};
    }
  }

  static Future<void> retenir(String notificationId, InvitationNotee etat) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toutes = await lire();
      toutes[notificationId] = etat;
      // Les invitations d'une soirée, pas d'une vie : on n'en garde que les cent dernières.
      final gardees = toutes.entries.toList().reversed.take(100).toList().reversed;
      await prefs.setString(_cle, jsonEncode({for (final e in gardees) e.key: e.value.toJson()}));
    } catch (_) {}
  }
}
