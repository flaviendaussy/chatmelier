import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/cellar/domain/wine_service_advisor.dart';
import 'package:chatmelier/features/cellar/domain/wine_world/wine_world.dart';

/// La base des régions viticoles — une seule table pour tous les usages.
///
/// Elle remplace la dispersion précédente : `AgingReference` décrivait des longévités,
/// `TerroirGISCatalog` des géographies, et les deux parlaient des mêmes régions sans se
/// connaître.
void main() {
  group('🗺️ Couverture', () {
    test('quinze pays, et la France reste la plus dense', () {
      final c = WineWorld.couverture();
      expect(c.keys.length, equals(15));
      expect(c['France']!.regions, greaterThan(30),
          reason: 'La France concentre le prestige ET le volume : elle mérite sa densité.');
      for (final pays in ['Italie', 'Espagne', 'Portugal', 'Allemagne', 'Autriche',
        'Hongrie', 'Grèce', 'Angleterre', 'États-Unis', 'Argentine', 'Chili',
        'Australie', 'Nouvelle-Zélande', 'Afrique du Sud']) {
        expect(c[pays], isNotNull, reason: '$pays absent de la base');
      }
    });

    test('les deux critères de présence sont représentés', () {
      // Un Pétrus est rarement scanné, un Yellow Tail l'est tous les jours : les deux
      // ont leur place, pour des raisons opposées.
      expect(WineWorld.reference(nom: 'Pétrus')?.raison,
          equals(RaisonDePresence.grandVin));
      expect(WineWorld.reference(nom: 'Yellow Tail Shiraz')?.raison,
          equals(RaisonDePresence.grandVolume));
    });
  });

  group('🔎 Reconnaissance', () {
    test('l\'appellation prime sur la région', () {
      // Un Morgon déclaré « Bourgogne » doit rester un cru du Beaujolais.
      final r = WineWorld.region(appellation: 'Morgon', region: 'Bourgogne');
      expect(r?.id, equals('fr_beaujolais_crus'));
    });

    test('un domaine nommé est reconnu malgré les variantes d\'écriture', () {
      for (final n in ['Domaine de Terrebrune', 'TERREBRUNE', 'Terrebrune Bandol']) {
        expect(WineWorld.reference(nom: n)?.nom, equals('Domaine de Terrebrune'),
            reason: 'variante « $n »');
      }
    });

    test('le nom le plus long l\'emporte', () {
      // « Penfolds » et « Penfolds Grange » coexistent : le second est plus précis.
      expect(WineWorld.reference(nom: 'Penfolds Grange 2016')?.nom,
          equals('Penfolds Grange'));
    });

    test('un fragment court ne déclenche rien', () {
      // Seuil de quatre caractères : en deçà, un morceau de nom de cuvée ferait
      // reconnaître n'importe quel domaine. « Ott » en fait trois — ce vin ne sera donc
      // pas rattaché à Domaines Ott, et c'est le comportement voulu : mieux vaut ne rien
      // affirmer que rattacher à tort.
      expect(WineWorld.reference(nom: 'Cuvée Ott de la Maison'), isNull);
      expect(WineWorld.reference(nom: 'Le Petit Chose'), isNull);
      // Le nom complet, lui, est reconnu.
      expect(WineWorld.reference(nom: 'Domaines Ott Clos Mireille')?.nom,
          equals('Domaines Ott'));
    });
  });

  group('🍷 Effet sur la fenêtre de garde', () {
    ({int debut, int fin}) f({
      required String type, required int mil, String? pays, String? region,
      String? app, String? nom, String? producteur,
    }) {
      final w = WineOenologyAdvisor.computeDrinkingWindow(
        wineType: type, vintage: mil, country: pays, region: region,
        appellation: app, wineName: nom, producer: producteur,
      );
      return (debut: w.drinkStart - mil, fin: w.drinkEnd - mil);
    }

    test('un domaine d\'exception dépasse sa catégorie', () {
      final categorie = f(type: 'Rosé', mil: 2022, app: 'Bandol');
      final terrebrune = f(type: 'Rosé', mil: 2022, app: 'Bandol',
          producteur: 'Domaine de Terrebrune');
      expect(terrebrune.fin, greaterThanOrEqualTo(categorie.fin));
    });

    test('Yquem dépasse largement Sauternes', () {
      final sauternes = f(type: 'Moelleux', mil: 2015, app: 'Sauternes');
      final yquem = f(type: 'Moelleux', mil: 2015, app: 'Sauternes',
          nom: 'Château d\'Yquem');
      expect(yquem.fin, greaterThan(sauternes.fin + 30));
    });

    test('un vin de volume reçoit une fenêtre courte', () {
      // Se tromper sur eux se produit des milliers de fois : ils sont scannés
      // des milliers de fois.
      expect(f(type: 'red', mil: 2023, pays: 'Australie', nom: 'Yellow Tail Shiraz').fin,
          lessThanOrEqualTo(4));
      expect(f(type: 'red', mil: 2022, pays: 'Chili',
              nom: 'Casillero del Diablo Cabernet').fin, lessThanOrEqualTo(9));
    });

    test('les quinze pays produisent tous une fenêtre plausible', () {
      const cas = <(String, String, String, int, int)>[
        ('France', 'Margaux', 'red', 15, 40),
        ('Italie', 'Barolo', 'red', 20, 45),
        ('Espagne', 'Rioja', 'red', 12, 30),
        ('Portugal', 'Douro', 'red', 12, 30),
        ('Allemagne', 'Mosel', 'white', 15, 40),
        ('Autriche', 'Wachau', 'white', 12, 30),
        ('Hongrie', 'Tokaji', 'sweet', 40, 90),
        ('Grèce', 'Santorini', 'white', 10, 30),
        ('Angleterre', 'Sussex', 'sparkling', 8, 20),
        ('États-Unis', 'Napa Valley', 'red', 15, 35),
        ('Argentine', 'Mendoza', 'red', 10, 25),
        ('Chili', 'Maipo', 'red', 12, 28),
        ('Australie', 'Barossa Valley', 'red', 15, 35),
        ('Nouvelle-Zélande', 'Marlborough', 'white', 3, 10),
        ('Afrique du Sud', 'Stellenbosch', 'red', 12, 28),
      ];
      for (final (pays, app, type, mini, maxi) in cas) {
        final r = f(type: type, mil: 2020, pays: pays, app: app);
        expect(r.fin, inInclusiveRange(mini, maxi),
            reason: '$pays / $app : ${r.fin} ans hors de [$mini, $maxi]');
      }
    });
  });
}
