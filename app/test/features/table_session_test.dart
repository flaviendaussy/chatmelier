import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/auth/domain/wine_taste_radar.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';

/// Ce qu'un convive emporte en rejoignant une table.
///
/// Une table ne vivait que dans une `static Map` du téléphone hôte : chacun votait dans
/// son coin, et l'hôte ne voyait jamais les préférences des autres. Maintenant qu'elles
/// voyagent, encore faut-il qu'elles arrivent intactes — sinon la table vote sur une
/// caricature des goûts de chacun.
void main() {
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
