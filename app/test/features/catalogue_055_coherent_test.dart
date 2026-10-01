import 'package:chatmelier/features/cellar/domain/aging_reference.dart';
import 'package:chatmelier/features/cellar/domain/wine_service_advisor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les fenêtres corrigées par la migration 055 doivent passer telles quelles le contrôle
/// de plausibilité de l'app (l'enveloppe de `computeDrinkingWindow`). Sinon l'app les
/// remplace par sa propre estimation et la correction ne se voit jamais.
///
/// Relevé le 01/10 : trois corrections étaient rejetées. Deux par un défaut de l'app
/// (un second vin rangé au sommet, la « Réserve » d'un nom de coopérative), une par une
/// erreur de la migration (un Bandol rouge ramené à dix ans).
void main() {
  // nom, producteur, appellation, région, pays, type, classification, millésime,
  // puis la fenêtre écrite par la 055 : début, fin, début d'apogée, fin d'apogée.
  const corrections = <List<Object?>>[
    ['Coste Brune Cuvée Prestige Bandol Rosé', 'Domaine Coste Brune', 'Bandol', 'Provence', 'France', 'rosé', 'AOP Bandol', 2023, 2024, 2028, 2024, 2026],
    ['Bandol', 'Domaine de la Garenne', 'Bandol', 'Provence', 'France', 'rosé', 'AOP', 2024, 2025, 2028, 2025, 2027],
    ['So Sauternes', 'Château Bastor-Lamontagne', 'Sauternes', 'Bordeaux', 'France', 'dessert', 'AOC', 2022, 2024, 2032, 2025, 2029],
    ['Sarget de Gruaud Larose', 'Château Gruaud Larose', 'Saint-Julien', 'Bordeaux', 'France', 'red', 'Second Vin de Grand Cru Classé', 2019, 2024, 2036, 2026, 2032],
    ['Réserve des Hospitaliers Cairanne', 'Réserve des Hospitaliers', 'Cairanne', 'Vallée du Rhône', 'France', 'red', 'AOC Cru des Côtes du Rhône', 2021, 2023, 2030, 2024, 2028],
    ['Cave de Tain Nobles Rives Crozes-Hermitage', 'Cave de Tain (Héritiers Gambert)', 'Crozes-Hermitage', 'Vallée du Rhône', 'France', 'red', 'AOC', 2021, 2023, 2030, 2024, 2027],
    ['Chorey-les-Beaune', 'Remy Lefevre', 'Chorey-lès-Beaune', 'Bourgogne', 'France', 'red', 'Village', 2023, 2025, 2033, 2027, 2031],
    ['Grande Réserve', 'Domaine du Paternel', 'Bandol', 'Provence', 'France', 'red', null, 2021, 2024, 2041, 2027, 2035],
    ['Château Crabitey Graves Blanc', 'Château Crabitey', 'Graves', 'Bordeaux', 'France', 'white', 'AOC', 2022, 2023, 2030, 2024, 2027],
    ['Cave de Turckheim Gewurztraminer', 'Cave de Turckheim', 'Alsace', 'Alsace', 'France', 'white', 'AOC Alsace', 2023, 2024, 2030, 2025, 2028],
    // Fenêtres inchangées, mais l'appellation ou l'élevage corrigés ne doivent pas les faire rejeter.
    ['Meursault Premier Cru Les Charmes', 'Domaine des Comtes Lafon', 'Meursault Premier Cru', 'Bourgogne', 'France', 'white', null, 2020, 2022, 2037, 2024, 2031],
    ['Gran Reserva 904', 'La Rioja Alta S.A.', 'Rioja DOCa', 'La Rioja', 'Spain', 'red', 'Gran Reserva', 2016, 2024, 2045, 2026, 2038],
  ];

  for (final c in corrections) {
    test('${c[0]} ${c[7]} : la fenêtre ${c[8]}-${c[9]} est gardée', () {
      final f = WineOenologyAdvisor.computeDrinkingWindow(
        wineName: c[0] as String,
        producer: c[1] as String,
        appellation: c[2] as String?,
        region: c[3] as String,
        country: c[4] as String,
        wineType: c[5] as String,
        classification: c[6] as String?,
        vintage: c[7] as int,
        explicitDrinkStart: c[8] as int,
        explicitDrinkEnd: c[9] as int,
        explicitPeakStart: c[10] as int,
        explicitPeakEnd: c[11] as int,
      );
      expect([f.drinkStart, f.drinkEnd], [c[8], c[9]]);
    });
  }

  group('Le rang d\'une cuvée', () {
    test('un second vin n\'est pas un grand vin, même « de Grand Cru Classé »', () {
      expect(
          AgingReference.rangDe(nom: 'Sarget de Gruaud Larose', classification: 'Second Vin de Grand Cru Classé'),
          WineTier.entree);
      expect(AgingReference.rangDe(nom: 'Château Gruaud Larose', classification: 'Deuxième Grand Cru Classé'),
          WineTier.sommet);
    });

    test('les mots du producteur ne disent rien de la cuvée', () {
      expect(
          AgingReference.rangDe(
              nom: 'Réserve des Hospitaliers Cairanne', producteur: 'Réserve des Hospitaliers', appellation: 'Cairanne'),
          WineTier.standard);
      // La mention portée par la cuvée, elle, compte toujours.
      expect(AgingReference.rangDe(nom: 'Grande Réserve', producteur: 'Domaine du Paternel'), WineTier.superieur);
    });
  });
}
