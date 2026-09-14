import '../../cellar/domain/bottle.dart';
import '../../cellar/domain/wine.dart';
import '../../journal/domain/tasting_entry.dart';
import '../../cocktails/domain/bar_pantry_item.dart';
import '../domain/badge.dart';
import 'badge_catalog.dart';

class BadgeEvaluator {
  BadgeEvaluator._();

  static List<ContributingItem>? _activeContributing;

  static ContributingItem _bottleToItem(Bottle b) {
    final w = b.wine;
    return ContributingItem(
      id: b.id,
      name: (w?.name != null && w!.name.isNotEmpty) ? w.name : 'Flacon',
      producer: w?.producer,
      vintage: w?.vintage,
      type: w?.type,
      region: w?.region,
      appellation: w?.appellation,
      imageUrl: w?.imageUrl ?? b.photoUrl,
      isTasting: false,
    );
  }

  static ContributingItem _tastingToItem(TastingEntry te) {
    return ContributingItem(
      id: te.id,
      name: (te.wineName != null && te.wineName!.isNotEmpty) ? te.wineName! : 'Dégustation',
      vintage: te.vintage,
      type: te.wineType,
      region: te.region,
      appellation: te.appellation,
      imageUrl: te.photoUrl,
      isTasting: true,
      rating: te.rating,
    );
  }

