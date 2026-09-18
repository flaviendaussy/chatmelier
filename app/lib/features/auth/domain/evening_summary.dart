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
      out.add(verresGoutes == 1
          ? 'Un verre goûté${nomDuLieu != null ? " à $nomDuLieu" : ""}'
          : '$verresGoutes verres goûtés${nomDuLieu != null ? " à $nomDuLieu" : ""}');
    }

    final axe = _axeLePlusObserve(profil);
    if (axe != null) {
      out.add('Votre palais commence à se dessiner sur ${_nomDeLAxe(axe)}');
    }

    if (profil.favoriteRegions.isNotEmpty) {
      final r = profil.favoriteRegions.take(2).join(' et ');
      out.add('Un goût qui se précise pour $r');
    }

    if (messagesEchanges > 0) {
      out.add(messagesEchanges == 1
          ? 'Une question posée au sommelier'
          : '$messagesEchanges échanges avec le sommelier');
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

  static String _nomDeLAxe(String axe) => switch (axe) {
        'acidity' => 'la vivacité',
        'body' => 'le corps',
        'tannin' => 'les tanins',
        'oak' => 'le boisé',
        'ripeFruit' => 'le fruit mûr',
        'spice' => 'les épices',
        'freshFruit' => 'le fruit frais',
        'minerality' => 'la minéralité',
        _ => axe,
      };
}
