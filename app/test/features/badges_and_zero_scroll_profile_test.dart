import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:chatmelier/features/badges/domain/badge.dart';
import 'package:chatmelier/features/badges/data/badge_catalog.dart';
import 'package:chatmelier/features/badges/data/badge_evaluator.dart';
import 'package:chatmelier/features/badges/data/badges_provider.dart';
import 'package:chatmelier/features/badges/presentation/badges_gallery_sheet.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/domain/tasting_entry.dart';
import 'package:chatmelier/features/cocktails/domain/bar_pantry_item.dart';
import 'package:chatmelier/features/auth/presentation/profile_screen.dart';
import 'package:chatmelier/shared/providers/auth_provider.dart';
import 'package:chatmelier/features/auth/data/auth_repository.dart';
import 'package:chatmelier/features/auth/domain/user_profile.dart';
import 'package:chatmelier/features/offline/data/offline_storage_service.dart';
import 'package:chatmelier/features/offline/presentation/sync_provider.dart';
import 'package:chatmelier/features/friends/data/friends_repository.dart';
import 'package:chatmelier/shared/providers/cellar_provider.dart';
import 'package:chatmelier/l10n/app_localizations.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Stream<sb.AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<UserProfile?> getProfile(String userId) async {
    return const UserProfile(
      id: 'test_user',
      displayName: 'Sommelier Testeur',
      username: 'sommelier_expert',
      phoneNumber: '+33612345678',
      defaultCurrency: 'EUR',
    );
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    String? username,
    String? phoneNumber,
    String? email,
    String? avatarUrl,
    String? defaultCurrency,
    Map<String, dynamic>? tasteProfileData,
  }) async {}

  @override
  Future<bool> isPhoneAvailable(String phone, {String? excludeUserId}) async => true;

  @override
  Future<bool> isUsernameAvailable(String username, {String? excludeUserId}) async => true;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signOut() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Bottle _testBottle({
  required String id,
  required Wine wine,
  double? purchasePrice,
  String? notes,
}) {
  return Bottle(
    id: id,
    cellarId: 'c1',
    wineId: wine.id,
    addedBy: 'u1',
    ownerId: 'u1',
    createdAt: DateTime(2026, 1, 1),
    wine: wine,
    purchasePrice: purchasePrice,
    notes: notes,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BadgeCatalog & Domain Tests', () {
    test('BadgeCatalog contains 50+ diverse badges across all 10 categories', () {
      const badges = BadgeCatalog.allBadges;
      expect(badges.length, greaterThanOrEqualTo(50));

      for (final cat in BadgeCategory.values) {
        final inCat = badges.where((b) => b.category == cat).toList();
        expect(inCat.isNotEmpty, isTrue, reason: 'Category $cat should have at least 1 badge');
      }
    });

    test('Chatmelier lore is informative and non-empty for every badge', () {
      for (final b in BadgeCatalog.allBadges) {
        expect(b.chatmelierLore.trim().length, greaterThanOrEqualTo(20),
            reason: 'Badge ${b.id} must have rich Chatmelier lore');
        expect(b.emoji.isNotEmpty, isTrue);
        expect(b.title.isNotEmpty, isTrue);
      }
    });
  });

  group('BadgeEvaluator Pure Logic Engine Tests', () {
    test('Evaluates Cellar Milestones (Bottles & Tastings) progression tiers', () {
      final bottles10 = List.generate(
        12,
        (i) => _testBottle(
          id: 'b_$i',
          wine: Wine(id: 'w_$i', name: 'Vin $i', type: 'red', country: 'France', region: 'Bordeaux'),
        ),
      );

      final tastings5 = List.generate(
        6,
        (i) => TastingEntry(
          id: 't_$i',
          wineId: 'w_$i',
          wineName: 'Dégustation $i',
          consumedAt: DateTime.now(),
        ),
      );

      final results = BadgeEvaluator.evaluate(bottles: bottles10, tastings: tastings5);

      final b10 = results.firstWhere((p) => p.badge.id == 'milestone_bottles_10');
      final b50 = results.firstWhere((p) => p.badge.id == 'milestone_bottles_50');
      final t5 = results.firstWhere((p) => p.badge.id == 'milestone_tastings_5');
      final t25 = results.firstWhere((p) => p.badge.id == 'milestone_tastings_25');

      expect(b10.isUnlocked, isTrue);
      expect(b10.currentCount, equals(12));
      expect(b50.isUnlocked, isFalse);
      expect(b50.currentCount, equals(12));

      expect(t5.isUnlocked, isTrue);
      expect(t5.currentCount, equals(6));
      expect(t25.isUnlocked, isFalse);
      expect(t25.currentCount, equals(6));
    });

    test('Evaluates Old World, New World, and Globe Trotter continents', () {
      final bottles = [
        _testBottle(
          id: 'b1',
          wine: const Wine(
            id: 'w1',
            name: 'Château Margaux',
            type: 'red',
            country: 'France',
            region: 'Bordeaux',
          ),
        ),
        _testBottle(
          id: 'b2',
          wine: const Wine(
            id: 'w2',
            name: 'Opus One',
            type: 'red',
            country: 'USA',
            region: 'Napa Valley',
          ),
        ),
        _testBottle(
          id: 'b3',
          wine: const Wine(
            id: 'w3',
            name: 'Vega Sicilia Único',
            type: 'red',
            country: 'Espagne',
            region: 'Ribera del Duero',
          ),
        ),
      ];

      final List<TastingEntry> tastings = [
        TastingEntry(
          id: 't1',
          wineId: 'w_ext1',
          wineName: 'Barolo Monfortino',
          country: 'Italie',
          region: 'Piémont',
          consumedAt: DateTime.now(),
        ),
        TastingEntry(
          id: 't2',
          wineId: 'w_ext2',
          wineName: 'Catena Zapata Malbec',
          country: 'Argentine',
          region: 'Mendoza',
          consumedAt: DateTime.now(),
        ),
        TastingEntry(
          id: 't3',
          wineId: 'w_ext3',
          wineName: 'Penfolds Grange',
          country: 'Australie',
          region: 'Barossa',
          consumedAt: DateTime.now(),
        ),
      ];

      final results = BadgeEvaluator.evaluate(bottles: bottles, tastings: tastings);

      final oldWorld = results.firstWhere((p) => p.badge.id == 'continent_old_world');
      final newWorld = results.firstWhere((p) => p.badge.id == 'continent_new_world');
      final globeTrotter = results.firstWhere((p) => p.badge.id == 'continent_globe_trotter');

      expect(oldWorld.isUnlocked, isTrue); // France + Espagne + Italie (3) >= 3
      expect(oldWorld.currentCount, greaterThanOrEqualTo(3));
      expect(newWorld.isUnlocked, isTrue); // USA + Argentine + Australie (3) >= 2
      expect(newWorld.currentCount, greaterThanOrEqualTo(3));
      expect(globeTrotter.isUnlocked, isTrue); // 6 countries >= 5
      expect(globeTrotter.currentCount, greaterThanOrEqualTo(5));
    });

    test('Evaluates Looser & Autodérision Badges correctly', () {
      final bottles = [
        _testBottle(
          id: 'b_cheap',
          purchasePrice: 2.49, // < 3€
          wine: const Wine(
            id: 'w_cheap',
            name: 'Vin de Table Carton',
            type: 'red',
            country: 'France',
            region: 'Inconnue',
            vintage: 1998,
            drinkStart: 2000,
            drinkEnd: 2010, // Vinaigrier en chef (past peak)
          ),
        ),
      ];

      final List<TastingEntry> tastings = [
        TastingEntry(
          id: 't_terrible',
          wineId: 'w_terrible',
          wineName: 'Cuvée Douteuse',
          rating: 1.5, // <= 2.0 (Masochiste)
          tastingNotes: 'Gout affreux de bouchon et tca intense', // TCA Traqueur
          coTasters: const [], // Loup solitaire
          consumedAt: DateTime.now(),
        ),
      ];

      final results = BadgeEvaluator.evaluate(bottles: bottles, tastings: tastings);

      final piquette = results.firstWhere((p) => p.badge.id == 'looser_piquette');
      final pastPeak = results.firstWhere((p) => p.badge.id == 'looser_past_peak');
      final masochist = results.firstWhere((p) => p.badge.id == 'looser_masochist');
      final bouchonne = results.firstWhere((p) => p.badge.id == 'looser_bouchonne');
      final solo = results.firstWhere((p) => p.badge.id == 'looser_solo');

      expect(piquette.isUnlocked, isTrue);
      expect(pastPeak.isUnlocked, isTrue);
      expect(masochist.isUnlocked, isTrue);
      expect(bouchonne.isUnlocked, isTrue);
      expect(solo.isUnlocked, isTrue);
    });

    test('Evaluates Le Chatmelier Savant (Historical & Scientific) Badges', () {
      final bottles = [
        _testBottle(
          id: 'b_bio',
          notes: 'Levures indigènes et vinification naturelle',
          wine: const Wine(
            id: 'w_bio',
            name: 'Cuvée Vivante',
            type: 'red',
            country: 'France',
            region: 'Loire',
            classification: 'Demeter Biodynamie',
          ),
        ),
        _testBottle(
          id: 'b_cist',
          wine: const Wine(
            id: 'w_cist',
            name: 'Chablis Grand Cru Les Clos',
            type: 'white',
            country: 'France',
            region: 'Bourgogne',
            appellation: 'Chablis',
          ),
        ),
        _testBottle(
          id: 'b_nap',
          wine: const Wine(
            id: 'w_nap',
            name: 'Gevrey-Chambertin Premier Cru',
            type: 'red',
            country: 'France',
            region: 'Bourgogne',
          ),
        ),
        _testBottle(
          id: 'b_volc',
          wine: const Wine(
            id: 'w_volc',
            name: 'Etna Rosso Contrada Rampante',
            type: 'red',
            country: 'Italie',
            region: 'Sicile',
          ),
        ),
        _testBottle(
          id: 'b_extra',
          wine: const Wine(
            id: 'w_extra',
            name: 'Domaine de la Romanée-Conti',
            type: 'red',
            country: 'France',
            region: 'Bourgogne',
          ),
        ),
        _testBottle(
          id: 'b_amphore',
          wine: const Wine(
            id: 'w_amphore',
            name: 'Qvevri Rkatsiteli',
            type: 'orange',
            country: 'Géorgie',
            region: 'Kakhétie',
            classification: 'Vin en jarre d\'argile',
          ),
        ),
        _testBottle(
          id: 'b_sauternes',
          wine: const Wine(
            id: 'w_sauternes',
            name: 'Château d\'Yquem Premier Cru Supérieur',
            type: 'sweet',
            country: 'France',
            region: 'Bordeaux',
            appellation: 'Sauternes',
          ),
        ),
        _testBottle(
          id: 'b_beauj',
          wine: const Wine(
            id: 'w_beauj',
            name: 'Morgon Lapierre',
            type: 'red',
            country: 'France',
            region: 'Beaujolais',
            appellation: 'Morgon',
          ),
        ),
      ];

      final results = BadgeEvaluator.evaluate(bottles: bottles, tastings: const []);

      final pasteur = results.firstWhere((p) => p.badge.id == 'savant_pasteur');
      final cistercien = results.firstWhere((p) => p.badge.id == 'savant_cistercien');
      final napoleon = results.firstWhere((p) => p.badge.id == 'savant_napoleon');
      final volcan = results.firstWhere((p) => p.badge.id == 'savant_volcan');
      final biodynamie = results.firstWhere((p) => p.badge.id == 'savant_biodynamie');
      final phylloxera = results.firstWhere((p) => p.badge.id == 'savant_phylloxera');
      final amphore = results.firstWhere((p) => p.badge.id == 'savant_amphore');
      final botrytis = results.firstWhere((p) => p.badge.id == 'savant_botrytis');
      final carbonique = results.firstWhere((p) => p.badge.id == 'savant_maceration_carbonique');
      final kimmeridgien = results.firstWhere((p) => p.badge.id == 'savant_kimmeridgien');

      expect(pasteur.isUnlocked, isTrue);
      expect(cistercien.isUnlocked, isTrue);
      expect(napoleon.isUnlocked, isTrue);
      expect(volcan.isUnlocked, isTrue);
      expect(biodynamie.isUnlocked, isTrue);
      expect(phylloxera.isUnlocked, isTrue);
      expect(amphore.isUnlocked, isTrue);
      expect(botrytis.isUnlocked, isTrue);
      expect(carbonique.isUnlocked, isTrue);
      expect(kimmeridgien.isUnlocked, isTrue);
    });

    test('Evaluates Cocktails & Pantry Badges', () {
      final List<TastingEntry> tastings = [
        TastingEntry(
          id: 't_cocktail1',
          wineId: 'w_ck1',
          wineName: 'Negroni Parfait',
          wineType: 'Cocktail',
          consumedAt: DateTime.now(),
        ),
        TastingEntry(
          id: 't_cocktail2',
          wineId: 'w_ck2',
          wineName: 'Old Fashioned',
          wineType: 'Cocktail',
          consumedAt: DateTime.now(),
        ),
      ];

      final pantry = [
        const BarPantryItem(id: 'ice', name: 'Glaçons', category: PantryCategory.ice, quantity: 2),
        const BarPantryItem(id: 'lime', name: 'Citron vert', category: PantryCategory.fruits, quantity: 4),
        const BarPantryItem(id: 'mint', name: 'Menthe', category: PantryCategory.herbs, quantity: 1),
        const BarPantryItem(id: 'mixer1', name: 'Tonic', category: PantryCategory.mixers, quantity: 1),
        const BarPantryItem(id: 'syrup1', name: 'Sirop simple', category: PantryCategory.syrups, quantity: 1),
      ];

      final results = BadgeEvaluator.evaluate(bottles: const [], tastings: tastings, pantry: pantry);

      final apprentice = results.firstWhere((p) => p.badge.id == 'cocktail_apprentice');
      final master = results.firstWhere((p) => p.badge.id == 'cocktail_master');
      final pantryBadge = results.firstWhere((p) => p.badge.id == 'cocktail_pantry');

      expect(apprentice.isUnlocked, isTrue);
      expect(master.currentCount, equals(2)); // 2 unique cocktails out of 5 required
      expect(pantryBadge.isUnlocked, isTrue); // 5 stocked ingredients >= 5
    });
  });

  group('Badges Gallery & Detail Presentation Widgets', () {
    testWidgets('BadgesGallerySheet displays badges, category filters, and detail modal with Chatmelier lore',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userBadgesProgressProvider.overrideWithValue([
              BadgeProgress(
                badge: BadgeCatalog.allBadges.firstWhere((b) => b.id == 'looser_piquette'),
                currentCount: 2,
                isUnlocked: true,
                unlockedAt: DateTime.now(),
              ),
              BadgeProgress(
                badge: BadgeCatalog.allBadges.firstWhere((b) => b.id == 'savant_pasteur'),
                currentCount: 0,
                isUnlocked: false,
              ),
            ]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: Scaffold(
              body: BadgesGallerySheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check title and categories
      expect(find.text('Galerie des Trophées'), findsOneWidget);
      expect(find.textContaining('Tous'), findsOneWidget);
      expect(find.textContaining('Piquette'), findsOneWidget);

      // Tap on the badge card to open Chatmelier lore dialog
      await tester.tap(find.textContaining('Piquette'));
      await tester.pumpAndSettle();

      // Verify Chatmelier Science & Lore header and text
      expect(find.text('La Science & l\'Histoire du Chatmelier'), findsOneWidget);
      expect(find.textContaining('barbecue'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(find.text('La Science & l\'Histoire du Chatmelier'), findsNothing);
    });

    testWidgets('BadgesShowcaseCard renders summary and gallery button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userBadgesProgressProvider.overrideWithValue([
              BadgeProgress(
                badge: BadgeCatalog.allBadges.firstWhere((b) => b.id == 'country_france'),
                currentCount: 5,
                isUnlocked: true,
              ),
            ]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: Scaffold(
              body: BadgesShowcaseCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Trophées & Badges'), findsOneWidget);
      expect(find.text('Galerie'), findsOneWidget);
      expect(find.textContaining('Hexagone'), findsOneWidget);
    });

    testWidgets('BadgesShowcaseCard renders English localization when locale is en', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userBadgesProgressProvider.overrideWithValue([
              BadgeProgress(
                badge: BadgeCatalog.allBadges.firstWhere((b) => b.id == 'looser_piquette'),
                currentCount: 1,
                isUnlocked: true,
              ),
            ]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: BadgesShowcaseCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Trophies & Badges'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.textContaining('Cheap Wine'), findsOneWidget);
    });
  });

  group('ProfileScreen Zero-Scroll Structure & Tab Switching Tests', () {
    testWidgets('ProfileScreen renders 4 tabs and allows instant zero-scroll access to settings',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'chatmelier_last_selected_cellar_id': 'cellar_1',
      });
      final prefs = await SharedPreferences.getInstance();
      final mockAuth = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesInstanceProvider.overrideWithValue(prefs),
            offlineStorageServiceProvider.overrideWithValue(OfflineStorageService(prefs)),
            authRepositoryProvider.overrideWithValue(mockAuth),
            currentUserProvider.overrideWithValue(
              const sb.User(
                id: 'test_user',
                appMetadata: {},
                userMetadata: {'display_name': 'Sommelier Testeur'},
                aud: 'authenticated',
                createdAt: '2026-01-01',
              ),
            ),
            userCellarsProvider.overrideWith((ref) async => [
                  {'cellar_id': 'cellar_1', 'cellars': {'name': 'Cave Principale'}, 'role': 'owner'}
                ]),
            unreadNotificationsCountProvider.overrideWith((ref) => 0),
            userBadgesProgressProvider.overrideWithValue([
              BadgeProgress(
                badge: BadgeCatalog.allBadges.firstWhere((b) => b.id == 'country_france'),
                currentCount: 3,
                isUnlocked: true,
              ),
            ]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header and 4 Tabs
      expect(find.text('Sommelier Testeur'), findsOneWidget);
      expect(find.text('@sommelier_expert'), findsOneWidget);
      expect(find.text('Palais'), findsOneWidget);
      expect(find.text('Réglages'), findsOneWidget);
      expect(find.text('Outils'), findsOneWidget);
      expect(find.text('Compte'), findsOneWidget);

      // Tab 0 (Palais & Badges) shows Radar and Badges Showcase
      expect(find.text('Radar des Goûts'), findsOneWidget);
      expect(find.text('Trophées & Badges'), findsOneWidget);

      // Switch to Tab 1: Réglages
      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();

      // Immediately visible without scrolling!
      expect(find.text('Langue de l\'application'), findsOneWidget);
      expect(find.text('Devise par défaut'), findsOneWidget);
      expect(find.text('Ambiance / Thème'), findsOneWidget);
      expect(find.textContaining('Notifications & Alertes'), findsOneWidget);

      // Switch to Tab 2: Outils
      await tester.tap(find.text('Outils'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Mes Amis & Cartes des Goûts'), findsOneWidget);
      expect(find.textContaining('Exporter ma Cave'), findsOneWidget);
      expect(find.textContaining('Carte à Gratter des Terroirs'), findsOneWidget);
      expect(find.textContaining('Journal des versions'), findsOneWidget);

      // Switch to Tab 3: Compte
      await tester.tap(find.text('Compte'));
      await tester.pumpAndSettle();

      expect(find.text('Nom d\'affichage'), findsOneWidget);
      expect(find.text('Numéro de téléphone'), findsOneWidget);
      expect(find.text('Politique de Confidentialité'), findsOneWidget);
      expect(find.text('Conditions Générales d\'Utilisation'), findsOneWidget);
      expect(find.text('Se déconnecter'), findsOneWidget);
      expect(find.text('Supprimer mon compte'), findsOneWidget);
    });
  });
}
