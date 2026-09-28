import 'package:flutter/material.dart';

import '../../auth/domain/wine_taste_radar.dart';
import '../../auth/presentation/widgets/wine_taste_radar_chart.dart';
import '../../sommelier/domain/guest_matcher_engine.dart';

/// Ce qu'un invité dit de ses goûts en vingt secondes.
class PalaisSaisi {
  final double tanins;
  final double corps;
  final double acidite;
  final double boise;
  final double fruit;
  final double mineralite;

  /// « Rouge », « Blanc », « Rosé », « Bulles » — le vocabulaire du moteur de consensus.
  final Set<String> couleurs;

  /// « tanin », « boisé », « acide » — les aversions que le moteur sait lire.
  final Set<String> aversions;

  const PalaisSaisi({
    this.tanins = 5,
    this.corps = 5,
    this.acidite = 5,
    this.boise = 3,
    this.fruit = 5,
    this.mineralite = 5,
    this.couleurs = const {},
    this.aversions = const {},
  });

  PalaisSaisi copie({
    double? tanins,
    double? corps,
    double? acidite,
    double? boise,
    double? fruit,
    double? mineralite,
    Set<String>? couleurs,
    Set<String>? aversions,
  }) =>
      PalaisSaisi(
        tanins: tanins ?? this.tanins,
        corps: corps ?? this.corps,
        acidite: acidite ?? this.acidite,
        boise: boise ?? this.boise,
        fruit: fruit ?? this.fruit,
        mineralite: mineralite ?? this.mineralite,
        couleurs: couleurs ?? this.couleurs,
        aversions: aversions ?? this.aversions,
      );

  WineTasteRadarMetrics get radar => WineTasteRadarMetrics(
        tannin: tanins,
        body: corps,
        oak: boise,
        ripeFruit: fruit,
        spice: 4,
        freshFruit: fruit,
        minerality: mineralite,
        acidity: acidite,
      );

  String archetype(bool fr) {
    if (aversions.contains('tanin')) return fr ? 'Aversion aux tanins durs' : 'Dislikes firm tannins';
    if (tanins >= 7 && corps >= 6) return fr ? 'Grands Rouges Puissants' : 'Big, powerful reds';
    if (acidite >= 7 && mineralite >= 6) return fr ? 'Blancs Minéraux & Tendus' : 'Taut, mineral whites';
    if (fruit >= 7 && tanins <= 5) return fr ? 'Rouges Fruits Croquants' : 'Crunchy fruity reds';
    return fr ? 'Curieux & Éclectique' : 'Curious & eclectic';
  }

  GuestProfile versConvive({required String id, required String nom, required bool fr}) => GuestProfile(
        id: id,
        name: nom,
        favoriteTypes: couleurs.toList(),
        dislikedCharacteristics: aversions.toList(),
        archetype: archetype(fr),
        radarDistant: radar,
      );

  /// Les points de départ proposés, pour aller plus vite que six curseurs.
  static const prereglages = <String, PalaisSaisi>{
    'sans_tanin': PalaisSaisi(tanins: 2, corps: 4, acidite: 6, boise: 2, fruit: 6, mineralite: 6,
        couleurs: {'Blanc', 'Rosé'}, aversions: {'tanin'}),
    'mineral': PalaisSaisi(tanins: 1, corps: 4, acidite: 8, boise: 2, fruit: 5, mineralite: 8, couleurs: {'Blanc'}),
    'puissant': PalaisSaisi(tanins: 8, corps: 8, acidite: 5, boise: 6, fruit: 6, mineralite: 4, couleurs: {'Rouge'}),
    'fruit': PalaisSaisi(tanins: 4, corps: 5, acidite: 6, boise: 2, fruit: 8, mineralite: 4, couleurs: {'Rouge'}),
    'equilibre': PalaisSaisi(),
  };
}

/// Le profilage express d'un invité : PROPOSÉ, jamais imposé.
///
/// Six curseurs, le radar qui se dessine pendant qu'on les bouge, les couleurs aimées
/// et trois aversions. « Juste mon prénom » reste toujours possible : rejoindre une table
/// ne doit jamais dépendre du profilage (retour du 28/09 — « on doit lui proposer le
/// profilage, mais il peut le refuser »).
class PalaisExpress extends StatefulWidget {
  final bool isFr;
  final PalaisSaisi initial;
  final String libelleValider;
  final ValueChanged<PalaisSaisi> onValider;

  /// Nul une fois assis : on met à jour ses goûts, on ne les refuse plus.
  final VoidCallback? onJusteMonPrenom;

  /// Le texte du refus (« Juste mon prénom… » à table, « Plus tard » ailleurs).
  final String? libelleRefus;

  const PalaisExpress({
    super.key,
    required this.isFr,
    required this.libelleValider,
    required this.onValider,
    this.onJusteMonPrenom,
    this.libelleRefus,
    this.initial = const PalaisSaisi(),
  });

