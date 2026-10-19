import 'package:shared_preferences/shared_preferences.dart';

/// Une invitation par lien ouverte sans être connecté (V2.5 · Q3).
///
/// Sur le web, la connexion qui suit se fait souvent ailleurs que dans l'onglet de
/// l'invitation : le lien de l'e-mail ouvre un nouvel onglet, Google repart de la page
/// d'accueil. Le code est donc gardé sur l'appareil, un jour au plus, et l'app y revient
/// d'elle-même une fois la personne connectée. Effacé dès qu'il a servi ou qu'on le décline.
class InvitationEnAttente {
  InvitationEnAttente._();

  static const _cle = 'chatmelier_invitation_en_attente';
  static const _duree = Duration(days: 1);

  /// Le code d'une invitation : `encode(gen_random_bytes(16), 'hex')` en base, d'où une
  /// forme stricte, qui ne laisse rien passer d'autre dans une adresse.
  static bool codeValide(String code) => RegExp(r'^[A-Za-z0-9_-]{6,64}$').hasMatch(code);

  static String? lire(SharedPreferences prefs, {DateTime? maintenant}) {
    final brut = prefs.getString(_cle);
    if (brut == null) return null;
    final separateur = brut.indexOf('|');
    final code = separateur < 0 ? '' : brut.substring(0, separateur);
    final quand = separateur < 0 ? null : DateTime.tryParse(brut.substring(separateur + 1));
    if (!codeValide(code) || quand == null || (maintenant ?? DateTime.now()).difference(quand) > _duree) {
      prefs.remove(_cle);
      return null;
    }
    return code;
  }

  static Future<void> garder(SharedPreferences prefs, String code, {DateTime? maintenant}) async {
    if (!codeValide(code)) return;
    await prefs.setString(_cle, '$code|${(maintenant ?? DateTime.now()).toIso8601String()}');
  }

  static Future<void> effacer(SharedPreferences prefs) => prefs.remove(_cle);
}
