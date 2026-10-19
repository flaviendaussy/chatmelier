import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/cellar_provider.dart';
import '../../../../shared/utils/langue.dart';
import '../../../cellar/domain/bottle.dart';
import '../../../cellar/domain/wine.dart';
import '../../../cellar/presentation/bottle_detail_screen.dart';
import '../../../sommelier/domain/taste_frontier_engine.dart';
import '../../domain/palais.dart';
import '../../domain/taste_profile.dart';

/// Les bouteilles de la cave d'où le moteur choisit : prêtes à boire, jamais en garde, et
/// pas de spiritueux (ils ne disent rien d'un palais de vin).
List<Bottle> bouteillesPourApprendre(List<Bottle> bouteilles) => [
      for (final b in bouteilles)
        if (b.quantity > 0 &&
            b.wine != null &&
            !b.wine!.isSpirit &&
            const {DrinkWindowStatus.inPeak, DrinkWindowStatus.drinkSoon, DrinkWindowStatus.pastPeak}
                .contains(b.wine!.windowStatus))
          b,
    ];

/// Les bouteilles de la cave courante d'où le moteur choisit. Lues dans un fournisseur
/// asynchrone : sans cave lisible (aucune cave, préférences absentes), le radar s'affiche
/// sans ces suggestions au lieu de tomber.
final bouteillesPourApprendreProvider = FutureProvider<List<Bottle>>((ref) async {
  final cave = ref.watch(currentCellarIdProvider);
  return bouteillesPourApprendre(await ref.watch(bottlesProvider(cave).future));
});

String _nomDe(Bottle b) => '${b.wine!.name}${b.wine!.vintage != null ? ' ${b.wine!.vintage}' : ''}';

void _ouvrir(BuildContext context, Bottle b) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BottleDetailScreen(id: b.id)));

/// « Les bouteilles de votre cave qui m'apprendraient le plus », axe par axe (V2.5 · F3).
///
/// 11/10, Flavien : « ça serait bien de pouvoir savoir vite quelles bouteilles en cave
/// pourraient améliorer les axes encore inconnus ». Rien ne s'affiche si la cave n'a
/// aucune bouteille prête à boire qui tranche un axe encore deviné.
class BouteillesQuiApprendraient extends ConsumerWidget {
  final TasteProfile profil;
  final Color couleur;

  const BouteillesQuiApprendraient({super.key, required this.profil, required this.couleur});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bouteilles = ref.watch(bouteillesPourApprendreProvider).valueOrNull ?? const [];
    final axes = TasteFrontierEngine.parAxe(bouteilles, [profil], profilDe: (b) => ProfilDeVin.depuisLaCave(b.wine!));
    if (axes.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gris = isDark ? Colors.white60 : Colors.black54;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2530) : const Color(0xFFEFF4FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profil.isPrimary
                ? tr('🧭 Les bouteilles de votre cave qui m\'apprendraient le plus',
                    '🧭 The bottles in your cellar that would teach me the most')
                : tr('🧭 Les bouteilles de votre cave qui m\'apprendraient le plus sur {nom}',
                    '🧭 The bottles in your cellar that would teach me the most about {nom}', {'nom': profil.name}),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              tr('Axe par axe, ce que je devine encore, et la bouteille prête à boire qui le trancherait.',
                  'Axis by axis, what I\'m still guessing, and the ready-to-drink bottle that would settle it.'),
              style: TextStyle(fontSize: 12, color: gris, height: 1.3),
            ),
          ),
          const SizedBox(height: 6),
          for (final a in axes.take(5))
            InkWell(
              key: ValueKey('apprendre-${a.famille}-${a.axe}'),
              borderRadius: BorderRadius.circular(10),
              onTap: () => _ouvrir(context, a.bouteille),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text: _nomDeLAxe(a.famille, a.axe),
                                style: TextStyle(fontWeight: FontWeight.w700, color: couleur),
                              ),
                              TextSpan(text: '  ${_etat(profil, a.famille, a.axe)}', style: TextStyle(color: gris)),
                            ]),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr('Votre {vin}, {comment}', 'Your {vin}, {comment}', {
                              'vin': _nomDe(a.bouteille),
                              'comment': TasteFrontierEngine.commentLeVinLeMontre(a.axe, a.valeurDuVin),
                            }),
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: gris),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// « Boisé · blancs » : l'axe et la famille dont il manque (V2.6).
  static String _nomDeLAxe(String famille, String axe) => axe == AxesDuPalais.tanins
      ? AxesDuPalais.nom(axe)
      : tr('{axe} · {famille}', '{axe} · {famille}', {
          'axe': AxesDuPalais.nom(axe),
          'famille': famille == FamillesDeVins.rouge ? tr('rouges', 'reds') : tr('blancs', 'whites'),
        });

  /// « jamais goûté », ou « deviné · 2 dégustations ».
  static String _etat(TasteProfile p, String famille, String axe) {
    final n = p.observationsSur(famille, axe);
    if (n <= 0) return tr('jamais goûté', 'never tasted');
    if (n == 1) return tr('deviné · 1 dégustation', 'a guess · 1 tasting');
    return tr('deviné · {n} dégustations', 'a guess · {n} tastings', {'n': n});
  }
}

