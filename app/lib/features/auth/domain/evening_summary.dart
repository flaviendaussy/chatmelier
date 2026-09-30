import '../../../shared/utils/langue.dart';
import 'taste_profile.dart';

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

    final axe = _axeLePlusObserve(profil);
    if (axe != null) {
      out.add(tr('Votre palais commence à se dessiner sur {v1}', 'Your palate is starting to take shape around {v1}', {'v1': nomDeLAxe(axe)}));
    }

    if (profil.favoriteRegions.isNotEmpty) {
      final r = profil.favoriteRegions.take(2).join(tr(' et ', ' and '));
      out.add(tr('Un goût qui se précise pour {r}', 'A growing taste for {r}', {'r': r}));
    }

    if (messagesEchanges > 0) {
      out.add(messagesEchanges == 1
          ? tr('Une question posée au sommelier', 'One question for the sommelier')
          : tr('{messagesEchanges} échanges avec le sommelier', '{messagesEchanges} messages with the sommelier', {'messagesEchanges': messagesEchanges}));
    }

    return out;
  }

  /// L'axe sur lequel on a le plus observé — donc celui dont on peut parler sans mentir.
  static String? _axeLePlusObserve(TasteProfile p) {
    String? meilleur;
    var n = 0;
    p.axisObservations.forEach((axe, compte) {
      if (compte > n) {
        n = compte;
        meilleur = axe;
      }
    });
    // Une seule observation ne dessine rien. Le dire quand même serait la première
    // exagération d'une phrase qui ne tient que par son exactitude.
    return n >= 2 ? meilleur : null;
  }

  /// Le nom d'un axe dans une phrase (« les tanins », « crisp acidity »).
  static String nomDeLAxe(String axe) => switch (axe) {
        'acidity' => tr('la vivacité', 'crisp acidity'),
        'body' => tr('le corps', 'body'),
        'tannin' => tr('les tanins', 'tannins'),
        'oak' => tr('le boisé', 'oak'),
        'ripeFruit' => tr('le fruit mûr', 'ripe fruit'),
        'spice' => tr('les épices', 'spice'),
        'freshFruit' => tr('le fruit frais', 'fresh fruit'),
        'minerality' => tr('la minéralité', 'minerality'),
        _ => axe,
      };
}
