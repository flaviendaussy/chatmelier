import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/menu_scan/data/recent_menus_store.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';

/// Une carte scannée doit survivre à la fermeture de son écran.
///
/// Les vins reconnus partaient bien au cache de connaissances, mais la CARTE — quel
/// restaurant, quels vins, à quels prix — n'était conservée nulle part. Sortir de l'écran
/// pour prendre un appel obligeait à tout rescanner : nouvel appel IA, nouvelles photos,
/// et la table ouverte perdue au passage.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ScannedMenu carte(String resto, {int vins = 2, String? id}) => ScannedMenu(
        id: id ?? resto,
        restaurantName: resto,
        pagePhotoPaths: const [],
        scannedAt: DateTime(2026, 9, 18),
        wines: [
          for (var i = 0; i < vins; i++)
            MenuWine(
              id: '$resto-$i',
              name: 'Vin $i',
              producer: 'Domaine $i',
              wineType: 'Rouge',
              bottlePrice: 40.0 + i,
            ),
        ],
      );

  group('🕓 Rouvrir sans rescanner', () {
    test('une carte enregistrée se relit entière', () async {
      final s = await RecentMenusStore.ouvrir();
      await s.enregistrer(carte('Le Comptoir', vins: 3));

      final relu = (await RecentMenusStore.ouvrir()).derniere;
      expect(relu!.restaurantName, equals('Le Comptoir'));
      expect(relu.wines, hasLength(3));
      expect(relu.wines.first.bottlePrice, equals(40.0),
          reason: 'les prix font toute l\'utilité d\'une carte conservée');
    });

    test('la plus récente vient en tête', () async {
      final s = await RecentMenusStore.ouvrir();
      await s.enregistrer(carte('Premier'));
      await (await RecentMenusStore.ouvrir()).enregistrer(carte('Second'));

      expect((await RecentMenusStore.ouvrir()).derniere!.restaurantName,
          equals('Second'));
    });

    test('rescanner le même restaurant ne le duplique pas', () async {
      await (await RecentMenusStore.ouvrir()).enregistrer(carte('Le Comptoir', id: 'a'));
      await (await RecentMenusStore.ouvrir())
          .enregistrer(carte('Le Comptoir', id: 'b', vins: 5));

      final toutes = (await RecentMenusStore.ouvrir()).lire();
      expect(toutes, hasLength(1));
      expect(toutes.first.wines, hasLength(5),
          reason: 'c\'est le nouveau scan qui fait foi');
    });

    test('au-delà de trois, la plus ancienne sort', () async {
      for (final n in ['A', 'B', 'C', 'D']) {
        await (await RecentMenusStore.ouvrir()).enregistrer(carte(n));
      }
      final toutes = (await RecentMenusStore.ouvrir()).lire();
      expect(toutes, hasLength(RecentMenusStore.maximum));
      expect(toutes.map((m) => m.restaurantName), isNot(contains('A')));
      expect(toutes.first.restaurantName, equals('D'));
    });

    test('une carte vide n\'est pas conservée', () async {
      // Un scan raté ne doit pas venir s'installer en tête de liste.
      await (await RecentMenusStore.ouvrir()).enregistrer(carte('Raté', vins: 0));
      expect((await RecentMenusStore.ouvrir()).lire(), isEmpty);
    });

    test('des données corrompues ne font pas tomber l\'écran', () async {
      SharedPreferences.setMockInitialValues(
          {'chatmelier_recent_menus_v1': 'pas du json'});
      expect((await RecentMenusStore.ouvrir()).lire(), isEmpty);
      expect((await RecentMenusStore.ouvrir()).derniere, isNull);
    });

    test('on peut oublier une carte précise', () async {
      await (await RecentMenusStore.ouvrir()).enregistrer(carte('A', id: 'a'));
      await (await RecentMenusStore.ouvrir()).enregistrer(carte('B', id: 'b'));
      await (await RecentMenusStore.ouvrir()).oublier('a');

      final toutes = (await RecentMenusStore.ouvrir()).lire();
      expect(toutes.map((m) => m.id), equals(['b']));
    });
  });
}
