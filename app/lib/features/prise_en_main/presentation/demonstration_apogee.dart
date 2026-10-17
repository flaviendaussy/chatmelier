import 'package:flutter/material.dart';

import '../../../shared/utils/langue.dart';
import '../../../shared/widgets/bottle_card.dart';
import '../../../shared/widgets/gaussian_drinking_curve.dart';
import '../../../shared/widgets/projecteur.dart';
import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/wine.dart';

/// « Me montrer » pour l'apogée (V2.5 · E6), sur une cave de démonstration : la cave, on
/// ouvre une bouteille, on descend jusqu'à sa courbe de garde, et un projecteur l'isole.
///
/// Le 16/10, Flavien : « ça aurait dû passer en cave simulée, ouvrir une bouteille,
/// scroller vers l'apogée, et isoler visuellement la zone (en opacifiant légèrement le
/// reste) ». Ce sont les vrais éléments de l'app (la carte d'une bouteille, sa courbe),
/// nourris de fausses bouteilles : rien n'est lu ni écrit dans la cave de la personne.
class DemonstrationApogee extends StatefulWidget {
  /// Vrai dans les essais : pas d'enchaînement automatique, on avance au toucher.
  final bool pasAPas;

  const DemonstrationApogee({super.key, this.pasAPas = false});

  /// Les bouteilles de la démonstration, les mêmes que celles du guide de prise en main.
  static final bouteilles = <Bottle>[
    _bouteille(
        'demo-champagne', 'Champagne brut', 'Maison de démonstration', null, 'sparkling', 'Champagne', 'Champagne'),
    _bouteille('demo-bandol', 'Bandol rouge', 'Domaine de démonstration', 2019, 'red', 'Provence', 'Bandol',
        cepages: const [Grape(name: 'Mourvèdre'), Grape(name: 'Grenache'), Grape(name: 'Cinsault')]),
    _bouteille('demo-beaujolais', 'Beaujolais-Villages', 'Domaine de démonstration', 2021, 'red', 'Beaujolais',
        'Beaujolais-Villages',
        cepages: const [Grape(name: 'Gamay')]),
  ];

  /// La bouteille qu'on ouvre : un rouge de garde, dont la courbe a de quoi montrer.
  static Bottle get bandol => bouteilles[1];

  static Bottle _bouteille(
          String id, String nom, String domaine, int? millesime, String type, String region, String appellation,
          {List<Grape> cepages = const []}) =>
      Bottle(
        id: id,
        cellarId: 'demo',
        wineId: 'vin-$id',
        addedBy: 'demo',
        ownerId: 'demo',
        createdAt: DateTime(2026),
        wine: Wine(
          id: 'vin-$id',
          name: nom,
          producer: domaine,
          vintage: millesime,
          type: type,
          country: 'France',
          region: region,
          appellation: appellation,
          grapes: cepages,
        ),
      );

  @override
  State<DemonstrationApogee> createState() => _DemonstrationApogeeState();
}

class _DemonstrationApogeeState extends State<DemonstrationApogee> {
  final _carteDuBandol = GlobalKey(debugLabel: 'carteDuBandol');

  @override
  void initState() {
    super.initState();
    if (!widget.pasAPas) WidgetsBinding.instance.addPostFrameCallback((_) => _enchainer());
  }