  @override
  State<PalaisExpress> createState() => _PalaisExpressState();
}

class _PalaisExpressState extends State<PalaisExpress> {
  late PalaisSaisi _palais = widget.initial;
  String? _prereglage;

  static const _or = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final fr = widget.isFr;
    final curseurs = <(String, double, PalaisSaisi Function(double))>[
      (fr ? 'Tanins' : 'Tannins', _palais.tanins, (v) => _palais.copie(tanins: v)),
      (fr ? 'Corps' : 'Body', _palais.corps, (v) => _palais.copie(corps: v)),
      (fr ? 'Acidité' : 'Acidity', _palais.acidite, (v) => _palais.copie(acidite: v)),
      (fr ? 'Boisé' : 'Oak', _palais.boise, (v) => _palais.copie(boise: v)),
      (fr ? 'Fruit' : 'Fruit', _palais.fruit, (v) => _palais.copie(fruit: v)),
      (fr ? 'Minéralité' : 'Minerality', _palais.mineralite, (v) => _palais.copie(mineralite: v)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _prereglage,
          dropdownColor: const Color(0xFF281E34),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: fr ? 'Point de départ (facultatif)' : 'Starting point (optional)',
            labelStyle: const TextStyle(color: _or),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            DropdownMenuItem(value: 'sans_tanin', child: Text(fr ? '🕊️ Aversion aux tanins durs' : '🕊️ No firm tannins')),
            DropdownMenuItem(value: 'mineral', child: Text(fr ? '⚡ Blancs Minéraux & Tendus' : '⚡ Taut, mineral whites')),
            DropdownMenuItem(value: 'puissant', child: Text(fr ? '🧱 Grands Rouges Puissants' : '🧱 Big, powerful reds')),
            DropdownMenuItem(value: 'fruit', child: Text(fr ? '🍒 Rouges Fruits Croquants' : '🍒 Crunchy fruity reds')),
            DropdownMenuItem(value: 'equilibre', child: Text(fr ? '🍷 Curieux & Éclectique' : '🍷 Curious & eclectic')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _prereglage = v;
              _palais = PalaisSaisi.prereglages[v] ?? _palais;
            });
          },
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final (libelle, valeur, avec) in curseurs)
                    Row(
                      children: [
                        SizedBox(
                          width: 78,
                          child: Text(libelle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                        Expanded(
                          child: Slider(
                            value: valeur,
                            min: 0,
                            max: 10,
                            divisions: 10,
                            activeColor: _or,
                            label: valeur.round().toString(),
                            onChanged: (v) => setState(() => _palais = avec(v)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Le radar se dessine pendant qu'on bouge les curseurs : c'est lui qui donne
            // envie d'aller au bout.
            SizedBox(
              width: 120,
              height: 120,
              child: WineTasteRadarChart(
                size: 120,
                showLabels: false,
                isInteractive: false,
                datasets: [
                  RadarChartDataset(label: fr ? 'Vos goûts' : 'Your taste', color: _or, metrics: _palais.radar),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(fr ? 'Couleurs que vous aimez' : 'Colours you enjoy',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Wrap(
          spacing: 6,
          children: [
            for (final (cle, libelle) in [
              ('Rouge', fr ? 'Rouge' : 'Red'),
              ('Blanc', fr ? 'Blanc' : 'White'),
              ('Rosé', fr ? 'Rosé' : 'Rosé'),
              ('Bulles', fr ? 'Bulles' : 'Sparkling'),
            ])
              FilterChip(
                label: Text(libelle, style: const TextStyle(fontSize: 12)),
                selected: _palais.couleurs.contains(cle),
                onSelected: (oui) => setState(() => _palais = _palais.copie(
                    couleurs: oui ? {..._palais.couleurs, cle} : ({..._palais.couleurs}..remove(cle)))),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(fr ? 'Ce que vous n\'aimez pas' : 'What you dislike',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Wrap(
          spacing: 6,
          children: [
            for (final (cle, libelle) in [
              ('tanin', fr ? 'Tanins durs' : 'Firm tannins'),
              ('boisé', fr ? 'Boisé marqué' : 'Heavy oak'),
              ('acide', fr ? 'Acidité vive' : 'Sharp acidity'),
            ])
              FilterChip(
                label: Text(libelle, style: const TextStyle(fontSize: 12)),
                selected: _palais.aversions.contains(cle),
                onSelected: (oui) => setState(() => _palais = _palais.copie(
                    aversions: oui ? {..._palais.aversions, cle} : ({..._palais.aversions}..remove(cle)))),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.group_add_rounded, size: 18),
            label: Text(widget.libelleValider, style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => widget.onValider(_palais),
          ),
        ),
        if (widget.onJusteMonPrenom != null)
          Center(
            child: TextButton(
              onPressed: widget.onJusteMonPrenom,
              child: Text(
                widget.libelleRefus ??
                    (fr ? 'Juste mon prénom — je préciserai plus tard' : 'Just my name — I\'ll add my tastes later'),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
