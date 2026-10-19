// V2.5 · Q4 (revue du 18/10) — le type enregistré cédait à une sous-chaîne du nom : un
// rouge de Valtellina « Grumello » devenait du rhum, l'AOC Corse Porto-Vecchio un porto,
// un Amarone un spiritueux (« amaro »). Le rouge partait dans « Spiritueux », sortait des
// goûts, et se suivait au niveau de remplissage au lieu de son apogée.

import 'package:chatmelier/features/cellar/domain/type_de_vin.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/scan/domain/scan_result.dart';
import 'package:flutter_test/flutter_test.dart';

Wine _vin(String nom, {String? type, String? producteur, String? appellation, double? alcool}) => Wine.fromJson({
      'id': 'essai',
      'name': nom,
      if (type != null) 'wine_type': type,
      if (producteur != null) 'producer': producteur,
      if (appellation != null) 'appellation': appellation,
      if (alcool != null) 'alcohol_pct': alcool,
    });

void main() {
  group('Un vin enregistré reste un vin, quel que soit son nom', () {
    for (final (nom, producteur, appellation) in [
      ('Valtellina Superiore Grumello', 'Nino Negri', 'Valtellina Superiore'),
      ('Brumaire', 'Château Plaisance', 'Fronton'),
      ('Porto Vecchio Rouge', 'Domaine de Torraccia', 'Corse Porto-Vecchio'),
      ('Clos du Maury', 'Clos du Maury', 'Côtes du Roussillon Villages'),
      ('Amarone della Valpolicella Classico', 'Bertani', 'Amarone della Valpolicella'),
      ('Côtes du Rhône', 'Chartreuse de Valbonne', 'Côtes du Rhône'),
    ]) {
      test('$nom ($appellation)', () {
        final vin = _vin(nom, type: 'red', producteur: producteur, appellation: appellation);
        expect(vin.type, 'red');
        expect(vin.isSpirit, isFalse);
        expect(vin.isFortified, isFalse);
        expect(vin.tracksFillLevel, isFalse);
      });
    }

    test('un Sauternes de Château la Chartreuse : un moelleux, sans 55 % inventés', () {
      final vin = _vin('Château la Chartreuse', type: 'dessert', appellation: 'Sauternes');
      expect(vin.type, 'dessert');
      expect(vin.isSpirit, isFalse);
      expect(vin.alcoholPct, isNull);
    });

    test('un blanc de Marc Morey n\'est pas un marc', () {
      final vin = _vin('Chassagne-Montrachet', type: 'white', producteur: 'Domaine Marc Morey');
      expect(vin.type, 'white');
      expect(vin.isSpirit, isFalse);
    });
  });

  group('Le rouge mis d\'office cède à un nom sans ambiguïté', () {
    test('une Chartreuse Verte enregistrée en rouge redevient une liqueur', () {
      final vin = _vin('Chartreuse Verte', type: 'red', producteur: 'Pères Chartreux');
      expect(vin.type, 'liqueur');
      expect(vin.isSpirit, isTrue);
      expect(vin.alcoholPct, 55.0);
    });

    test('un tawny enregistré en rouge redevient un porto', () {
      final vin = _vin('10 Year Old Tawny Porto', type: 'red', producteur: 'Taylor\'s');
      expect(vin.type, 'fortified');
      expect(vin.isFortified, isTrue);
    });

    test('un nom de lieu ne suffit pas : un rouge de Cognac reste un rouge', () {
      expect(_vin('Rouge de Cognac', type: 'red').type, 'red');
    });

    test('un degré qu\'aucun vin n\'atteint l\'emporte sur le type', () {
      expect(_vin('Hors d\'âge', type: 'red', alcool: 42).type, 'spirit');
      expect(_vin('Single Malt Scotch Whisky', type: 'white', alcool: 40).type, 'whisky');
    });
  });

  group('Un vin doux naturel se reconnaît à son appellation', () {
    test('un Banyuls rouge est un muté', () {
      final vin = _vin('Rimage', type: 'red', appellation: 'Banyuls');
      expect(vin.type, 'red');
      expect(vin.isFortified, isTrue);
    });

    test('un Maury sec ne l\'est pas', () {
      expect(_vin('Maury sec', type: 'red', appellation: 'Maury sec').isFortified, isFalse);
    });

    test('un porto rangé parmi les moelleux reste un porto', () {
      expect(_vin('Velhotes Tawny Porto', type: 'dessert').isFortified, isTrue);
    });
  });

  group('Sans type enregistré, le nom guide, en mots entiers', () {
    test('Cointreau, Gin Mare, Rhum agricole', () {
      expect(_vin('Cointreau').type, 'liqueur');
      expect(_vin('Gin Mare').type, 'gin');
      expect(_vin('Rhum agricole blanc').type, 'rhum');
    });

    test('Grumello sans type n\'est pas du rhum', () {
      expect(_vin('Valtellina Superiore Grumello').type, 'red');
    });
  });

  group('Le scan suit la même règle', () {
    test('un Grumello lu comme rouge reste un rouge', () {
      final scan = ScanResult.fromJson({'name': 'Valtellina Superiore Grumello', 'wine_type': 'red', 'appellation': 'Valtellina Superiore'});
      expect(scan.wineType, 'red');
    });

    test('une Chartreuse lue comme rouge devient une liqueur', () {
      expect(ScanResult.fromJson({'name': 'Chartreuse Jaune', 'wine_type': 'red'}).wineType, 'liqueur');
    });

    test('un whisky lu comme tel le reste', () {
      expect(ScanResult.fromJson({'name': 'Lagavulin 16', 'wine_type': 'whisky'}).wineType, 'whisky');
    });
  });

  test('les mots entiers tiennent compte des accents', () {
    expect(TypeDeVin.spiritueuxNomme('bénédictine d.o.m.'), 'liqueur');
    expect(TypeDeVin.spiritueuxNomme('grumello'), isNull);
    expect(TypeDeVin.spiritueuxNomme('rumeur'), isNull);
    expect(TypeDeVin.spiritueuxNomme('crémant de loire'), isNull);
  });
}
