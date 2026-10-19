import 'package:flutter/material.dart';

import '../../../../shared/utils/langue.dart';
import '../../domain/palais.dart';
import '../../domain/taste_profile.dart';
import 'wine_taste_radar_chart.dart';

/// Le palais d'une famille sur le radar (V2.6 · P2) : cinq axes, et ce qu'on sait de chacun.
///
/// Le radar d'une personne en avait huit, toutes couleurs confondues : il disait « moyen »
/// de qui aime les blancs légers et les rouges puissants.
class RadarDuPalais {
  RadarDuPalais._();

  static List<String> libelles(String famille) => [for (final a in AxesDuPalais.duRadar(famille)) AxesDuPalais.nom(a)];

  /// [avecConfiance] : trait plein là où le palais est observé, pointillés là où il est
  /// deviné. À plusieurs sur un même radar, on s'en passe : il ne se lirait plus.
  static RadarChartDataset jeu(
    TasteProfile p,
    String famille, {
    required String label,
    required Color color,
    bool isVisible = true,
    bool avecConfiance = true,
  }) {
    final palais = p.palaisPour(famille);
    final axes = AxesDuPalais.duRadar(famille);
    return RadarChartDataset(
      label: label,
      color: color,
      isVisible: isVisible,
      customValues: [for (final a in axes) palais.valeur(a)],
      confidences: avecConfiance ? [for (final a in axes) palais.confianceDe(a)] : null,
    );
  }
}

/// Rouges ou blancs : la famille dont on regarde le palais.
class ChoixDeFamille extends StatelessWidget {
  final String famille;
  final ValueChanged<String> onChanged;

  const ChoixDeFamille({super.key, required this.famille, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget libelle(String texte) => Text(texte, maxLines: 1, overflow: TextOverflow.fade, softWrap: false);
    return SegmentedButton<String>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(value: FamillesDeVins.rouge, label: libelle(tr('Rouges', 'Reds'))),
        ButtonSegment(value: FamillesDeVins.blanc, label: libelle(FamillesDeVins.nom(FamillesDeVins.blanc))),
      ],
      selected: {famille},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
