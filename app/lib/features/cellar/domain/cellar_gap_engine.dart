import '../domain/bottle.dart';

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
      return const CellarGapAnalysis(
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
            title: 'Cave Vierge',
            status: 'warning',
            diagnosis: 'Votre cave est actuellement vide.',
            sommelierAdvice: 'Commencez par 3 piliers indispensables : un blanc minéral vif, un rouge soyeux de plaisir et un flacon de garde.',
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

    final currentYear = DateTime.now().year;

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

      // Analyse de maturité
      final endYear = w.drinkEnd;
      final startYear = w.drinkStart;

      if (endYear != null && endYear < currentYear) {
        pastCount += qty;
      } else if (startYear != null && startYear > currentYear) {
        agingCount += qty;
      } else {
        readyCount += qty;
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
        title: 'Hégémonie des Rouges',
        status: 'warning',
        diagnosis: '${(redRatio * 100).toStringAsFixed(0)}% de vos flacons sont des rouges.',
        sommelierAdvice: 'Vous manquez d\'options vives pour les apéritifs spontanés, poissons, volailles crémées ou fromages de chèvre.',
        recommendedAppellations: ['Sancerre Blanc', 'Chablis Premier Cru', 'Riesling d\'Alsace'],
      ));
      wishlist.addAll(['Sancerre Blanc', 'Chablis']);
    } else if (whiteRatio > 0.70) {
      gaps.add(CellarGapCategory(
        title: 'Manque de Rouges Structurés',
        status: 'warning',
        diagnosis: '${(whiteRatio * 100).toStringAsFixed(0)}% de blancs.',
        sommelierAdvice: 'Pour les viandes grillées ou plats mijotés d\'hiver, vous manquerez de tannins patinés.',
        recommendedAppellations: ['Saint-Joseph Rouge', 'Pessac-Léognan', 'Chianti Classico'],
      ));
      wishlist.addAll(['Saint-Joseph Rouge', 'Pessac-Léognan']);
    }

    if (sparklingCount == 0) {
      gaps.add(const CellarGapCategory(
        title: 'Zéro Effervescent',
        status: 'critical',
        diagnosis: 'Aucune bouteille de bulles recensée en cave.',
        sommelierAdvice: 'Un imprévu à fêter ? Avoir au moins 2 bouteilles de bulles prêtes évite l\'achat d\'urgence.',
        recommendedAppellations: ['Champagne Blanc de Blancs', 'Crémant de Bourgogne', 'Franciacorta'],
      ));
      wishlist.add('Champagne Blanc de Blancs');
    }

    // 2. Diagnostic Maturité / Garde
    if (agingCount > 0 && readyCount < (total * 0.25)) {
      gaps.add(CellarGapCategory(
        title: 'Risque d\'Infanticide Oenologique',
        status: 'warning',
        diagnosis: 'Beaucoup de flacons en vieillissement mais très peu de bouteilles prêtes à boire (${readyCount} flacons).',
        sommelierAdvice: 'Vous risquez d\'ouvrir prématurément de grands vins de garde. Rentrez quelques cuvées de plaisir immédiat.',
        recommendedAppellations: ['Beaujolais Villages', 'Côtes-du-Rhône Méridional', 'Languedoc frais'],
      ));
      wishlist.add('Côtes-du-Rhône jeune & fruité');
    }

    if (pastCount > 0) {
      gaps.add(CellarGapCategory(
        title: 'Flacons en Urgence de Dégustation',
        status: 'critical',
        diagnosis: '$pastCount bouteilles ont dépassé leur fenêtre optimale d\'apogée.',
        sommelierAdvice: 'Ouvrez ces bouteilles lors de vos prochains repas pour ne pas perdre leur éclat aromatique.',
        recommendedAppellations: [],
      ));
    }

    // Si la cave est très équilibrée
    if (gaps.isEmpty) {
      gaps.add(const CellarGapCategory(
        title: 'Cave Harmonieuse & Complète',
        status: 'balanced',
        diagnosis: 'Votre cave présente un équilibre remarquable en styles et en fenêtres de dégustation.',
        sommelierAdvice: 'Vous êtes paré pour tous les types de repas et célébrations.',
        recommendedAppellations: ['Condrieu', 'Barolo', 'Corton-Charlemagne'],
      ));
      wishlist.add('Cuvée coup de cœur ou d\'émotion');
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
