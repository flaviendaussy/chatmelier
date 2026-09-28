import 'menu_wine.dart';

/// Un vin de la carte proposé pour un plat, avec la raison de l'accord.
class AccordMetVin {
  final MenuWine vin;
  final double score;
  final String raison;

  const AccordMetVin({required this.vin, required this.score, required this.raison});
}

/// Accords mets-vins sur la carte scannée : quel vin pour ce plat ?
///
/// Extrait de l'écran invité du consensus, où il testait `wineType.contains('rouge')`.
/// Or le scan renvoie la couleur en anglais (`red`) : aucun vin n'était jamais reconnu
/// rouge, tous les scores se valaient, et l'ordre de la carte — les blancs d'abord —
/// gagnait. D'où « trois blancs pour une viande rouge » au restaurant en Écosse. La
/// couleur passe désormais par `MenuWine.isRed`…, et les métriques départagent les vins
/// d'une même couleur au lieu de laisser l'ordre de la carte décider.
class FoodPairingEngine {
  /// Catégories de plats, dans l'ordre des pastilles de l'écran.
  static const categories = ['viande', 'poisson', 'volaille', 'fromage', 'pates', 'dessert'];

  // Mots entiers, en français et en anglais : les cartes se scannent aussi à l'étranger.
  static RegExp _mots(String alternatives) =>
      RegExp('(?<!\\p{L})(?:$alternatives)(?!\\p{L})', unicode: true, caseSensitive: false);

  // L'ordre compte : « canard » et « gibier » sont de la viande rouge avant d'être une
  // volaille, et « poulet » doit gagner sur « sauce ».
  static final _motsParCategorie = <String, RegExp>{
    'viande': _mots('bœuf|boeuf|steak|entrecôte|entrecote|faux-filet|côte de bœuf|agneau|canard|'
        'magret|gibier|chevreuil|sanglier|burger|bavette|onglet|tartare|beef|ribeye|rib-eye|'
        'sirloin|fillet steak|lamb|venison|duck|game|haggis|short rib'),
    'poisson': _mots('poisson|saumon|crevettes?|huîtres?|huitres?|cabillaud|dorade|bar|sole|thon|'
        'saint-jacques|st-jacques|homard|langoustines?|moules|crabe|truite|lotte|turbot|fish|'
        'salmon|prawns?|shrimps?|oysters?|cod|haddock|sea bass|seabass|tuna|scallops?|lobster|'
        'mussels|crab|trout|halibut|monkfish|langoustines'),
    'volaille': _mots('poulet|volaille|dinde|veau|porc|pintade|caille|chicken|turkey|veal|pork|'
        'guinea fowl|quail|poultry'),
    'fromage': _mots('fromages?|comté|comte|camembert|chèvre|chevre|roquefort|brie|reblochon|'
        'cheeses?|cheddar|stilton|goat'),
    'dessert': _mots('desserts?|tarte|chocolat|glace|fraises?|crème brûlée|sorbet|gâteau|gateau|'
        'chocolate|pudding|tart|ice cream|strawberr(?:y|ies)|sticky toffee|cranachan|cake'),
    'pates': _mots('pâtes|pates|pasta|risotto|pizza|lasagnes?|gnocchi|spaghetti|tagliatelle'),
  };

  /// La catégorie d'un plat saisi librement (« Scottish beef fillet » → viande), ou nulle.
  static String? categorieDuPlat(String saisie) {
    final texte = saisie.trim();
    if (texte.isEmpty) return null;
    for (final entree in _motsParCategorie.entries) {
      if (entree.value.hasMatch(texte)) return entree.key;
    }
    return null;
  }

  /// Les [nombre] meilleurs vins de [vins] pour un plat de [categorie].
  static List<AccordMetVin> meilleursVins(
    List<MenuWine> vins,
    String categorie, {
    bool isFr = true,
    int nombre = 3,
  }) {
    final accords = [for (final vin in vins) _evaluer(vin, categorie, isFr)]
      ..sort((a, b) => b.score.compareTo(a.score));
    return accords.take(nombre).toList();
  }