/// « Pour mieux vous connaître tous les deux » (V2.5 · F2) : l'axe que ni l'un ni l'autre
/// n'a encore montré, et la bouteille de la cave qui le trancherait pour les deux.
class PourVousConnaitreTousLesDeux extends ConsumerWidget {
  final TasteProfile a;
  final TasteProfile b;

  const PourVousConnaitreTousLesDeux({super.key, required this.a, required this.b});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (a.id == b.id) return const SizedBox.shrink();
    final bouteilles = ref.watch(bouteillesPourApprendreProvider).valueOrNull ?? const [];
    final axes = TasteFrontierEngine.parAxe(bouteilles, [a, b], profilDe: (x) => ProfilDeVin.depuisLaCave(x.wine!));
    if (axes.isEmpty) return const SizedBox.shrink();
    final premier = axes.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1F2530) : const Color(0xFFEFF4FA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const ValueKey('connaitre-les-deux'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => _ouvrir(context, premier.bouteille),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                premier.ignorants.length == 2
                    ? tr('🧭 Pour mieux vous connaître tous les deux', '🧭 To get to know you both better')
                    : tr('🧭 Pour mieux vous connaître', '🧭 To get to know you better'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              const SizedBox(height: 6),
              Text(
                phrase(premier, _nomDe(premier.bouteille)),
                style: TextStyle(fontSize: 12.5, height: 1.4, color: isDark ? Colors.white70 : Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// « Je ne sais pas encore ce que Caro et vous pensez du boisé. Votre Meursault 2019,
  /// nettement boisé et prêt à boire, me le dirait pour vous deux. » Le palais principal,
  /// c'est « vous ».
  static String phrase(AxeAApprendre<Object?> x, String vin) {
    final quoi = TasteFrontierEngine.ceQueJugeLAxe(x.axe, famille: x.famille);
    final comment = TasteFrontierEngine.commentLeVinLeMontre(x.axe, x.valeurDuVin);
    final ignorants = x.ignorants;
    final String qui;
    if (ignorants.length >= 2) {
      final principal = ignorants.where((p) => p.isPrimary).firstOrNull;
      final autres = [for (final p in ignorants) if (!identical(p, principal)) p.name];
      qui = principal != null
          ? tr('Je ne sais pas encore ce que {nom} et vous pensez {quoi}.', 'I don\'t know yet how you and {nom} feel about {quoi}.',
              {'nom': autres.first, 'quoi': quoi})
          : tr('Je ne sais pas encore ce que {a} et {b} pensent {quoi}.', 'I don\'t know yet how {a} and {b} feel about {quoi}.',
              {'a': autres[0], 'b': autres[1], 'quoi': quoi});
      return '$qui ${tr('Votre {vin}, {comment} et prêt à boire, me le dirait pour vous deux.', 'Your {vin}, {comment} and ready to drink, would tell me for both of you.', {'vin': vin, 'comment': comment})}';
    }
    final seul = ignorants.single;
    qui = seul.isPrimary
        ? tr('Je ne sais pas encore ce que vous pensez {quoi}.', 'I don\'t know yet how you feel about {quoi}.', {'quoi': quoi})
        : tr('Je ne sais pas encore ce que {nom} pense {quoi}.', 'I don\'t know yet how {nom} feels about {quoi}.',
            {'nom': seul.name, 'quoi': quoi});
    return '$qui ${tr('Votre {vin}, {comment} et prêt à boire, me le dirait.', 'Your {vin}, {comment} and ready to drink, would tell me.', {'vin': vin, 'comment': comment})}';
  }
}
