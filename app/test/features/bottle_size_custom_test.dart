import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/cellar/domain/bottle_size.dart';

/// Contenances libres — demandé par une utilisatrice qui voulait saisir une 20 cl.
///
/// Le stockage acceptait déjà n'importe quel code (`bottle_size` est une chaîne), mais
/// `fromCode` renvoyait `volumeLiters: 0.75` pour tout code inconnu : une fiole de 20 cl
/// comptait comme une bouteille standard. Aucun code ne lisait encore ce champ, donc
/// c'était une donnée fausse en attente de son premier lecteur.
void main() {
  group('🍾 Contenances libres', () {
    test('les trois unités d\'une étiquette sont comprises', () {
      expect(BottleSize.fromCode('20cl').volumeLiters, closeTo(0.20, 1e-9));
      expect(BottleSize.fromCode('200ml').volumeLiters, closeTo(0.20, 1e-9));
      expect(BottleSize.fromCode('0.2L').volumeLiters, closeTo(0.20, 1e-9));
      expect(BottleSize.fromCode('0,2 L').volumeLiters, closeTo(0.20, 1e-9),
          reason: 'Virgule décimale et espaces : c\'est ce qu\'on tape en français.');
    });

    test('un volume qui correspond à un format standard rend ce format', () {
      final saisi = BottleSize.fromLiters(0.75);
      expect(saisi.code, equals('75cl'));
      expect(saisi.labelFr, contains('standard'),
          reason: 'Saisir 75 cl à la main doit donner la bouteille standard avec son nom, '
              'pas un doublon anonyme.');
      expect(BottleSize.fromLiters(1.5).shortNameFr, contains('Magnum'));
    });

    test('l\'écriture canonique suit la convention des codes existants', () {
      expect(BottleSize.canonicalCode(0.20), equals('20cl'));
      expect(BottleSize.canonicalCode(0.375), equals('37.5cl'));
      expect(BottleSize.canonicalCode(1.5), equals('1.5L'));
      expect(BottleSize.canonicalCode(3.0), equals('3L'),
          reason: 'Pas de « 3.0L » : les codes existants s\'écrivent « 3L ».');
    });

    test('un code libre fait l\'aller-retour sans se déformer', () {
      for (final litres in [0.10, 0.20, 0.25, 0.62, 2.0, 5.0]) {
        final code = BottleSize.canonicalCode(litres);
        expect(BottleSize.fromCode(code).volumeLiters, closeTo(litres, 1e-9),
            reason: 'Aller-retour cassé pour $litres L (code « $code »)');
      }
    });

    test('l\'affichage suit la convention des formats nommés', () {
      final vingt = BottleSize.fromLiters(0.20);
      expect(vingt.shortNameFr, equals('20 cl'),
          reason: 'Espace et centilitres, comme « 75 cl » juste à côté dans la même rangée.');
      expect(vingt.shortNameEn, equals('200 ml'),
          reason: 'Millilitres en anglais sous le litre, comme « 750 ml ».');

      final deuxLitres = BottleSize.fromLiters(2.0);
      expect(deuxLitres.shortNameFr, equals('2 L'));
      expect(deuxLitres.shortNameEn, equals('2 L'));

      expect(BottleSize.fromLiters(0.175).shortNameFr, equals('17,5 cl'),
          reason: 'Virgule décimale en français, comme « 37,5 cl ».');
    });

    test('les saisies absurdes ne produisent pas un volume aberrant', () {
      // Hors bornes : on préserve le code sans prétendre en connaître le volume.
      expect(BottleSize.fromCode('500L').code, equals('500L'));
      expect(BottleSize.fromCode('0.1ml').code, equals('0.1ml'));
      expect(BottleSize.fromCode('').code, equals('75cl'),
          reason: 'Code vide : on retombe sur le format par défaut.');
    });

    test('les formats nommés restent prioritaires sur le calcul', () {
      expect(BottleSize.fromCode('magnum').code, equals('1.5L'));
      expect(BottleSize.fromCode('clavelin').code, equals('62cl'));
      expect(BottleSize.fromCode('750ml').code, equals('75cl'),
          reason: 'Une étiquette américaine doit tomber sur la bouteille standard.');
    });
  });
}
