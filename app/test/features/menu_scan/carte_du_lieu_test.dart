import 'dart:convert';

import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/ce_soir/presentation/ce_soir_screen.dart';
import 'package:chatmelier/features/menu_scan/domain/carte_du_lieu.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/shared/l10n/fallback_localizations_delegates.dart';
import 'package:chatmelier/shared/services/nearby_places_service.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La carte d'un lieu, retrouvée sans rescanner (V2.3 · K6, fait le 08/10).
void main() {
  setUp(() => Langue.code = 'fr');

  group('le lieu d\'une carte', () {
    test('un restaurant d\'OpenStreetMap garde son identifiant et sa position', () {
      final lieu = LieuDeLaCarte.depuisLieuProche(const NearbyPlace(
        id: '123',
        name: 'Le Petit Zinc',
        type: 'restaurant',
        latitude: 48.856612,
        longitude: 2.352219,
        osmCle: 'node/123',
      ))!;
      expect(lieu.cle, 'osm:node/123');
      expect(lieu.nom, 'Le Petit Zinc');
      expect(lieu.latitude, 48.856612);
    });

    test('un nom tapé est rangé sous son nom normalisé et une position arrondie (≈ 100 m)', () {
      final lieu = LieuDeLaCarte.tape('  Café de l\'Œuvre ', 48.856612, 2.352219)!;
      expect(lieu.cle, 'nom:cafe-de-l-oeuvre@48.857,2.352');
      expect(lieu.nom, 'Café de l\'Œuvre');
      expect(lieu.latitude, 48.857, reason: 'jamais la position exacte de la personne');
      expect(LieuDeLaCarte.tape('café de l’oeuvre', 48.8571, 2.3519)!.cle, lieu.cle,
          reason: 'le même lieu, autrement tapé');
    });

    test('sans nom ou sans position, pas de lieu, donc pas de partage', () {
      expect(LieuDeLaCarte.tape('   ', 48.85, 2.35), isNull);
      expect(LieuDeLaCarte.depuisLieuProche(const NearbyPlace(id: 'x', name: 'Bar', type: 'bar')), isNull);
    });
  });

  group('ce qui se partage', () {
    final carte = ScannedMenu(
      id: 'appareil-1',
      restaurantName: 'Le Petit Zinc',
      scannedAt: DateTime(2026, 10, 7, 20),
      pagePhotoPaths: const ['/data/user/0/page1.jpg'],
      currency: 'EUR',
      wines: const [
        MenuWine(
          id: 'w1',
          name: 'Morgon',
          producer: 'Lapierre',
          wineType: 'red',
          bottlePrice: 42,
          userMatchScore: 91,
          flag: MenuWineFlag(type: MenuWineFlagType.tasteMatch, label: 'Match Profil 91%'),
        ),
      ],
    );

    test('ni photos, ni identifiant d\'appareil, ni score ni badge du palais de celui qui a scanné', () {
      final partagee = CarteDuLieu.aPartager(carte);
      expect(partagee.containsKey('page_photo_paths'), isFalse);
      expect(partagee.containsKey('id'), isFalse);
      final vin = (partagee['wines'] as List).single as Map;
      expect(vin.containsKey('user_match_score'), isFalse);
      expect(vin.containsKey('flag'), isFalse);
      expect(vin['name'], 'Morgon');
      expect(vin['bottle_price'], 42);
      expect(partagee['currency'], 'EUR');
      expect(jsonEncode(partagee), isNot(contains('page1.jpg')));
    });

    test('reçue : nommée comme le lieu, datée du dépôt, recalculée pour le palais de qui l\'ouvre', () {
      final depot = DateTime(2026, 10, 5, 21);
      const sansPalais = null;
      final recue = CarteDuLieu.recue(CarteDuLieu.aPartager(carte),
          nomDuLieu: 'Le Petit Zinc', deposeeLe: depot, profil: sansPalais);
      expect(recue.restaurantName, 'Le Petit Zinc');
      expect(recue.scannedAt, depot);
      expect(recue.pagePhotoPaths, isEmpty);
      expect(recue.id, isNot('appareil-1'));
      expect(recue.wines.single.id, isNotEmpty);
      expect(recue.wines.single.userMatchScore, isNull, reason: 'pas de palais connu : pas de score inventé');
      expect(recue.currency, 'EUR');

      const palais = TasteProfile(
        id: 'p',
        name: 'Caro',
        favoriteTypes: ['Rouge'],
        favoriteRegions: ['Beaujolais'],
        favoriteGrapes: ['Gamay'],
        questionnairesCompleted: 4,
      );
      final pourCaro = CarteDuLieu.recue(CarteDuLieu.aPartager(carte),
          nomDuLieu: 'Le Petit Zinc', deposeeLe: depot, profil: palais);
      expect(pourCaro.wines.single.userMatchScore, isNotNull);
    });
  });

  group('l\'âge d\'une carte', () {
    final maintenant = DateTime(2026, 10, 8, 12);
    CarteProche aJours(int j) => CarteProche.fromJson({
          'lieu_cle': 'osm:node/1',
          'lieu_nom': 'Le Petit Zinc',
          'distance_m': 12,
          'nb_vins': 24,
          'devise': 'EUR',
          'deposee_le': maintenant.subtract(Duration(days: j)).toUtc().toIso8601String(),
        });

    test('aujourd\'hui, hier, il y a n jours ; prix à vérifier au-delà d\'une semaine', () {
      expect(aJours(0).age(maintenant), 'aujourd\'hui');
      expect(aJours(1).age(maintenant), 'hier');
      expect(aJours(3).age(maintenant), 'il y a 3 jours');
      expect(aJours(3).prixAVerifier(maintenant), isFalse);
      expect(aJours(8).prixAVerifier(maintenant), isTrue);
      expect(aJours(8).nbVins, 24);
    });
  });

  testWidgets('« Ce soir » rouvre chacune des cartes récentes, et cherche celles d\'à côté', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    ScannedMenu carte(String nom, int jour) => ScannedMenu(
          id: nom,
          restaurantName: nom,
          scannedAt: DateTime.now().subtract(Duration(days: jour)),
          pagePhotoPaths: const [],
          wines: const [MenuWine(id: '1', name: 'Barolo', producer: 'Vietti', wineType: 'red')],
        );
    SharedPreferences.setMockInitialValues({
      'chatmelier_recent_menus_v1':
          jsonEncode([carte('The Kitchin', 0).toJson(), carte('Le Petit Zinc', 2).toJson(), carte('Septime', 5).toJson()]),
    });
    final routeur = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const CeSoirScreen())]);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: kAppLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: routeur,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Rouvrir « The Kitchin »'), findsOneWidget);
    expect(find.text('Rouvrir « Le Petit Zinc »'), findsOneWidget);
    expect(find.text('Rouvrir « Septime »'), findsOneWidget, reason: 'plus seulement la dernière');
    expect(find.textContaining('il y a 2 jours'), findsOneWidget);
    expect(find.text('Les cartes autour de moi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
