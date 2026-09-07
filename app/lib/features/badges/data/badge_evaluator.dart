import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/wine.dart';
import '../../journal/domain/tasting_entry.dart';
import '../../cocktails/domain/bar_pantry_item.dart';
import '../domain/badge.dart';
import 'badge_catalog.dart';

class BadgeEvaluator {
  BadgeEvaluator._();

  static List<BadgeProgress> evaluate({
    required List<Bottle> bottles,
    required List<TastingEntry> tastings,
    List<BarPantryItem>? pantry,
  }) {
    final List<BadgeProgress> results = [];

    for (final badge in BadgeCatalog.allBadges) {
      int count = 0;

      switch (badge.id) {
        // ==========================================
        // 🏛️ PALIERS DE CAVE (STOCK & DÉGUSTATION)
        // ==========================================
        case 'milestone_first_bottle':
          count = bottles.length;
          break;

        case 'milestone_first_tasting':
          count = tastings.length;
          break;

        case 'milestone_bottles_10':
        case 'milestone_bottles_50':
        case 'milestone_bottles_100':
        case 'milestone_bottles_500':
        case 'milestone_bottles_1000':
          count = bottles.length;
          break;

        case 'milestone_tastings_5':
        case 'milestone_tastings_25':
        case 'milestone_tastings_50':
        case 'milestone_tastings_100':
        case 'milestone_tastings_250':
          count = tastings.length;
          break;

        case 'milestone_cellar_rainbow':
          final types = <String>{};
          for (final b in bottles) {
            final t = (b.wine?.type ?? '').toLowerCase();
            if (t == 'red' || t == 'rouge') types.add('red');
            if (t == 'white' || t == 'blanc') types.add('white');
            if (t == 'rose' || t == 'rosé') types.add('rose');
            if (t == 'sparkling' || t == 'bulles' || t == 'effervescent' || t == 'champagne') types.add('sparkling');
          }
          count = types.length;
          break;

        case 'milestone_grand_cru_collection':
          for (final b in bottles) {
            final w = b.wine;
            final cl = (w?.classification ?? '').toLowerCase();
            final a = (w?.appellation ?? '').toLowerCase();
            final n = (w?.name ?? '').toLowerCase();
            final isGC = cl.contains('grand cru') || cl.contains('premier cru') || cl.contains('1er cru') ||
                a.contains('grand cru') || a.contains('premier cru') || a.contains('1er cru') ||
                n.contains('grand cru') || n.contains('premier cru');
            if (isGC) count++;
          }
          break;

        // ==========================================
        // 🌍 CONTINENTS & EXPLORATION
        // ==========================================
        case 'continent_old_world':
          const oldWorld = [
            'france', 'italie', 'italy', 'espagne', 'spain', 'portugal',
            'allemagne', 'germany', 'suisse', 'switzerland', 'autriche', 'austria',
            'grèce', 'greece', 'hongrie', 'hungary', 'croatie', 'croatia', 'géorgie', 'georgia', 'royaume-uni', 'uk'
          ];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => oldWorld.any((w) => c.contains(w)),
          );
          break;

        case 'continent_new_world':
          const newWorld = [
            'usa', 'états-unis', 'etats-unis', 'united states', 'californ', 'chili', 'chile',
            'argentine', 'argentina', 'australie', 'australia', 'nouvelle-zélande', 'nouvelle-zelande',
            'new zealand', 'afrique du sud', 'south africa', 'canada', 'uruguay'
          ];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => newWorld.any((w) => c.contains(w)),
          );
          break;

        case 'continent_globe_trotter':
        case 'continent_explorer':
        case 'continent_universal':
          final countries = <String>{};
          for (final b in bottles) {
            final c = b.wine?.country.trim().toLowerCase();
            if (c != null && c.isNotEmpty) countries.add(c);
          }
          for (final t in tastings) {
            final c = t.country?.trim().toLowerCase();
            if (c != null && c.isNotEmpty) countries.add(c);
          }
          count = countries.length;
          break;

        // ==========================================
        // 🏳️ PAYS
        // ==========================================
        case 'country_france':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('france'),
          );
          break;

