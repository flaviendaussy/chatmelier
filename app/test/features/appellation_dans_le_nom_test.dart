import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/wine_service_advisor.dart';
import 'package:chatmelier/features/cellar/domain/wine_world/wine_world.dart';
import 'package:chatmelier/shared/utils/sans_accents.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deux défauts de reconnaissance trouvés en réalignant les tests (01/10).
void main() {
  group('Les accents des vins espagnols et portugais', () {
    test('sont repliés comme les accents français', () {
      expect(sansAccents('Rías Baixas'), 'rias baixas');
      expect(sansAccents('López de Heredia'), 'lopez de heredia');
      expect(sansAccents('Cariñena'), 'carinena');
      expect(sansAccents('Dão'), 'dao');
      expect(sansAccents('Duché d’Uzès'), "duche d'uzes");
    });

    test('n\'empêchent plus de reconnaître la région', () {
      // « Rías Baixas » devenait « r as baixas » et ne correspondait à rien.
      expect(WineWorld.region(appellation: 'Rías Baixas')?.id, 'es_galice');
      expect(WineWorld.region(appellation: 'Cariñena')?.id, 'es_castille');
      expect(WineWorld.region(appellation: 'Dão')?.id, 'pt_dao_bairrada');
    });

    test('ni le domaine', () {
      // Le producteur seul : « R. López de Heredia » devenait « r l pez de heredia ».
      expect(WineWorld.reference(nom: 'Gran Reserva', producteur: 'R. López de Heredia')?.nom,
          'R. López de Heredia');
    });
  });

  group('Le trait d\'union', () {
    test('« Côtes-du-Rhône » et « Côtes du Rhône » sont la même appellation', () {
      expect(WineWorld.region(appellation: 'Côtes-du-Rhône')?.id, 'fr_rhone_villages');
      expect(WineWorld.region(appellation: 'Côtes du Rhône')?.id, 'fr_rhone_villages');
      expect(WineWorld.region(appellation: 'Chateauneuf du Pape')?.id, 'fr_chateauneuf');
    });

    test('la région seule « Vallée du Rhône » a une catégorie', () {
      expect(WineWorld.region(region: 'Vallée du Rhône')?.id, 'fr_rhone_villages');
    });
  });

  group('L\'appellation portée par le nom', () {
    test('un Châteauneuf-du-Pape sans appellation n\'est pas un côtes-du-rhône', () {
      final f = WineOenologyAdvisor.computeDrinkingWindow(
        wineType: 'red',
        vintage: 2018,
        country: 'France',
        region: 'Vallée du Rhône',
        wineName: 'Châteauneuf-du-Pape',
      );
      // Un Châteauneuf se garde une quinzaine d'années ; un côtes-du-rhône, sept.
      expect(f.drinkEnd, greaterThanOrEqualTo(2030));
    });

    test('le nom ne l\'emporte pas sur une appellation renseignée', () {
      final f = WineOenologyAdvisor.computeDrinkingWindow(
        wineType: 'red',
        vintage: 2020,
        country: 'France',
        region: 'Vallée du Rhône',
        appellation: 'Côtes du Rhône',
        wineName: 'Cuvée Châteauneuf',
      );
      expect(f.drinkEnd, lessThanOrEqualTo(2028));
    });

    test('ni sur le pays : un « Chablis » californien n\'est pas un chablis', () {
      expect(WineWorld.appellationDansLeNom('Chablis', pays: 'USA'), isFalse);
      expect(WineWorld.appellationDansLeNom('Chablis', pays: 'France'), isTrue);
      expect(WineWorld.appellationDansLeNom('Chablis'), isTrue);
      expect(WineWorld.appellationDansLeNom('Rioja Reserva', pays: 'Spain'), isTrue);
      expect(WineWorld.appellationDansLeNom('Rioja Reserva', pays: 'España'), isTrue);
    });
  });

  test('une valeur sourcée garde sa source dans le cache hors ligne', () {
    const vin = Wine(
      id: 'w',
      name: 'Opus One',
      type: 'red',
      country: 'États-Unis',
      region: 'Napa Valley',
      estimatedMarketValue: 380,
      valeurSource: 'https://www.example.org/cote/opus-one',
    );
    final relu = Wine.fromJson(vin.toJson());
    expect(relu.valeurSource, vin.valeurSource);
    expect(relu.valeurFiable, 380);
  });
}
