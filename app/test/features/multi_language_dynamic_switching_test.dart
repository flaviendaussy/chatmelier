import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:go_router/go_router.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/shared/l10n/fallback_localizations_delegates.dart';
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

  // Depuis la V2.3 (H6), l'app parle français, anglais et espagnol. Les dix autres `.arb`
  // attendent dans `l10n_plus_tard/` : ils reviendront avec leur catalogue de phrases
  // (`tool/langues`), sans quoi l'écran mêlerait leur langue et l'anglais.
  group('Langues de l\'app : français, anglais, espagnol', () {
    test('les traductions générées et le choix du profil proposent les trois mêmes langues', () {
      final codes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
      expect(codes, {'fr', 'en', 'es'});
      expect(kSupportedLanguageCodes.toSet(), codes);
    });

    test('une langue choisie avant la 72 et mise de côté revient à celle du téléphone', () async {
      SharedPreferences.setMockInitialValues({'user_selected_locale': 'it'});
      final notifier = LocaleNotifier();
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state, isNull);
      notifier.dispose();
    });

    testWidgets('BadgeCategory and BadgeTier display authentic translations in fr, en, es', (tester) async {
      for (final loc in const [Locale('fr'), Locale('en'), Locale('es')]) {
        await tester.pumpWidget(
          MaterialApp(
            locale: loc,
            localizationsDelegates: kAppLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) {
                for (final cat in BadgeCategory.values) {
                  expect(cat.label(ctx).isNotEmpty, isTrue,
                      reason: 'Category $cat should have non-empty label for ${loc.languageCode}');
                }
                for (final tier in BadgeTier.values) {
                  expect(tier.label(ctx).isNotEmpty, isTrue,
                      reason: 'Tier $tier should have non-empty label for ${loc.languageCode}');
                }
                if (loc.languageCode == 'es') {
                  expect(BadgeCategory.milestones.label(ctx), 'Hitos de Bodega');
                  expect(BadgeCategory.grapes.label(ctx), 'Variedades de Uva');
                  expect(BadgeCategory.chatmelierSavant.label(ctx), 'El Chatmelier Erudito');
                }
                return const SizedBox();
              },
            ),
          ),
        );
      }
    });

    testWidgets('App navigation destinations update dynamically across the three languages', (tester) async {
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
              GoRoute(path: '/ce-soir', builder: (_, __) => const Scaffold(body: Text('Tonight Content'))),
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
                localizationsDelegates: kAppLocalizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ce soir · Cave · Journal · Profil (V2.3 · E1) : le chat n'est plus un onglet.
      expect(find.text('Ce soir'), findsWidgets);
      expect(find.text('Cave'), findsWidgets);
      expect(find.text('Journal'), findsWidgets);
      expect(find.text('Profil'), findsWidgets);
      expect(find.text('Chat'), findsNothing);

      container.read(localeProvider.notifier).setLocale(const Locale('es'));
      await tester.pumpAndSettle();

      expect(find.text('Esta noche'), findsWidgets);
      expect(find.text('Bodega'), findsWidgets);
      expect(find.text('Diario'), findsWidgets);
      expect(find.text('Perfil'), findsWidgets);

      container.read(localeProvider.notifier).setLocale(const Locale('en'));
      await tester.pumpAndSettle();

      expect(find.text('Tonight'), findsWidgets);
      expect(find.text('Cellar'), findsWidgets);
      expect(find.text('Journal'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);

      expect(prefs.getString('user_selected_locale'), 'en');
    });

    testWidgets('ProfileScreen tabs translate accurately across the three languages', (tester) async {
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
                localizationsDelegates: kAppLocalizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const ProfileScreen(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Palais'), findsOneWidget);
      expect(find.text('Réglages'), findsOneWidget);
      expect(find.text('Outils'), findsOneWidget);
      expect(find.text('Compte'), findsOneWidget);

      container.read(localeProvider.notifier).setLocale(const Locale('en'));
      await tester.pumpAndSettle();

      expect(find.text('Palate'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Tools'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      container.read(localeProvider.notifier).setLocale(const Locale('es'));
      await tester.pumpAndSettle();

      expect(find.text('Paladar'), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Herramientas'), findsOneWidget);
      expect(find.text('Cuenta'), findsOneWidget);
    });

    test('Cellar domain models localize correctly in English and French', () {
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

    });
  });
}
