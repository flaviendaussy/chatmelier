import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/cellar_provider.dart';
import '../../../../shared/utils/langue.dart';
import '../../../../shared/utils/valeurs_rangees.dart';
import '../../../cellar/domain/bottle.dart';
import '../../../journal/domain/tasting_entry.dart';
import '../../../journal/presentation/journal_screen.dart';
import '../../../sommelier/domain/carte_des_terroirs.dart';
import '../../domain/taste_profile.dart';

/// « Vos terroirs » (V2.3 · J3) : les régions goûtées, celles qui attendent en cave sans
/// avoir été goûtées, ce qui reste à découvrir, et la prochaine région à explorer.
class CarteDesTerroirsCard extends ConsumerWidget {
  final TasteProfile profil;

  const CarteDesTerroirsCard({super.key, required this.profil});

  static const _chipsMax = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(tastingLogProvider).valueOrNull ?? const <TastingEntry>[];
    final bouteilles =
        ref.watch(bottlesProvider(ref.watch(currentCellarIdProvider))).valueOrNull ?? const <Bottle>[];
    final carte = CarteDesTerroirs.dresser(
      goutes: [
        for (final e in journal) (pays: e.country, region: e.region, appellation: e.appellation, nom: e.wineName),
      ],
      enCave: [
        for (final b in bouteilles)
          if (b.quantity > 0 && b.wine != null)
            (pays: b.wine!.country, region: b.wine!.region, appellation: b.wine!.appellation, nom: b.wine!.name),
      ],
      profil: profil,
    );
    if (carte.goutes.isEmpty && carte.enCave.isEmpty && carte.prochaine == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const or = Color(0xFFD4AF37);
    const bordeaux = Color(0xFF8B1E3F);

    Widget puces(List<TerroirVu> terroirs, Color couleur) => Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in terroirs.take(_chipsMax))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: couleur.withValues(alpha: 0.45)),
                ),
                child: Text(valeurAffichee(t.libelle), style: const TextStyle(fontSize: 11.5)),
              ),
            if (terroirs.length > _chipsMax)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('+${terroirs.length - _chipsMax}',
                    style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
              ),
          ],
        );

    Widget sousTitre(String texte) => Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Text(texte, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        );

    final reste = carte.total - carte.explorees;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: or.withValues(alpha: 0.5), width: 1.2),
      ),
      color: isDark ? const Color(0xFF221A28) : const Color(0xFFFCF9F5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🗺️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tr('Vos terroirs', 'Your terroirs'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
            if (carte.goutes.isNotEmpty) ...[
              sousTitre(tr('Goûtés ({n})', 'Tasted ({n})', {'n': carte.goutes.length})),
              puces(carte.goutes, bordeaux),
            ],
            if (carte.enCave.isNotEmpty) ...[
              sousTitre(tr('En cave, jamais goûtés ({n})', 'In the cellar, never tasted ({n})', {'n': carte.enCave.length})),
              puces(carte.enCave, or),
            ],
            const SizedBox(height: 10),
            Text(
              tr('{explorees} régions approchées sur {total} : {reste} restent à découvrir.',
                  '{explorees} of {total} regions explored: {reste} left to discover.',
                  {'explorees': carte.explorees, 'total': carte.total, 'reste': reste}),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11.5),
            ),
            if (carte.prochaine != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧭', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(carte.prochaine!.phrase,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5, height: 1.3)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
