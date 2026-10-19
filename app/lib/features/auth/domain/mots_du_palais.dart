import '../../../shared/utils/langue.dart';
import 'palais.dart';
import 'taste_profile.dart';

/// Le palais d'une famille dit en mots, pour l'écran (V2.6 · P2).
///
/// Six axes qui vont chacun d'un bout à l'autre : « bas » est un goût aussi (les tanins
/// souples, les blancs sans bois), pas un manque. Seules les préférences franches se
/// disent ; un corps moyen ne fait pas un portrait.
class MotsDuPalais {
  MotsDuPalais._();

  /// Les rouges, les blancs — au pluriel, pour une phrase.
  static String familleAuPluriel(String famille) =>
      famille == FamillesDeVins.rouge ? tr('rouges', 'reds') : tr('blancs', 'whites');

  /// L'axe nommé dans une phrase : « la douceur », « les tanins ».
  static String nomDe(String axe) => switch (axe) {
        AxesDuPalais.fraicheur => tr('la fraîcheur', 'freshness'),
        AxesDuPalais.douceur => tr('la douceur', 'sweetness'),
        AxesDuPalais.corps => tr('le corps', 'body'),
        AxesDuPalais.tanins => tr('les tanins', 'tannins'),
        AxesDuPalais.boise => tr('le boisé', 'oak'),
        AxesDuPalais.evolution => tr('l\'évolution', 'maturity'),
        _ => axe,
      };

  /// « les tanins », « la douceur des blancs » : l'axe et sa famille, dans une phrase.
  static String nomDansLaFamille(String famille, String axe) => axe == AxesDuPalais.tanins
      ? nomDe(axe)
      : tr('{axe} des {famille}', '{axe} in {famille}', {'axe': nomDe(axe), 'famille': familleAuPluriel(famille)});

  /// Le goût que dit une valeur (0–10) d'un axe dans une famille — « les rouges
  /// puissants », « les tanins souples » —, ou rien quand elle ne tranche pas.
  ///
  /// La douceur ne se dit que du côté doux : un vin sec est la règle, l'aimer ne
  /// distingue personne.
  static String? gout(String famille, String axe, double v) {
    final rouge = famille == FamillesDeVins.rouge;
    return switch (axe) {
      AxesDuPalais.fraicheur when v >= 6.5 => rouge ? tr('les rouges vifs', 'crisp reds') : tr('les blancs vifs', 'crisp whites'),
      AxesDuPalais.fraicheur when v <= 3.5 => rouge ? tr('les rouges ronds', 'soft reds') : tr('les blancs ronds', 'soft whites'),
      AxesDuPalais.douceur when v >= 6 => rouge ? tr('les rouges doux', 'sweet reds') : tr('les blancs doux', 'sweet whites'),
      AxesDuPalais.douceur when v >= 3.5 =>
        rouge ? tr('les rouges tendres', 'off-dry reds') : tr('les blancs tendres', 'off-dry whites'),
      AxesDuPalais.corps when v >= 6.5 => rouge ? tr('les rouges puissants', 'full-bodied reds') : tr('les blancs amples', 'full-bodied whites'),
      AxesDuPalais.corps when v <= 3.5 => rouge ? tr('les rouges légers', 'light reds') : tr('les blancs légers', 'light whites'),
      AxesDuPalais.tanins when v >= 6.5 => tr('les tanins fermes', 'firm tannins'),
      AxesDuPalais.tanins when v <= 3.5 => tr('les tanins souples', 'supple tannins'),
      AxesDuPalais.boise when v >= 6 => rouge ? tr('les rouges boisés', 'oaky reds') : tr('les blancs boisés', 'oaky whites'),
      AxesDuPalais.boise when v <= 1.5 => rouge ? tr('les rouges sans bois', 'unoaked reds') : tr('les blancs sans bois', 'unoaked whites'),
      AxesDuPalais.evolution when v >= 6.5 => rouge ? tr('les rouges évolués', 'mature reds') : tr('les blancs évolués', 'mature whites'),
      AxesDuPalais.evolution when v <= 2.5 => rouge ? tr('les rouges jeunes', 'young reds') : tr('les blancs jeunes', 'young whites'),
      _ => null,
    };
  }

  /// Le comparatif d'un axe, pour « les rouges plus puissants que Caro ».
  static String plus(String famille, String axe) => switch (axe) {
        AxesDuPalais.fraicheur => tr('vifs', 'crisper'),
        AxesDuPalais.douceur => tr('doux', 'sweeter'),
        AxesDuPalais.corps => famille == FamillesDeVins.rouge ? tr('puissants', 'fuller') : tr('amples', 'fuller'),
        AxesDuPalais.tanins => tr('tanniques', 'more tannic'),
        AxesDuPalais.boise => tr('boisés', 'oakier'),
        AxesDuPalais.evolution => tr('évolués', 'more mature'),
        _ => '',
      };

  /// Une liste dite comme une phrase : « a, b et c ».
  static String liste(List<String> mots) {
    if (mots.length <= 1) return mots.join();
    return '${mots.sublist(0, mots.length - 1).join(', ')} ${tr('et', 'and')} ${mots.last}';
  }

