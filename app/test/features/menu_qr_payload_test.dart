import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/menu_scan/data/menu_table_session_manager.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';

/// Le QR de table, qui ne fonctionnait sur AUCUN navigateur.
///
/// `gzip` venait de `dart:io`, dont le correctif dart2js lève `UnsupportedError`.
/// `decodeMenuPayload` renvoyait donc null en web, et l'invité basculait en silence sur
/// un menu de trois vins inventés, présenté comme la carte du restaurant.
///
/// **Ce fichier doit tourner sous `flutter test --platform chrome`** : c'est le seul
/// environnement où le bug existait, et donc le seul qui prouve qu'il est parti. Il n'y a
/// aucun import `dart:io` ici, volontairement.
void main() {
  MenuWine vin(
    String nom, {
    String type = 'Rouge',
    double prix = 42.0,
    MenuWineRadarMetrics? metrics,
    List<String> cepages = const [],
    List<MenuWineGlassPrice> verres = const [],
  }) =>
      MenuWine(
        id: nom,
        name: nom,
        producer: 'Domaine $nom',
        wineType: type,
        bottlePrice: prix,
        vintage: 2020,
        appellation: 'AOC $nom',
        region: 'Région $nom',
        metrics: metrics ?? const MenuWineRadarMetrics(),
        grapes: cepages,
        glassPrices: verres,
      );

  ScannedMenu carte(List<MenuWine> vins) => ScannedMenu(
        id: 'm',
        restaurantName: 'Le Comptoir',
        pagePhotoPaths: const [],
        wines: vins,
        scannedAt: DateTime.now(),
      );

  group('🔗 L\'aller-retour du QR', () {
    test('une carte encodée se relit, ici comme sur un navigateur', () {
      final origine = carte([vin('Bandol'), vin('Chablis', type: 'Blanc')]);
      final relu = MenuTableSessionManager.decodeMenuPayload(
          MenuTableSessionManager.encodeMenuPayload(origine));

      expect(relu, isNotNull,
          reason: 'c\'est exactement ce qui renvoyait null sous dart2js');
      expect(relu!.restaurantName, equals('Le Comptoir'));
      expect(relu.wines.map((w) => w.name), containsAll(['Bandol', 'Chablis']));
    });

    test('les métriques survivent au voyage', () {
      // Sans elles, le moteur de consensus note tous les vins à la même valeur par
      // défaut : l'écart entre le premier et le dernier tombe à deux points, et une
      // aversion déclarée aux tanins ne change plus le classement.
      final origine = carte([
        vin('Madiran',
            metrics: const MenuWineRadarMetrics(
              tannins: 9.0,
              acidity: 5.5,
              body: 8.5,
              fruit: 6.0,
              oak: 7.0,
              minerality: 4.0,
            )),
      ]);
      final m = MenuTableSessionManager.decodeMenuPayload(
              MenuTableSessionManager.encodeMenuPayload(origine))!
          .wines
          .first
          .metrics;

      expect(m.tannins, closeTo(9.0, 0.05));
      expect(m.body, closeTo(8.5, 0.05));
      expect(m.oak, closeTo(7.0, 0.05));
    });

    test('les cépages et les prix au verre aussi', () {
      final origine = carte([
        vin('Sancerre',
            type: 'Blanc',
            cepages: ['Sauvignon Blanc'],
            verres: [const MenuWineGlassPrice(format: '125ml', price: 7.5)]),
      ]);
      final w = MenuTableSessionManager.decodeMenuPayload(
              MenuTableSessionManager.encodeMenuPayload(origine))!
          .wines
          .first;

      expect(w.grapes, contains('Sauvignon Blanc'));
      expect(w.glassPrices, hasLength(1));
      expect(w.glassPrices.first.price, closeTo(7.5, 0.05));
      expect(w.hasGlassPrice, isTrue);
    });

    test('seize vins complets tiennent dans une URL scannable', () {
      final vins = [
        for (var i = 0; i < 16; i++)
          vin('Cuvée numéro $i',
              type: i.isEven ? 'Rouge' : 'Blanc',
              cepages: const ['Grenache', 'Syrah'],
              verres: [const MenuWineGlassPrice(format: '125ml', price: 8.0)],
              metrics: const MenuWineRadarMetrics(
                  tannins: 6.5, acidity: 5.5, body: 7.0, fruit: 6.0)),
      ];
      final url = MenuTableSessionManager.buildQrUrl(
          sessionId: 'ABC123', menu: carte(vins));

      // Un QR en mode octet plafonne autour de 2 900 caractères ; au-delà la matrice
      // devient trop dense pour être lue d'un téléphone à travers une table.
      expect(url.length, lessThan(2500),
          reason: 'URL de ${url.length} caractères : le QR deviendrait illisible');
      final relu = MenuTableSessionManager.decodeMenuPayload(
          Uri.parse(url).queryParameters['data']);
      expect(relu!.wines, hasLength(16));
    });

    test('une charge illisible donne null, et non une carte inventée', () {
      expect(MenuTableSessionManager.decodeMenuPayload('pas-du-tout-du-base64!!'), isNull);
      expect(MenuTableSessionManager.decodeMenuPayload(''), isNull);
      expect(MenuTableSessionManager.decodeMenuPayload(null), isNull);
    });

    test('une charge non compressée reste lisible', () {
      // Le repli d'encodage n'utilise pas gzip, et d'anciennes URL circulent peut-être.
      const brut =
          'eyJyIjogIkNoZXogUGF1bCIsICJ3IjogW1siQmFuZG9sIiwgIlJvdWdlIiwgNDIuMF1dfQ==';
      final relu = MenuTableSessionManager.decodeMenuPayload(brut);
      expect(relu, isNotNull);
      expect(relu!.restaurantName, equals('Chez Paul'));
      expect(relu.wines.first.name, equals('Bandol'));
    });
  });
}
