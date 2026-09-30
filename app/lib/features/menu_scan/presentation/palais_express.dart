import 'package:flutter/material.dart';

import '../../auth/domain/wine_taste_radar.dart';
import '../../auth/presentation/widgets/wine_taste_radar_chart.dart';
import '../../sommelier/domain/guest_matcher_engine.dart';
import '../../../shared/utils/langue.dart';

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
    if (aversions.contains('tanin')) return trSi(fr, 'Aversion aux tanins durs', 'Dislikes firm tannins');
    if (tanins >= 7 && corps >= 6) return trSi(fr, 'Grands Rouges Puissants', 'Big, powerful reds');
    if (acidite >= 7 && mineralite >= 6) return trSi(fr, 'Blancs Minéraux & Tendus', 'Taut, mineral whites');
    if (fruit >= 7 && tanins <= 5) return trSi(fr, 'Rouges Fruits Croquants', 'Crunchy fruity reds');
    return trSi(fr, 'Curieux & Éclectique', 'Curious & eclectic');
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

  /// Le lexique sous les curseurs, replié par défaut (V2.3 · G3).
  bool _lexiqueOuvert = false;

  /// Un exemple concret par mot : « tanins » ne dit rien à quelqu'un qui boit surtout de la
  /// bière. Replié, il ne prend qu'une ligne.
  static List<(String, String)> lexique(bool fr) => [
        (
          trSi(fr, 'Tanins', 'Tannins'),
          trSi(fr, 'Ce qui assèche la bouche, comme un thé trop infusé. Marqués dans un Madiran, discrets dans un Beaujolais.', 'What dries your mouth, like over-brewed tea. Firm in a Madiran, soft in a Beaujolais.')
        ),
        (
          trSi(fr, 'Corps', 'Body'),
          trSi(fr, 'Le poids du vin en bouche : léger comme du lait écrémé, ou ample comme de la crème.', 'The weight in your mouth: skimmed milk, or cream.')
        ),
        (
          trSi(fr, 'Acidité', 'Acidity'),
          trSi(fr, 'Ce qui fait saliver et donne de la fraîcheur, comme un zeste de citron. Vive dans un Chablis.', 'What makes your mouth water, like a squeeze of lemon. Lively in a Chablis.')
        ),
        (
          trSi(fr, 'Boisé', 'Oak'),
          trSi(fr, 'La vanille, le toasté ou le fumé que donne l\'élevage en fût de chêne.', 'Vanilla, toast or smoky notes from ageing in oak barrels.')
        ),
        (
          trSi(fr, 'Fruit', 'Fruit'),
          trSi(fr, 'L\'intensité des arômes de fruits : cerise, cassis, pêche…', 'How much fruit you taste: cherry, blackcurrant, peach…')
        ),
        (
          trSi(fr, 'Minéralité', 'Minerality'),
          trSi(fr, 'Une sensation saline, de pierre mouillée ou de craie, typique d\'un Chablis ou d\'un Sancerre.', 'A salty, wet-stone or chalky feel, typical of a Chablis or a Sancerre.')
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final fr = widget.isFr;
    final curseurs = <(String, double, PalaisSaisi Function(double))>[
      (trSi(fr, 'Tanins', 'Tannins'), _palais.tanins, (v) => _palais.copie(tanins: v)),
      (trSi(fr, 'Corps', 'Body'), _palais.corps, (v) => _palais.copie(corps: v)),
      (trSi(fr, 'Acidité', 'Acidity'), _palais.acidite, (v) => _palais.copie(acidite: v)),
      (trSi(fr, 'Boisé', 'Oak'), _palais.boise, (v) => _palais.copie(boise: v)),
      (trSi(fr, 'Fruit', 'Fruit'), _palais.fruit, (v) => _palais.copie(fruit: v)),
      (trSi(fr, 'Minéralité', 'Minerality'), _palais.mineralite, (v) => _palais.copie(mineralite: v)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          // Sans cela, « 🕊️ Aversion aux tanins durs » débordait de 20 pixels sur un
          // téléphone de 400 points de large.
          isExpanded: true,
          initialValue: _prereglage,
          dropdownColor: const Color(0xFF281E34),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: trSi(fr, 'Point de départ (facultatif)', 'Starting point (optional)'),
            labelStyle: const TextStyle(color: _or),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            DropdownMenuItem(value: 'sans_tanin', child: Text(trSi(fr, '🕊️ Aversion aux tanins durs', '🕊️ No firm tannins'))),
            DropdownMenuItem(value: 'mineral', child: Text(trSi(fr, '⚡ Blancs Minéraux & Tendus', '⚡ Taut, mineral whites'))),
            DropdownMenuItem(value: 'puissant', child: Text(trSi(fr, '🧱 Grands Rouges Puissants', '🧱 Big, powerful reds'))),
            DropdownMenuItem(value: 'fruit', child: Text(trSi(fr, '🍒 Rouges Fruits Croquants', '🍒 Crunchy fruity reds'))),
            DropdownMenuItem(value: 'equilibre', child: Text(trSi(fr, '🍷 Curieux & Éclectique', '🍷 Curious & eclectic'))),
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
                  RadarChartDataset(label: trSi(fr, 'Vos goûts', 'Your taste'), color: _or, metrics: _palais.radar),
                ],
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _lexiqueOuvert = !_lexiqueOuvert),
            icon: Icon(_lexiqueOuvert ? Icons.expand_less : Icons.help_outline, size: 16, color: _or),
            label: Text(trSi(fr, 'Que veulent dire ces mots ?', 'What do these words mean?'),
                style: const TextStyle(color: _or, fontSize: 12)),
          ),
        ),
        if (_lexiqueOuvert)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (mot, exemple) in lexique(fr))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '$mot : ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: exemple),
                      ]),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text(trSi(fr, 'Couleurs que vous aimez', 'Colours you enjoy'),
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Wrap(
          spacing: 6,
          children: [
            for (final (cle, libelle) in [
              ('Rouge', trSi(fr, 'Rouge', 'Red')),
              ('Blanc', trSi(fr, 'Blanc', 'White')),
              ('Rosé', trSi(fr, 'Rosé', 'Rosé')),
              ('Bulles', trSi(fr, 'Bulles', 'Sparkling')),
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
        Text(trSi(fr, 'Ce que vous n\'aimez pas', 'What you dislike'),
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Wrap(
          spacing: 6,
          children: [
            for (final (cle, libelle) in [
              ('tanin', trSi(fr, 'Tanins durs', 'Firm tannins')),
              ('boisé', trSi(fr, 'Boisé marqué', 'Heavy oak')),
              ('acide', trSi(fr, 'Acidité vive', 'Sharp acidity')),
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
                    (trSi(fr, 'Juste mon prénom — je préciserai plus tard', 'Just my name — I\'ll add my tastes later')),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