  static List<BadgeProgress> evaluate({
    required List<Bottle> bottles,
    required List<TastingEntry> tastings,
    List<BarPantryItem>? pantry,
    bool isLatin = false,
  }) {
    final List<BadgeProgress> results = [];

    for (final badge in BadgeCatalog.allBadges) {
      int count = 0;
      final List<ContributingItem> contributing = [];
      _activeContributing = contributing;

      switch (badge.id) {
        // ==========================================
        // 🏛️ PALIERS DE CAVE (STOCK & DÉGUSTATION)
        // ==========================================
        case 'milestone_first_bottle':
        case 'milestone_bottles_10':
        case 'milestone_bottles_50':
        case 'milestone_bottles_100':
        case 'milestone_bottles_500':
        case 'milestone_bottles_1000':
          count = bottles.length;
          for (final b in bottles) {
            contributing.add(_bottleToItem(b));
          }
          break;

        case 'milestone_first_tasting':
        case 'milestone_tastings_5':
        case 'milestone_tastings_25':
        case 'milestone_tastings_50':
        case 'milestone_tastings_100':
        case 'milestone_tastings_250':
          count = tastings.length;
          for (final t in tastings) {
            contributing.add(_tastingToItem(t));
          }
          break;

        case 'milestone_cellar_rainbow':
          final types = <String>{};
          for (final b in bottles) {
            final t = (b.wine?.type ?? '').toLowerCase();
            String? detected;
            if (t == 'red' || t == 'rouge') detected = 'red';
            if (t == 'white' || t == 'blanc') detected = 'white';
            if (t == 'rose' || t == 'rosé') detected = 'rose';
            if (t == 'sparkling' || t == 'bulles' || t == 'effervescent' || t == 'champagne') detected = 'sparkling';
            if (detected != null && !types.contains(detected)) {
              types.add(detected);
              contributing.add(_bottleToItem(b));
            }
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
            if (isGC) {
              count++;
              contributing.add(_bottleToItem(b));
            }
          }
          break;

        // ==========================================
        // 🌍 CONTINENTS & EXPLORATION
        // ==========================================
        case 'continent_old_world':
          const oldWorld = [
            'france', 'fr', 'italie', 'italy', 'italia', 'it', 'espagne', 'spain', 'espana', 'es',
            'portugal', 'pt', 'allemagne', 'germany', 'deutschland', 'de', 'suisse', 'switzerland', 'schweiz', 'ch',
            'autriche', 'austria', 'osterreich', 'at', 'grèce', 'grece', 'greece', 'gr', 'hongrie', 'hungary', 'hu',
            'croatie', 'croatia', 'hr', 'géorgie', 'georgie', 'georgia', 'ge', 'royaume-uni', 'royaume uni', 'united kingdom', 'uk', 'england'
          ];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, oldWorld),
          );
          break;

        case 'continent_new_world':
          const newWorld = [
            'usa', 'us', 'états-unis', 'etats-unis', 'etats unis', 'united states', 'californie', 'california',
            'chili', 'chile', 'cl', 'argentine', 'argentina', 'ar', 'australie', 'australia', 'au',
            'nouvelle-zélande', 'nouvelle-zelande', 'nouvelle zelande', 'new zealand', 'nz',
            'afrique du sud', 'south africa', 'za', 'canada', 'ca', 'uruguay', 'uy'
          ];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, newWorld),
          );
          break;

        case 'continent_globe_trotter':
        case 'continent_explorer':
        case 'continent_universal':
          final countries = <String>{};
          for (final b in bottles) {
            final c = b.wine?.country.trim().toLowerCase();
            if (c != null && c.isNotEmpty && !countries.contains(c)) {
              countries.add(c);
              contributing.add(_bottleToItem(b));
            }
          }
          for (final t in tastings) {
            final c = t.country?.trim().toLowerCase();
            if (c != null && c.isNotEmpty && !countries.contains(c)) {
              countries.add(c);
              contributing.add(_tastingToItem(t));
            }
          }
          count = countries.length;
          break;

        // ==========================================
        // 🏳️ PAYS (Strict tokenized matching)
        // ==========================================
        case 'country_france':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['france', 'fr']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['bordeaux', 'bourgogne', 'champagne', 'loire', 'rhone', 'alsace', 'beaujolais'])),
          );
          break;

        case 'country_italy':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['italie', 'italy', 'italia', 'it']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['piemont', 'piemonte', 'toscane', 'toscana', 'veneto', 'sicile', 'barolo', 'chianti'])),
          );
          break;

        case 'country_spain':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['espagne', 'spain', 'espana', 'es']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['rioja', 'ribera del duero', 'priorat'])),
          );
          break;

        case 'country_usa':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['usa', 'us', 'états-unis', 'etats-unis', 'etats unis', 'united states', 'californie', 'california']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['napa valley', 'sonoma', 'oregon', 'washington state'])),
          );
          break;

        case 'country_portugal':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['portugal', 'pt']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['douro', 'porto', 'alentejo', 'dao'])),
          );
          break;

        case 'country_germany':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['allemagne', 'germany', 'deutschland', 'de']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['mosel', 'rheingau', 'pfalz', 'baden'])),
          );
          break;

        case 'country_switzerland':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['suisse', 'switzerland', 'schweiz', 'ch']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['valais', 'vaud', 'lavaux', 'geneve'])),
          );
          break;

        case 'country_argentina':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['argentine', 'argentina', 'ar']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['mendoza', 'cafayate', 'salta'])),
          );
          break;

        case 'country_chile':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['chili', 'chile', 'cl']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['maipo', 'colchagua', 'casablanca'])),
          );
          break;

        case 'country_australia':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['australie', 'australia', 'au']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['barossa', 'mclaren vale', 'margaret river', 'yarra valley'])),
          );
          break;

        case 'country_new_zealand':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['nouvelle-zélande', 'nouvelle-zelande', 'nouvelle zelande', 'new zealand', 'nz']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['marlborough', 'central otago'])),
          );
          break;

        case 'country_south_africa':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['afrique du sud', 'south africa', 'za']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['stellenbosch', 'swartland', 'constantia', 'paarl'])),
          );
          break;

        case 'country_greece':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['grèce', 'grece', 'greece', 'gr']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['santorin', 'santorini', 'naoussa', 'nemee'])),
          );
          break;

        case 'country_austria':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['autriche', 'austria', 'österreich', 'osterreich', 'at']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['wachau', 'kamptal', 'burgenland', 'kremstal'])),
          );
          break;

        case 'country_georgia':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['géorgie', 'georgie', 'georgia', 'ge']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['kakhétie', 'kakhetie', 'kakheti', 'imereti'])),
          );
          break;

        case 'country_uk':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            requireWine: true,
            predicate: (c, r, a, n, t) => _matchCountry(c, ['royaume-uni', 'royaume uni', 'united kingdom', 'england', 'angleterre', 'uk', 'gb']) ||
                (c.isEmpty && _matchRegionAppellation(r, a, ['sussex', 'kent', 'hampshire'])),
          );
          break;

        // ==========================================
        // 🏰 RÉGIONS (Region & Appellation only)
        // ==========================================
        case 'region_bourgogne':
          const bgKeywords = ['bourgogne', 'burgundy', 'chablis', 'meursault', 'nuits', 'beaune', 'macon', 'mâcon', 'beaujolais'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, bgKeywords),
          );
          break;

        case 'region_bordeaux':
          const bdxKeywords = ['bordeaux', 'médoc', 'medoc', 'saint-émilion', 'saint-emilion', 'pomerol', 'graves', 'pessac', 'margaux', 'pauillac', 'saint-julien', 'sauternes'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, bdxKeywords),
          );
          break;

        case 'region_rhone':
          const rhKeywords = ['rhône', 'rhone', 'châteauneuf', 'chateauneuf', 'côte-rôtie', 'cote-rotie', 'hermitage', 'crozes', 'gigondas', 'vacqueyras', 'saint-joseph', 'cornas'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, rhKeywords),
          );
          break;

        case 'region_champagne':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, ['champagne']),
          );
          break;

        case 'region_loire':
          const loireKeywords = ['loire', 'sancerre', 'saumur', 'chinon', 'vouvray', 'muscadet', 'anjou', 'pouilly-fumé', 'pouilly-fume'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, loireKeywords),
          );
          break;

        case 'region_alsace':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, ['alsace']),
          );
          break;

        case 'region_provence':
          const prvKeywords = ['provence', 'bandol', 'cassis', 'corse', 'patrimonio', 'bellet'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, prvKeywords),
          );
          break;

        case 'region_jura_savoie':
          const jsKeywords = ['jura', 'savoie', 'arbois', 'château-chalon', 'chateau-chalon', 'apremont', 'chignin', 'savagnin', 'mondeuse'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, jsKeywords),
          );
          break;

        case 'region_sud_ouest':
          const soKeywords = ['cahors', 'madiran', 'jurançon', 'jurancon', 'bergerac', 'gaillac', 'sud-ouest', 'fronton', 'iroleguy', 'irouléguy', 'monbazillac', 'pecharmant', 'pécharmant'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, soKeywords),
          );
          break;

        case 'region_languedoc_roussillon':
          const lrKeywords = ['languedoc', 'roussillon', 'pic saint-loup', 'pic saint loup', 'terrasses du larzac', 'collioure', 'banyuls', 'corbières', 'corbieres', 'minervois', 'faugères', 'faugeres', 'saint-chinian', 'fitou', 'limoux'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, lrKeywords),
          );
          break;

        case 'region_corse':
          const crKeywords = ['corse', 'patrimonio', 'ajaccio', 'calvi', 'porto-vecchio', 'sartène', 'sartene', 'figari'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, crKeywords),
          );
          break;

        case 'region_beaujolais':
          const bjKeywords = ['beaujolais', 'morgon', 'moulin-à-vent', 'moulin a vent', 'fleurie', 'brouilly', 'chénas', 'chenas', 'chiroubles', 'juliénas', 'julienas', 'régnié', 'regnie', 'saint-amour'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, bjKeywords),
          );
          break;

        case 'region_toscana':
          const tsKeywords = ['toscane', 'toscana', 'tuscany', 'chianti', 'brunello', 'montalcino', 'bolgheri', 'montepulciano', 'maremma', 'super-toscan', 'supertuscan', 'morellino'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, tsKeywords),
          );
          break;

        case 'region_piemonte':
          const pmKeywords = ['piémont', 'piemont', 'piemonte', 'piedmont', 'barolo', 'barbaresco', 'langhe', 'barbera', 'roero', 'gavi', 'nebbiolo d\'alba', 'dolcetto'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, pmKeywords),
          );
          break;

        case 'region_veneto':
          const vnKeywords = ['vénétie', 'veneto', 'valpolicella', 'amarone', 'ripasso', 'soave', 'bardolino', 'prosecco'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, vnKeywords),
          );
          break;

        case 'region_rioja':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, ['rioja']),
          );
          break;

        case 'region_napa':
          const npKeywords = ['napa valley', 'napa', 'oakville', 'rutherford', 'stags leap', 'howell mountain', 'mount veeder', 'calistoga'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, npKeywords),
          );
          break;

        // ==========================================
        // 🍇 CÉPAGES (Varietals & Mono-AOC matching)
        // ==========================================
        case 'grape_pinot_noir':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['pinot noir', 'spätburgunder', 'spatburgunder'],
              requiredType: 'red',
              monoVarietalAppellations: ['bourgogne rouge', 'gevrey-chambertin', 'vosne-romanée', 'vosne-romanee', 'nuits-saint-georges', 'chambolle-musigny', 'volnay', 'pommard', 'clos de vougeot'],
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['pinot noir', 'spätburgunder', 'spatburgunder'],
              requiredType: 'red',
              monoVarietalAppellations: ['bourgogne rouge', 'gevrey-chambertin', 'vosne-romanée', 'vosne-romanee', 'nuits-saint-georges', 'chambolle-musigny', 'volnay', 'pommard', 'clos de vougeot'],
            ),
          );
          break;

        case 'grape_cabernet':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['cabernet sauvignon'],
              requiredType: 'red',
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['cabernet sauvignon'],
              requiredType: 'red',
            ),
          );
          break;

        case 'grape_chardonnay':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['chardonnay'],
              requiredType: 'white',
              monoVarietalAppellations: ['chablis', 'meursault', 'puligny-montrachet', 'chassagne-montrachet', 'corton-charlemagne', 'pouilly-fuissé', 'pouilly-fuisse'],
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['chardonnay'],
              requiredType: 'white',
              monoVarietalAppellations: ['chablis', 'meursault', 'puligny-montrachet', 'chassagne-montrachet', 'corton-charlemagne', 'pouilly-fuissé', 'pouilly-fuisse'],
            ),
          );
          break;

        case 'grape_syrah':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['syrah', 'shiraz'],
              requiredType: 'red',
              monoVarietalAppellations: ['cornas', 'côte-rôtie', 'cote-rotie', 'hermitage'],
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['syrah', 'shiraz'],
              requiredType: 'red',
              monoVarietalAppellations: ['cornas', 'côte-rôtie', 'cote-rotie', 'hermitage'],
            ),
          );
          break;

        case 'grape_chenin':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['chenin', 'chenin blanc'],
              requiredType: 'white',
              monoVarietalAppellations: ['vouvray', 'saumur blanc', 'savennières', 'savennieres', 'montlouis', 'coteaux du layon'],
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['chenin', 'chenin blanc'],
              requiredType: 'white',
              monoVarietalAppellations: ['vouvray', 'saumur blanc', 'savennières', 'savennieres', 'montlouis', 'coteaux du layon'],
            ),
          );
          break;

        case 'grape_riesling':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['riesling'],
              requiredType: 'white',
              monoVarietalAppellations: ['riesling'],
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['riesling'],
              requiredType: 'white',
              monoVarietalAppellations: ['riesling'],
            ),
          );
          break;

        case 'grape_nebbiolo':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['nebbiolo', 'spanna'],
              requiredType: 'red',
              monoVarietalAppellations: ['barolo', 'barbaresco', 'roero', 'gattinara', 'ghemme', 'nebbiolo d\'alba'],
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['nebbiolo', 'spanna'],
              requiredType: 'red',
              monoVarietalAppellations: ['barolo', 'barbaresco', 'roero', 'gattinara', 'ghemme', 'nebbiolo d\'alba'],
            ),
          );
          break;

        case 'grape_merlot':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['merlot'],
              requiredType: 'red',
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['merlot'],
              requiredType: 'red',
            ),
          );
          break;

        case 'grape_sauvignon_blanc':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['sauvignon', 'sauvignon blanc'],
              requiredType: 'white',
              monoVarietalAppellations: ['sancerre', 'pouilly-fumé', 'pouilly-fume', 'menetou-salon'],
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['sauvignon', 'sauvignon blanc'],
              requiredType: 'white',
              monoVarietalAppellations: ['sancerre', 'pouilly-fumé', 'pouilly-fume', 'menetou-salon'],
            ),
          );
          break;

        case 'grape_grenache':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['grenache', 'garnacha', 'cannonau'],
              requiredType: 'red',
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['grenache', 'garnacha', 'cannonau'],
              requiredType: 'red',
            ),
          );
          break;

        case 'grape_cabernet_franc':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['cabernet franc'],
              requiredType: 'red',
              monoVarietalAppellations: ['chinon', 'bourgueil', 'saumur-champigny', 'saint-nicolas'],
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['cabernet franc'],
              requiredType: 'red',
              monoVarietalAppellations: ['chinon', 'bourgueil', 'saumur-champigny', 'saint-nicolas'],
            ),
          );
          break;

        case 'grape_sangiovese':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['sangiovese'],
              requiredType: 'red',
              monoVarietalAppellations: ['brunello', 'rosso di montalcino', 'morellino', 'vino nobile'],
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['sangiovese'],
              requiredType: 'red',
              monoVarietalAppellations: ['brunello', 'rosso di montalcino', 'morellino', 'vino nobile'],
            ),
          );
          break;

        case 'grape_malbec':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            requireWine: true,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['malbec', 'cot', 'côt'],
              requiredType: 'red',
              monoVarietalAppellations: ['cahors'],
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['malbec', 'cot', 'côt'],
              requiredType: 'red',
              monoVarietalAppellations: ['cahors'],
            ),
          );
          break;

        case 'grape_tempranillo':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['tempranillo', 'tinta del pais', 'tinto fino', 'cencibel', 'ull de llebre'],
              requiredType: 'red',
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['tempranillo', 'tinta del pais', 'tinto fino', 'cencibel', 'ull de llebre'],
              requiredType: 'red',
            ),
          );
          break;

        case 'grape_gamay':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['gamay'],
              requiredType: 'red',
              monoVarietalAppellations: ['beaujolais', 'morgon', 'fleurie', 'brouilly', 'moulin-à-vent', 'moulin a vent', 'chénas', 'chenas', 'chiroubles', 'juliénas', 'julienas', 'régnié', 'regnie', 'saint-amour'],
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['gamay'],
              requiredType: 'red',
              monoVarietalAppellations: ['beaujolais', 'morgon', 'fleurie', 'brouilly', 'moulin-à-vent', 'moulin a vent', 'chénas', 'chenas', 'chiroubles', 'juliénas', 'julienas', 'régnié', 'regnie', 'saint-amour'],
            ),
          );
          break;

        case 'grape_viognier':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['viognier'],
              requiredType: 'white',
              monoVarietalAppellations: ['condrieu', 'château-grillet', 'chateau-grillet'],
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['viognier'],
              requiredType: 'white',
              monoVarietalAppellations: ['condrieu', 'château-grillet', 'chateau-grillet'],
            ),
          );
          break;

        case 'grape_gewurztraminer':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchesGrape(
              wine: null,
              wineName: n,
              wineType: t,
              appellation: a,
              grapeAliases: ['gewurztraminer', 'gewürztraminer', 'gewurz'],
              requiredType: 'white',
            ),
            winePredicate: (w) => _matchesGrape(
              wine: w,
              wineName: w?.name,
              wineType: w?.type,
              appellation: w?.appellation,
              grapeAliases: ['gewurztraminer', 'gewürztraminer', 'gewurz'],
              requiredType: 'white',
            ),
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
              contributing.add(_tastingToItem(t));
              continue;
            }
            // Check if bottle or wine has peak window
            final matchingBottle = bottles.where((b) => (t.bottleId != null && b.id == t.bottleId) || b.wineId == t.wineId).firstOrNull;
            final w = matchingBottle?.wine;
            if (w != null && w.peakStart != null && w.peakEnd != null) {
              final consumedYear = t.consumedAt.year;
              if (consumedYear >= w.peakStart! && consumedYear <= w.peakEnd!) {
                count++;
                contributing.add(_tastingToItem(t));
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
              contributing.add(_bottleToItem(b));
            }
          }
          for (final t in tastings) {
            final vintage = t.vintage;
            if (vintage != null && vintage > 0 && (currentYear - vintage) >= 25) {
              count++;
              contributing.add(_tastingToItem(t));
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
              contributing.add(_tastingToItem(t));
              continue;
            }
            final matchingBottle = bottles.where((b) => (t.bottleId != null && b.id == t.bottleId) || b.wineId == t.wineId).firstOrNull;
            final w = matchingBottle?.wine;
            if (w != null && w.peakStart != null) {
              if ((w.peakStart! - t.consumedAt.year) >= 5) {
                count++;
                contributing.add(_tastingToItem(t));
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
              contributing.add(_tastingToItem(t));
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
              final key = t.wineName?.toLowerCase().trim() ?? t.id;
              if (!cocktailNames.contains(key)) {
                cocktailNames.add(key);
                contributing.add(_tastingToItem(t));
              }
            }
          }
          count = cocktailNames.length;
          break;

        case 'cocktail_pantry':
          if (pantry != null) {
            final inStock = pantry.where((i) => i.inStock).toList();
            count = inStock.length;
            for (final item in inStock) {
              contributing.add(ContributingItem(
                id: item.id,
                name: item.name,
                type: 'Ingrédient Bar',
                isTasting: false,
              ));
            }
          }
          break;

        case 'cocktail_diy_shaker':
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            final occ = (t.occasion ?? '').toLowerCase();
            if (notes.contains('shaker maison') || notes.contains('diy shaker') || notes.contains('bocal') || notes.contains('système d') || occ.contains('diy shaker') || occ.contains('shaker maison')) {
              count++;
              contributing.add(_tastingToItem(t));
            }
          }
          break;

        case 'cocktail_spritz':
          for (final t in tastings) {
            final name = (t.wineName ?? '').toLowerCase();
            final notes = (t.tastingNotes ?? '').toLowerCase();
            if (name.contains('spritz') || name.contains('negroni') || name.contains('americano') || notes.contains('spritz') || notes.contains('negroni')) {
              count++;
              contributing.add(_tastingToItem(t));
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
            predicate: (c, r, a, n, t) => t == 'gin' || RegExp(r'\bgin\b', caseSensitive: false).hasMatch(t) || RegExp(r'\bgin\b', caseSensitive: false).hasMatch(n),
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

        case 'spirit_amaretto_italian':
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            requireWine: false,
            predicate: (c, r, a, n, t) =>
                n.contains('amaretto') ||
                n.contains('disaronno') ||
                t.contains('amaretto') ||
                t.contains('disaronno'),
          );
          break;

        case 'spirit_fill_vigilant':
          for (final b in bottles) {
            final isSp = !_isWine(b.wine?.type ?? '', b.wine?.name ?? '', b.wine?.classification ?? '');
            if (isSp && b.fillLevel <= 25) {
              count++;
              contributing.add(_bottleToItem(b));
            }
          }
          break;

        // ==========================================
        // 💩 BADGES LOOSER & AUTODÉRISION
        // ==========================================
        case 'looser_piquette':
          for (final b in bottles) {
            if (b.purchasePrice != null && b.purchasePrice! > 0 && b.purchasePrice! < 3.0) {
              count++;
              contributing.add(_bottleToItem(b));
            }
          }
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            if (notes.contains('piquette') || notes.contains('villageoise') || notes.contains('2€') || notes.contains('2,50')) {
              count++;
              contributing.add(_tastingToItem(t));
            }
          }
          break;

        case 'looser_past_peak':
          // Must only count wine that was actually consumed/tasted after its peak,
          // or where tasting notes explicitly note spoilage/past peak.
          // Bottles in cellar are unopened inventory and must NEVER count towards "Avoir bu un vin passé".
          final pastWordRegex = RegExp(r'\b(passé|passée|vinaigre|madérisé|oxydé|mort)\b');
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            if (pastWordRegex.hasMatch(notes)) {
              count++;
              contributing.add(_tastingToItem(t));
              continue;
            }
            final matchingBottle = bottles.where((b) => (t.bottleId != null && b.id == t.bottleId) || b.wineId == t.wineId).firstOrNull;
            final w = matchingBottle?.wine;
            if (w != null && w.peakEnd != null && t.consumedAt.year > w.peakEnd! + 2) {
              count++;
              contributing.add(_tastingToItem(t));
            } else if (w != null && w.drinkEnd != null && t.consumedAt.year > w.drinkEnd! + 2) {
              count++;
              contributing.add(_tastingToItem(t));
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
              contributing.add(_tastingToItem(t));
            }
          }
          break;

        case 'looser_bouchonne':
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            if (notes.contains('bouchon') || notes.contains('tca')) {
              count++;
              contributing.add(_tastingToItem(t));
            }
          }
          break;

        case 'looser_solo':
          for (final t in tastings) {
            if (t.coTasters.isEmpty) {
              count++;
              contributing.add(_tastingToItem(t));
            }
          }
          break;

        case 'looser_poussiere':
          final threeYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 3));
          for (final b in bottles) {
            if (b.createdAt.isBefore(threeYearsAgo)) {
              count++;
              contributing.add(_bottleToItem(b));
            }
          }
          break;

        case 'looser_tache_etiquette':
          for (final b in bottles) {
            final notes = (b.notes ?? '').toLowerCase();
            if (notes.contains('tache') || notes.contains('coulure') || notes.contains('étiquette abîmée') || notes.contains('etiquette abimee')) {
              count++;
              contributing.add(_bottleToItem(b));
            }
          }
          for (final t in tastings) {
            final notes = (t.tastingNotes ?? '').toLowerCase();
            if (notes.contains('tache') || notes.contains('coulure') || notes.contains('nappe') || notes.contains('goutte')) {
              count++;
              contributing.add(_tastingToItem(t));
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
          const bgMarkers = ['bourgogne', 'burgundy', 'chablis', 'vougeot', 'cîteaux', 'citeaux', 'meursault', 'côte de nuits', 'cote de nuits', 'côte de beaune', 'cote de beaune', 'corton'];
          for (final b in bottles) {
            final w = b.wine;
            final r = (w?.region ?? '').toLowerCase();
            final a = (w?.appellation ?? '').toLowerCase();
            final n = (w?.name ?? '').toLowerCase();
            final cl = (w?.classification ?? '').toLowerCase();
            final inBourgogne = bgMarkers.any((k) => r.contains(k) || a.contains(k));
            final isClimat = cl.contains('grand cru') || cl.contains('premier cru') || cl.contains('1er cru') || cl.contains('climat') || cl.contains('cistercien') || a.contains('grand cru') || a.contains('premier cru') || a.contains('1er cru') || n.contains('grand cru') || n.contains('premier cru') || n.contains('1er cru');
            if (inBourgogne && isClimat) {
              count++;
            }
          }
          for (final t in tastings) {
            final r = (t.region ?? '').toLowerCase();
            final a = (t.appellation ?? '').toLowerCase();
            final n = (t.wineName ?? '').toLowerCase();
            final inBourgogne = bgMarkers.any((k) => r.contains(k) || a.contains(k));
            final isClimat = a.contains('grand cru') || a.contains('premier cru') || a.contains('1er cru') || a.contains('climat') || n.contains('grand cru') || n.contains('premier cru') || n.contains('1er cru');
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
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) {
              final normA = _normalize(a);
              final normN = _normalize(n);
              return normA.contains('chambertin') || normN.contains('chambertin') || normN.contains('napoleon');
            },
          );
          break;

        case 'savant_volcan':
          const volKeywords = [
            'etna',
            'canaries',
            'canary',
            'lanzarote',
            'santorin',
            'santorini',
            'côtes du forez',
            'cotes du forez',
            'côtes d\'auvergne',
            'cotes d\'auvergne',
            'campi flegrei',
            'vesuvio',
            'vesuve',
            'açores',
            'azores',
            'somlo',
            'somló',
            'aglianico del vulture',
            'tenerife',
            'valle de la orotava',
          ];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) {
              final normR = _normalize(r);
              final normA = _normalize(a);
              final normN = _normalize(n);
              return volKeywords.any((k) {
                final normK = _normalize(k);
                return normR.contains(normK) || normA.contains(normK) || (normK == 'etna' && normN.contains('etna'));
              });
            },
            winePredicate: (w) {
              if (w == null) return false;
              final sub = _normalize(w.subRegion ?? '');
              final soil = _normalize(w.terroirSoil ?? '');
              final isVolcanicSoil = soil.contains('volcan') || soil.contains('basalte') || soil.contains('pouzzolane');
              return volKeywords.any((k) => sub.contains(_normalize(k))) || isVolcanicSoil;
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
            predicate: (c, r, a, n, t) {
              if (t == 'red' || t == 'rouge') return false;
              return botKeywords.any((k) => _normalize(r).contains(_normalize(k)) || _normalize(a).contains(_normalize(k)));
            },
            winePredicate: (w) {
              if (w?.type == 'red') return false;
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
              final r = w.region.toLowerCase();
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
              if (_matchRegionAppellation(r, a, kimKeywords)) return true;
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
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) {
              final normA = _normalize(a);
              final normN = _normalize(n);
              // Hermitage (excluding Crozes-Hermitage)
              if (normA.contains('hermitage') && !normA.contains('crozes')) return true;
              // Château d'Yquem
              if (normN.contains('yquem') || normA.contains('yquem')) return true;
              // Château Haut-Brion
              if (normN.contains('haut brion') || normA.contains('haut brion')) return true;
              // Vino Nobile di Montepulciano (excluding Montepulciano d'Abruzzo)
              if (normA.contains('montepulciano') && !normA.contains('abruzzo')) return true;
              return false;
            },
          );
          break;

        case 'savant_schiste':
          const schKeywords = ['priorat', 'côte-rôtie', 'cote-rotie', 'collioure', 'banyuls', 'faugères', 'faugeres', 'douro'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) {
              if (_matchRegionAppellation(r, a, schKeywords)) return true;
              if (n.contains('schiste')) return true;
              return false;
            },
            winePredicate: (w) {
              final tn = (w?.tastingNotes ?? '').toLowerCase();
              final soil = (w?.terroirSoil ?? '').toLowerCase();
              return tn.contains('schiste') || soil.contains('schiste');
            },
          );
          break;

        case 'savant_vents':
          const ventKeywords = ['châteauneuf', 'chateauneuf', 'gigondas', 'vacqueyras', 'bandol', 'côtes de provence', 'cotes de provence', 'ventoux'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) {
              if (_matchRegionAppellation(r, a, ventKeywords)) return true;
              if (n.contains('mistral') || n.contains('tramontane')) return true;
              return false;
            },
          );
          break;

        case 'savant_alienor':
          const alKeywords = ['bordeaux', 'graves', 'médoc', 'medoc', 'pessac-léognan', 'pessac-leognan', 'clairet'];
          count += _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => _matchRegionAppellation(r, a, alKeywords),
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

        case 'savant_sanguis_christi':
          count = isLatin ? 1 : 0;
          break;

        case 'savant_blind_battle':
          count = _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) => n.contains('aveugle') || n.contains('blind') || a.contains('aveugle'),
            winePredicate: (w) {
              final tn = (w?.tastingNotes ?? '').toLowerCase();
              final s = (w?.summary ?? '').toLowerCase();
              return tn.contains('aveugle') || tn.contains('blind') || s.contains('aveugle') || s.contains('blind');
            },
          );
          for (final te in tastings) {
            final tn = (te.tastingNotes ?? '').toLowerCase();
            final occ = (te.occasion ?? '').toLowerCase();
            if (tn.contains('aveugle') || tn.contains('blind') || occ.contains('aveugle') || occ.contains('blind')) {
              count++;
            }
          }
          break;

        case 'savant_thermocourbe':
          for (final b in bottles) {
            final n = (b.notes ?? '').toLowerCase();
            final tn = (b.wine?.tastingNotes ?? '').toLowerCase();
            if (n.contains('température') || n.contains('temperature') || n.contains('service') || tn.contains('température') || tn.contains('temperature') || tn.contains('service')) {
              count++;
              contributing.add(_bottleToItem(b));
            }
          }
          for (final te in tastings) {
            final tn = (te.tastingNotes ?? '').toLowerCase();
            if (tn.contains('température') || tn.contains('temperature') || tn.contains('service') || tn.contains('frais') || tn.contains('chambré')) {
              count++;
              contributing.add(_tastingToItem(te));
            }
          }
          break;

        case 'savant_table_consensus':
          for (final b in bottles) {
            final n = (b.notes ?? '').toLowerCase();
            if (n.contains('table') || n.contains('convive') || n.contains('accord') || n.contains('consensus') || (b.wine?.foodPairings.isNotEmpty ?? false)) {
              count++;
              contributing.add(_bottleToItem(b));
            }
          }
          for (final te in tastings) {
            final tn = (te.tastingNotes ?? '').toLowerCase();
            final fp = (te.foodPaired ?? '').toLowerCase();
            if (tn.contains('table') || tn.contains('convive') || tn.contains('accord') || tn.contains('consensus') || fp.isNotEmpty || te.coTasters.isNotEmpty) {
              count++;
              contributing.add(_tastingToItem(te));
            }
          }
          break;

        case 'savant_consensus_table_master':
          for (final b in bottles) {
            final n = (b.notes ?? '').toLowerCase();
            if (n.contains('table') || n.contains('groupe') || n.contains('convive') || n.contains('consensus') || (b.wine?.foodPairings.isNotEmpty ?? false)) {
              count++;
              contributing.add(_bottleToItem(b));
            }
          }
          for (final te in tastings) {
            final tn = (te.tastingNotes ?? '').toLowerCase();
            if (tn.contains('table') || tn.contains('groupe') || tn.contains('convive') || tn.contains('consensus') || te.coTasters.isNotEmpty) {
              count++;
              contributing.add(_tastingToItem(te));
            }
          }
          break;

        case 'savant_flight_discovery':
          for (final te in tastings) {
            final tn = (te.tastingNotes ?? '').toLowerCase();
            if (tn.contains('flight') || tn.contains('verre') || tn.contains('série') || tn.contains('degustation')) {
              count++;
              contributing.add(_tastingToItem(te));
            }
          }
          if (tastings.length >= 3) {
            count += 1;
            if (contributing.isEmpty) {
              for (final t in tastings.take(3)) {
                contributing.add(_tastingToItem(t));
              }
            }
          }
          break;

        case 'savant_cellar_architect':
          final regions = <String>{};
          final types = <String>{};
          for (final b in bottles) {
            final r = (b.wine?.region ?? '').trim().toLowerCase();
            final t = (b.wine?.type ?? '').trim().toLowerCase();
            if (r.isNotEmpty) regions.add(r);
            if (t.isNotEmpty) types.add(t);
          }
          if ((regions.length >= 3 && types.length >= 2) || bottles.length >= 10) {
            count = 1;
            for (final b in bottles.take(10)) {
              contributing.add(_bottleToItem(b));
            }
          } else {
            count = 0;
          }
          break;

        case 'savant_storyteller':
          for (final b in bottles) {
            final w = b.wine;
            final n = (b.notes ?? '').toLowerCase();
            final tn = (w?.tastingNotes ?? '').toLowerCase();
            final p = (w?.producer ?? '').toLowerCase();
            if (n.length > 30 || tn.length > 30 || p.isNotEmpty) {
              count++;
              contributing.add(_bottleToItem(b));
            }
          }
          for (final te in tastings) {
            final tn = (te.tastingNotes ?? '').toLowerCase();
            if (tn.length > 30) {
              count++;
              contributing.add(_tastingToItem(te));
            }
          }
          break;

        case 'savant_bulles_royales':
          const effervescents = ['champagne', 'crémant', 'cremant', 'cava', 'franciacorta', 'prosecco', 'sparkling', 'effervescent', 'mousseux'];
          count = _countMatching(
            bottles: bottles,
            tastings: tastings,
            predicate: (c, r, a, n, t) {
              return t == 'sparkling' || t == 'effervescent' || effervescents.any((e) => r.contains(e) || a.contains(e) || n.contains(e));
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
        contributingItems: List.unmodifiable(contributing),
      ));
    }

    _activeContributing = null;

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

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ûüù]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .trim();
  }

  static bool _matchCountry(String? country, List<String> canonicalTokens) {
    if (country == null || country.trim().isEmpty) return false;
    final norm = _normalize(country);
    for (final token in canonicalTokens) {
      final normToken = _normalize(token);
      if (norm == normToken) return true;
      final regex = RegExp('\\b${RegExp.escape(normToken)}\\b');
      if (regex.hasMatch(norm)) return true;
    }
    return false;
  }

  static bool _matchRegionAppellation(String region, String appellation, List<String> keywords) {
    final normR = _normalize(region);
    final normA = _normalize(appellation);
    for (final kw in keywords) {
      final normKw = _normalize(kw);
      if (normR.contains(normKw) || normA.contains(normKw)) {
        return true;
      }
    }
    return false;
  }

  static bool _matchesGrape({
    required Wine? wine,
    required String? wineName,
    required String? wineType,
    required String? appellation,
    required List<String> grapeAliases,
    required String requiredType, // 'red' or 'white'
    List<String> monoVarietalAppellations = const [],
  }) {
    final type = _normalize(wine?.type ?? wineType ?? '');
    final isRed = type == 'red' || type == 'rouge';
    final isWhite = type == 'white' || type == 'blanc';
    if (requiredType == 'red' && !isRed) return false;
    if (requiredType == 'white' && !isWhite) return false;

    // 1. If structured grapes list exists and is non-empty, ONLY use it:
    if (wine != null && wine.grapes.isNotEmpty) {
      return wine.grapes.any((g) {
        final gName = _normalize(g.name);
        return grapeAliases.any((alias) => gName.contains(_normalize(alias)));
      });
    }

    // 2. Otherwise (tasting without grapes list or wine without grape data):
    final normApp = _normalize(appellation ?? '');
    final normName = _normalize(wineName ?? '');

    // 2a. Certified 100% mono-varietal appellation
    for (final aoc in monoVarietalAppellations) {
      final normAoc = _normalize(aoc);
      if (normApp.contains(normAoc)) return true;
    }

    // 2b. Explicit grape token with word boundary in name or appellation
    for (final alias in grapeAliases) {
      final normAlias = _normalize(alias);
      final regex = RegExp('\\b${RegExp.escape(normAlias)}\\b');
      if (regex.hasMatch(normName) || regex.hasMatch(normApp)) {
        return true;
      }
    }

    return false;
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
        _activeContributing?.add(_bottleToItem(b));
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
        _activeContributing?.add(_tastingToItem(te));
      }
    }
    return count;
  }
}
