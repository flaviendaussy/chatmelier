import 'dart:math' as math;

import '../../../shared/utils/langue.dart';
import 'evening_summary.dart';
import 'taste_profile.dart';
import 'wine_taste_radar.dart';

/// Ce que dit l'empreinte de palais qu'on partage (plan V2, S4 ; P5).
///
/// L'image circule : elle ne doit rien affirmer qu'on ne puisse vérifier. Un axe n'est
/// « aimé » que s'il est observé (cinq dégustations, confiance 0,5) ET haut sur l'échelle ;
/// un a priori déclaré au premier lancement ne suffit pas. Ce qui reste deviné est dit
/// comme tel : c'est ce qui rend l'empreinte crédible, et c'est aussi une invitation.
class EmpreinteDePalais {
  /// Axes aimés, par préférence décroissante (clés de [TasteProfile.axisKeys]).
  final List<String> aime;

  /// Axes les moins connus, à découvrir.
  final List<String> aDecouvrir;

  /// Le nombre de dégustations sur lequel repose l'axe le mieux connu.
  final int degustations;

  /// Part du palais observée, de 0 à 100.
  final int pourcentageConnu;

  const EmpreinteDePalais({
    required this.aime,
    required this.aDecouvrir,
    required this.degustations,
    required this.pourcentageConnu,
  });

  /// Préférence minimale (sur 10) pour qu'un axe observé se dise « aimé ».
  static const double seuilAime = 6.5;

  factory EmpreinteDePalais.lire(TasteProfile profil, WineTasteRadarMetrics radar) {
    final valeurs = radar.toList();
    final cles = TasteProfile.axisKeys;
    final aimes = [
      for (var i = 0; i < cles.length && i < valeurs.length; i++)
        if (profil.axisConfidence(cles[i]) >= 0.5 && valeurs[i] >= seuilAime) (cles[i], valeurs[i]),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final inconnus = [
      for (final k in cles)
        if (profil.axisConfidence(k) < 0.5) (k, profil.axisConfidence(k)),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return EmpreinteDePalais(
      aime: [for (final a in aimes.take(2)) a.$1],
      aDecouvrir: [for (final a in inconnus.take(2)) a.$1],
      degustations: profil.axisObservations.values.fold(0, math.max),
      pourcentageConnu: (profil.overallConfidence * 100).round(),
    );
  }

  static String _liste(List<String> axes) {
    final noms = [for (final a in axes) EveningSummary.nomDeLAxe(a)];
    if (noms.length <= 1) return noms.join();
    return '${noms.sublist(0, noms.length - 1).join(', ')} ${tr('et', 'and')} ${noms.last}';
  }

  String get phraseAime => aime.isEmpty
      ? tr('Mon palais commence à se dessiner', 'My palate is starting to take shape')
      : tr('J\'aime ${_liste(aime)}', 'I love ${_liste(aime)}');

  String? get phraseADecouvrir => aDecouvrir.isEmpty
      ? null
      : tr('Encore à découvrir : ${_liste(aDecouvrir)}', 'Still to discover: ${_liste(aDecouvrir)}');

  String get phraseBase => degustations == 0
      ? tr('Aucune dégustation encore : tout est deviné', 'No tastings yet: everything is a guess')
      : tr('D\'après $degustations ${degustations > 1 ? 'dégustations' : 'dégustation'} · palais connu à $pourcentageConnu %',
          'Based on $degustations ${degustations > 1 ? 'tastings' : 'tasting'} · palate $pourcentageConnu% known');
}
