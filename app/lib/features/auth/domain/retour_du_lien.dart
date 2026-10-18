import 'package:flutter/foundation.dart';

/// Un lien de connexion qui n'a connecté personne (V2.5 · Q11, Camille, 18/10).
///
/// « Je reçois bien le lien, quand je clique ça me demande si j'ai l'âge, et après ça me
/// remet sur la page initiale. » Sur le web, Supabase ne connecte que le navigateur qui a
/// demandé le lien : ce qui le vérifie est resté dans ce navigateur (flux PKCE). Ouvert
/// ailleurs — le navigateur intégré à l'app de messagerie, le plus souvent, qui n'avait
/// jamais vu Chatmelier, d'où la question de l'âge —, le lien n'a aucun effet, et le SDK
/// n'en dit rien. L'app lit donc elle-même l'adresse d'ouverture pour pouvoir le dire, et
/// proposer le code du même e-mail, qui connecte là où on le tape.
///
/// Rien de ce qui est lu n'est gardé ni journalisé, hormis le motif d'erreur que Supabase
/// écrit en clair (« otp_expired »).
@immutable
class RetourDuLien {
  /// Le motif donné par Supabase dans l'adresse (`error_code`, à défaut `error`), ou nul.
  final String? motif;

  const RetourDuLien._(this.motif);

  /// Un échange refusé par le SDK sans motif dans l'adresse : sur un téléphone, le lien
  /// demandé depuis un autre appareil.
  static const sansMotif = RetourDuLien._(null);

  /// Les paramètres que guette le SDK pour reconnaître un retour de connexion, dans la
  /// requête ou dans le fragment. Les liens de table n'utilisent jamais `?code=` pour cette
  /// raison (`menu_table_session_manager.dart`).
  static const _cles = ['code', 'access_token', 'error', 'error_code', 'error_description'];

  /// Le retour de connexion que porte [adresse], ou nul si elle n'en porte pas.
  static RetourDuLien? lire(Uri adresse) {
    try {
      final fragment = _parametres(adresse.fragment);
      String? valeur(String cle) => adresse.queryParameters[cle] ?? fragment[cle];
      if (!_cles.any((cle) => valeur(cle) != null)) return null;
      final motif = valeur('error_code') ?? valeur('error');
      return RetourDuLien._(motif == null || motif.trim().isEmpty ? null : motif.trim());
    } catch (_) {
      // Une adresse mal encodée n'est pas un retour qu'on sache lire.
      return null;
    }
  }

  /// Le lien a expiré, ou il a déjà servi une fois : son code ne vaut plus rien non plus,
  /// il faut en demander un autre. Supabase l'écrit « access_denied » / « otp_expired ».
  bool get expire => motif != null && (motif!.contains('expired') || motif == 'access_denied');

  static Map<String, String> _parametres(String fragment) {
    if (fragment.isEmpty || !fragment.contains('=')) return const {};
    return Uri.splitQueryString(fragment.startsWith('?') ? fragment.substring(1) : fragment);
  }

  @override
  bool operator ==(Object other) => other is RetourDuLien && other.motif == motif;

  @override
  int get hashCode => motif.hashCode;
}

/// Le lien d'ouverture n'a connecté personne : l'écran de connexion le dit (Q11).
final lienSansEffet = ValueNotifier<RetourDuLien?>(null);

/// L'adresse du dernier lien envoyé, le temps que l'app reste ouverte : l'écran de
/// connexion la reprend pour proposer le code, même quand le lien est parti de
/// l'inscription. Jamais enregistrée sur l'appareil.
final adresseDuDernierLien = ValueNotifier<String?>(null);