  /// La cave, puis le Bandol éclairé, puis sa fiche.
  Future<void> _enchainer() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await Projecteur.eclairer(
        context,
        _carteDuBandol,
        tr('Dans votre cave, chaque bouteille a sa jauge. Ouvrons ce Bandol rouge 2019 pour voir sa courbe de garde.',
            'In your cellar, every bottle has its gauge. Let\'s open this 2019 red Bandol to see its ageing curve.'));
    if (mounted) await _ouvrirLaFiche();
  }

  Future<void> _ouvrirLaFiche() async {
    final fini = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => FicheDeDemonstration(bouteille: DemonstrationApogee.bandol, pasAPas: widget.pasAPas)),
    );
    if (fini == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Cave de démonstration', 'Demo cellar'))),
      body: Column(
        children: [
          const _BandeauDeDemonstration(),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(12),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.62,
              children: [
                for (final b in DemonstrationApogee.bouteilles)
                  KeyedSubtree(
                    key: b.id == DemonstrationApogee.bandol.id ? _carteDuBandol : null,
                    // La vraie carte, sans ses gestes : le cœur des favoris écrirait une bouteille
                    // de démonstration dans les vrais favoris. Seul le Bandol s'ouvre.
                    child: Stack(
                      children: [
                        IgnorePointer(child: BottleCard(bottle: b)),
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: b.id == DemonstrationApogee.bandol.id ? _ouvrirLaFiche : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La fiche d'une bouteille de démonstration, jusqu'à sa courbe de garde.
class FicheDeDemonstration extends StatefulWidget {
  final Bottle bouteille;
  final bool pasAPas;

  const FicheDeDemonstration({super.key, required this.bouteille, this.pasAPas = false});

  /// Ce que la courbe montre, en une phrase tirée de la courbe elle-même.
  static String legende(Wine vin) {
    final f = GaussianDrinkingCurve.fenetreDe(vin);
    return tr(
        'La courbe de garde : ce vin s\'ouvre à partir de {debut}, il est à son apogée de {pic1} à {pic2}, puis décline jusqu\'en {fin}. Sous chaque bouteille de votre cave, une jauge le résume.',
        'The ageing curve: this wine opens from {debut}, peaks from {pic1} to {pic2}, then declines until {fin}. Under each bottle in your cellar, a gauge sums it up.',
        {'debut': f.drinkStart, 'pic1': f.peakStart, 'pic2': f.peakEnd, 'fin': f.drinkEnd});
  }

  @override
  State<FicheDeDemonstration> createState() => _FicheDeDemonstrationState();
}

class _FicheDeDemonstrationState extends State<FicheDeDemonstration> {
  final _courbe = GlobalKey(debugLabel: 'courbeDeGarde');
  bool _montree = false;

  @override
  void initState() {
    super.initState();
    if (!widget.pasAPas) WidgetsBinding.instance.addPostFrameCallback((_) => eclairerLaCourbe());
  }

  /// On descend jusqu'à la courbe, et le projecteur l'isole.
  Future<void> eclairerLaCourbe() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await Projecteur.eclairer(context, _courbe, FicheDeDemonstration.legende(widget.bouteille.wine!));
    if (mounted) setState(() => _montree = true);
  }

  @override
  Widget build(BuildContext context) {
    final vin = widget.bouteille.wine!;
    final theme = Theme.of(context);
    final cepages = vin.grapes.map((g) => g.name).join(', ');
    return Scaffold(
      appBar: AppBar(title: Text('${vin.name} ${vin.vintage ?? ''}'.trim())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BandeauDeDemonstration(),
            const SizedBox(height: 12),
            Text('${vin.name} ${vin.vintage ?? ''}'.trim(),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text('${vin.producer} · ${vin.appellation}',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 16),
            _Ligne(tr('Appellation', 'Appellation'), vin.appellation ?? ''),
            _Ligne(tr('Région', 'Region'), vin.region),
            if (cepages.isNotEmpty) _Ligne(tr('Cépages', 'Grapes'), cepages),
            _Ligne(tr('Couleur', 'Colour'), tr('Rouge', 'Red')),
            const SizedBox(height: 16),
            Text(
                tr('Un Bandol rouge, c\'est d\'abord le mourvèdre : fruits noirs, garrigue, et des tanins serrés qui s\'assouplissent avec les années.',
                    'A red Bandol is Mourvèdre first: dark fruit, garrigue, and firm tannins that soften over the years.'),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            const SizedBox(height: 28),
            Text(tr('Quand l\'ouvrir ?', 'When to open it?'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            KeyedSubtree(key: _courbe, child: GaussianDrinkingCurve(wine: vin)),
            const SizedBox(height: 24),
            if (_montree || widget.pasAPas)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(tr('Terminer la démonstration', 'End the demo')),
              ),
            // De quoi descendre : la courbe n'est pas visible d'emblée, comme sur une vraie fiche.
            const SizedBox(height: 240),
          ],
        ),
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final String libelle;
  final String valeur;
  const _Ligne(this.libelle, this.valeur);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 110, child: Text(libelle, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(valeur, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

/// Toujours visible : rien de ce qu'on voit ici n'est dans la cave de la personne.
class _BandeauDeDemonstration extends StatelessWidget {
  const _BandeauDeDemonstration();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          tr('Démonstration : ces bouteilles ne sont pas dans votre cave, et rien n\'est enregistré.',
              'Demo: these bottles aren\'t in your cellar, and nothing is saved.'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
}
