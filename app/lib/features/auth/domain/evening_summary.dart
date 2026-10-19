import '../../../shared/utils/langue.dart';
import 'mots_du_palais.dart';
import 'palais.dart';
import 'taste_profile.dart';
import '../../../shared/utils/valeurs_rangees.dart';

/// Ce qu'une soirée a laissé, dit en toutes lettres.
///
/// **Pourquoi c'est du domaine et non de l'affichage.** La phrase qu'on montre avant de
/// demander une adresse doit être VRAIE et VÉRIFIABLE : « vous avez goûté quatre verres »
/// se contrôle d'un regard, et c'est précisément ce qui la rend crédible. Une formule
/// vague — « ne perdez pas vos données ! » — n'engage à rien et se lit comme telle. La
/// composer ici, à partir des chiffres réels, empêche qu'elle dérive vers du slogan.
class EveningSummary {
  /// Les lignes à montrer, de la plus personnelle à la moins.
  ///
  /// Vide s'il n'y a rien à garder — et dans ce cas il ne faut rien demander du tout :
  /// réclamer une adresse pour sauvegarder le vide est la manière la plus sûre de ne
  /// jamais l'obtenir.
  static List<String> lignes({
    required TasteProfile profil,
    required int verresGoutes,
    int messagesEchanges = 0,
    String? nomDuLieu,
  }) {
    final out = <String>[];

    if (verresGoutes > 0) {
      final ou = nomDuLieu != null ? tr(' à {nomDuLieu}', ' at {nomDuLieu}', {'nomDuLieu': nomDuLieu}) : '';
      out.add(verresGoutes == 1
          ? tr('Un verre goûté{ou}', 'One glass tasted{ou}', {'ou': ou})
          : tr('{verresGoutes} verres goûtés{ou}', '{verresGoutes} glasses tasted{ou}', {'verresGoutes': verresGoutes, 'ou': ou}));
    }

    if (_axeLePlusObserve(profil) case (final famille, final axe)) {
      out.add(tr('Votre palais commence à se dessiner sur {v1}', 'Your palate is starting to take shape around {v1}',
          {'v1': MotsDuPalais.nomDansLaFamille(famille, axe)}));
    }

    if (profil.favoriteRegions.isNotEmpty) {
      final r = profil.favoriteRegions.take(2).map(valeurAffichee).join(tr(' et ', ' and '));
      out.add(tr('Un goût qui se précise pour {r}', 'A growing taste for {r}', {'r': r}));
    }

    if (messagesEchanges > 0) {
      out.add(messagesEchanges == 1
          ? tr('Une question posée au sommelier', 'One question for the sommelier')
          : tr('{messagesEchanges} échanges avec le sommelier', '{messagesEchanges} messages with the sommelier', {'messagesEchanges': messagesEchanges}));
    }

    return out;
  }

  /// L'axe sur lequel on a le plus observé, et sa famille (V2.6) — donc celui dont on peut
  /// parler sans mentir.
  static (String, String)? _axeLePlusObserve(TasteProfile p) {
    (String, String)? meilleur;
    var n = 0;
    for (final famille in FamillesDeVins.toutes) {
      for (final axe in AxesDuPalais.de(famille)) {
        final compte = p.observationsSur(famille, axe);
        if (compte > n) {
          n = compte;
          meilleur = (famille, axe);
        }
      }
    }
    // Une seule observation ne dessine rien. Le dire quand même serait la première
    // exagération d'une phrase qui ne tient que par son exactitude.
    return n >= 2 ? meilleur : null;
  }
}