        case 'country_italy':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('ital'),
          );
          break;

        case 'country_spain':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('espagn') || c.contains('spain') || c.contains('españ') || c.contains('espan'),
          );
          break;

        case 'country_usa':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('usa') || c.contains('états-unis') || c.contains('etats-unis') || c.contains('californ') || c.contains('united states') || c == 'us',
          );
          break;

        case 'country_portugal':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('portugal') || r.contains('douro') || a.contains('porto'),
          );
          break;

        case 'country_germany':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('allemagne') || c.contains('germany') || c.contains('deutschland') || r.contains('mosel') || r.contains('rheingau') || r.contains('pfalz'),
          );
          break;

        case 'country_switzerland':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('suisse') || c.contains('switzerland') || c.contains('schweiz') || r.contains('valais') || r.contains('vaud') || r.contains('lavaux') || r.contains('genève') || r.contains('geneve'),
          );
          break;

        case 'country_argentina':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('argentine') || c.contains('argentina') || r.contains('mendoza') || r.contains('cafayate') || r.contains('salta'),
          );
          break;

        case 'country_chile':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('chili') || c.contains('chile') || r.contains('maipo') || r.contains('colchagua') || r.contains('casablanca'),
          );
          break;

        case 'country_australia':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('australie') || c.contains('australia') || r.contains('barossa') || r.contains('mclaren') || r.contains('margaret river'),
          );
          break;

        case 'country_new_zealand':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('nouvelle-zélande') || c.contains('nouvelle-zelande') || c.contains('new zealand') || r.contains('marlborough') || r.contains('central otago'),
          );
          break;

        case 'country_south_africa':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('afrique du sud') || c.contains('south africa') || r.contains('stellenbosch') || r.contains('swartland') || r.contains('constantia'),
          );
          break;

        case 'country_greece':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('grèce') || c.contains('grece') || c.contains('greece') || r.contains('santorin') || r.contains('santorini') || r.contains('naoussa') || r.contains('némée') || r.contains('nemee'),
          );
          break;

        case 'country_austria':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('autriche') || c.contains('austria') || c.contains('österreich') || r.contains('wachau') || r.contains('kamptal') || r.contains('burgenland'),
          );
          break;

        case 'country_georgia':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => c.contains('géorgie') || c.contains('georgie') || c.contains('georgia') || r.contains('kakhétie') || r.contains('kakheti'),
          );
          break;

        case 'country_uk':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            requireWine: true,
            predicate: (c, r, a, n, t) => c.contains('royaume-uni') || c.contains('united kingdom') || c.contains('england') || c.contains('angleterre') || r.contains('sussex') || r.contains('kent') || r.contains('hampshire'),
          );
          break;

        // ==========================================
        // 🏰 RÉGIONS
        // ==========================================
        case 'region_bourgogne':
          const bgKeywords = ['bourgogne', 'burgundy', 'chablis', 'meursault', 'nuits', 'beaune', 'macon', 'mâcon', 'beaujolais'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => bgKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'region_bordeaux':
          const bdxKeywords = ['bordeaux', 'médoc', 'medoc', 'saint-émilion', 'saint-emilion', 'pomerol', 'graves', 'pessac', 'margaux', 'pauillac', 'saint-julien', 'sauternes'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => bdxKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'region_rhone':
          const rhKeywords = ['rhône', 'rhone', 'châteauneuf', 'chateauneuf', 'côte-rôtie', 'cote-rotie', 'hermitage', 'crozes', 'gigondas', 'vacqueyras', 'saint-joseph', 'cornas'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => rhKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'region_champagne':
          // Strict: Must be true Champagne AOC, not general sparkling
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => r.contains('champagne') || a.contains('champagne') || n.contains('champagne'),
          );
          break;

        case 'region_loire':
          const loireKeywords = ['loire', 'sancerre', 'saumur', 'chinon', 'vouvray', 'muscadet', 'anjou', 'pouilly-fumé', 'pouilly-fume'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => loireKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'region_alsace':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => r.contains('alsace') || a.contains('alsace'),
          );
          break;

        case 'region_provence':
          const prvKeywords = ['provence', 'bandol', 'cassis', 'corse', 'patrimonio', 'bellet'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => prvKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'region_jura_savoie':
          const jsKeywords = ['jura', 'savoie', 'arbois', 'château-chalon', 'chateau-chalon', 'savagnin', 'mondeuse'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => jsKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'region_sud_ouest':
          const soKeywords = ['cahors', 'madiran', 'jurançon', 'jurancon', 'bergerac', 'gaillac', 'sud-ouest', 'fronton', 'iroleguy', 'irouléguy', 'monbazillac', 'pecharmant', 'pécharmant'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => soKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'region_languedoc_roussillon':
          const lrKeywords = ['languedoc', 'roussillon', 'pic saint-loup', 'pic saint loup', 'terrasses du larzac', 'collioure', 'banyuls', 'corbières', 'corbieres', 'minervois', 'faugères', 'faugeres', 'saint-chinian', 'fitou', 'limoux'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => lrKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'region_corse':
          const crKeywords = ['corse', 'patrimonio', 'ajaccio', 'calvi', 'porto-vecchio', 'sartène', 'sartene', 'figari'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => crKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'region_beaujolais':
          const bjKeywords = ['beaujolais', 'morgon', 'moulin-à-vent', 'moulin a vent', 'fleurie', 'brouilly', 'chénas', 'chenas', 'chiroubles', 'juliénas', 'julienas', 'régnié', 'regnie', 'saint-amour'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => bjKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'region_toscana':
          const tsKeywords = ['toscane', 'toscana', 'tuscany', 'chianti', 'brunello', 'montalcino', 'bolgheri', 'montepulciano', 'maremma', 'super-toscan', 'supertuscan', 'morellino'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => tsKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'region_piemonte':
          const pmKeywords = ['piémont', 'piemont', 'piemonte', 'piedmont', 'barolo', 'barbaresco', 'langhe', 'barbera', 'roero', 'gavi', 'nebbiolo d\'alba', 'dolcetto'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => pmKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'region_veneto':
          const vnKeywords = ['vénétie', 'veneto', 'valpolicella', 'amarone', 'ripasso', 'soave', 'bardolino', 'prosecco'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => vnKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'region_rioja':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => r.contains('rioja') || a.contains('rioja') || n.contains('rioja'),
          );
          break;

        case 'region_napa':
          const npKeywords = ['napa valley', 'napa', 'oakville', 'rutherford', 'stags leap', 'howell mountain', 'mount veeder', 'calistoga'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => npKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        // ==========================================
        // 🍇 CÉPAGES
        // ==========================================
        case 'grape_pinot_noir':
          const pnKeywords = ['pinot noir', 'spätburgunder', 'spatburgunder', 'bourgogne rouge', 'gevrey-chambertin', 'vosne-romanée', 'vosne-romanee', 'nuits-saint-georges', 'chambolle-musigny', 'volnay', 'pommard'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => pnKeywords.any((k) => n.contains(k) || a.contains(k)),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('pinot noir') || g.name.toLowerCase().contains('spätburgunder')),
          );
          break;

        case 'grape_cabernet':
          const csKeywords = ['cabernet sauvignon', 'pauillac', 'saint-julien', 'saint-estèphe', 'saint-estephe', 'margaux', 'graves', 'pessac-léognan', 'pessac-leognan'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => csKeywords.any((k) => n.contains(k) || a.contains(k)),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('cabernet sauvignon')),
          );
          break;

        case 'grape_chardonnay':
          const cdKeywords = ['chardonnay', 'chablis', 'meursault', 'puligny-montrachet', 'chassagne-montrachet', 'corton-charlemagne', 'pouilly-fuissé', 'pouilly-fuisse'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => cdKeywords.any((k) => n.contains(k) || a.contains(k)),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('chardonnay')),
          );
          break;

        case 'grape_syrah':
          const syKeywords = ['syrah', 'shiraz', 'cornas', 'côte-rôtie', 'cote-rotie', 'hermitage', 'crozes-hermitage', 'saint-joseph'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => syKeywords.any((k) => n.contains(k) || a.contains(k)),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('syrah') || g.name.toLowerCase().contains('shiraz')),
          );
          break;

        case 'grape_chenin':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => n.contains('chenin') || a.contains('vouvray') || a.contains('saumur blanc') || a.contains('savennières') || a.contains('coteaux du layon'),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('chenin')),
          );
          break;

        case 'grape_riesling':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => n.contains('riesling') || a.contains('riesling'),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('riesling')),
          );
          break;

        case 'grape_nebbiolo':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => n.contains('nebbiolo') || a.contains('barolo') || a.contains('barbaresco') || a.contains('roero'),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('nebbiolo')),
          );
          break;

        case 'grape_merlot':
          const merlotKeywords = ['merlot', 'pomerol', 'saint-émilion', 'saint-emilion', 'fronsac', 'lalande-de-pomerol'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => merlotKeywords.any((k) => n.contains(k) || a.contains(k)),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('merlot')),
          );
          break;

        case 'grape_sauvignon_blanc':
          const sbKeywords = ['sauvignon', 'sancerre', 'pouilly-fumé', 'pouilly-fume', 'menetou-salon'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => sbKeywords.any((k) => n.contains(k) || a.contains(k)),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('sauvignon')),
          );
          break;

        case 'grape_grenache':
          const grKeywords = ['grenache', 'garnacha', 'châteauneuf', 'chateauneuf', 'gigondas', 'vacqueyras', 'cannonau'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => grKeywords.any((k) => n.contains(k) || a.contains(k)),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('grenache') || g.name.toLowerCase().contains('garnacha')),
          );
          break;

        case 'grape_cabernet_franc':
          const cfKeywords = ['cabernet franc', 'chinon', 'bourgueil', 'saumur-champigny', 'saint-nicolas'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => cfKeywords.any((k) => n.contains(k) || a.contains(k)),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('cabernet franc')),
          );
          break;

        case 'grape_sangiovese':
          const sgKeywords = ['sangiovese', 'chianti', 'brunello', 'rosso di montalcino', 'morellino', 'vino nobile'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => sgKeywords.any((k) => n.contains(k) || a.contains(k)),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('sangiovese')),
          );
          break;

        case 'grape_malbec':
          const mbKeywords = ['malbec', 'cahors'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            requireWine: true,
            predicate: (c, r, a, n, t) {
              if (mbKeywords.any((k) => n.contains(k) || a.contains(k))) return true;
              final words = '$n $a'.split(RegExp(r'[^a-zA-ZÀ-ÿ0-9]'));
              return words.contains('cot') || words.contains('côt');
            },
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('malbec') || g.name.toLowerCase() == 'côt' || g.name.toLowerCase() == 'cot'),
          );
          break;

        case 'grape_tempranillo':
          const tpKeywords = ['tempranillo', 'tinta del pais', 'tinto fino', 'cencibel', 'ull de llebre', 'rioja', 'ribera del duero', 'toro'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => tpKeywords.any((k) => n.contains(k) || a.contains(k)),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('tempranillo')),
          );
          break;

        case 'grape_gamay':
          const gmKeywords = ['gamay', 'beaujolais', 'morgon', 'fleurie', 'brouilly', 'moulin-à-vent', 'moulin a vent', 'chénas', 'chenas', 'chiroubles', 'juliénas', 'julienas', 'régnié', 'regnie', 'saint-amour'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => gmKeywords.any((k) => n.contains(k) || a.contains(k)),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('gamay')),
          );
          break;

        case 'grape_viognier':
          const vgKeywords = ['viognier', 'condrieu', 'château-grillet', 'chateau-grillet'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => vgKeywords.any((k) => n.contains(k) || a.contains(k)),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('viognier')),
          );
          break;

        case 'grape_gewurztraminer':
          const gwKeywords = ['gewurztraminer', 'gewürztraminer'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => gwKeywords.any((k) => n.contains(k) || a.contains(k)),
            winePredicate: (w) => (w?.grapes ?? []).any((g) => g.name.toLowerCase().contains('gewurz')),
          );
          break;

        // ==========================================
        // ⏳ GARDE & APOGÉE
        // ==========================================
        case 'aging_peak':
          // Must be an actual tasting consumed within peak, NOT cellar bottles in stock!
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            final hasPeakNotes = notes.contains('apogée') || notes.contains('apogee') || notes.contains('au sommet') || notes.contains('à point') || notes.contains('a point') || notes.contains('pleine maturité');
            if (hasPeakNotes) {
              count++;
              continue;
            }
            // Check if bottle or wine has peak window
            final matchingBottle = bottles.where((b) => (t.bottleId != null && b.id == t.bottleId) || b.wineId == t.wineId).firstOrNull;
            final w = matchingBottle?.wine;
            if (w != null && w.peakStart != null && w.peakEnd != null) {
              final consumedYear = t.consumedAt.year;
              if (consumedYear >= w.peakStart! && consumedYear <= w.peakEnd!) {
                count++;
              }
            }
          }
          break;

        case 'aging_venerable':
          final currentYear = DateTime.now().year;
          for (final b in bottles) {
            final vintage = b.wine?.vintage;
            if (vintage != null && vintage > 0 && (currentYear - vintage) >= 25) {
              count++;
            }
          }
          for (final t in tastings) {
            final vintage = t.vintage;
            if (vintage != null && vintage > 0 && (currentYear - vintage) >= 25) {
              count++;
            }
          }
          break;

        case 'aging_infanticide':
          // Must be an actual tasting of a wine drunk too young, NOT young bottles aging in cellar!
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            final hasInfanticideNote = notes.contains('trop jeune') || notes.contains('infanticide') || notes.contains('fermé') || notes.contains('tanins serrés') || notes.contains('à attendre') || notes.contains('a attendre');
            if (hasInfanticideNote) {
              count++;
              continue;
            }
            final matchingBottle = bottles.where((b) => (t.bottleId != null && b.id == t.bottleId) || b.wineId == t.wineId).firstOrNull;
            final w = matchingBottle?.wine;
            if (w != null && w.peakStart != null) {
              if ((w.peakStart! - t.consumedAt.year) >= 5) {
                count++;
              }
            }
          }
          break;

        // ==========================================
        // 🍸 MIXOLOGIE & COCKTAILS
        // ==========================================
        case 'cocktail_apprentice':
          for (final t in tastings) {
            final wType = (t.wineType ?? '').toLowerCase();
            final name = (t.wineName ?? '').toLowerCase();
            final app = (t.appellation ?? '').toLowerCase();
            if (wType == 'cocktail' || app == 'cocktail' || name.startsWith('cocktail') || _isKnownCocktail(name)) {
              count++;
            }
          }
          break;

        case 'cocktail_master':
        case 'cocktail_expert':
        case 'cocktail_legend':
          final cocktailNames = <String>{};
          for (final t in tastings) {
            final wType = (t.wineType ?? '').toLowerCase();
            final name = (t.wineName ?? '').toLowerCase();
            final app = (t.appellation ?? '').toLowerCase();
            if (wType == 'cocktail' || app == 'cocktail' || _isKnownCocktail(name)) {
              cocktailNames.add(t.wineName?.toLowerCase().trim() ?? t.id);
            }
          }
          count = cocktailNames.length;
          break;

        case 'cocktail_pantry':
          if (pantry != null) {
            count = pantry.where((i) => i.inStock).length;
          }
          break;

        case 'cocktail_diy_shaker':
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            final occ = (t.occasion ?? '').toLowerCase();
            if (notes.contains('shaker maison') || notes.contains('diy shaker') || notes.contains('bocal') || notes.contains('système d') || occ.contains('diy shaker') || occ.contains('shaker maison')) {
              count++;
            }
          }
          break;

        case 'cocktail_spritz':
          for (final t in tastings) {
            final name = (t.wineName ?? '').toLowerCase();
            final notes = (t.tastingNotes ?? '').toLowerCase();
            if (name.contains('spritz') || name.contains('negroni') || name.contains('americano') || notes.contains('spritz') || notes.contains('negroni')) {
              count++;
            }
          }
          break;

        // ==========================================
        // 🥃 SPIRITUEUX & ALCOOLS FORTS
        // ==========================================
        case 'spirit_whisky':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            requireWine: false,
            predicate: (c, r, a, n, t) => t.contains('whisk') || t.contains('bourbon') || t.contains('scotch') || n.contains('whisky') || n.contains('whiskey'),
          );
          break;

        case 'spirit_gin':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            requireWine: false,
            predicate: (c, r, a, n, t) => t.contains('gin') || n.contains('gin'),
          );
          break;

        case 'spirit_rhum':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            requireWine: false,
            predicate: (c, r, a, n, t) => t.contains('rhum') || t.contains('rum') || t.contains('cachaça') || n.contains('rhum'),
          );
          break;

        case 'spirit_brandy':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            requireWine: false,
            predicate: (c, r, a, n, t) => t.contains('cognac') || t.contains('armagnac') || t.contains('brandy') || n.contains('cognac'),
          );
          break;

        case 'spirit_tequila_mezcal':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            requireWine: false,
            predicate: (c, r, a, n, t) => t.contains('tequila') || t.contains('mezcal') || n.contains('tequila') || n.contains('mezcal'),
          );
          break;

        case 'spirit_vodka':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            requireWine: false,
            predicate: (c, r, a, n, t) => t.contains('vodka') || n.contains('vodka'),
          );
          break;

        case 'spirit_liqueurs':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            requireWine: false,
            predicate: (c, r, a, n, t) => t.contains('liqueur') || t.contains('amaro') || t.contains('pastis') || n.contains('chartreuse') || n.contains('amaro') || n.contains('pastis') || n.contains('génépi') || n.contains('genepi'),
          );
          break;

        // ==========================================
        // 💩 BADGES LOOSER & AUTODÉRISION
        // ==========================================
        case 'looser_piquette':
          for (final b in bottles) {
            if (b.purchasePrice != null && b.purchasePrice! > 0 && b.purchasePrice! < 3.0) {
              count++;
            }
          }
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            if (notes.contains('piquette') || notes.contains('villageoise') || notes.contains('2€') || notes.contains('2,50')) {
              count++;
            }
          }
          break;

        case 'looser_past_peak':
          count += bottles.where((b) => b.wine?.windowStatus == DrinkWindowStatus.pastPeak).length;
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            final hasPastNote = notes.contains('passé') || notes.contains('passe') || notes.contains('vinaigre') || notes.contains('mort') || notes.contains('oxydé') || notes.contains('madérisé');
            if (hasPastNote) {
              count++;
              continue;
            }
            final matchingBottle = bottles.where((b) => (t.bottleId != null && b.id == t.bottleId) || b.wineId == t.wineId).firstOrNull;
            final w = matchingBottle?.wine;
            if (w != null && w.peakEnd != null && t.consumedAt.year > w.peakEnd! + 3) {
              count++;
            }
          }
          break;

        case 'looser_masochist':
          for (final t in tastings) {
            final rawR = t.rating;
            final displayR = t.displayRating;
            final isSevereRating = (rawR != null && rawR <= 2.0) || (displayR != null && displayR <= 3.0);
            final notes = (t.tastingNotes ?? '').toLowerCase();
            final isHorribleNote = notes.contains('imbuvable') ||
                notes.contains('horrible') ||
                notes.contains('dégoûtant') ||
                notes.contains('degoutant') ||
                notes.contains('affreux');
            if (isSevereRating || isHorribleNote) {
              count++;
            }
          }
          break;

        case 'looser_bouchonne':
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            if (notes.contains('bouchon') || notes.contains('tca')) {
              count++;
            }
          }
          break;

        case 'looser_solo':
          for (final t in tastings) {
            if (t.coTasters.isEmpty) {
              count++;
            }
          }
          break;

        case 'looser_poussiere':
          final threeYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 3));
          for (final b in bottles) {
            if (b.createdAt.isBefore(threeYearsAgo)) {
              count++;
            }
          }
          break;

        case 'looser_tache_etiquette':
          for (final b in bottles) {
            final notes = (b.notes ?? '').toLowerCase();
            if (notes.contains('tache') || notes.contains('coulure') || notes.contains('étiquette abîmée') || notes.contains('etiquette abimee')) {
              count++;
            }
          }
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            if (notes.contains('tache') || notes.contains('coulure') || notes.contains('nappe') || notes.contains('goutte')) {
              count++;
            }
          }
          break;

        // ==========================================
        // 🔬 LE CHATMELIER SAVANT (Histoire & Sciences)
        // ==========================================
        case 'savant_pasteur':
          final pasteurKeywords = [
            'vin nature',
            'vin naturel',
            'vins naturels',
            'sans soufre',
            'sans sulfite',
            'levures indigènes',
            'levure indigène',
            'fermentation spontanée',
            'biodynamie',
            'biodynamique',
            'demeter',
            'biodyvin',
            'louis pasteur',
            'pasteur',
          ];
          for (final b in bottles) {
            if (!_isWine(b.wine?.type ?? '', b.wine?.name ?? '', b.wine?.classification ?? '')) continue;
            final classif = (b.wine?.classification ?? '').toLowerCase();
            final notes = (b.notes ?? '').toLowerCase();
            final tn = (b.wine?.tastingNotes ?? '').toLowerCase();
            if (pasteurKeywords.any((k) => classif.contains(k) || notes.contains(k) || tn.contains(k))) {
              count++;
            }
          }
          for (final t in tastings) {
            if (!_isWine(t.wineType ?? '', t.wineName ?? '')) continue;
            final notes = (t.tastingNotes ?? '').toLowerCase();
            if (pasteurKeywords.any((k) => notes.contains(k))) {
              count++;
            }
          }
          break;

        case 'savant_cistercien':
          const bgMarkers = ['bourgogne', 'chablis', 'vougeot', 'cîteaux', 'citeaux', 'meursault', 'côte de nuits', 'cote de nuits', 'côte de beaune', 'cote de beaune', 'corton'];
          for (final b in bottles) {
            final w = b.wine;
            final r = (w?.region ?? '').toLowerCase();
            final a = (w?.appellation ?? '').toLowerCase();
            final n = (w?.name ?? '').toLowerCase();
            final cl = (w?.classification ?? '').toLowerCase();
            final inBourgogne = bgMarkers.any((k) => r.contains(k) || a.contains(k) || n.contains(k));
            final isClimat = cl.contains('grand cru') || cl.contains('premier cru') || cl.contains('1er cru') || cl.contains('climat') || cl.contains('cistercien') || a.contains('grand cru') || a.contains('premier cru') || a.contains('1er cru') || n.contains('grand cru') || n.contains('premier cru');
            if (inBourgogne && isClimat) {
              count++;
            }
          }
          for (final t in tastings) {
            final r = (t.region ?? '').toLowerCase();
            final a = (t.appellation ?? '').toLowerCase();
            final n = (t.wineName ?? '').toLowerCase();
            final inBourgogne = bgMarkers.any((k) => r.contains(k) || a.contains(k) || n.contains(k));
            final isClimat = a.contains('grand cru') || a.contains('premier cru') || a.contains('1er cru') || a.contains('climat') || n.contains('grand cru') || n.contains('premier cru') || n.contains('climat');
            if (inBourgogne && isClimat) {
              count++;
            }
          }
          break;

        case 'savant_phylloxera':
          // Require at least 5 authentic vitis vinifera wine bottles (exclude spirits)
          final wineBottles = bottles.where((b) {
            return _isWine(b.wine?.type ?? '', b.wine?.name ?? '', b.wine?.classification ?? '');
          }).toList();
          count = wineBottles.length;
          break;

        case 'savant_napoleon':
          const napKeywords = ['chambertin', 'napoléon', 'napoleon'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => napKeywords.any((k) => n.contains(k) || a.contains(k) || r.contains(k)),
          );
          break;

        case 'savant_volcan':
          const volKeywords = [
            'etna',
            'volcan',
            'volcanique',
            'canaries',
            'canary',
            'lanzarote',
            'santorin',
            'santorini',
            'basalte',
            'côtes du forez',
            'cotes du forez',
            'côtes d\'auvergne',
            'cotes d\'auvergne',
            'campi flegrei',
            'vesuvio',
          ];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => volKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
            winePredicate: (w) {
              final tn = (w?.tastingNotes ?? '').toLowerCase();
              return volKeywords.any((k) => tn.contains(k));
            },
          );
          break;

        case 'savant_biodynamie':
          for (final b in bottles) {
            final classif = (b.wine?.classification ?? '').toLowerCase();
            final notes = (b.notes ?? '').toLowerCase();
            if (classif.contains('demeter') || classif.contains('biodyvin') || classif.contains('biodynami') || notes.contains('biodynami')) {
              count++;
            }
          }
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            if (notes.contains('demeter') || notes.contains('biodyvin') || notes.contains('biodynami')) {
              count++;
            }
          }
          break;

        case 'savant_amphore':
          const amphKeywords = [
            'amphore',
            'qvevri',
            'kvevri',
            'vin orange',
            'orange wine',
            'amber wine',
            'macération pelliculaire',
            'maceration pelliculaire',
            'jarre de terre',
            'jarre en terre',
          ];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) {
              if (t == 'orange') return true;
              if (amphKeywords.any((k) => a.contains(k) || n.contains(k))) return true;
              if ((c.contains('géorgie') || c.contains('georgia')) && (n.contains('qvevri') || a.contains('qvevri'))) {
                return true;
              }
              return false;
            },
            winePredicate: (w) {
              if (w == null) return false;
              if (w.type.toLowerCase() == 'orange') return true;
              final tn = (w.tastingNotes ?? '').toLowerCase();
              final classif = (w.classification ?? '').toLowerCase();
              return amphKeywords.any((k) => tn.contains(k) || classif.contains(k));
            },
          );
          break;

        case 'savant_botrytis':
          const botKeywords = [
            'botrytis',
            'sauternes',
            'tokaj',
            'tokaji',
            'grains nobles',
            'liquoreux',
            'pourriture noble',
            'barsac',
            'monbazillac',
            'trockenbeerenauslese',
            'beerenauslese',
          ];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => botKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
            winePredicate: (w) {
              final tn = (w?.tastingNotes ?? '').toLowerCase();
              return botKeywords.any((k) => tn.contains(k));
            },
          );
          break;

        case 'savant_maceration_carbonique':
          const carbKeywords = [
            'carbonique',
            'semi-carbonique',
            'macération carbonique',
            'maceration carbonique',
            'beaujolais nouveau',
            'primeur',
            'intracellulaire',
          ];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) {
              if (carbKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k))) return true;
              if (r.contains('beaujolais') || a.contains('morgon') || a.contains('fleurie') || a.contains('brouilly') || a.contains('juliénas') || a.contains('moulin-à-vent') || a.contains('chénas') || a.contains('chiroubles') || a.contains('régnié') || a.contains('saint-amour')) {
                return true;
              }
              return false;
            },
            winePredicate: (w) {
              if (w == null) return false;
              final r = (w.region ?? '').toLowerCase();
              final a = (w.appellation ?? '').toLowerCase();
              final n = w.name.toLowerCase();
              final tn = (w.tastingNotes ?? '').toLowerCase();
              if (carbKeywords.any((k) => tn.contains(k) || n.contains(k) || a.contains(k) || r.contains(k))) return true;
              if (r.contains('beaujolais') || a.contains('morgon') || a.contains('fleurie') || a.contains('brouilly')) return true;
              return false;
            },
          );
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            if (notes.contains('banane') || notes.contains('bonbon anglais')) {
              count++;
            }
          }
          break;

        case 'savant_kimmeridgien':
          const kimKeywords = ['kimméridg', 'kimmeridg', 'chablis'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) {
              if (kimKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k))) return true;
              if (a.contains('sancerre') && (n.contains('terres blanches') || r.contains('terres blanches'))) return true;
              return false;
            },
            winePredicate: (w) {
              final tn = (w?.tastingNotes ?? '').toLowerCase();
              return tn.contains('kimméridgien') || tn.contains('kimmeridgien');
            },
          );
          break;

        case 'savant_jefferson':
          const jeffKeywords = ['hermitage', 'yquem', 'montepulciano', 'haut-brion', 'château haut-brion', 'chateau haut-brion'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => jeffKeywords.any((k) => n.contains(k) || a.contains(k)),
          );
          break;

        case 'savant_schiste':
          const schKeywords = ['priorat', 'côte-rôtie', 'cote-rotie', 'collioure', 'banyuls', 'faugères', 'faugeres', 'douro', 'schiste'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => schKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
            winePredicate: (w) {
              final tn = (w?.tastingNotes ?? '').toLowerCase();
              return tn.contains('schiste');
            },
          );
          break;

        case 'savant_vents':
          const ventKeywords = ['châteauneuf', 'chateauneuf', 'gigondas', 'vacqueyras', 'bandol', 'côtes de provence', 'cotes de provence', 'ventoux', 'mistral', 'tramontane'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => ventKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'savant_alienor':
          const alKeywords = ['bordeaux', 'graves', 'médoc', 'medoc', 'pessac', 'clairet', 'aquitaine'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => alKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
          );
          break;

        case 'savant_fleur_voile':
          const voileKeywords = ['vin jaune', 'château-chalon', 'chateau-chalon', 'fino', 'manzanilla', 'jerez', 'xérès', 'xeres', 'voile de levure', 'savagnin sous voile'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            requireWine: true,
            predicate: (c, r, a, n, t) => voileKeywords.any((k) => r.contains(k) || a.contains(k) || n.contains(k)),
            winePredicate: (w) {
              final tn = (w?.tastingNotes ?? '').toLowerCase();
              return tn.contains('sous voile') || tn.contains('voile de levure') || tn.contains('élevage sous voile') || tn.contains('sotolon') || (tn.contains('oxydatif') && (w?.type == 'white' || w?.type == 'fortified'));
            },
          );
          break;
      }

      final isUnlocked = count >= badge.requiredCount;
      results.add(BadgeProgress(
        badge: badge,
        currentCount: count,
        isUnlocked: isUnlocked,
        unlockedAt: isUnlocked ? DateTime.now() : null,
      ));
    }

    // Sort: Unlocked first, then by progress fraction descending
    results.sort((a, b) {
      if (a.isUnlocked != b.isUnlocked) {
        return a.isUnlocked ? -1 : 1;
      }
      return b.progressFraction.compareTo(a.progressFraction);
    });

    return results;
  }

  static bool _isKnownCocktail(String name) {
    const list = [
      'mojito', 'margarita', 'negroni', 'old fashioned', 'daiquiri', 'martini',
      'spritz', 'cosmopolitan', 'whiskey sour', 'whisky sour', 'pisco sour',
      'moscow mule', 'gin tonic', 'gin fizz', 'manhattan', 'bloody mary',
      'piña colada', 'pina colada', 'cuba libre', 'mai tai', 'caipirinha',
      'bellini', 'french 75', 'espresso martini', 'sazerac', 'sidecar', 'boulevardier'
    ];
    return list.any((c) => name.contains(c));
  }

  static bool _isWine(String type, String name, [String classification = '']) {
    final t = type.toLowerCase().trim();
    const nonWineTypes = {
      'gin', 'vodka', 'whisky', 'whiskey', 'scotch', 'bourbon', 'spirit', 'spirits',
      'spiritueux', 'liqueur', 'liqueurs', 'rhum', 'rum', 'pastis', 'tequila',
      'mezcal', 'brandy', 'cognac', 'armagnac', 'calvados', 'beer', 'biere', 'bière',
      'cider', 'cidre', 'cocktail', 'cocktails'
    };
    if (nonWineTypes.contains(t)) return false;

    final n = name.toLowerCase();
    final cl = classification.toLowerCase();
    const spiritIndicators = [
      'gin', 'whisky', 'whiskey', 'vodka', 'pisco', 'pastis', 'liqueur',
      'crème de', 'creme de', 'eau de vie', 'eau-de-vie', 'aguardente',
      'amaretto', 'rosolio', 'genépi', 'genepi'
    ];
    for (final ind in spiritIndicators) {
      if (n.contains(ind) || cl.contains(ind)) {
        return false;
      }
    }
    return true;
  }

  static int _countMatching({
    required List<Bottle> bottles,
    required List<TastingEntry> tastings,
    required bool Function(String country, String region, String appellation, String name, String type) predicate,
    bool Function(Wine? wine)? winePredicate,
    bool requireWine = true,
  }) {
    int count = 0;
    final matchedWineIds = <String>{};
    final matchedWineNames = <String>{};

    for (final b in bottles) {
      final w = b.wine;
      final t = (w?.type ?? '').toLowerCase();
      final n = (w?.name ?? '').toLowerCase();
      final cl = (w?.classification ?? '').toLowerCase();
      if (requireWine && !_isWine(t, n, cl)) continue;

      final c = (w?.country ?? '').toLowerCase();
      final r = (w?.region ?? '').toLowerCase();
      final a = (w?.appellation ?? '').toLowerCase();
      if (predicate(c, r, a, n, t) || (winePredicate != null && winePredicate(w))) {
        count++;
        if (b.wineId.isNotEmpty) matchedWineIds.add(b.wineId);
        if (n.isNotEmpty) matchedWineNames.add(n);
      }
    }
    for (final te in tastings) {
      final t = (te.wineType ?? '').toLowerCase();
      final n = (te.wineName ?? '').toLowerCase();
      if (requireWine && !_isWine(t, n)) continue;

      // Avoid counting the exact same wine twice if it was already matched in bottles
      if (te.wineId.isNotEmpty && matchedWineIds.contains(te.wineId)) continue;
      if (n.isNotEmpty && matchedWineNames.contains(n)) continue;

      final c = (te.country ?? '').toLowerCase();
      final r = (te.region ?? '').toLowerCase();
      final a = (te.appellation ?? '').toLowerCase();
      if (predicate(c, r, a, n, t)) {
        count++;
        if (te.wineId.isNotEmpty) matchedWineIds.add(te.wineId);
        if (n.isNotEmpty) matchedWineNames.add(n);
      }
    }
    return count;
  }
}
