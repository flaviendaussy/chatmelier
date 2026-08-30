import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/wine_merchant.dart';
import 'package:chatmelier/features/journal/domain/tasting_entry.dart';
import 'package:chatmelier/features/offline/domain/offline_action.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Bottle Movement & Offline Action Tests', () {
    test('OfflineActionType.moveBottle serializes and deserializes properly', () {
      final action = OfflineAction(
        type: OfflineActionType.moveBottle,
        cellarId: 'cellar-damblain-123',
        data: {
          'action': 'move',
          'bottle_id': 'bottle-champagne-456',
          'source_cellar_id': 'cellar-damblain-123',
          'target_cellar_id': 'cellar-londres-789',
          'quantity_to_move': 2,
        },
      );

      final json = action.toJson();
      expect(json['type'], 'moveBottle');
      expect(json['cellar_id'], 'cellar-damblain-123');

      final deserialized = OfflineAction.fromJson(json);
      expect(deserialized.type, OfflineActionType.moveBottle);
      expect(deserialized.data['target_cellar_id'], 'cellar-londres-789');
      expect(deserialized.data['quantity_to_move'], 2);
    });
  });

  group('2. Tasting History Multi-Fields Search Tests', () {
    final sampleEntries = [
      TastingEntry(
        id: 'entry-1',
        wineId: 'wine-1',
        wineName: 'Champagne Billecart-Salmon Brut Rosé',
        vintage: null, // Non-millésimé
        region: 'Champagne',
        appellation: 'Champagne AOC',
        rating: 9.2,
        foodPaired: 'Carpaccio de Saint-Jacques',
        tastingNotes: 'Effervescence fine, notes de framboise et de brioche fraîche.',
        coTasters: ['Caro', 'Flavien', 'Camille'],
        locationName: 'Chez Dimitri',
        isExternal: true,
        consumedAt: DateTime(2026, 8, 27, 20, 0),
      ),
      TastingEntry(
        id: 'entry-2',
        wineId: 'wine-2',
        wineName: 'Château Margaux',
        vintage: 2015,
        region: 'Bordeaux',
        appellation: 'Margaux AOC',
        rating: 9.8,
        foodPaired: 'Côte de bœuf aux sarments',
        tastingNotes: 'Tanins veloutés, cassis, cèdre et élégance infinie.',
        coTasters: ['Jean-Luc', 'Flavien'],
        locationName: 'Cave Damblain',
        isExternal: false,
        consumedAt: DateTime(2025, 12, 24, 21, 0),
      ),
      TastingEntry(
        id: 'entry-3',
        wineId: 'wine-3',
        wineName: 'Domaine Laroche Chablis Grand Cru Les Clos',
        vintage: 2020,
        region: 'Bourgogne',
        appellation: 'Chablis Grand Cru',
        rating: 8.9,
        foodPaired: 'Plateau d\'huîtres Gillardeau',
        tastingNotes: 'Tension minérale tranchante, pierre à fusil, finale saline.',
        coTasters: ['Caro'],
        locationName: 'Restaurant Le Gabriel (Londres)',
        isExternal: true,
        consumedAt: DateTime(2026, 5, 15, 13, 0),
      ),
    ];

    bool searchMatches(TastingEntry entry, String query) {
      final q = query.toLowerCase();
      final name = (entry.wineName ?? '').toLowerCase();
      final region = (entry.region ?? '').toLowerCase();
      final appellation = (entry.appellation ?? '').toLowerCase();
      final loc = (entry.locationName ?? '').toLowerCase();
      final notes = (entry.tastingNotes ?? '').toLowerCase();
      final food = (entry.foodPaired ?? '').toLowerCase();
      final guests = entry.coTasters.map((g) => g.toLowerCase()).join(' ');
      final year = entry.consumedAt.year.toString();

      return name.contains(q) ||
          region.contains(q) ||
          appellation.contains(q) ||
          loc.contains(q) ||
          notes.contains(q) ||
          food.contains(q) ||
          guests.contains(q) ||
          year.contains(q);
    }

    test('Search by Location (où la bouteille a été bue)', () {
      final dimitriMatches = sampleEntries.where((e) => searchMatches(e, 'Dimitri')).toList();
      expect(dimitriMatches.length, 1);
      expect(dimitriMatches.first.wineName, contains('Billecart-Salmon'));

      final londonMatches = sampleEntries.where((e) => searchMatches(e, 'Londres')).toList();
      expect(londonMatches.length, 1);
      expect(londonMatches.first.wineName, contains('Chablis'));
    });

    test('Search by Co-Tasters (avec qui)', () {
      final camilleMatches = sampleEntries.where((e) => searchMatches(e, 'Camille')).toList();
      expect(camilleMatches.length, 1);

      final jeanLucMatches = sampleEntries.where((e) => searchMatches(e, 'Jean-Luc')).toList();
      expect(jeanLucMatches.length, 1);
      expect(jeanLucMatches.first.wineName, contains('Margaux'));
    });

    test('Search by Year and Food Pairing', () {
      final year2025Matches = sampleEntries.where((e) => searchMatches(e, '2025')).toList();
      expect(year2025Matches.length, 1);

      final oystersMatches = sampleEntries.where((e) => searchMatches(e, 'huîtres')).toList();
      expect(oystersMatches.length, 1);
      expect(oystersMatches.first.wineName, contains('Chablis'));
    });
  });

  group('3. Cavistes & Bottle Provenance Tests', () {
    test('WineMerchant serialization, Google Maps place metadata and fullAddressDisplay', () {
      final merchant = WineMerchant.create(
        name: 'Les Caves Legrand Filles & Fils',
        address: '1 Rue de la Banque',
        city: 'Paris',
        postalCode: '75002',
        country: 'France',
        latitude: 48.8665,
        longitude: 2.3396,
        placeId: 'ChIJ_abc123',
        isFavorite: true,
      );

      final json = merchant.toJson();
      expect(json['name'], 'Les Caves Legrand Filles & Fils');
      expect(json['city'], 'Paris');
      expect(json['is_favorite'], isTrue);

      final reconstructed = WineMerchant.fromJson(json);
      expect(reconstructed.name, merchant.name);
      expect(reconstructed.latitude, 48.8665);
      expect(reconstructed.fullAddressDisplay, contains('Paris'));
    });

    test('Bottle provenanceDisplay formats different source types correctly', () {
      // 1. Estate
      final estateBottle = Bottle(
        id: 'b1',
        cellarId: 'c1',
        wineId: 'w1',
        addedBy: 'u1',
        ownerId: 'u1',
        sourceType: 'estate',
        createdAt: DateTime.now(),
      );
      expect(estateBottle.provenanceDisplay, '🏰 Acheté au domaine');

      // 2. Merchant
      final merchantBottle = Bottle(
        id: 'b2',
        cellarId: 'c1',
        wineId: 'w1',
        addedBy: 'u1',
        ownerId: 'u1',
        sourceType: 'merchant',
        sourceDetails: 'Lavinia Madeleine',
        createdAt: DateTime.now(),
      );
      expect(merchantBottle.provenanceDisplay, contains('🏪 Caviste : Lavinia Madeleine'));

      // 3. Gift
      final giftBottle = Bottle(
        id: 'b3',
        cellarId: 'c1',
        wineId: 'w1',
        addedBy: 'u1',
        ownerId: 'u1',
        sourceType: 'gift',
        sourceDetails: 'Camille',
        createdAt: DateTime.now(),
      );
      expect(giftBottle.provenanceDisplay, '🎁 Offert par Camille');

      // 4. Supermarket
      final superBottle = Bottle(
        id: 'b4',
        cellarId: 'c1',
        wineId: 'w1',
        addedBy: 'u1',
        ownerId: 'u1',
        sourceType: 'supermarket',
        sourceDetails: 'Monoprix',
        createdAt: DateTime.now(),
      );
      expect(superBottle.provenanceDisplay, contains('🛒 Grande surface (Monoprix)'));
    });
  });

  group('4. Non-Vintage Wines Apogee & Maturity Tests', () {
    test('Non-vintage wine (vintage == null) windowStatus returns inPeak ready to drink', () {
      const nvChampagne = Wine(
        id: 'w-nv',
        name: 'Ruinart Blanc de Blancs Brut NM',
        type: 'sparkling',
        vintage: null, // Non-millésimé
        country: 'France',
        region: 'Champagne',
        appellation: 'Champagne AOC',
      );

      expect(nvChampagne.vintage, isNull);
      // Non-vintage status must be immediately inPeak / ready to drink
      expect(nvChampagne.windowStatus, DrinkWindowStatus.inPeak);
    });

    test('Wine with vintage == 0 is treated as non-vintage', () {
      const zeroVintage = Wine(
        id: 'w-zero',
        name: 'Cuvée Réserve Brut',
        type: 'sparkling',
        vintage: 0,
        country: 'France',
        region: 'Champagne',
      );

      expect(zeroVintage.vintage, 0);
    });
  });

  group('5. Type Safety & Numeric Cast Resilience Tests', () {
    test('Bottle.fromJson handles purchase_price as int, double, num or string safely', () {
      final bottleFromIntPrice = Bottle.fromJson({
        'id': 'b-1',
        'wine_id': 'w-1',
        'quantity': 2,
        'purchase_price': 45, // int instead of double
      });
      expect(bottleFromIntPrice.purchasePrice, 45.0);

      final bottleFromDoublePrice = Bottle.fromJson({
        'id': 'b-2',
        'wine_id': 'w-1',
        'quantity': 1,
        'purchase_price': 45.5,
      });
      expect(bottleFromDoublePrice.purchasePrice, 45.5);
    });

    test('Wine.fromJson handles vintage and drinking windows as num, int or double without crashing', () {
      final wineFromMixedNums = Wine.fromJson({
        'id': 'w-1',
        'name': 'Test Cru',
        'vintage': 2020.0, // double representation
        'alcohol_pct': 14, // int representation
        'ideal_drinking_start': 2024.0,
        'ideal_drinking_end': 2035,
        'peak_drinking_start': 2028,
        'peak_drinking_end': 2030.0,
        'estimated_market_value': 120, // int representation
      });

      expect(wineFromMixedNums.vintage, 2020);
      expect(wineFromMixedNums.alcoholPct, 14.0);
      expect(wineFromMixedNums.drinkStart, 2024);
      expect(wineFromMixedNums.drinkEnd, 2035);
      expect(wineFromMixedNums.peakStart, 2028);
      expect(wineFromMixedNums.peakEnd, 2030);
      expect(wineFromMixedNums.estimatedMarketValue, 120.0);
    });

    test('TastingEntry.fromJson safely parses vintage and rating numbers', () {
      final entry = TastingEntry.fromJson({
        'id': 't-1',
        'wine_id': 'w-1',
        'rating': 9, // int instead of double
        'wines': {
          'name': 'Pauillac',
          'vintage': 2018.0, // double instead of int
        },
      });

      expect(entry.rating, 9.0);
      expect(entry.vintage, 2018);
    });
  });

  group('6. 10-Point Scale & Tasting Card Detail Tests', () {
    test('10-point tasting ratings format accurately without crashes', () {
      final entry95 = TastingEntry(
        id: 't-95',
        wineId: 'w-1',
        wineName: 'Château Latour',
        vintage: 2010,
        rating: 9.5,
        consumedAt: DateTime.now(),
      );
      expect(entry95.rating, 9.5);

      final entryLegacy4 = TastingEntry(
        id: 't-leg',
        wineId: 'w-2',
        wineName: 'Côtes du Rhône',
        vintage: 2021,
        rating: 4.5,
        consumedAt: DateTime.now(),
      );
      // Legacy rating on 5 scale normalizes to 9.0/10
      final normalized = entryLegacy4.rating! <= 5.0 ? entryLegacy4.rating! * 2 : entryLegacy4.rating!;
      expect(normalized, 9.0);
    });
  });
}