  static AccordMetVin _evaluer(MenuWine vin, String categorie, bool fr) {
    final m = vin.metrics;
    var score = 70.0;
    String raison;
    String note(double v) => '${v.round()}/10';

    switch (categorie) {
      case 'viande':
        if (vin.isRed) {
          score += 20 + (m.tannins - 5) * 1.5 + (m.body - 5);
          raison = fr
              ? 'Tanins ${note(m.tannins)} et corps ${note(m.body)} : de quoi tenir tête aux sucs d\'une viande rouge.'
              : 'Tannins ${note(m.tannins)} and body ${note(m.body)}: enough grip to stand up to red meat.';
        } else if (vin.isRose) {
          score -= 10;
          raison = fr
              ? 'Un rosé reste léger face à une viande rouge : à garder pour une cuisson rosée ou grillée.'
              : 'A rosé is light for red meat: keep it for something grilled or pink.';
        } else {
          score -= 25;
          raison = fr
              ? 'Sans tanins, un blanc manque de structure pour une viande rouge.'
              : 'Without tannins, a white lacks the structure for red meat.';
        }
        break;

      case 'poisson':
        if (vin.isWhite || vin.isSparkling) {
          score += 22 + (m.acidity - 5) * 1.5 + (m.minerality - 5);
          raison = fr
              ? 'Vivacité ${note(m.acidity)} et minéralité ${note(m.minerality)} : elles équilibrent la chair délicate du poisson.'
              : 'Freshness ${note(m.acidity)} and minerality ${note(m.minerality)} balance delicate fish.';
        } else if (vin.isRose) {
          score += 8 + (m.acidity - 5);
          raison = fr
              ? 'Un rosé vif peut suivre un poisson grillé ou une cuisine méditerranéenne.'
              : 'A crisp rosé can follow grilled fish or Mediterranean cooking.';
        } else {
          score -= 30 + (m.tannins - 5) * 2;
          raison = fr
              ? 'Les tanins d\'un rouge réagissent avec l\'iode et laissent une amertume métallique.'
              : 'Red-wine tannins clash with iodine and leave a metallic bitterness.';
        }
        break;

      case 'volaille':
        if (vin.isWhite || (vin.isRed && m.tannins <= 5)) {
          score += 20 + (m.fruit - 5) - (m.tannins - 3).clamp(0, 10);
          raison = fr
              ? 'Fruit ${note(m.fruit)} et tanins discrets : la chair tendre reste au premier plan.'
              : 'Fruit ${note(m.fruit)} and gentle tannins keep tender meat centre stage.';
        } else {
          score += 5;
          raison = fr
              ? 'Accord possible si la volaille est rôtie ou servie avec une sauce riche.'
              : 'Works if the poultry is roasted or served with a rich sauce.';
        }
        break;

      case 'fromage':
        if (vin.isWhite || m.sweetness >= 4) {
          score += 20 + (m.acidity - 5) + (m.sweetness - 2).clamp(0, 6);
          raison = fr
              ? 'Pas de conflit tannique avec le gras du fromage, et de la fraîcheur pour le relancer.'
              : 'No tannic clash with the richness of cheese, and freshness to lift it.';
        } else {
          score += 10 - (m.tannins - 6).clamp(0, 10);
          raison = fr
              ? 'Accord classique avec une pâte pressée cuite bien affinée.'
              : 'A classic match for a well-aged hard cheese.';
        }
        break;

      case 'pates':
        score += 15 + (m.acidity - 5) - (m.tannins - 6).clamp(0, 10);
        raison = fr
            ? 'De la fraîcheur pour la rondeur des sauces et des féculents.'
            : 'Freshness to match rich sauces and starches.';
        break;

      case 'dessert':
        if (vin.isSparkling || m.sweetness >= 4) {
          score += 25 + (m.sweetness - 4).clamp(0, 6) * 1.5;
          raison = fr
              ? 'Bulles fraîches ou douceur en miroir de la gourmandise du dessert.'
              : 'Fresh bubbles or sweetness mirroring the dessert.';
        } else {
          score -= 15;
          raison = fr
              ? 'Un vin sec ou tannique paraît âpre face au sucre.'
              : 'A dry or tannic wine turns harsh against sugar.';
        }
        break;

      default:
        raison = '';
    }

    return AccordMetVin(vin: vin, score: score.clamp(30.0, 99.0), raison: raison);
  }
}
