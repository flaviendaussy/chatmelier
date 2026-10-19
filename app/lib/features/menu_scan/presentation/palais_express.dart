import 'package:flutter/material.dart';

import '../../auth/presentation/widgets/wine_taste_radar_chart.dart';
import '../domain/palais_saisi.dart';
import '../../../shared/utils/langue.dart';

export '../domain/palais_saisi.dart';

/// Le profilage express d'un invité : PROPOSÉ, jamais imposé.
///
/// Cinq curseurs, le radar qui se dessine pendant qu'on les bouge, les couleurs aimées
/// et quatre aversions. « Juste mon prénom » reste toujours possible : rejoindre une table
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

  /// « Je ne bois pas ce soir » (E3), à table seulement.
  final VoidCallback? onJeNeBoisPas;

  const PalaisExpress({
    super.key,
    required this.isFr,
    required this.libelleValider,
    required this.onValider,
    this.onJusteMonPrenom,
    this.libelleRefus,
    this.onJeNeBoisPas,
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
          trSi(fr, 'Sec ou doux', 'Dry or sweet'),
          trSi(fr, 'Le sucre qu\'on sent : aucun dans un Sancerre, un peu dans un Vouvray demi-sec, beaucoup dans un Sauternes.', 'The sugar you taste: none in a Sancerre, a little in a demi-sec Vouvray, a lot in a Sauternes.')
        ),
        (
          trSi(fr, 'Rond ou vif', 'Soft or crisp'),
          trSi(fr, 'Ce qui fait saliver et donne de la fraîcheur, comme un zeste de citron. Vif dans un Chablis, rond dans un Viognier.', 'What makes your mouth water, like a squeeze of lemon. Crisp in a Chablis, soft in a Viognier.')
        ),
        (
          trSi(fr, 'Léger ou puissant', 'Light or full'),
          trSi(fr, 'Le poids du vin en bouche : léger comme du lait écrémé, ou ample comme de la crème.', 'The weight in your mouth: skimmed milk, or cream.')
        ),
        (
          trSi(fr, 'Tanins', 'Tannins'),
          trSi(fr, 'Ce qui assèche la bouche, comme un thé trop infusé. Fermes dans un Madiran, souples dans un Beaujolais.', 'What dries your mouth, like over-brewed tea. Firm in a Madiran, soft in a Beaujolais.')
        ),
        (
          trSi(fr, 'Boisé', 'Oak'),
          trSi(fr, 'La vanille, le toasté ou le fumé que donne l\'élevage en fût de chêne.', 'Vanilla, toast or smoky notes from ageing in oak barrels.')
        ),
      ];


  @override
  Widget build(BuildContext context) {
    final fr = widget.isFr;
    final axes = PalaisSaisi.curseurs(fr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Le radar se dessine pendant qu'on bouge les curseurs : c'est lui qui donne envie
        // d'aller au bout. À côté du point de départ, il laisse aux curseurs toute la
        // largeur (« Tanins souples » se coupait à côté de lui, 20/10).
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                // Sans cela, « 🕊️ Aversion aux tanins durs » débordait de 20 pixels sur un
                // téléphone de 400 points de large.
                isExpanded: true,
                initialValue: _prereglage,
                dropdownColor: const Color(0xFF281E34),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  // Court : le radar est à côté. Tout est facultatif, la feuille le dit déjà.
                  labelText: trSi(fr, 'Point de départ', 'Starting point'),
                  labelStyle: const TextStyle(color: _or),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  DropdownMenuItem(value: 'sans_tanin', child: Text(trSi(fr, '🕊️ Aversion aux tanins durs', '🕊️ No firm tannins'))),
                  DropdownMenuItem(value: 'mineral', child: Text(trSi(fr, '⚡ Blancs Minéraux & Tendus', '⚡ Taut, mineral whites'))),
                  DropdownMenuItem(value: 'tendre', child: Text(trSi(fr, '🍯 Blancs tendres ou doux', '🍯 Off-dry and sweet whites'))),
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
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 76,
              height: 76,
              child: WineTasteRadarChart(
                size: 76,
                showLabels: false,
                isInteractive: false,
                customAxisLabels: [for (final (axe, _, _) in axes) axe],
                datasets: [
                  RadarChartDataset(
                    label: trSi(fr, 'Vos goûts', 'Your taste'),
                    color: _or,
                    customValues: [for (final (axe, _, _) in axes) _palais.valeur(axe)],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final (axe, bas, haut) in axes)
          _Curseur(
            bas: bas,
            haut: haut,
            valeur: _palais.valeur(axe),
            // Pas touché : pâle, et rien de déclaré.
            dit: _palais.dits.containsKey(axe),
            couleur: _or,
            onChanged: (v) => setState(() => _palais = _palais.avec(axe, v)),
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
              ('sucré', trSi(fr, 'Vins sucrés', 'Sweet wines')),
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
        if (widget.onJeNeBoisPas != null)
          Center(
            child: TextButton.icon(
              onPressed: widget.onJeNeBoisPas,
              icon: const Icon(Icons.no_drinks_outlined, size: 16, color: Colors.white54),
              label: Text(
                trSi(fr, 'Je ne bois pas ce soir', 'I\'m not drinking tonight'),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

/// Un curseur entre ses deux bouts, dits en mots de tous les jours.
class _Curseur extends StatelessWidget {
  final String bas;
  final String haut;
  final double valeur;
  final bool dit;
  final Color couleur;
  final ValueChanged<double> onChanged;

  const _Curseur({
    required this.bas,
    required this.haut,
    required this.valeur,
    required this.dit,
    required this.couleur,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Colors.white70, fontSize: 11);
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: SizedBox(
            height: 30,
            child: Slider(
              value: valeur,
              min: 0,
              max: 10,
              divisions: 20,
              activeColor: dit ? couleur : couleur.withValues(alpha: 0.35),
              inactiveColor: Colors.white24,
              onChanged: onChanged,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(child: Text(bas, style: style, overflow: TextOverflow.ellipsis)),
              Expanded(child: Text(haut, style: style, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end)),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
