import 'package:chatmelier/features/auth/domain/wine_taste_radar.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_table_matcher_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// La table au centre (V2.3 · E3, E4) : qui ne boit pas ce soir, et deux bouteilles
/// quand une seule laisse trop de monde de côté.
void main() {
  tearDown(() => Langue.code = 'fr');

  MenuTableMatchResult resultat(String nom, String type, Map<String, double> scores) => MenuTableMatchResult(
        menuWine: MenuWine(id: nom, name: nom, producer: 'Domaine', wineType: type),
        harmonyScore: scores.values.reduce((a, b) => a + b) / scores.length,
        consensusRationale: '',
        guestScores: scores,
      );

  group('À deux bouteilles', () {
    test('une table partagée entre blancs et rouges : la paire couvre tout le monde', () {
      // Trois amateurs de blanc, trois de rouge : le meilleur vin seul en satisfait trois.
      final classement = [
        resultat('Morgon', 'red', {'a': 85, 'b': 80, 'c': 78, 'd': 45, 'e': 40, 'f': 42}),
        resultat('Sancerre', 'white', {'a': 40, 'b': 45, 'c': 42, 'd': 84, 'e': 82, 'f': 79}),
        resultat('Côtes du Rhône', 'red', {'a': 70, 'b': 65, 'c': 61, 'd': 50, 'e': 48, 'f': 52}),
      ];
      final p = MenuTableMatcherEngine.meilleurePaire(classement)!;
      expect(p.couverts, 6);
      expect(p.couvertsParLePremier, 3);
      expect(p.entreeEtPlat, isTrue);
      expect(p.dansLOrdre.$1.name, 'Sancerre', reason: 'le blanc pour l\'entrée');
      expect(RedactionDesRaisons.phraseDeLaPaire(p),
          'Sancerre pour l\'entrée, Morgon pour le plat : 6 convives sur 6 y trouvent leur compte, '
          'contre 3 avec une seule bouteille.');
    });

    test('une bouteille qui plaît presque à tous suffit', () {
      final classement = [
        resultat('Morgon', 'red', {'a': 85, 'b': 80, 'c': 78, 'd': 70, 'e': 40}),
        resultat('Sancerre', 'white', {'a': 40, 'b': 45, 'c': 42, 'd': 84, 'e': 82}),
      ];
      expect(MenuTableMatcherEngine.meilleurePaire(classement), isNull, reason: '4 sur 5, soit 80 %');
    });

    test('il faut au moins deux convives de plus, sinon pas de paire', () {
      final classement = [
        resultat('Morgon', 'red', {'a': 85, 'b': 50, 'c': 50}),
        resultat('Sancerre', 'white', {'a': 40, 'b': 75, 'c': 45}),
      ];
      expect(MenuTableMatcherEngine.meilleurePaire(classement), isNull);
    });

    test('un rosé et un rouge : la phrase générale', () {
      final classement = [
        resultat('Bandol rouge', 'red', {'a': 85, 'b': 80, 'c': 40, 'd': 45}),
        resultat('Tavel', 'rosé', {'a': 40, 'b': 45, 'c': 84, 'd': 82}),
      ];
      final p = MenuTableMatcherEngine.meilleurePaire(classement)!;
      expect(p.entreeEtPlat, isFalse);
      expect(RedactionDesRaisons.phraseDeLaPaire(p),
          'Bandol rouge et Tavel : 4 convives sur 4 y trouvent leur compte, contre 2 avec une seule bouteille.');
      Langue.code = 'es';
      expect(RedactionDesRaisons.phraseDeLaPaire(p, isFr: false), contains('comensales'));
    });
  });

  group('Je ne bois pas ce soir', () {
    const tannique = MenuWine(
      id: 'madiran',
      name: 'Madiran',
      producer: 'Domaine',
      wineType: 'red',
      metrics: MenuWineRadarMetrics(tannins: 9, body: 8.5, acidity: 6),
    );
    const souple = MenuWine(
      id: 'fleurie',
      name: 'Fleurie',
      producer: 'Domaine',
      wineType: 'red',
      metrics: MenuWineRadarMetrics(tannins: 3, body: 4, acidity: 6.5),
    );
    const paul = GuestProfile(
      id: 'paul',
      name: 'Paul',
      favoriteTypes: ['Rouge'],
      radarDistant: WineTasteRadarMetrics(
          tannin: 9, body: 8.5, oak: 6, ripeFruit: 7, spice: 6, freshFruit: 4, minerality: 4, acidity: 6),
    );
    const lea = GuestProfile(
      id: 'lea',
      name: 'Léa',
      dislikedCharacteristics: ['Tanins durs'],
      radarDistant: WineTasteRadarMetrics(
          tannin: 2, body: 3, oak: 2, ripeFruit: 5, spice: 3, freshFruit: 8, minerality: 6, acidity: 7),
      neBoitPas: true,
    );

    test('il ne vote pas : la table choisit comme si Paul était seul', () {
      final avecLea = MenuTableMatcherEngine.classerLaCarte(menuWines: const [souple, tannique], guests: const [paul, lea]);
      final seul = MenuTableMatcherEngine.classerLaCarte(menuWines: const [souple, tannique], guests: const [paul]);
      expect(avecLea.first.menuWine.name, 'Madiran');
      expect(avecLea.map((r) => r.harmonyScore), seul.map((r) => r.harmonyScore));
      expect(avecLea.first.guestScores.containsKey('lea'), isFalse);
      expect(avecLea.first.aversionAlerts, isEmpty, reason: 'son aversion ne compte pas : elle ne boit pas');
    });

    test('il voyage dans le profil envoyé à la table', () {
      final relu = GuestProfile.fromJson('lea', lea.toJson());
      expect(relu.neBoitPas, isTrue);
      expect(GuestProfile.fromJson('paul', paul.toJson()).neBoitPas, isFalse);
    });

    test('si personne ne boit, la carte reste classée', () {
      final r = MenuTableMatcherEngine.classerLaCarte(menuWines: const [souple, tannique], guests: const [lea]);
      expect(r, hasLength(2));
    });
  });
}
