import 'dart:math' as math;
import '../../auth/domain/taste_profile.dart';
import 'menu_wine.dart';

/// 🏷️ Engine to intelligently allocate sommelier highlight flags on scanned wine menus:
/// 1. 💎 Bons plans / Grosses affaires (`deal`)
/// 2. ✨ Vins pépite (`gem`)
/// 3. 🎯 Vins en accord parfait avec le profil (`tasteMatch`) - Uniquement si profil bien fourni !
///
/// Quotas souples :
/// - Petite carte (<= 14 vins) : Max 3 flags
/// - Moyenne carte (15 - 22 vins) : Max 4 flags
/// - Grande carte (> 22 vins) : Max 5 flags
class MenuFlaggingEngine {
  /// Computes the recommended maximum number of flags for a given menu size
  static int computeMaxFlags(int totalWines) {
    if (totalWines <= 0) return 0;
    if (totalWines <= 6) return math.min(2, totalWines);
    if (totalWines <= 14) return 3;
    if (totalWines <= 22) return 4;
    return 5;
  }

  /// Evaluates and applies sommelier flags to a list of extracted menu wines
  static List<MenuWine> applyFlags(
    List<MenuWine> wines,
    TasteProfile? userProfile,
  ) {
    if (wines.isEmpty) return [];

    final maxFlags = computeMaxFlags(wines.length);
    if (maxFlags == 0) return wines;

    // Condition cruciale : les accords de profil ne s'activent QUE si le profil est bien fourni
    final canFlagTasteMatch = userProfile != null && userProfile.isWellProvided;

    // 1. Identify candidates in each category
    final dealCandidates = <_FlagCandidate>[];
    final gemCandidates = <_FlagCandidate>[];
    final matchCandidates = <_FlagCandidate>[];

    for (int i = 0; i < wines.length; i++) {
      final wine = wines[i];

      // A. Deals & Grosses Affaires
      if (wine.isDeal) {
        double score = 0.85;
        // Bonification si on connaît le prix de détail estimé
        if (wine.bottlePrice != null &&
            wine.estimatedRetailPrice != null &&
            wine.estimatedRetailPrice! > 0) {
          final markup = wine.bottlePrice! / wine.estimatedRetailPrice!;
          // Markup standard en restaurant = ~2.8x à 3.5x. Si < 2.2x, c'est une excellente affaire !
          if (markup < 2.0) {
            score = 0.98;
          } else if (markup < 2.5) {
            score = 0.92;
          }
        }

        final isGrosseAffaire = score >= 0.95 ||
            (wine.dealReason != null &&
                wine.dealReason!.toLowerCase().contains('grosse'));

        dealCandidates.add(
          _FlagCandidate(
            wineIndex: i,
            wine: wine,
            flag: MenuWineFlag(
              type: MenuWineFlagType.deal,
              label: isGrosseAffaire ? 'Grosse Affaire' : 'Bon Plan',
              reason: wine.dealReason ??
                  'Excellent rapport prix/plaisir sur la carte',
            ),
            score: score,
          ),
        );
      }

      // B. Vins Pépite (Artisans stars, cuvées d'initiés, biodynamie remarquable)
      if (wine.isGem) {
        double score = 0.90;
        if (wine.sommelierComment != null &&
            wine.sommelierComment!.isNotEmpty) {
          score += 0.05;
        }
        gemCandidates.add(
          _FlagCandidate(
            wineIndex: i,
            wine: wine,
            flag: MenuWineFlag(
              type: MenuWineFlagType.gem,
              label: 'Vin Pépite',
              reason: wine.gemReason ??
                  'Domaine d\'exception et référence incontournable',
            ),
            score: score,
          ),
        );
      }

      // C. Accord Profil (uniquement si profil mature & bien renseigné)
      if (canFlagTasteMatch &&
          wine.userMatchScore != null &&
          wine.userMatchScore! >= 78.0) {
        final matchScore = wine.userMatchScore!;
        final score = matchScore / 100.0;
        matchCandidates.add(
          _FlagCandidate(
            wineIndex: i,
            wine: wine,
            flag: MenuWineFlag(
              type: MenuWineFlagType.tasteMatch,
              label: 'Match Profil ${matchScore.round()}%',
              reason: 'Flacon taillé sur mesure pour vos préférences',
            ),
            score: score,
          ),
        );
      }
    }

    // Trier les candidats par score décroissant dans chaque catégorie
    dealCandidates.sort((a, b) => b.score.compareTo(a.score));
    gemCandidates.sort((a, b) => b.score.compareTo(a.score));
    matchCandidates.sort((a, b) => b.score.compareTo(a.score));

    final assignedWineIndices = <int>{};
    final chosenFlagsByWineIndex = <int, MenuWineFlag>{};

    // 2. Équilibre des sélections : accorder au moins 1 place par catégorie existante si possible
    void tryAssignCandidate(_FlagCandidate candidate) {
      if (chosenFlagsByWineIndex.length >= maxFlags) return;
      if (!assignedWineIndices.contains(candidate.wineIndex)) {
        assignedWineIndices.add(candidate.wineIndex);
        chosenFlagsByWineIndex[candidate.wineIndex] = candidate.flag;
      }
    }

    // Priorité 1 : La meilleure pépite si disponible
    if (gemCandidates.isNotEmpty) {
      tryAssignCandidate(gemCandidates.first);
    }

    // Priorité 2 : Le meilleur bon plan si disponible
    if (dealCandidates.isNotEmpty) {
      final bestDeal = dealCandidates.firstWhere(
        (c) => !assignedWineIndices.contains(c.wineIndex),
        orElse: () => dealCandidates.first,
      );
      tryAssignCandidate(bestDeal);
    }

    // Priorité 3 : Le meilleur match de profil (si éligible)
    if (canFlagTasteMatch && matchCandidates.isNotEmpty) {
      final bestMatch = matchCandidates.firstWhere(
        (c) => !assignedWineIndices.contains(c.wineIndex),
        orElse: () => matchCandidates.first,
      );
      tryAssignCandidate(bestMatch);
    }

    // 3. Compléter les places restantes jusqu'au quota avec les meilleurs candidats restants
    final remainingPool = <_FlagCandidate>[
      ...dealCandidates.where((c) => !assignedWineIndices.contains(c.wineIndex)),
      ...gemCandidates.where((c) => !assignedWineIndices.contains(c.wineIndex)),
      ...matchCandidates.where((c) => !assignedWineIndices.contains(c.wineIndex)),
    ];
    remainingPool.sort((a, b) => b.score.compareTo(a.score));

    for (final candidate in remainingPool) {
      if (chosenFlagsByWineIndex.length >= maxFlags) break;
      tryAssignCandidate(candidate);
    }

    // 4. Reconstruire la liste de vins avec leurs flags appliqués
    final resultWines = <MenuWine>[];
    for (int i = 0; i < wines.length; i++) {
      final assignedFlag = chosenFlagsByWineIndex[i];
      resultWines.add(wines[i].copyWith(flag: assignedFlag));
    }

    return resultWines;
  }
}

class _FlagCandidate {
  final int wineIndex;
  final MenuWine wine;
  final MenuWineFlag flag;
  final double score;

  const _FlagCandidate({
    required this.wineIndex,
    required this.wine,
    required this.flag,
    required this.score,
  });
}
