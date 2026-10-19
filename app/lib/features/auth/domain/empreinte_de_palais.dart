import 'dart:math' as math;

import '../../../shared/utils/langue.dart';
import 'mots_du_palais.dart';
import 'palais.dart';
import 'taste_profile.dart';

/// Ce que dit l'empreinte de palais qu'on partage (plan V2, S4 ; P5).
///
/// L'image circule : elle ne doit rien affirmer qu'on ne puisse vérifier. Un axe n'est
/// « aimé » que s'il est observé (cinq dégustations, confiance 0,5) ET franc d'un côté ou
/// de l'autre ; un a priori déclaré au premier lancement ne suffit pas. Ce qui reste deviné
/// est dit comme tel : c'est ce qui rend l'empreinte crédible, et c'est aussi une invitation.
///
/// V2.6 : une empreinte par famille — les rouges ou les blancs —, celle que la personne
/// connaît le mieux par défaut.
class EmpreinteDePalais {
  final String famille;

  /// Axes aimés (clés de [AxesDuPalais]), du plus franc au moins franc.
  final List<String> aime;

  /// Ce que disent ces axes : « les rouges puissants », « les tanins fermes ».
  final List<String> gouts;

  /// Axes les moins connus, à découvrir.
  final List<String> aDecouvrir;

  /// Le nombre de dégustations sur lequel repose l'axe le mieux connu.
  final int degustations;

  /// Part du palais de la famille observée, de 0 à 100.
  final int pourcentageConnu;

  const EmpreinteDePalais({
    required this.famille,
    required this.aime,
    required this.gouts,
    required this.aDecouvrir,
    required this.degustations,
    required this.pourcentageConnu,
  });

  /// Confiance à partir de laquelle un axe est observé (celle du radar).
  static const double seuilObserve = 0.5;

  factory EmpreinteDePalais.lire(TasteProfile profil, {String? famille}) {
    final f = famille ?? profil.familleDominante;
    final palais = profil.palaisPour(f);
    final axes = AxesDuPalais.duRadar(f);
    final aimes = [
      for (final a in axes)
        if (palais.confianceDe(a) >= seuilObserve)
          if (MotsDuPalais.gout(f, a, palais.valeur(a)) case final g?) (a, g, (palais.valeur(a) - AxesDuPalais.neutre(f, a)).abs()),
    ]..sort((x, y) => y.$3.compareTo(x.$3));
    final inconnus = [
      for (final a in axes)
        if (palais.confianceDe(a) < seuilObserve) a,
    ]..sort((x, y) {
        final c = palais.confianceDe(x).compareTo(palais.confianceDe(y));
        return c != 0 ? c : axes.indexOf(x).compareTo(axes.indexOf(y));
      });
    return EmpreinteDePalais(
      famille: f,
      aime: [for (final a in aimes.take(2)) a.$1],
      gouts: [for (final a in aimes.take(2)) a.$2],
      aDecouvrir: inconnus.take(2).toList(),
      degustations: axes.map((a) => profil.observationsSur(f, a)).fold(0, math.max),
      pourcentageConnu: (palais.connaissance * 100).round(),
    );
  }

  String get phraseAime => gouts.isEmpty
      ? tr('Mon palais commence à se dessiner', 'My palate is starting to take shape')
      : tr('J\'aime {v1}', 'I love {v1}', {'v1': MotsDuPalais.liste(gouts)});

  String? get phraseADecouvrir => aDecouvrir.isEmpty
      ? null
      : tr('Encore à découvrir : {v1}', 'Still to discover: {v1}',
          {'v1': MotsDuPalais.liste([for (final a in aDecouvrir) MotsDuPalais.nomDe(a)])});

  String get phraseBase => degustations == 0
      ? tr('Aucune dégustation encore : tout est deviné', 'No tastings yet: everything is a guess')
      : degustations > 1
          ? tr('D\'après {n} dégustations · palais connu à {pct} %', 'Based on {n} tastings · palate {pct}% known',
              {'n': degustations, 'pct': pourcentageConnu})
          : tr('D\'après une dégustation · palais connu à {pct} %', 'Based on one tasting · palate {pct}% known',
              {'pct': pourcentageConnu});
}
