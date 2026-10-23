import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../domain/bottle.dart';
import '../domain/cellar_gap_engine.dart';
import '../domain/opportunites_de_cave.dart';
import '../domain/styles_de_vin.dart';
import '../domain/vins_connus/vins_connus.dart';
import '../../../shared/utils/langue.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../auth/domain/taste_profile.dart';
import '../../sommelier/domain/angle_mort_de_la_cave.dart';
import '../../sommelier/domain/taste_frontier_engine.dart';

/// Les opportunités de la cave (23/10) : ce qu'elle n'a pas, ce qu'elle ne m'apprend pas
/// de vous, et les conseils d'équilibre.
///
/// Flavien, 23/10 : « c'est pour proposer des types de vins très différents de ceux que
/// l'utilisateur a, donc il faut voir aussi le côté "angle mort et conseils" ». L'écran
/// s'ouvre donc sur trois styles absents et très éloignés de la cave, avec des vins pour
/// les goûter ; puis l'angle mort du palais ; puis la cave telle qu'elle est (ses styles,
/// ses couleurs, ses apogées).
class CellarGapAnalyzerSheet extends ConsumerWidget {
  final List<Bottle>? preloadedBottles;

  const CellarGapAnalyzerSheet({super.key, this.preloadedBottles});

  static Future<void> show(BuildContext context, {List<Bottle>? bottles}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CellarGapAnalyzerSheet(preloadedBottles: bottles),
    );
  }

  static const _or = Color(0xFFD4AF37);
  static const _fond = Color(0xFF1E1626);

  static Color couleurDuGroupe(String groupe) => switch (groupe) {
        // Plus clair que le bordeaux des couleurs de la cave : il se lit sur fond sombre.
        'red' => const Color(0xFFDE5A78),
        'white' => const Color(0xFFE5C07B),
        'rose' => const Color(0xFFE06C75),
        'sparkling' => const Color(0xFF61AFEF),
        _ => const Color(0xFFD19A66),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCellarId = ref.watch(currentCellarIdProvider);
    final bottlesAsync = ref.watch(bottlesProvider(currentCellarId));
    final bottles = preloadedBottles ?? bottlesAsync.value ?? [];
    // Le palais du maître de cave : ce qu'il ignore encore de lui-même oriente les
    // propositions, et l'angle mort a la sienne (V2.3 · J2).
    final principal = (ref.watch(tasteProfilesListProvider).value ?? const <TasteProfile>[])
        .where((p) => p.isPrimary)
        .firstOrNull;
    final analyse = CellarGapEngine.analyzeCellar(bottles);
    final carte = OpportunitesDeCave.analyser(bottles, profil: principal);
    // L'ancien « cave harmonieuse » proposait toujours les trois mêmes vins : les
    // opportunités le remplacent.
    final conseils = [
      for (final g in analyse.gaps)
        if (g.status != 'balanced' || carte.opportunites.isEmpty) g,
    ];

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Color(0xFF140F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _or, width: 1.5)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _or.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.explore_outlined, color: _or, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Opportunités de cave', 'Cellar opportunities'),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        analyse.totalBottles == 0
                            ? tr('Votre cave est vide', 'Your cellar is empty')
                            : tr('{n} bouteilles · {k} styles sur {total}', '{n} bottles · {k} styles out of {total}', {
                                'n': analyse.totalBottles,
                                'k': carte.stylesPresents,
                                'total': StylesDeVin.tous.length,
                              }),
                        style: const TextStyle(color: _or, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  tooltip: tr('Fermer', 'Close'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                if (carte.opportunites.isNotEmpty) ...[
                  _titre(tr('À découvrir', 'To discover'), Icons.auto_awesome_outlined,
                      sous: tr('Des styles très différents de ce que contient votre cave.',
                          'Styles very different from what your cellar holds.')),
                  for (final o in carte.opportunites) _CarteOpportunite(o),
                  const SizedBox(height: 12),
                ],
                if (carte.angleMort case final angle?) ...[
                  _titre(tr('Votre angle mort', 'Your blind spot'), Icons.visibility_off_outlined,
                      sous: tr('Ce que votre cave ne m\'apprend pas de vous.', 'What your cellar can\'t teach me about you.')),
                  _CarteAngleMort(angle, comble: carte.opportunites.where((o) => o.angleMort).firstOrNull),
                  const SizedBox(height: 12),
                ],
                if (carte.bouteilles.isNotEmpty) ...[
                  _titre(tr('Votre cave en styles', 'Your cellar by style'), Icons.grid_view_rounded),
                  _CarteDesStylesPresents(carte),
                  const SizedBox(height: 20),
                ],
                _titre(tr('Conseils pour la cave', 'Cellar advice'), Icons.tips_and_updates_outlined),
                if (analyse.totalBottles > 0) ...[
                  _barreDesCouleurs(analyse),
                  const SizedBox(height: 10),
                  _maturite(analyse),
                  const SizedBox(height: 12),
                ],
                ...conseils.map(_carteConseil),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _titre(String titre, IconData icone, {String? sous}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: _or, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(titre,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.3)),
              ),
            ],
          ),
          if (sous != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(sous, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _barreDesCouleurs(CellarGapAnalysis a) {
    final parts = [
      (a.redRatio, const Color(0xFF8B1E3F), tr('Rouges', 'Reds')),
      (a.whiteRatio, const Color(0xFFE5C07B), tr('Blancs', 'Whites')),
      (a.sparklingRatio, const Color(0xFF61AFEF), tr('Bulles', 'Sparkling')),
      (a.roseRatio, const Color(0xFFE06C75), tr('Rosés', 'Rosés')),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _fond, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (final (r, c, _) in parts)
                    if (r > 0) Expanded(flex: (r * 100).round().clamp(1, 100), child: Container(color: c)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final (r, c, nom) in parts)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('$nom ${(r * 100).toStringAsFixed(0)} %', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _maturite(CellarGapAnalysis a) {
    Widget colonne(String libelle, int n, Color c) => Expanded(
          child: Column(
            children: [
              Text('$n', style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(libelle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: _fond, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          colonne(tr('Prêtes à boire', 'Ready to drink'), a.readyToDrinkCount, Colors.greenAccent),
          Container(width: 1, height: 34, color: Colors.white12),
          colonne(tr('En garde', 'Ageing'), a.inAgingCount, Colors.lightBlueAccent),
          Container(width: 1, height: 34, color: Colors.white12),
          colonne(tr('À boire bientôt', 'Drink soon'), a.pastPeakCount, a.pastPeakCount > 0 ? Colors.orangeAccent : Colors.white38),
        ],
      ),
    );
  }

  Widget _carteConseil(CellarGapCategory gap) {
    final (couleur, icone) = switch (gap.status) {
      'critical' => (Colors.redAccent, Icons.error_outline_rounded),
      'warning' => (Colors.orangeAccent, Icons.warning_amber_rounded),
      _ => (Colors.greenAccent, Icons.check_circle_outline_rounded),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _fond, borderRadius: BorderRadius.circular(14), border: Border.all(color: couleur.withValues(alpha: 0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: couleur, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(gap.title, style: TextStyle(color: couleur, fontSize: 14, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 6),
          Text(gap.diagnosis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(gap.sommelierAdvice, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3)),
          if (gap.recommendedAppellations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final app in gap.recommendedAppellations) _pastille(app)],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _pastille(String texte, {Color couleur = _or}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF2B1A2C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: couleur.withValues(alpha: 0.8), width: 0.8),
        ),
        child: Text(texte, style: TextStyle(color: couleur, fontSize: 11)),
      );
}

/// Un style à découvrir : ce qu'il est, pourquoi il est neuf pour cette cave, ce qu'il
/// apprendrait du palais, et trois vins pour le goûter.
class _CarteOpportunite extends StatelessWidget {
  final OpportuniteDeCave o;

  const _CarteOpportunite(this.o);

  @override
  Widget build(BuildContext context) {
    final couleur = CellarGapAnalyzerSheet.couleurDuGroupe(o.style.groupe);
    final famille = o.style.famille;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [couleur.withValues(alpha: 0.16), const Color(0xFF1E1626)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleur.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(width: 10, height: 10, decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(o.style.nom, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              if (o.angleMort) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: CellarGapAnalyzerSheet._or.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                  child: Text(tr('Angle mort', 'Blind spot'),
                      style: const TextStyle(color: CellarGapAnalyzerSheet._or, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(o.style.portrait, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
          const SizedBox(height: 6),
          Text(
            o.plusProche == null
                ? tr('Rien de tel dans votre cave.', 'Nothing like it in your cellar.')
                : tr('Rien de tel dans votre cave : le plus proche est « {style} ».', 'Nothing like it in your cellar: the closest is “{style}”.',
                    {'style': o.plusProche!.nom}),
            style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.3),
          ),
          if (o.axe != null) ...[
            const SizedBox(height: 4),
            Text(
              tr('Il m\'apprendrait ce que vous pensez {quoi}.', 'It would tell me how you feel about {quoi}.',
                  {'quoi': TasteFrontierEngine.ceQueJugeLAxe(o.axe!, famille: famille)}),
              style: const TextStyle(color: CellarGapAnalyzerSheet._or, fontSize: 12, height: 1.3),
            ),
          ],
          if (o.exemples.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(tr('Pour le goûter', 'To taste it'), style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final v in o.exemples) CellarGapAnalyzerSheet._pastille(_libelle(v), couleur: couleur)],
            ),
          ],
        ],
      ),
    );
  }

  /// « Domaine Huet · Vouvray », « Lytton Springs (Ridge) · Santa Cruz Mountains ».
  static String _libelle(VinTrouve v) {
    final de = v.vin.de == null ? '' : ' (${v.vin.de})';
    return '${v.vin.nom}$de · ${v.appellation.nom}';
  }
}

/// L'angle mort du palais : l'axe que le palais ignore et qu'aucune bouteille de la cave
/// ne trancherait, avec le conseil qui va avec.
class _CarteAngleMort extends StatelessWidget {
  final AngleMortDeLaCave angle;

  /// L'opportunité qui le comble, quand il y en a une.
  final OpportuniteDeCave? comble;

  const _CarteAngleMort(this.angle, {required this.comble});

  @override
  Widget build(BuildContext context) {
    final lacune = angle.lacune;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1626),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CellarGapAnalyzerSheet._or.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lacune.diagnosis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3)),
          const SizedBox(height: 6),
          Text(lacune.sommelierAdvice, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3)),
          if (comble != null) ...[
            const SizedBox(height: 6),
            Text(
              tr('C\'est « {style} », plus haut.', 'That\'s “{style}”, above.', {'style': comble!.style.nom}),
              style: const TextStyle(color: CellarGapAnalyzerSheet._or, fontSize: 12),
            ),
          ],
          if (lacune.recommendedAppellations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final a in lacune.recommendedAppellations) CellarGapAnalyzerSheet._pastille(a)],
            ),
          ],
        ],
      ),
    );
  }
}

/// Les styles que la cave contient, du plus fourni au moins fourni.
class _CarteDesStylesPresents extends StatelessWidget {
  final CarteDesStyles carte;

  const _CarteDesStylesPresents(this.carte);

  @override
  Widget build(BuildContext context) {
    final presents = [
      for (final s in StylesDeVin.tous)
        if (carte.bouteilles[s.id] case final n?) (s, n),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1E1626), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final (s, n) in presents)
            CellarGapAnalyzerSheet._pastille('${s.nom} · $n', couleur: CellarGapAnalyzerSheet.couleurDuGroupe(s.groupe)),
        ],
      ),
    );
  }
}
