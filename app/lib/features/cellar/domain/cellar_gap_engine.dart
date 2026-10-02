import '../domain/bottle.dart';
import '../domain/wine.dart';
import '../../../shared/utils/langue.dart';

class CellarGapCategory {
  final String title;
  final String status; // 'balanced', 'warning', 'critical'
  final String diagnosis;
  final String sommelierAdvice;
  final List<String> recommendedAppellations;

  const CellarGapCategory({
    required this.title,
    required this.status,
    required this.diagnosis,
    required this.sommelierAdvice,
    required this.recommendedAppellations,
  });
}

class CellarGapAnalysis {
  final int totalBottles;
  final double redRatio;
  final double whiteRatio;
  final double roseRatio;
  final double sparklingRatio;
  final int readyToDrinkCount;
  final int inAgingCount;
  final int pastPeakCount;
  final List<CellarGapCategory> gaps;
  final List<String> shoppingWishlist;

  const CellarGapAnalysis({
    required this.totalBottles,
    required this.redRatio,
    required this.whiteRatio,
    required this.roseRatio,
    required this.sparklingRatio,
    required this.readyToDrinkCount,
    required this.inAgingCount,
    required this.pastPeakCount,
    required this.gaps,
    required this.shoppingWishlist,
  });
}

class CellarGapEngine {
  static CellarGapAnalysis analyzeCellar(List<Bottle> bottles) {
    final available = bottles.where((b) => b.quantity > 0).toList();
    final total = available.fold<int>(0, (sum, b) => sum + b.quantity);

    if (total == 0) {
      return CellarGapAnalysis(
        totalBottles: 0,
        redRatio: 0,
        whiteRatio: 0,
        roseRatio: 0,
        sparklingRatio: 0,
        readyToDrinkCount: 0,
        inAgingCount: 0,
        pastPeakCount: 0,
        gaps: [
          CellarGapCategory(
            title: tr('Cave Vierge', 'Empty cellar'),
            status: 'warning',
            diagnosis: tr('Votre cave est actuellement vide.', 'Your cellar is empty for now.'),
            sommelierAdvice: tr('Commencez par 3 piliers indispensables : un blanc minéral vif, un rouge soyeux de plaisir et un flacon de garde.', 'Start with 3 essentials: a crisp mineral white, a silky easy-drinking red and a bottle to age.'),
            recommendedAppellations: ['Chablis', 'Bourgogne Pinot Noir', 'Côtes-du-Rhône'],
          ),
        ],
        shoppingWishlist: ['Chablis', 'Bourgogne Pinot Noir', 'Crozes-Hermitage'],
      );
    }

    int redCount = 0;
    int whiteCount = 0;
    int roseCount = 0;
    int sparklingCount = 0;
    int readyCount = 0;
    int agingCount = 0;
    int pastCount = 0;

    for (final b in available) {
      final w = b.wine;
      if (w == null) continue;
      final type = w.type.toLowerCase();
      final qty = b.quantity;

      if (type.contains('blanc') || type.contains('white')) {
        whiteCount += qty;
      } else if (type.contains('rosé') || type.contains('rose')) {
        roseCount += qty;
      } else if (type.contains('champ') || type.contains('sparkling') || type.contains('efferv')) {
        sparklingCount += qty;
      } else {
        redCount += qty;
      }

      // La maturité de [Wine.windowStatus], le seul calcul de fenêtre de l'app : lue sur
      // les dates brutes de la fiche (souvent absentes, ou corrigées depuis), l'analyse
      // annonçait 25 bouteilles prêtes quand les fiches en montraient plusieurs en garde.
      switch (w.windowStatus) {
        case DrinkWindowStatus.tooYoung || DrinkWindowStatus.aging:
          agingCount += qty;
        case DrinkWindowStatus.inPeak:
          readyCount += qty;
        case DrinkWindowStatus.drinkSoon || DrinkWindowStatus.pastPeak:
          pastCount += qty;
      }
    }

    final redRatio = redCount / total;
    final whiteRatio = whiteCount / total;
    final roseRatio = roseCount / total;
    final sparklingRatio = sparklingCount / total;

    final gaps = <CellarGapCategory>[];
    final wishlist = <String>[];

    // 1. Diagnostic Équilibre des Couleurs
    if (redRatio > 0.70) {
      gaps.add(CellarGapCategory(
        title: tr('Hégémonie des Rouges', 'Mostly reds'),
        status: 'warning',
        diagnosis: tr('{v1}% de vos flacons sont des rouges.', '{v1}% of your bottles are reds.', {'v1': (redRatio * 100).toStringAsFixed(0)}),
        sommelierAdvice: tr('Vous manquez d\'options vives pour les apéritifs spontanés, poissons, volailles crémées ou fromages de chèvre.', 'You\'re short of fresh options for impromptu aperitifs, fish, creamy poultry or goat\'s cheese.'),
        recommendedAppellations: ['Sancerre Blanc', 'Chablis Premier Cru', 'Riesling d\'Alsace'],
      ));
      wishlist.addAll(['Sancerre Blanc', 'Chablis']);
    } else if (whiteRatio > 0.70) {
      gaps.add(CellarGapCategory(
        title: tr('Manque de Rouges Structurés', 'Short of structured reds'),
        status: 'warning',
        diagnosis: tr('{v1}% de blancs.', '{v1}% whites.', {'v1': (whiteRatio * 100).toStringAsFixed(0)}),
        sommelierAdvice: tr('Pour les viandes grillées ou plats mijotés d\'hiver, vous manquerez de tannins patinés.', 'For grilled meat or winter stews, you\'ll be short of mellow tannins.'),
        recommendedAppellations: ['Saint-Joseph Rouge', 'Pessac-Léognan', 'Chianti Classico'],
      ));
      wishlist.addAll(['Saint-Joseph Rouge', 'Pessac-Léognan']);
    }

    if (sparklingCount == 0) {
      gaps.add(CellarGapCategory(
        title: tr('Zéro Effervescent', 'No sparkling wine'),
        status: 'critical',
        diagnosis: tr('Aucune bouteille de bulles recensée en cave.', 'Not a single bottle of bubbles in the cellar.'),
        sommelierAdvice: tr('Un imprévu à fêter ? Avoir au moins 2 bouteilles de bulles prêtes évite l\'achat d\'urgence.', 'Something to celebrate at short notice? Keeping at least 2 bottles of bubbles ready saves a last-minute purchase.'),
        recommendedAppellations: ['Champagne Blanc de Blancs', 'Crémant de Bourgogne', 'Franciacorta'],
      ));
      wishlist.add('Champagne Blanc de Blancs');
    }

    // 2. Diagnostic Maturité / Garde
    if (agingCount > 0 && readyCount < (total * 0.25)) {
      gaps.add(CellarGapCategory(
        title: tr('Risque d\'Infanticide Oenologique', 'Risk of opening wines too young'),
        status: 'warning',
        diagnosis: tr('Beaucoup de flacons en vieillissement mais très peu de bouteilles prêtes à boire ({readyCount} flacons).', 'Lots of bottles still ageing, but very few ready to drink ({readyCount} bottles).', {'readyCount': readyCount}),
        sommelierAdvice: tr('Vous risquez d\'ouvrir prématurément de grands vins de garde. Rentrez quelques cuvées de plaisir immédiat.', 'You may end up opening great wines too early. Add a few bottles to enjoy now.'),
        recommendedAppellations: ['Beaujolais Villages', 'Côtes-du-Rhône Méridional', tr('Languedoc frais', 'Fresh Languedoc')],
      ));
      wishlist.add(tr('Côtes-du-Rhône jeune & fruité', 'Young, fruity Côtes-du-Rhône'));
    }

    if (pastCount > 0) {
      gaps.add(CellarGapCategory(
        title: tr('Flacons en Urgence de Dégustation', 'Bottles to drink now'),
        status: 'critical',
        diagnosis: tr('{pastCount} bouteilles arrivent au bout de leur fenêtre, ou l\'ont passée.',
            '{pastCount} bottles are at the end of their window, or past it.', {'pastCount': pastCount}),
        sommelierAdvice: tr('Ouvrez ces bouteilles lors de vos prochains repas pour ne pas perdre leur éclat aromatique.', 'Open them at your next meals before they lose their aromas.'),
        recommendedAppellations: [],
      ));
    }

    // Si la cave est très équilibrée
    if (gaps.isEmpty) {
      gaps.add(CellarGapCategory(
        title: tr('Cave Harmonieuse & Complète', 'A balanced, complete cellar'),
        status: 'balanced',
        diagnosis: tr('Votre cave présente un équilibre remarquable en styles et en fenêtres de dégustation.', 'Your cellar is remarkably balanced in styles and drinking windows.'),
        sommelierAdvice: tr('Vous êtes paré pour tous les types de repas et célébrations.', 'You\'re ready for any meal or celebration.'),
        recommendedAppellations: ['Condrieu', 'Barolo', 'Corton-Charlemagne'],
      ));
      wishlist.add(tr('Cuvée coup de cœur ou d\'émotion', 'A bottle you fall for'));
    }

    return CellarGapAnalysis(
      totalBottles: total,
      redRatio: redRatio,
      whiteRatio: whiteRatio,
      roseRatio: roseRatio,
      sparklingRatio: sparklingRatio,
      readyToDrinkCount: readyCount,
      inAgingCount: agingCount,
      pastPeakCount: pastCount,
      gaps: gaps,
      shoppingWishlist: wishlist.toSet().toList(),
    );
  }
}
