import '../../cellar/domain/bottle.dart';
import 'bar_pantry_item.dart';
import 'cocktail.dart';

class CocktailMatchResult {
  final Cocktail cocktail;
  final bool isReady;
  final bool isAlmostReady;
  final List<String> availableIngredients;
  final List<String> missingIngredients;
  /// Maps ingredient spiritType -> ALL matching bottles in the user's cellar
  final Map<String, List<Bottle>> matchedBottles;

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

/// Mixer equivalence groups: if a recipe asks for 'tonic', any of these pantry keys satisfy it.
const Map<String, Set<String>> _mixerEquivalences = {
  'tonic': {
    'tonic', 'mediterranean_tonic',
    'ft_elderflower_tonic', 'ft_light_tonic', 'ft_aromatic_tonic',
    'ft_clementine_tonic', 'ft_rhubarb_tonic', 'ft_cucumber_tonic',
  },
  'ginger_beer': {'ginger_beer', 'ft_ginger_beer'},
  'ginger_ale': {'ginger_ale', 'ft_ginger_ale'},
  'soda_water': {'soda_water', 'ft_soda_water'},
  'cola': {'cola', 'ft_cola'},
  'lemonade': {'lemonade', 'ft_lemonade'},
};

class CocktailMatcher {
  static CocktailMatchResult matchCocktail({
    required Cocktail cocktail,
    required List<Bottle> cellarBottles,
    required List<BarPantryItem> pantryItems,
  }) {
    final availableSpirits = cellarBottles.where((b) => b.quantity > 0 && b.fillLevel > 0).toList();
    final inStockPantry = {for (final item in pantryItems.where((i) => i.inStock)) item.id: item};

    final List<String> available = [];
    final List<String> missing = [];
    final Map<String, List<Bottle>> matchedBottles = {};

    for (final ing in cocktail.ingredients) {
      if (ing.optional) continue;

      if (ing.isSpirit && ing.spiritType != null) {
        final allMatched = _findAllMatchingSpirits(ing.spiritType!, availableSpirits);
        if (allMatched.isNotEmpty) {
          available.add(ing.name);
          matchedBottles[ing.spiritType!] = allMatched;
        } else {
          missing.add(ing.name);
        }
      } else if (ing.pantryKey != null) {
        if (_isPantryIngredientAvailable(ing.pantryKey!, inStockPantry)) {
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

  /// Check if a pantry ingredient is available, considering mixer equivalences.
  static bool _isPantryIngredientAvailable(String pantryKey, Map<String, BarPantryItem> inStockPantry) {
    if (inStockPantry.containsKey(pantryKey)) return true;

    for (final entry in _mixerEquivalences.entries) {
      if (entry.value.contains(pantryKey)) {
        for (final alt in entry.value) {
          if (inStockPantry.containsKey(alt)) return true;
        }
      }
    }

    return false;
  }

  /// Returns ALL bottles matching a given spirit type, sorted by fill level descending.
  static List<Bottle> _findAllMatchingSpirits(String spiritType, List<Bottle> bottles) {
    final target = spiritType.toLowerCase().trim();
    final List<Bottle> matches = [];

    for (final b in bottles) {
      final w = b.wine;
      if (w == null) continue;

      final wineType = w.type.toLowerCase().trim();
      final wineName = w.name.toLowerCase();
      final producer = (w.producer ?? '').toLowerCase();
      final combined = '$wineName $producer $wineType';

      bool isMatch = false;

      switch (target) {
        case 'gin':
          isMatch = wineType == 'gin' || combined.contains('gin');
          break;
        case 'rum':
        case 'rhum':
          isMatch = wineType == 'rum' || wineType == 'rhum' || combined.contains('rhum') || combined.contains('rum') || combined.contains('cachaça');
          break;
        case 'rum_dark':
          isMatch = combined.contains('dark') || combined.contains('ambré') || combined.contains('brun') || combined.contains('noir') || combined.contains('vieilli') || combined.contains('spiced') || wineType == 'rum' || wineType == 'rhum';
          break;
        case 'whisky':
        case 'whiskey':
        case 'bourbon':
          isMatch = wineType == 'whisky' || wineType == 'whiskey' || wineType == 'bourbon' || combined.contains('whisky') || combined.contains('whiskey') || combined.contains('bourbon') || combined.contains('scotch') || combined.contains('rye');
          break;
        case 'whisky_peated':
          isMatch = combined.contains('tourb') || combined.contains('islay') || combined.contains('laphroaig') || combined.contains('ardbeg') || combined.contains('talisk') || combined.contains('lagavulin') || combined.contains('peated') || wineType == 'whisky';
          break;
        case 'vodka':
          isMatch = wineType == 'vodka' || combined.contains('vodka');
          break;
        case 'tequila':
          isMatch = wineType == 'tequila' || combined.contains('tequila');
          break;
        case 'mezcal':
          isMatch = wineType == 'mezcal' || combined.contains('mezcal') || combined.contains('tequila');
          break;
        case 'cognac':
        case 'armagnac':
        case 'brandy':
          isMatch = wineType == 'cognac' || wineType == 'armagnac' || wineType == 'brandy' || combined.contains('cognac') || combined.contains('armagnac') || combined.contains('brandy');
          break;
        case 'campari':
          isMatch = combined.contains('campari') || combined.contains('bitter');
          break;
        case 'aperol':
          isMatch = combined.contains('aperol') || combined.contains('campari');
          break;
        case 'vermouth_red':
          isMatch = (combined.contains('vermouth') && (combined.contains('rouge') || combined.contains('rosso') || combined.contains('red') || combined.contains('doux') || combined.contains('carpano') || combined.contains('martini'))) || wineType == 'vermouth';
          break;
        case 'vermouth_dry':
        case 'vermouth_white':
          isMatch = (combined.contains('vermouth') && (combined.contains('dry') || combined.contains('sec') || combined.contains('blanc') || combined.contains('white') || combined.contains('noilly'))) || wineType == 'vermouth';
          break;
        case 'triple_sec':
          isMatch = combined.contains('triple sec') || combined.contains('cointreau') || combined.contains('grand marnier') || combined.contains('curaçao') || combined.contains('curacao');
          break;
        case 'benedictine':
        case 'bénédictine':
          isMatch = combined.contains('benedictine') || combined.contains('bénédictine');
          break;
        case 'chartreuse':
        case 'chartreuse_green':
        case 'chartreuse_yellow':
          isMatch = combined.contains('chartreuse');
          break;
        case 'maraschino':
        case 'marasquin':
          isMatch = combined.contains('marasquin') || combined.contains('maraschino') || combined.contains('luxardo');
          break;
        case 'cherry_brandy':
        case 'cherry_liqueur':
          isMatch = combined.contains('cherry') || combined.contains('cerise') || combined.contains('guignolet') || combined.contains('heering');
          break;
        case 'liqueur_coffee':
          isMatch = combined.contains('kahlúa') || combined.contains('kahlua') || combined.contains('tia maria') || (combined.contains('liqueur') && combined.contains('café'));
          break;
        case 'amaretto':
          isMatch = combined.contains('amaretto') || combined.contains('disaronno');
          break;
        case 'sparkling':
        case 'champagne':
        case 'prosecco':
          isMatch = wineType == 'sparkling' || combined.contains('champagne') || combined.contains('prosecco') || combined.contains('crémant') || combined.contains('cremant') || combined.contains('cava') || combined.contains('effervescent');
          break;
        default:
          isMatch = wineType == target || combined.contains(target);
      }

      if (isMatch) {
        matches.add(b);
      }
    }

    // Sort by fill level descending (fullest bottles first)
    matches.sort((a, b) => b.fillLevel.compareTo(a.fillLevel));
    return matches;
  }
}

