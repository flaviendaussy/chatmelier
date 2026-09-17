import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/auth/domain/cellar_concentration.dart';
import 'package:chatmelier/features/cellar/domain/elevage_backfill.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine_world/wine_world.dart';

/// L'élevage : le champ qui manquait pour répondre à « beaucoup de vins élevés 18 mois ».
///
/// `barrelAging` existait déjà mais en texte libre, et sur 79 vins réels il était
/// renseigné ZÉRO fois — aucune migration ne créait la colonne, et l'enrichissement ne
/// la remplissait pas. Un backfill depuis l'existant n'avait donc aucune matière.
void main() {
  Wine vin({
    required String nom,
    String? region,
    String? appellation,
    String type = 'red',
    String? pays,
    String? elevageType,
    int? elevageMois,
  }) =>
      Wine(
        id: 'w_$nom',
        name: nom,
        type: type,
        country: pays ?? 'France',
        region: region ?? '',
        appellation: appellation,
        elevageType: elevageType,
        elevageMois: elevageMois,
      );

  group('📜 Le cahier des charges comme source', () {
    test('les durées imposées sont connues et marquées comme telles', () {
      // Ce sont des FAITS réglementaires, pas des estimations : la distinction est
      // portée par `Elevage.impose`.
      final barolo = WineWorld.elevage(appellation: 'Barolo', type: 'red');
      expect(barolo?.mois, equals(18));
      expect(barolo?.impose, isTrue);
      expect(barolo?.sousBois, isTrue);

      expect(WineWorld.elevage(appellation: 'Brunello di Montalcino', type: 'red')?.mois,
          equals(24));
      expect(WineWorld.elevage(appellation: 'Rioja', type: 'red')?.mois, equals(12));
    });

    test('le contenant distingue des vins de même durée', () {
      // Douze mois en barrique marquent bien davantage que douze en inox : c'est le
      // matériau qui change le vin, pas seulement le temps.
      final chablis = WineWorld.elevage(appellation: 'Chablis', type: 'white');
      final pessac = WineWorld.elevage(appellation: 'Pessac-Léognan', type: 'white');
      expect(chablis?.sousBois, isFalse);
      expect(pessac?.sousBois, isTrue);
    });

    test('la couleur change l\'élevage dans une même appellation', () {
      // Un Bandol rouge passe dix-huit mois sous bois ; son rosé n'y va pas.
      expect(WineWorld.elevage(appellation: 'Bandol', type: 'red')?.sousBois, isTrue);
      expect(WineWorld.elevage(appellation: 'Bandol', type: 'Rosé')?.sousBois, isFalse);
    });
  });

  group('🏛️ Le domaine prime sur son appellation', () {
    test('« En Sol » est élevé en amphores, pas comme son domaine', () {
      // 100 % mourvèdre élevé en tinajas — des amphores de terre cuite commandées dans
      // les Dolomites. Le vin n'est même pas en AOC Bandol mais en IGP Méditerranée,
      // l'appellation exigeant un assemblage. Aucune règle de région ne peut le deviner.
      final enSol = WineWorld.elevage(
          nom: 'En Sol', producteur: 'Domaine de La Tour du Bon',
          appellation: 'IGP Méditerranée', type: 'red');
      expect(enSol?.contenant, equals(ContenantElevage.amphore));
      expect(enSol?.sousBois, isFalse);

      // Le même domaine, sur sa cuvée classique, élève bien sous bois.
      final classique = WineWorld.elevage(
          producteur: 'Domaine de La Tour du Bon', appellation: 'Bandol', type: 'red');
      expect(classique?.sousBois, isTrue);
    });

    test('le nom du vin l\'emporte sur celui du producteur', () {
      // La spécificité n'est pas la longueur du libellé : « Domaine de La Tour du Bon »
      // fait vingt-cinq caractères et « En Sol » six, mais c'est la cuvée qui décrit le
      // vin. Faire gagner le plus long donnait une réponse fausse.
      expect(
        WineWorld.reference(nom: 'En Sol', producteur: 'Domaine de La Tour du Bon')?.nom,
        equals('En Sol'),
      );
    });

    test('la pratique des domaines dépasse le minimum légal', () {
      // Le cahier des charges impose un PLANCHER, pas la pratique. Un Barolo doit
      // dix-huit mois sous bois ; Conterno en fait quatre-vingt-quatre.
      final categorie = WineWorld.elevage(appellation: 'Barolo', type: 'red');
      final monfortino = WineWorld.elevage(
          nom: 'Giacomo Conterno Monfortino', appellation: 'Barolo', type: 'red');
      expect(categorie?.mois, equals(18));
      expect(monfortino!.mois, greaterThan(categorie!.mois * 4));
    });

    test('un inox reste un inox, quel que soit le renom', () {
      // Le contre-exemple : tout n'est pas élevé sous bois, et la base doit le dire.
      final cloudy = WineWorld.elevage(
          nom: 'Cloudy Bay Sauvignon Blanc', appellation: 'Marlborough', type: 'Blanc');
      expect(cloudy?.contenant, equals(ContenantElevage.inox));
      expect(WineWorld.elevage(appellation: 'Chablis', type: 'Blanc')?.sousBois, isFalse);
    });

    test('l\'élevage du champagne se compte en années sur lattes', () {
      final dp = WineWorld.elevage(
          nom: 'Dom Pérignon', appellation: 'Champagne', type: 'sparkling');
      expect(dp?.contenant, equals(ContenantElevage.bouteille));
      expect(dp!.mois, greaterThanOrEqualTo(72));
    });
  });

  group('🔧 Le remplissage', () {
    test('un vin sans élevage est complété depuis son appellation', () {
      final c = ElevageBackfill.aCompleter([
        vin(nom: 'Barolo test', pays: 'Italie', appellation: 'Barolo'),
      ]);
      expect(c, hasLength(1));
      expect(c.first.payload['elevage_type'], equals('foudre'));
      expect(c.first.payload['elevage_months'], equals(18));
      expect(c.first.impose, isTrue);
    });

    test('un élevage déjà renseigné n\'est jamais écrasé', () {
      // Une valeur venue d'un domaine ou saisie à la main vaut mieux qu'une valeur de
      // catégorie.
      expect(
        ElevageBackfill.aCompleter([
          vin(nom: 'Barolo test', pays: 'Italie', appellation: 'Barolo',
              elevageType: 'barrique', elevageMois: 36),
        ]),
        isEmpty,
      );
    });

    test('un vin dont la région est inconnue n\'invente rien', () {
      expect(
        ElevageBackfill.aCompleter([vin(nom: 'Inconnu', region: 'Nulle part')]),
        isEmpty,
      );
    });
  });

  group('🍷 Ce que l\'élevage apprend du goût', () {
    var n = 0;
    Bottle btl(String type, int mois, {int quantity = 1}) {
      n++;
      return Bottle(
        id: 'b$n', cellarId: 'c1', wineId: 'w$n', addedBy: 'u1', ownerId: 'u1',
        createdAt: DateTime(2026, 1, 1), quantity: quantity,
        wine: Wine(
          id: 'w$n', name: 'Cuvée $n', type: 'Rouge', country: 'France',
          region: 'Test', elevageType: type, elevageMois: mois,
        ),
      );
    }

    test('une cave de bois long est un goût, pas un hasard', () {
      // C'est le signal réclamé par « beaucoup de vins élevés 18 mois ».
      final signaux = CellarConcentration.detecter([
        ...List.generate(9, (_) => btl('barrique', 20)),
        ...List.generate(3, (_) => btl('inox', 4)),
      ]);
      expect(signaux.map((s) => s.cible),
          contains('elevage:Bois long (18 mois et plus)'));
    });

    test('une cave d\'inox décrit le goût opposé', () {
      final signaux = CellarConcentration.detecter(
          List.generate(10, (_) => btl('inox', 5)));
      expect(signaux.map((s) => s.cible), contains('elevage:Sans bois, fruit préservé'));
    });

    test('les effervescents ne comptent pas comme un choix d\'élevage', () {
      // L'élevage sur lattes est imposé par la méthode, il ne traduit aucune préférence.
      final signaux = CellarConcentration.detecter(
          List.generate(10, (_) => btl('bouteille', 15)));
      expect(signaux.any((s) => s.dimension == 'elevage'), isFalse);
    });
  });
}
