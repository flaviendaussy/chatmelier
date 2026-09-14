import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/badges/data/badge_catalog.dart';
import 'package:chatmelier/features/badges/data/badge_evaluator.dart';
import 'package:chatmelier/features/badges/data/badge_unlock_tracker.dart';
import 'package:chatmelier/features/badges/domain/badge.dart';
import 'package:chatmelier/features/badges/presentation/badge_unlock_celebration_dialog.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/journal/domain/tasting_entry.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🍷 Contributing Items in BadgeEvaluator', () {
    test('Populates contributingItems for single matching bottle (Disaronno Amaretto)', () {
      final bottle = Bottle.fromJson({
        'id': 'b_amaretto_1',
        'cellar_id': 'c1',
        'wine_id': 'w_amaretto_1',
        'added_by': 'u1',
        'fill_level': 100,
        'wine': {
          'id': 'w_amaretto_1',
          'name': 'Disaronno Originale',
          'type': 'liqueur',
          'country': 'Italie',
          'vintage': 2021,
          'producer': 'Illva Saronno',
        },
      });

      final results = BadgeEvaluator.evaluate(bottles: [bottle], tastings: []);
      final progress = results.firstWhere((p) => p.badge.id == 'spirit_amaretto_italian');

      expect(progress.isUnlocked, isTrue);
      expect(progress.contributingItems.length, equals(1));
      final item = progress.contributingItems.first;
      expect(item.id, equals('b_amaretto_1'));
      expect(item.name, equals('Disaronno Originale'));
      expect(item.producer, equals('Illva Saronno'));
      expect(item.vintage, equals(2021));
      expect(item.isTasting, isFalse);
      expect(item.displaySubtitle, contains('2021'));
    });

    test('Populates contributingItems for tastings (Flight tasting & Cocktails)', () {
      final tasting = TastingEntry(
        id: 't_flight_1',
        wineId: 'w_flight_1',
        wineName: 'Pinot Noir Flight Verre 1',
        vintage: 2018,
        region: 'Bourgogne',
        wineType: 'red',
        rating: 4.5,
        tastingNotes: 'Superbe flight découverte à l aveugle',
        consumedAt: DateTime.now(),
      );

      final results = BadgeEvaluator.evaluate(bottles: [], tastings: [tasting]);
      final flightProgress = results.firstWhere((p) => p.badge.id == 'savant_flight_discovery');

      expect(flightProgress.contributingItems.length, equals(1));
      final item = flightProgress.contributingItems.first;
      expect(item.id, equals('t_flight_1'));
      expect(item.name, equals('Pinot Noir Flight Verre 1'));
      expect(item.isTasting, isTrue);
      expect(item.rating, equals(4.5));
      expect(item.displaySubtitle, contains('Dégustation Consignée'));
    });

    test('Scales gracefully with 500 bottles without memory or evaluation issues', () {
      final bottles = List.generate(500, (i) {
        return Bottle.fromJson({
          'id': 'b_$i',
          'cellar_id': 'c1',
          'wine_id': 'w_$i',
          'added_by': 'u1',
          'wine': {
            'id': 'w_$i',
            'name': 'Château Test $i',
            'type': 'red',
            'country': 'France',
            'region': 'Bordeaux',
            'appellation': 'Pauillac',
            'vintage': 2010 + (i % 14),
            'producer': 'Domaine Test $i',
          },
        });
      });

      final results = BadgeEvaluator.evaluate(bottles: bottles, tastings: []);
      final bordeauxProgress = results.firstWhere((p) => p.badge.id == 'region_bordeaux');

      expect(bordeauxProgress.isUnlocked, isTrue);
      expect(bordeauxProgress.contributingItems.length, equals(500));

      final milestone500 = results.firstWhere((p) => p.badge.id == 'milestone_bottles_500');
      expect(milestone500.isUnlocked, isTrue);
      expect(milestone500.contributingItems.length, equals(500));
    });
  });

  group('🏆 Badge Celebration Popup & Dialog Widget Tests', () {
    testWidgets('BadgeUnlockCelebrationDialog renders correctly with single contributing wine', (tester) async {
      final badge = BadgeCatalog.allBadges.firstWhere((b) => b.id == 'spirit_amaretto_italian');
      const contributing = [
        ContributingItem(
          id: 'b1',
          name: 'Disaronno Originale',
          producer: 'Illva Saronno',
          vintage: 2022,
          type: 'liqueur',
        ),
      ];

      final progress = BadgeProgress(
        badge: badge,
        currentCount: 1,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        contributingItems: contributing,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          home: Scaffold(
            body: BadgeUnlockCelebrationDialog(progress: progress),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify header and badge title
      expect(find.text('✦ DISTINCTION DÉBLOQUÉE ✦'), findsOneWidget);
      expect(find.text(badge.title), findsOneWidget);
      expect(find.textContaining('Rang'), findsOneWidget);

      // Verify contributing bottle callout
      expect(find.text('Débloqué grâce à ce flacon :'), findsOneWidget);
      expect(find.text('Disaronno Originale'), findsOneWidget);

      // Verify buttons
      expect(find.text('Merveilleux !'), findsOneWidget);
      expect(find.text('Galerie'), findsOneWidget);
    });

    testWidgets('BadgeUnlockCelebrationDialog renders with expandable list when multiple wines contribute', (tester) async {
      final badge = BadgeCatalog.allBadges.firstWhere((b) => b.id == 'region_bordeaux');
      final contributing = [
        const ContributingItem(
          id: 'b1',
          name: 'Château Margaux',
          producer: 'Margaux',
          vintage: 2015,
        ),
        const ContributingItem(
          id: 'b2',
          name: 'Château Latour',
          producer: 'Pauillac',
          vintage: 2010,
        ),
        const ContributingItem(
          id: 'b3',
          name: 'Château Haut-Brion',
          producer: 'Pessac-Léognan',
          vintage: 2018,
        ),
      ];

      final progress = BadgeProgress(
        badge: badge,
        currentCount: 3,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        contributingItems: contributing,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          home: Scaffold(
            body: BadgeUnlockCelebrationDialog(progress: progress),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Débloqué grâce à vos flacons (3) :'), findsOneWidget);
      expect(find.text('Château Margaux'), findsOneWidget);
      expect(find.text('+ 2 autres flacons...'), findsOneWidget);

      // Tap expander
      await tester.tap(find.text('+ 2 autres flacons...'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Masquer la liste'), findsOneWidget);
      expect(find.text('Château Latour'), findsOneWidget);
      expect(find.text('Château Haut-Brion'), findsOneWidget);
    });
  });

  group('⚙️ Badge Celebration Animation Settings & Opt-Out', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Badge celebration animations are enabled by default', () async {
      final enabled = await BadgeUnlockTracker.areAnimationsEnabled();
      expect(enabled, isTrue);
    });

    test('Badge celebration animations can be disabled and re-enabled', () async {
      await BadgeUnlockTracker.setAnimationsEnabled(false);
      expect(await BadgeUnlockTracker.areAnimationsEnabled(), isFalse);

      await BadgeUnlockTracker.setAnimationsEnabled(true);
      expect(await BadgeUnlockTracker.areAnimationsEnabled(), isTrue);
    });

    testWidgets('BadgeUnlockCelebrationDialog allows user to opt-out via text button', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final badge = BadgeCatalog.allBadges.firstWhere((b) => b.id == 'spirit_amaretto_italian');
      final progress = BadgeProgress(
        badge: badge,
        currentCount: 1,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        contributingItems: const [
          ContributingItem(id: 'b1', name: 'Disaronno', producer: 'Illva'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: BadgeUnlockCelebrationDialog(progress: progress),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Check opt-out button exists
      final optOutFinder = find.text('Ne plus afficher ces animations');
      expect(optOutFinder, findsOneWidget);

      // Scroll into view if needed and tap opt-out button
      await tester.ensureVisible(optOutFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(optOutFinder);
      await tester.pump(const Duration(milliseconds: 200));

      // Check preference is set to false
      expect(await BadgeUnlockTracker.areAnimationsEnabled(), isFalse);
    });
  });
}
