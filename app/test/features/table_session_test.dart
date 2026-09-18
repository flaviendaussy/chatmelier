import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/auth/domain/wine_taste_radar.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';

/// Ce qu'un convive emporte en rejoignant une table.
///
/// Une table ne vivait que dans une `static Map` du téléphone hôte : chacun votait dans
/// son coin, et l'hôte ne voyait jamais les préférences des autres. Maintenant qu'elles
/// voyagent, encore faut-il qu'elles arrivent intactes — sinon la table vote sur une
/// caricature des goûts de chacun.
void main() {
  _carteQuiTraverse();

  group('🧳 Le profil d\'un convive fait le voyage', () {
    final radar = const WineTasteRadarMetrics(
      tannin: 8.5,
      body: 7.0,
      oak: 2.0,
      ripeFruit: 4.0,
      spice: 6.5,
      freshFruit: 7.5,
      minerality: 9.0,
      acidity: 8.0,
    );

    test('les huit axes survivent à l\'aller-retour', () {
      final origine = GuestProfile(
        id: 'paul',
        name: 'Paul',
        favoriteTypes: const ['Rouge'],
        favoriteGrapes: const ['Mourvèdre'],
        dislikedCharacteristics: const ['Boisé marqué'],
        archetype: 'Amateur de Grands Rouges Puissants',
        radarDistant: radar,
      );
      final relu = GuestProfile.fromJson('paul', origine.toJson());

      expect(relu.radar.tannin, closeTo(8.5, 0.001));
      expect(relu.radar.minerality, closeTo(9.0, 0.001));
      expect(relu.radar.acidity, closeTo(8.0, 0.001));
      expect(relu.favoriteGrapes, contains('Mourvèdre'));
      expect(relu.dislikedCharacteristics, contains('Boisé marqué'));
    });

    test('le radar transmis prime sur l\'archétype', () {
      // Sans ce champ, un convive distant retombait sur le radar grossier déduit de son
      // étiquette : deux personnes au même archétype devenaient interchangeables.
      final relu = GuestProfile.fromJson('x', {
        'name': 'Aude',
        'archetype': 'Adepte de Minéralité & Fraîcheur Droite',
        'radar': {'tannin': 9.5, 'body': 9.0},
      });
      expect(relu.radar.tannin, closeTo(9.5, 0.001),
          reason: 'l\'archétype minéral aurait imposé 0.0 de tanin');
    });

    test('un profil sans radar reste utilisable', () {
      // Rejoindre sans profil de goût doit rester possible : le nom suffit à être compté
      // à table, et refuser l\'entrée serait pire que voter avec une valeur par défaut.
      final relu = GuestProfile.fromJson('y', {'name': 'Invité'});
      expect(relu.name, equals('Invité'));
      expect(relu.radar, isNotNull);
    });

    test('rien de plus que ce qu\'il faut ne part', () {
      // Le profil voyage vers d'autres convives : il ne doit emporter ni identifiant de
      // compte, ni cave, ni historique de dégustations.
      final json = GuestProfile(id: 'secret-user-id', name: 'Paul', radarDistant: radar)
          .toJson();
      expect(json.keys, isNot(contains('id')));
      expect(json.toString(), isNot(contains('secret-user-id')));
      expect(json.keys,
          unorderedEquals(['name', 'archetype', 'favorite_types', 'favorite_grapes',
              'disliked', 'radar']));
    });
  });
}

/// La carte qui traverse le serveur.
///
/// `open_table_session` écrit `menu.toJson()` en JSONB, `join_table_session` le rend, et
/// l'invité le relit avec `ScannedMenu.fromJson`. Ce chemin n'a pas le plafond de seize
/// vins du QR — encore faut-il que rien ne se perde en route.
void _carteQuiTraverse() {
  group('📋 La carte survit au passage par la base', () {
    test('un vin complet revient complet', () {
      final origine = ScannedMenu(
        id: 'm1',
        restaurantName: 'Le Comptoir',
        pagePhotoPaths: const [],
        scannedAt: DateTime(2026, 9, 18),
        wines: [
          MenuWine(
            id: 'w1',
            name: 'Bandol Rouge',
            producer: 'Domaine de Terrebrune',
            wineType: 'Rouge',
            vintage: 2019,
            appellation: 'Bandol',
            region: 'Provence',
            bottlePrice: 78,
            grapes: const ['Mourvèdre', 'Grenache'],
            glassPrices: const [MenuWineGlassPrice(format: '125ml', price: 12)],
            metrics: const MenuWineRadarMetrics(
                tannins: 8.5, acidity: 5.5, body: 8.0, oak: 6.0),
            tags: const ['tannique'],
            isGem: true,
          ),
        ],
      );

      final relu = ScannedMenu.fromJson(origine.toJson());
      final w = relu.wines.single;

      expect(relu.restaurantName, equals('Le Comptoir'));
      expect(w.name, equals('Bandol Rouge'));
      expect(w.producer, equals('Domaine de Terrebrune'));
      expect(w.bottlePrice, equals(78));
      expect(w.grapes, contains('Mourvèdre'));
      expect(w.glassPrices.single.price, equals(12));
      expect(w.metrics.tannins, closeTo(8.5, 0.001),
          reason: 'sans les métriques, le consensus note tous les vins pareil');
      expect(w.isGem, isTrue);
    });

    test('une carte de cinquante vins passe entière', () {
      // Le plafond de seize ne valait que pour l'URL du QR.
      final grande = ScannedMenu(
        id: 'm2',
        restaurantName: 'Grande carte',
        pagePhotoPaths: const [],
        scannedAt: DateTime(2026, 9, 18),
        wines: [
          for (var i = 0; i < 50; i++)
            MenuWine(
                id: 'w$i',
                name: 'Vin $i',
                producer: 'Domaine $i',
                wineType: 'Rouge',
                bottlePrice: 30.0 + i),
        ],
      );
      expect(ScannedMenu.fromJson(grande.toJson()).wines, hasLength(50));
    });
  });
}
