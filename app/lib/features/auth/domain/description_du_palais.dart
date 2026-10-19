import 'palais.dart';
import 'taste_profile.dart';

/// Le palais d'une personne dit en mots pour le sommelier IA (V2.6 · P5).
///
/// Une famille après l'autre, seulement les axes dont on sait quelque chose, et ce qu'on en
/// sait : « établi » quand la personne l'a dit plusieurs fois, « deviné » sinon. L'invite
/// ne recevait que l'acidité, les tanins et le corps, toutes couleurs confondues.
class DescriptionDuPalais {
  DescriptionDuPalais._();

  /// Les lignes de l'invite (en français, comme le reste de l'invite), vides si rien n'est su.
  static List<String> lignes(TasteProfile p, {String retrait = '    '}) {
    final sortie = <String>[];
    for (final famille in FamillesDeVins.toutes) {
      final palais = p.palaisPour(famille);
      final mots = [
        for (final axe in AxesDuPalais.de(famille))
          if (palais.connait(axe))
            '${motPourLAxe(axe, palais.valeur(axe))} (${palais.confianceDe(axe) >= 0.35 ? 'établi' : 'deviné'})',
      ];
      if (mots.isEmpty) continue;
      final nom = famille == FamillesDeVins.rouge ? 'rouges' : 'blancs, rosés et bulles';
      sortie.add('$retrait- Palais des $nom : ${mots.join(', ')}');
    }
    return sortie;
  }

  /// Ce qu'une préférence (0–10) dit d'un axe, en mots de sommelier.
  static String motPourLAxe(String axe, double v) => switch (axe) {
        AxesDuPalais.fraicheur => v < 3.5 ? 'aime les vins ronds' : (v < 6.5 ? 'fraîcheur modérée' : 'aime les vins vifs'),
        AxesDuPalais.douceur => v < 1.5
            ? 'aime les vins secs'
            : (v < 3.5 ? 'accepte un peu de douceur' : (v < 6 ? 'aime les vins tendres' : 'aime les vins doux')),
        AxesDuPalais.corps => v < 3.5 ? 'aime les vins légers' : (v < 6.5 ? 'corps moyen' : 'aime les vins puissants'),
        AxesDuPalais.tanins => v < 3.5 ? 'tanins souples' : (v < 6.5 ? 'tanins moyens' : 'tanins fermes'),
        AxesDuPalais.boise => v < 3 ? 'sans bois' : (v < 6 ? 'boisé discret' : 'boisé marqué'),
        AxesDuPalais.evolution =>
          v < 3.5 ? 'préfère les vins jeunes' : (v < 6.5 ? 'préfère les vins à leur apogée' : 'préfère les vins évolués'),
        _ => axe,
      };

  /// Ce qu'on dit d'un palais peu renseigné : le vrai, sans rien inventer. L'invite
  /// affirmait à chacun « une seule dégustation (un blanc) » et citait la Galice — un reste
  /// d'un cas précis, faux pour tous les autres.
  static String garde(String nom, int degustations) => degustations == 0
      ? 'Aucune dégustation enregistrée pour $nom : ne pas lui prêter de goûts ; le dire si on le demande.'
      : 'Données limitées pour $nom ($degustations dégustation${degustations > 1 ? 's' : ''}) : '
          'ne pas extrapoler au-delà de ce qui est listé ici ; le dire si on le demande.';
}
