import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/cellar_provider.dart';
import '../../cellar/domain/cellar_gap_engine.dart';
import '../../journal/presentation/journal_screen.dart';
import '../domain/cellar_bridge.dart';

/// Ce que la cave et le journal savent, prêt à croiser avec une carte des vins.
///
/// **Pourquoi un provider séparé.** Le moteur du pont est volontairement pur — il ne
/// connaît ni Riverpod ni Supabase — parce qu'une erreur y revient à affirmer à quelqu'un
/// qu'il a bu un vin qu'il n'a jamais ouvert, et qu'on veut pouvoir l'éprouver sans base
/// ni réseau. Le raccordement au reste de l'app se fait donc ici, en un seul endroit.
///
/// Silencieux en cas d'échec : une carte sans annotations personnelles reste une carte
/// utilisable, là où une erreur bloquante priverait du scan tout entier.
final cellarContextProvider = FutureProvider<ContexteDeCave>((ref) async {
  final cellarId = ref.watch(currentCellarIdProvider);

  var cave = <VinDeMaCave>[];
  CellarGapAnalysis? lacunes;
  try {
    final bouteilles = await ref.watch(bottlesProvider(cellarId).future);
    cave = [
      for (final b in bouteilles)
        if (b.quantity > 0 && (b.wine?.name ?? '').isNotEmpty)
          VinDeMaCave(
            nom: b.wine!.name,
            producteur: b.wine?.producer,
            millesime: b.wine?.vintage,
            prixAchat: b.purchasePrice,
            quantite: b.quantity,
          ),
    ];
    if (bouteilles.isNotEmpty) {
      lacunes = CellarGapEngine.analyzeCellar(bouteilles);
    }
  } catch (_) {
    // Cave illisible (hors ligne, cave non choisie) : on continue sans elle.
  }

  var journal = <VinDejaGoute>[];
  try {
    final entrees = await ref.watch(tastingLogProvider.future);
    journal = [
      for (final e in entrees)
        if ((e.wineName ?? '').isNotEmpty && e.fault == null)
          VinDejaGoute(
            nom: e.wineName!,
            producteur: e.producer,
            millesime: e.vintage,
            // `displayRating` et non `rating` : les lignes héritées de l'échelle /5
            // afficheraient sinon la moitié de la note réellement donnée.
            note: e.displayRating,
            quand: e.consumedAt,
          ),
    ];
  } catch (_) {
    // Journal illisible : idem.
  }

  return ContexteDeCave(cave: cave, journal: journal, lacunes: lacunes);
});
