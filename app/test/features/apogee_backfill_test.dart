import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/cellar/domain/apogee_backfill.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';

/// La correction des apogées déjà écrites en base.
///
/// L'app lit désormais tout à travers la correction, donc son affichage est juste sans
/// toucher à la base. Mais d'autres clients lisent ces colonnes directement — la version
/// web, les versions installées plus anciennes, les exports, le contexte envoyé au
/// sommelier IA. Tant que la donnée stockée est fausse, ils affichent faux.
void main() {
  Wine vin({
    required String nom,
    required String region,
    String? appellation,
    String type = 'red',
    int? millesime,
    int? debut,
    int? fin,
    String? producteur,
  }) =>
      Wine(
        id: 'w_$nom',
        name: nom,
        type: type,
        country: 'France',
        region: region,
        appellation: appellation,
        producer: producteur,
        vintage: millesime,
        drinkStart: debut,
        drinkEnd: fin,
      );

  group('🔧 Ce qui est corrigé', () {
    test('le cas signalé : un Margaux mort douze ans après la vendange', () {
      final c = ApogeeBackfill.aCorriger([
        vin(nom: 'Château X', region: 'Bordeaux', appellation: 'Margaux',
            millesime: 1987, debut: 1989, fin: 1999),
      ]);
      expect(c, hasLength(1));
      expect(c.first.nouvelleFin - c.first.nouveauDebut, greaterThan(15));
      expect(c.first.payload['ideal_drinking_end'], greaterThan(1999));
    });

    test('une fenêtre absente est toujours renseignée', () {
      // On passe de « rien » à « quelque chose » : ça vaut quel que soit l'écart.
      final c = ApogeeBackfill.aCorriger([
        vin(nom: 'Sans fenêtre', region: 'Bourgogne',
            appellation: 'Gevrey-Chambertin', millesime: 2018),
      ]);
      expect(c, hasLength(1));
      expect(c.first.ancienDebut, isNull);
    });

    test('la charge écrite porte les quatre colonnes', () {
      final c = ApogeeBackfill.aCorriger([
        vin(nom: 'So Sauternes', region: 'Bordeaux', appellation: 'Sauternes',
            type: 'Moelleux', millesime: 2022, debut: 2023, fin: 2030),
      ]).single;
      expect(c.payload.keys, containsAll(<String>[
        'ideal_drinking_start', 'ideal_drinking_end',
        'peak_drinking_start', 'peak_drinking_end',
      ]));
      expect(c.payload['ideal_drinking_end'], greaterThan(2050),
          reason: 'Un Sauternes se garde vingt à cent ans.');
    });
  });

  group('🚫 Ce qui n\'est PAS touché', () {
    test('une fenêtre déjà plausible est laissée telle quelle', () {
      // Sur le Morgon, l'enrichissement avait raison là où la table se trompait :
      // corriger reviendrait à dégrader.
      expect(
        ApogeeBackfill.aCorriger([
          vin(nom: 'Morgon Roches Noires', region: 'Beaujolais',
              appellation: 'Morgon', millesime: 2022, debut: 2024, fin: 2030),
        ]),
        isEmpty,
      );
    });

    test('un écart d\'un ou deux ans ne justifie pas une écriture', () {
      final c = ApogeeBackfill.aCorriger([
        vin(nom: 'Côtes du Rhône', region: 'Rhône', appellation: 'Côtes du Rhône',
            millesime: 2022, debut: 2023, fin: 2031),
      ]);
      for (final x in c) {
        expect(x.ecartAnnees, greaterThanOrEqualTo(ApogeeBackfill.ecartMinimalAnnees),
            reason: 'On ne réécrit pas la base pour gagner un an sur une estimation qui '
                'reste une estimation.');
      }
    });

    test('un vin sans millésime n\'est pas figé', () {
      expect(
        ApogeeBackfill.aCorriger([
          vin(nom: 'Champagne Brut', region: 'Champagne', appellation: 'Champagne',
              type: 'sparkling'),
        ]),
        isEmpty,
        reason: 'Sans millésime, la fenêtre n\'a pas de sens à être écrite en base.',
      );
    });

    test('un spiritueux n\'a pas d\'apogée', () {
      expect(
        ApogeeBackfill.aCorriger([
          vin(nom: 'Tomatin 12 ans', region: 'Highland', type: 'Spiritueux',
              millesime: 2012),
        ]),
        isEmpty,
        reason: 'On y suit le niveau de la bouteille, pas une courbe de garde.',
      );
    });
  });

  test('un domaine nommé est corrigé selon SON domaine, pas sa catégorie', () {
    final c = ApogeeBackfill.aCorriger([
      vin(nom: 'Château d\'Yquem', region: 'Bordeaux', appellation: 'Sauternes',
          type: 'Moelleux', millesime: 2010, debut: 2012, fin: 2025),
    ]).single;
    expect(c.nouvelleFin - 2010, greaterThan(60),
        reason: 'Yquem dépasse largement la catégorie Sauternes.');
  });
}
