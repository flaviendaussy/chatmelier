import 'dart:convert';

import 'package:chatmelier/features/ce_soir/presentation/ce_soir_screen.dart';
import 'package:chatmelier/features/friends/data/friends_repository.dart';
import 'package:chatmelier/features/friends/domain/user_notification.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/notifications/data/invitations_notees.dart';
import 'package:chatmelier/features/notifications/presentation/noter_une_invitation.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/shared/l10n/fallback_localizations_delegates.dart';
import 'package:chatmelier/shared/widgets/notification_bell_button.dart';
import 'package:chatmelier/shared/widgets/onglets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L'onglet « Ce soir » (V2.3 · E1).
void main() {
  group('Les onglets', () {
    test('Ce soir · Cave · Journal · Profil sur le téléphone, les statistiques en plus ailleurs', () {
      expect(ongletsDeLApp(grandEcran: false).map((o) => o.chemin), ['/ce-soir', '/', '/history', '/profile']);
      expect(ongletsDeLApp(grandEcran: true).map((o) => o.chemin),
          ['/ce-soir', '/', '/history', '/stats', '/profile']);
    });

    test('chaque emplacement sélectionne son onglet, la cave par défaut', () {
      final o = ongletsDeLApp(grandEcran: false);
      expect(indexDeLOnglet('/ce-soir', o), 0);
      expect(indexDeLOnglet('/', o), 1);
      expect(indexDeLOnglet('/journal', o), 2);
      expect(indexDeLOnglet('/historique', o), 2);
      expect(indexDeLOnglet('/profile', o), 3);
      expect(indexDeLOnglet('/stats', o), 1, reason: 'pas d\'onglet statistiques sur le téléphone');
    });
  });

  testWidgets('l\'écran propose la soirée au restaurant et à la maison, et rouvre la dernière carte',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final carte = ScannedMenu(
      id: 'c',
      restaurantName: 'The Kitchin',
      scannedAt: DateTime(2026, 10, 1),
      pagePhotoPaths: const [],
      wines: const [MenuWine(id: '1', name: 'Barolo', producer: 'Vietti', wineType: 'red')],
    );
    SharedPreferences.setMockInitialValues({
      'chatmelier_recent_menus_v1': jsonEncode([carte.toJson()]),
    });

    String? ouvert;
    final routeur = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const CeSoirScreen()),
      GoRoute(path: '/scan/menu', builder: (_, __) {
        ouvert = '/scan/menu';
        return const Scaffold(body: Text('Scanner'));
      }),
    ]);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: kAppLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: routeur,
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final texte in [
      'Scanner la carte des vins',
      'Rejoindre une table',
      'Noter un vin bu dehors',
      'Ouvrir une bouteille',
      'Quel vin pour mon plat ?',
    ]) {
      expect(find.text(texte), findsOneWidget, reason: texte);
    }
    expect(find.text('Rouvrir « The Kitchin »'), findsOneWidget);
    expect(find.byType(BoutonSommelier), findsOneWidget);

    await tester.tap(find.text('Scanner la carte des vins'));
    await tester.pumpAndSettle();
    expect(ouvert, '/scan/menu');
  });

  testWidgets('plusieurs cartes passées : une seule ligne, et leur liste déroulante (11/10)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    ScannedMenu carte(String id, String nom, int jour) => ScannedMenu(
          id: id,
          restaurantName: nom,
          scannedAt: DateTime(2026, 10, jour),
          pagePhotoPaths: const [],
          wines: const [MenuWine(id: '1', name: 'Barolo', producer: 'Vietti', wineType: 'red')],
        );
    SharedPreferences.setMockInitialValues({
      'chatmelier_recent_menus_v1': jsonEncode([
        carte('a', 'BA484', 13).toJson(),
        carte('b', 'The Kitchin', 10).toJson(),
        carte('c', 'Le Petit Zinc', 8).toJson(),
      ]),
    });
    Object? ouverte;
    final routeur = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const CeSoirScreen()),
      GoRoute(path: '/scan/menu/result', builder: (_, etat) {
        ouverte = etat.extra;
        return const Scaffold(body: Text('Carte'));
      }),
    ]);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: kAppLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: routeur,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Rouvrir une carte récente (3)'), findsOneWidget);
    expect(find.textContaining('Rouvrir « '), findsNothing, reason: 'plus une ligne par carte');
    await tester.tap(find.text('Rouvrir une carte récente (3)'));
    await tester.pumpAndSettle();
    expect(find.text('The Kitchin'), findsOneWidget);
    expect(find.text('Le Petit Zinc'), findsOneWidget);
    await tester.tap(find.text('The Kitchin'));
    await tester.pumpAndSettle();
    expect((ouverte as ScannedMenu).restaurantName, 'The Kitchin');
  });

  testWidgets('22/10 : plus de « Au bar », la table et le vin bu dehors en haut, la cloche, l\'invitation à noter',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    final routeur = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const CeSoirScreen())]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        userNotificationsProvider.overrideWith((ref) async => [
              UserNotification(
                id: 'n1',
                userId: 'moi',
                actorName: 'Caro',
                type: 'invitation_a_noter',
                title: 'Un vin à noter',
                body: '',
                data: const {
                  'vin': {'nom': 'Ungrafted - Muscat', 'millesime': 2024, 'couleur': 'white'},
                  'lieu': 'Vagabond',
                },
                createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
              ),
            ]),
        invitationsNoteesProvider.overrideWith((ref) async => const {}),
      ],
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: kAppLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: routeur,
      ),
    ));
    await tester.pumpAndSettle();

    // Caro : « enlever la partie au bar » ; une ardoise se scanne comme une carte.
    expect(find.text('AU BAR'), findsNothing);
    expect(find.text('Scanner l\'ardoise'), findsNothing);
    // Caro : « la section carte en dessous ».
    expect(tester.getTopLeft(find.text('Rejoindre une table')).dy,
        lessThan(tester.getTopLeft(find.text('Scanner la carte des vins')).dy));
    // Caro : « ajouter la cloche de notification ».
    expect(find.byType(NotificationBellButton), findsOneWidget);
    // Flavien : « la notif doit être inratable ».
    expect(find.text('Caro vous invite à noter'), findsOneWidget);
    expect(find.text('Ungrafted - Muscat 2024'), findsOneWidget);
  });

  testWidgets('une invitation déjà notée ne s\'affiche plus en tête', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final routeur = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const CeSoirScreen())]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        userNotificationsProvider.overrideWith((ref) async => [
              UserNotification(
                id: 'n1',
                userId: 'moi',
                actorName: 'Caro',
                type: 'invitation_a_noter',
                title: '',
                body: '',
                data: const {'vin': {'nom': 'Rosy'}},
                createdAt: DateTime.now(),
              ),
            ]),
        invitationsNoteesProvider
            .overrideWith((ref) async => {'n1': const InvitationNotee(tastingId: 't', note: 4.5, terminee: true)}),
      ],
      child: MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: kAppLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: routeur,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Caro vous invite à noter'), findsNothing);
  });

  test('une ardoise reste une ardoise une fois rangée parmi les cartes récentes', () {
    final ardoise = ScannedMenu(
      id: 'a',
      restaurantName: 'Le Bar à Vins',
      scannedAt: DateTime(2026, 10, 2),
      pagePhotoPaths: const [],
      wines: const [MenuWine(id: '1', name: 'Morgon', producer: 'Foillard', wineType: 'red')],
      ardoise: true,
    );
    expect(ScannedMenu.fromJson(ardoise.toJson()).ardoise, isTrue);
    expect(ardoise.copie(restaurantName: 'Chez Paul').ardoise, isTrue);
    expect(ScannedMenu.fromJson(ardoise.copie().toJson()..remove('ardoise')).ardoise, isFalse);
  });
}
