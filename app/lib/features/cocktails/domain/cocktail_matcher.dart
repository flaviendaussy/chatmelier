import '../../cellar/domain/bottle.dart';
import 'bar_pantry_item.dart';
import 'cocktail.dart';

class CocktailMatchResult {
  final Cocktail cocktail;
  final bool isReady;
  final bool isAlmostReady;
  final List<String> availableIngredients;
  final List<String> missingIngredients;
  final Map<String, Bottle> matchedBottles;

  const CocktailMatchResult({
    required this.cocktail,
    required this.isReady,
    required this.isAlmostReady,
    required this.availableIngredients,
    required this.missingIngredients,
    required this.matchedBottles,
  });

  int get missingCount => missingIngredients.length;
}

class CocktailMatcher {
  static CocktailMatchResult matchCocktail({
    required Cocktail cocktail,
    required List<Bottle> cellarBottles,
    required List<BarPantryItem> pantryItems,
  }) {
    final availableSpirits = cellarBottles.where((b) => b.quantity > 0).toList();
    final inStockPantry = {for (final item in pantryItems.where((i) => i.inStock)) item.id: item};

    final List<String> available = [];
    final List<String> missing = [];
    final Map<String, Bottle> matchedBottles = {};

    for (final ing in cocktail.ingredients) {
      if (ing.optional) continue;

      if (ing.isSpirit && ing.spiritType != null) {
        final matched = _findMatchingSpirit(ing.spiritType!, availableSpirits);
        if (matched != null) {
          available.add(ing.name);
          matchedBottles[ing.spiritType!] = matched;
        } else {
          missing.add(ing.name);
        }
      } else if (ing.pantryKey != null) {
        if (inStockPantry.containsKey(ing.pantryKey)) {
          available.add(ing.name);
        } else {
          missing.add(ing.name);
        }
      } else {
        // Basic kitchen pantry staple (water, ice, etc.) or assume available
        available.add(ing.name);
      }
    }

    final isReady = missing.isEmpty;
    final isAlmostReady = missing.length == 1;

    return CocktailMatchResult(
      cocktail: cocktail,
      isReady: isReady,
      isAlmostReady: isAlmostReady,
      availableIngredients: available,
      missingIngredients: missing,
      matchedBottles: matchedBottles,
    );
  }

  static Bottle? _findMatchingSpirit(String spiritType, List<Bottle> bottles) {
    final target = spiritType.toLowerCase().trim();

    for (final b in bottles) {
      final w = b.wine;
      if (w == null) continue;

      final wineType = w.type.toLowerCase().trim();
      final wineName = w.name.toLowerCase();
      final producer = (w.producer ?? '').toLowerCase();
      final combined = '$wineName $producer $wineType';

      switch (target) {
        case 'gin':
          if (wineType == 'gin' || combined.contains('gin')) return b;
          break;
        case 'rum':
        case 'rhum':
          if (wineType == 'rum' || wineType == 'rhum' || combined.contains('rhum') || combined.contains('rum') || combined.contains('cachaça')) return b;
          break;
        case 'rum_dark':
          if (combined.contains('dark') || combined.contains('ambré') || combined.contains('brun') || combined.contains('noir') || combined.contains('vieilli') || combined.contains('spiced') || wineType == 'rum' || wineType == 'rhum') return b;
          break;
        case 'whisky':
        case 'whiskey':
        case 'bourbon':
          if (wineType == 'whisky' || wineType == 'whiskey' || wineType == 'bourbon' || combined.contains('whisky') || combined.contains('whiskey') || combined.contains('bourbon') || combined.contains('scotch') || combined.contains('rye')) return b;
          break;
        case 'whisky_peated':
          if (combined.contains('tourb') || combined.contains('islay') || combined.contains('laphroaig') || combined.contains('ardbeg') || combined.contains('talisk') || combined.contains('lagavulin') || combined.contains('peated') || wineType == 'whisky') return b;
          break;
        case 'vodka':
          if (wineType == 'vodka' || combined.contains('vodka')) return b;
          break;
        case 'tequila':
          if (wineType == 'tequila' || combined.contains('tequila')) return b;
          break;
        case 'mezcal':
          if (wineType == 'mezcal' || combined.contains('mezcal') || combined.contains('tequila')) return b;
          break;
        case 'cognac':
        case 'armagnac':
        case 'brandy':
          if (wineType == 'cognac' || wineType == 'armagnac' || wineType == 'brandy' || combined.contains('cognac') || combined.contains('armagnac') || combined.contains('brandy')) return b;
          break;
        case 'campari':
          if (combined.contains('campari') || combined.contains('bitter')) return b;
          break;
        case 'aperol':
          if (combined.contains('aperol') || combined.contains('campari')) return b;
          break;
        case 'vermouth_red':
          if (combined.contains('vermouth') && (combined.contains('rouge') || combined.contains('rosso') || combined.contains('red') || combined.contains('doux') || combined.contains('carpano') || combined.contains('martini'))) return b;
          if (wineType == 'vermouth') return b;
          break;
        case 'vermouth_dry':
        case 'vermouth_white':
          if (combined.contains('vermouth') && (combined.contains('dry') || combined.contains('sec') || combined.contains('blanc') || combined.contains('white') || combined.contains('noilly'))) return b;
          if (wineType == 'vermouth') return b;
          break;
        case 'triple_sec':
          if (combined.contains('triple sec') || combined.contains('cointreau') || combined.contains('grand marnier') || combined.contains('curaçao') || combined.contains('curacao')) return b;
          break;
        case 'liqueur_coffee':
          if (combined.contains('kahlúa') || combined.contains('kahlua') || combined.contains('tia maria') || (combined.contains('liqueur') && combined.contains('café'))) return b;
          break;
        case 'amaretto':
          if (combined.contains('amaretto') || combined.contains('disaronno')) return b;
          break;
        case 'sparkling':
        case 'champagne':
        case 'prosecco':
          if (wineType == 'sparkling' || combined.contains('champagne') || combined.contains('prosecco') || combined.contains('crémant') || combined.contains('cremant') || combined.contains('cava') || combined.contains('effervescent')) return b;
          break;
        default:
          if (wineType == target || combined.contains(target)) return b;
      }
    }
    return null;
  }
}
