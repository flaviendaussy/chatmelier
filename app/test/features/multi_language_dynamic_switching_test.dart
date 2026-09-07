import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:go_router/go_router.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/shared/providers/locale_provider.dart';
import 'package:chatmelier/shared/widgets/adaptive_app_shell.dart';
import 'package:chatmelier/features/auth/presentation/profile_screen.dart';
import 'package:chatmelier/features/badges/domain/badge.dart';
import 'package:chatmelier/features/badges/data/badges_provider.dart';
import 'package:chatmelier/shared/providers/auth_provider.dart';
import 'package:chatmelier/features/auth/data/auth_repository.dart';
import 'package:chatmelier/features/auth/domain/user_profile.dart';
import 'package:chatmelier/features/offline/data/offline_storage_service.dart';
import 'package:chatmelier/features/offline/presentation/sync_provider.dart';
import 'package:chatmelier/shared/providers/cellar_provider.dart';
import 'package:chatmelier/features/friends/data/friends_repository.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/cellar_furniture.dart';
import 'package:chatmelier/features/cellar/domain/cellar_sort_by.dart';
import 'package:chatmelier/features/cellar/domain/cellar_group_by.dart';
import 'package:chatmelier/features/cocktails/domain/bar_pantry_item.dart';

class _MockAuthRepo implements AuthRepository {
  @override
  Stream<sb.AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<UserProfile?> getProfile(String userId) async {
    return const UserProfile(
      id: 'test_u',
      displayName: 'Sommelier International',
      username: 'sommelier_world',
      phoneNumber: '+33611223344',
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('12-Language Localization Completeness & Switching', () {
    test('All 12 expected locales are supported by AppLocalizations', () {
      final supportedCodes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
      const expectedCodes = {
        'fr', 'en', 'it', 'es', 'ca', 'pt', 'nl', 'de', 'ja', 'zh', 'ko', 'sv'
      };

      for (final code in expectedCodes) {
        expect(supportedCodes.contains(code), isTrue,
            reason: 'Locale $code should be in AppLocalizations.supportedLocales');
      }
    });

    testWidgets('BadgeCategory and BadgeTier display authentic translations in all 12 locales', (tester) async {
      final testLocales = [
        const Locale('fr'),
        const Locale('en'),
        const Locale('it'),
        const Locale('es'),
        const Locale('ca'),
        const Locale('pt'),
        const Locale('nl'),
        const Locale('de'),
        const Locale('ja'),
        const Locale('zh'),
        const Locale('ko'),
        const Locale('sv'),
      ];

      for (final loc in testLocales) {
        await tester.pumpWidget(
          MaterialApp(
            locale: loc,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) {
                for (final cat in BadgeCategory.values) {
                  final lbl = cat.label(ctx);
                  expect(lbl.isNotEmpty, isTrue,
                      reason: 'Category $cat should have non-empty label for ${loc.languageCode}');
                }
                for (final tier in BadgeTier.values) {
                  final tLbl = tier.label(ctx);
                  expect(tLbl.isNotEmpty, isTrue,
                      reason: 'Tier $tier should have non-empty label for ${loc.languageCode}');
                }

                if (loc.languageCode == 'it') {
                  expect(BadgeCategory.milestones.label(ctx), 'Traguardi Cantina');
                  expect(BadgeCategory.grapes.label(ctx), 'Vitigni');
                  expect(BadgeCategory.chatmelierSavant.label(ctx), 'Il Chatmelier Sapiente');
                } else if (loc.languageCode == 'es') {
                  expect(BadgeCategory.milestones.label(ctx), 'Hitos de Bodega');
                  expect(BadgeCategory.grapes.label(ctx), 'Variedades de Uva');
                  expect(BadgeCategory.chatmelierSavant.label(ctx), 'El Chatmelier Erudito');
                } else if (loc.languageCode == 'ca') {
                  expect(BadgeCategory.milestones.label(ctx), 'Fites de Celler');
                  expect(BadgeCategory.grapes.label(ctx), 'Varietats de Raïm');
                } else if (loc.languageCode == 'de') {
                  expect(BadgeCategory.milestones.label(ctx), 'Keller-Meilensteine');
                  expect(BadgeCategory.grapes.label(ctx), 'Rebsorten');
                } else if (loc.languageCode == 'ja') {
                  expect(BadgeCategory.milestones.label(ctx), 'セラーのマイルストーン');
                  expect(BadgeCategory.grapes.label(ctx), 'ブドウ品種');
                } else if (loc.languageCode == 'zh') {
                  expect(BadgeCategory.milestones.label(ctx), '酒窖里程碑');
                  expect(BadgeCategory.grapes.label(ctx), '葡萄品种');
                }

                return const SizedBox();
              },
            ),
          ),
        );
      }
    });

    testWidgets('App navigation destinations update dynamically across multiple locales', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesInstanceProvider.overrideWithValue(prefs),
          currentCellarRoleProvider.overrideWithValue('owner'),
        ],
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AdaptiveAppShell(child: child),
            routes: [
              GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('Home Content'))),
              GoRoute(path: '/bar', builder: (_, __) => const Scaffold(body: Text('Bar Content'))),
              GoRoute(path: '/chat', builder: (_, __) => const Scaffold(body: Text('Chat Content'))),
              GoRoute(path: '/history', builder: (_, __) => const Scaffold(body: Text('History Content'))),
              GoRoute(path: '/stats', builder: (_, __) => const Scaffold(body: Text('Stats Content'))),
              GoRoute(path: '/profile', builder: (_, __) => const Scaffold(body: Text('Profile Content'))),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final userLocale = ref.watch(localeProvider);
              return MaterialApp.router(
                routerConfig: router,
                locale: userLocale ?? const Locale('fr'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In French (default)
      expect(find.text('Cave'), findsWidgets);
      expect(find.text('Bar'), findsWidgets);
      expect(find.text('Chat'), findsWidgets);
      expect(find.text('Degust.'), findsWidgets);
      expect(find.text('Profil'), findsWidgets);

      // Switch to Italian
      container.read(localeProvider.notifier).setLocale(const Locale('it'));
      await tester.pumpAndSettle();

      expect(find.text('Cantina'), findsWidgets);
      expect(find.text('Profilo'), findsWidgets);
      expect(find.text('Storico'), findsWidgets);

      // Switch to Spanish
      container.read(localeProvider.notifier).setLocale(const Locale('es'));
      await tester.pumpAndSettle();

      expect(find.text('Bodega'), findsWidgets);
      expect(find.text('Perfil'), findsWidgets);
      expect(find.text('Historial'), findsWidgets);

      // Switch to German
      container.read(localeProvider.notifier).setLocale(const Locale('de'));
      await tester.pumpAndSettle();

      expect(find.text('Keller'), findsWidgets);
      expect(find.text('Profil'), findsWidgets);

      // Switch to Japanese
      container.read(localeProvider.notifier).setLocale(const Locale('ja'));
      await tester.pumpAndSettle();

      expect(find.text('セラー'), findsWidgets);
      expect(find.text('マイページ'), findsWidgets);

      // Switch to Chinese
      container.read(localeProvider.notifier).setLocale(const Locale('zh'));
      await tester.pumpAndSettle();

      expect(find.text('酒窖'), findsWidgets);
      expect(find.text('个人'), findsWidgets);

      // Verify preference was persisted in SharedPreferences
      expect(prefs.getString('user_selected_locale'), 'zh');
    });

    testWidgets('ProfileScreen tabs translate accurately across locales', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockAuth = _MockAuthRepo();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesInstanceProvider.overrideWithValue(prefs),
          offlineStorageServiceProvider.overrideWithValue(OfflineStorageService(prefs)),
          authRepositoryProvider.overrideWithValue(mockAuth),
          currentUserProvider.overrideWithValue(
            const sb.User(
              id: 'test_u',
              appMetadata: {},
              userMetadata: {'display_name': 'Sommelier International'},
              aud: 'authenticated',
              createdAt: '2026-01-01',
            ),
          ),
          userCellarsProvider.overrideWith((ref) async => [
                {'cellar_id': 'cellar_1', 'cellars': {'name': 'Grand Cru Cellar'}, 'role': 'owner'}
              ]),
          unreadNotificationsCountProvider.overrideWith((ref) => 0),
          userBadgesProgressProvider.overrideWithValue([]),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final userLocale = ref.watch(localeProvider);
              return MaterialApp(
                locale: userLocale ?? const Locale('fr'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const ProfileScreen(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // French tabs
      expect(find.text('Palais'), findsOneWidget);
      expect(find.text('Réglages'), findsOneWidget);
      expect(find.text('Outils'), findsOneWidget);
      expect(find.text('Compte'), findsOneWidget);

      // Switch to English
      container.read(localeProvider.notifier).setLocale(const Locale('en'));
      await tester.pumpAndSettle();

      expect(find.text('Palate'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Tools'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      // Switch to Italian
      container.read(localeProvider.notifier).setLocale(const Locale('it'));
      await tester.pumpAndSettle();

      expect(find.text('Palato'), findsOneWidget);
      expect(find.text('Impostazioni'), findsOneWidget);
      expect(find.text('Strumenti'), findsOneWidget);

      // Switch to German
      container.read(localeProvider.notifier).setLocale(const Locale('de'));
      await tester.pumpAndSettle();

      expect(find.text('Gaumen'), findsOneWidget);
      expect(find.text('Einstellungen'), findsOneWidget);
      expect(find.text('Werkzeuge'), findsOneWidget);
      expect(find.text('Konto'), findsOneWidget);
    });

    test('Cellar and Cocktail domain models localize correctly in English and French', () {
      // CellarSortBy
      expect(CellarSortBy.vintageAsc.localizedLabel(true), 'Millésime (Plus ancien)');
      expect(CellarSortBy.vintageAsc.localizedLabel(false), 'Vintage (Oldest)');
      expect(CellarSortBy.priceDesc.localizedLabel(true), 'Prix / Valeur (Plus cher)');
      expect(CellarSortBy.priceDesc.localizedLabel(false), 'Price / Value (Highest)');

      // CellarGroupBy
      expect(CellarGroupBy.color.localizedLabel(true), 'Couleur');
      expect(CellarGroupBy.color.localizedLabel(false), 'Color');
      expect(CellarGroupBy.region.localizedLabel(true), 'Région');
      expect(CellarGroupBy.region.localizedLabel(false), 'Region');
      expect(CellarGroupBy.vintage.localizedLabel(true), 'Millésime');
      expect(CellarGroupBy.vintage.localizedLabel(false), 'Vintage');
      expect(CellarGroupBy.maturity.localizedLabel(true), 'Maturité / Apogée');
      expect(CellarGroupBy.maturity.localizedLabel(false), 'Maturity / Peak');

      // CellarFurniture slot code description
      expect(CellarFurniture.describeSlotCode('A1', true), 'A1 (1ère colonne, 1ère rangée)');
      expect(CellarFurniture.describeSlotCode('A1', false), 'A1 (1st column, 1st row)');
      expect(CellarFurniture.describeSlotCode('B2', false), 'B2 (2nd column, 2nd row)');
      expect(CellarFurniture.describeSlotCode('placard', true), 'Rangement libre (sans case fixe)');
      expect(CellarFurniture.describeSlotCode('closet', false), 'Free placement (no fixed slot)');

      // Bottle location and provenance
      final now = DateTime(2026, 1, 1);
      final testBottle = Bottle(
        id: 'b1',
        cellarId: 'c1',
        wineId: 'w1',
        addedBy: 'u1',
        ownerId: 'u1',
        createdAt: now,
        sourceType: 'gift',
        sourceDetails: 'Alice',
        rack: 'A',
        shelf: '2',
      );
      expect(testBottle.getLocationSummary(true), 'Casier A • Tablette 2');
      expect(testBottle.getLocationSummary(false), 'Rack A • Shelf 2');
      expect(testBottle.getProvenanceDisplay(true), '🎁 Offert par Alice');
      expect(testBottle.getProvenanceDisplay(false), '🎁 Gift from Alice');

      final boughtBottle = Bottle(
        id: 'b2',
        cellarId: 'c1',
        wineId: 'w2',
        addedBy: 'u1',
        ownerId: 'u1',
        createdAt: now,
        sourceType: 'merchant',
        sourceDetails: 'La Maison du Whisky',
      );
      expect(boughtBottle.getProvenanceDisplay(true), '🏪 Caviste : La Maison du Whisky');
      expect(boughtBottle.getProvenanceDisplay(false), '🏪 Wine merchant: La Maison du Whisky');

      // PantryCategory labels
      expect(PantryCategory.ice.label(true), 'Glaçons & Glace');
      expect(PantryCategory.ice.label(false), 'Ice & Cubes');
      expect(PantryCategory.fruits.label(true), 'Agrumes & Fruits');
      expect(PantryCategory.fruits.label(false), 'Citrus & Fruits');
      expect(PantryCategory.herbs.label(true), 'Herbes & Épices');
      expect(PantryCategory.herbs.label(false), 'Herbs & Spices');
      expect(PantryCategory.mixers.label(true), 'Mixers & Softs');
      expect(PantryCategory.mixers.label(false), 'Mixers & Sodas');
      expect(PantryCategory.syrups.label(true), 'Sirops & Bitters');
      expect(PantryCategory.syrups.label(false), 'Syrups & Bitters');
      expect(PantryCategory.custom.label(true), 'Personnalisés');
      expect(PantryCategory.custom.label(false), 'Custom');
    });
  });
}

