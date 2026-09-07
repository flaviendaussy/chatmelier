import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/cellar/data/favorite_wines_service.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('FavoriteWinesNotifier & Favorites System', () {
    test('Can toggle favorite wines and persists in SharedPreferences', () async {
      final notifier = FavoriteWinesNotifier();
      expect(notifier.isFavorite('wine_123'), false);

      await notifier.toggleFavorite('wine_123');
      expect(notifier.isFavorite('wine_123'), true);
      expect(notifier.state.contains('wine_123'), true);

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('chatmelier_favorite_wine_ids');
      expect(list, contains('wine_123'));

      // Toggle off
      await notifier.toggleFavorite('wine_123');
      expect(notifier.isFavorite('wine_123'), false);
      expect(notifier.state.contains('wine_123'), false);
    });

    test('Loads pre-existing favorites on initialization', () async {
      SharedPreferences.setMockInitialValues({
        'chatmelier_favorite_wine_ids': ['fav_wine_1', 'fav_wine_2'],
      });

      final notifier = FavoriteWinesNotifier();
      // Allow async load to complete
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.isFavorite('fav_wine_1'), true);
      expect(notifier.isFavorite('fav_wine_2'), true);
      expect(notifier.isFavorite('other_wine'), false);
    });
  });

  group('Country Flag & Text Display on MenuWine', () {
    test('Resolves proper national flags for various wine origins', () {
      const frWine = MenuWine(
        id: '1',
        name: 'Chablis',
        producer: 'Dauvissat',
        wineType: 'white',
        country: 'France',
      );
      expect(frWine.countryFlag, '🇫🇷');
      expect(frWine.countryWithFlag, '🇫🇷 France');

      const itWine = MenuWine(
        id: '2',
        name: 'Barolo',
        producer: 'Conterno',
        wineType: 'red',
        country: 'Italie',
      );
      expect(itWine.countryFlag, '🇮🇹');
      expect(itWine.countryWithFlag, '🇮🇹 Italie');

      const esWine = MenuWine(
        id: '3',
        name: 'Rioja',
        producer: 'Lopez de Heredia',
        wineType: 'red',
        country: 'Espagne',
      );
      expect(esWine.countryFlag, '🇪🇸');
      expect(esWine.countryWithFlag, '🇪🇸 Espagne');

      const usWine = MenuWine(
        id: '4',
        name: 'Cabernet',
        producer: 'Opus One',
        wineType: 'red',
        country: 'États-Unis',
      );
      expect(usWine.countryFlag, '🇺🇸');
      expect(usWine.countryWithFlag, '🇺🇸 États-Unis');
    });
  });

  group('Dynamic 7-Axis Colour-Specific Radar Spider', () {
    test('Red wine maps strictly to 7 red axes', () {
      const redMetrics = MenuWineRadarMetrics(
        tannins: 9.0,
        body: 8.5,
        acidity: 7.0,
        fruit: 7.5,
        oak: 8.0,
        minerality: 6.0,
        sweetness: 2.0,
        butteriness: 1.0,
      );

      final values = redMetrics.toRedValues();
      expect(values.length, 7);
      expect(values[0], 9.0); // Tannins & Structure
      expect(values[1], 8.5); // Puissance & Corps
      expect(values[2], 7.0); // Fraîcheur & Acidité

      final labels = MenuWineRadarMetrics.redAxisLabels;
      expect(labels.length, 7);
      expect(labels[0].contains('Tannins'), true);
      expect(labels[6].contains('Persistance'), true);
    });

    test('White wine maps strictly to 7 white axes including Beurré', () {
      const whiteMetrics = MenuWineRadarMetrics(
        tannins: 0.2,
        body: 7.0,
        acidity: 8.5,
        fruit: 6.5,
        oak: 7.0,
        minerality: 9.0,
        butteriness: 8.8,
        sweetness: 1.5,
      );

      final values = whiteMetrics.toWhiteValues();
      expect(values.length, 7);
      expect(values[0], 9.0); // Minéralité & Tension
      expect(values[1], 8.5); // Fraîcheur & Vivacité
      expect(values[3], 8.8); // Beurré & Rondeur

      final labels = MenuWineRadarMetrics.whiteAxisLabels;
      expect(labels.length, 7);
      expect(labels[3].contains('Beurré'), true);
    });
  });

  group('Taste Profile Incompleteness Handling', () {
    test('calculateMatch returns null when profile is null or not well provided', () {
      const wine = MenuWine(
        id: 'test_wine',
        name: 'Crozes-Hermitage',
        producer: 'Jaboulet',
        wineType: 'red',
        metrics: MenuWineRadarMetrics(
          tannins: 7.0,
          body: 8.0,
          acidity: 6.0,
          fruit: 7.5,
        ),
      );

      // Null profile
      expect(MenuWineMatchCalculator.calculateMatch(wine, null), isNull);

      // Incomplete profile (< 3 questionnaires and < 3 explicit preferences)
      const incompleteProfile = TasteProfile(
        id: 'prof_inc',
        name: 'Incomplet',
        questionnairesCompleted: 1,
      );
      expect(MenuWineMatchCalculator.calculateMatch(wine, incompleteProfile), isNull);

      // Complete profile
      const matureProfile = TasteProfile(
        id: 'prof_mat',
        name: 'Connaisseur',
        questionnairesCompleted: 4,
        favoriteTypes: ['Rouge', 'Bordeaux', 'Rhône'],
      );
      expect(MenuWineMatchCalculator.calculateMatch(wine, matureProfile), isNotNull);
      expect(MenuWineMatchCalculator.calculateMatch(wine, matureProfile)!, inInclusiveRange(0.0, 100.0));
    });
  });

  group('Matchmaker Pre-Filtering & Price Question Logic', () {
    test('Pre-filtering whites restricts matchmaking pool to whites only', () {
      final allWines = [
        const MenuWine(id: 'r1', name: 'Syrah', producer: 'P1', wineType: 'red'),
        const MenuWine(id: 'w1', name: 'Riesling', producer: 'P2', wineType: 'white'),
        const MenuWine(id: 'w2', name: 'Meursault', producer: 'P3', wineType: 'white'),
        const MenuWine(id: 'ros1', name: 'Bandol', producer: 'P4', wineType: 'rose'),
      ];

      // Pre-filter whites only (as done in EnrichedMenuScreen)
      final prefilteredWhites = allWines.where((w) => w.wineType == 'white').toList();

      expect(prefilteredWhites.length, 2);
      expect(prefilteredWhites.every((w) => w.wineType == 'white'), true);
    });

    test('Mutual filter exclusions logic', () {
      // Rule: Red hides Beurré. Beurré hides Red.
      // White hides Tannique. Tannique hides White.
      bool isChipVisible({
        required String chip,
        required String? selectedType,
        required Set<String> selectedSensoryTags,
      }) {
        if (chip == 'beurré' && selectedType == 'red') return false;
        if (chip == 'tannique' && selectedType == 'white') return false;
        if (chip == 'red' && selectedSensoryTags.contains('beurré')) return false;
        if (chip == 'white' && selectedSensoryTags.contains('tannique')) return false;
        return true;
      }

      // If red is selected, beurré chip is hidden
      expect(isChipVisible(chip: 'beurré', selectedType: 'red', selectedSensoryTags: {}), false);
      expect(isChipVisible(chip: 'tannique', selectedType: 'red', selectedSensoryTags: {}), true);

      // If beurré tag is selected, red wine type chip is hidden
      expect(isChipVisible(chip: 'red', selectedType: null, selectedSensoryTags: {'beurré'}), false);
      expect(isChipVisible(chip: 'white', selectedType: null, selectedSensoryTags: {'beurré'}), true);

      // If white is selected, tannique chip is hidden
      expect(isChipVisible(chip: 'tannique', selectedType: 'white', selectedSensoryTags: {}), false);

      // If tannique is selected, white wine type chip is hidden
      expect(isChipVisible(chip: 'white', selectedType: null, selectedSensoryTags: {'tannique'}), false);
    });
  });
}