  /// Le style de vin qui irait à un palais (0–10 par axe), et deux ou trois vins qui
  /// l'incarnent. Ce qui tranche le plus passe d'abord : l'âge, la douceur, la structure.
  static String vinPour(String famille, Map<String, double> v) {
    double a(String axe) => v[axe] ?? AxesDuPalais.neutre(famille, axe);
    if (famille == FamillesDeVins.rouge) {
      if (a(AxesDuPalais.evolution) >= 6.5) {
        return tr('Un rouge à maturité : un Rioja Gran Reserva ou un Bordeaux d\'une quinzaine d\'années.',
            'A mature red: a Rioja Gran Reserva or a fifteen-year-old Bordeaux.');
      }
      if (a(AxesDuPalais.tanins) >= 7 && a(AxesDuPalais.corps) >= 6.5) {
        return tr('Un rouge charpenté : un Madiran, un Cahors ou un Barolo.', 'A firmly structured red: a Madiran, a Cahors or a Barolo.');
      }
      if (a(AxesDuPalais.corps) >= 7) {
        return tr('Un rouge ample et solaire : un Châteauneuf-du-Pape ou un Priorat.',
            'A full, sun-drenched red: a Châteauneuf-du-Pape or a Priorat.');
      }
      if (a(AxesDuPalais.tanins) <= 4 && a(AxesDuPalais.corps) <= 5) {
        return tr('Un rouge souple et léger : un cru du Beaujolais ou un Bourgogne.',
            'A light, supple red: a Beaujolais cru or a red Burgundy.');
      }
      if (a(AxesDuPalais.boise) >= 6) {
        return tr('Un rouge élevé en fût : un Rioja Reserva ou un Saint-Émilion.', 'An oak-aged red: a Rioja Reserva or a Saint-Émilion.');
      }
      if (a(AxesDuPalais.fraicheur) >= 7) {
        return tr('Un rouge frais et digeste : un Saumur-Champigny ou un Etna rosso.', 'A fresh, easy red: a Saumur-Champigny or an Etna Rosso.');
      }
      return tr('Un rouge équilibré : un Côtes-du-Rhône Villages ou un Chianti Classico.',
          'A balanced red: a Côtes-du-Rhône Villages or a Chianti Classico.');
    }
    if (a(AxesDuPalais.douceur) >= 5.5) {
      return tr('Un blanc doux : un Coteaux du Layon, un Jurançon moelleux ou un Sauternes.',
          'A sweet white: a Coteaux du Layon, a sweet Jurançon or a Sauternes.');
    }
    if (a(AxesDuPalais.douceur) >= 3.5) {
      return tr('Un blanc tendre : un Vouvray demi-sec ou un riesling Kabinett.', 'An off-dry white: a demi-sec Vouvray or a Riesling Kabinett.');
    }
    // Entre qui aime les blancs secs et vifs et qui les aime un peu tendres : la vivacité
    // porte une pointe de sucre sans qu'elle se sente — le compromis classique.
    if (a(AxesDuPalais.douceur) >= 2.5 && a(AxesDuPalais.fraicheur) >= 6.5) {
      return tr('Un blanc vif avec une pointe de douceur : un riesling Kabinett de Moselle ou un Vouvray sec-tendre.',
          'A crisp white with a hint of sweetness: a Mosel Riesling Kabinett or an off-dry Vouvray.');
    }
    if (a(AxesDuPalais.evolution) >= 6.5) {
      return tr('Un blanc évolué : un vin jaune, un vieux Savennières ou un riesling mûr.',
          'A mature white: a vin jaune, an aged Savennières or a mature Riesling.');
    }
    if (a(AxesDuPalais.boise) >= 6) {
      return tr('Un blanc boisé et ample : un Meursault ou un Pessac-Léognan.', 'A rich, oaked white: a Meursault or a white Pessac-Léognan.');
    }
    if (a(AxesDuPalais.fraicheur) >= 7 && a(AxesDuPalais.corps) <= 5) {
      return tr('Un blanc vif et tendu : un Chablis, un Sancerre ou un Muscadet.', 'A crisp, taut white: a Chablis, a Sancerre or a Muscadet.');
    }
    if (a(AxesDuPalais.corps) >= 6.5) {
      return tr('Un blanc ample : un Condrieu ou un Châteauneuf-du-Pape blanc.', 'A full-bodied white: a Condrieu or a white Châteauneuf-du-Pape.');
    }
    return tr('Un blanc équilibré : un Mâcon, un chenin sec de Loire ou un Albariño.',
        'A balanced white: a Mâcon, a dry Loire Chenin or an Albariño.');
  }

  /// Les arômes qu'une personne cite le plus (identifiants de
  /// `TastingQuestionnaireResult.aromaOptions`), du plus cité au moins cité.
  ///
  /// La minéralité n'est plus un axe (V2.6) : celle que le palais d'avant avait apprise
  /// devient une étiquette, à côté des arômes.
  static List<String> aromesPreferes(TasteProfile p, {int max = 5}) {
    final cites = p.aromaPreferences.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));
    final ids = [for (final e in cites) e.key];
    final mineral = (p.axisObservations['minerality'] ?? 0) >= 3 && (p.avgMineralityPreference ?? 0) >= 0.65;
    if (mineral && !ids.contains('mineral')) ids.add('mineral');
    return ids.take(max).toList();
  }
}
