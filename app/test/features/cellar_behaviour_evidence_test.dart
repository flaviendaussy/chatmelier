import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/auth/data/taste_profile_service.dart';

import 'package:chatmelier/features/auth/domain/cellar_behaviour_evidence.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';

/// Les signaux comportementaux de la cave — ce que les gens FONT, pas ce qu'ils disent.
///
/// Le modèle n'apprenait que des déclarations : une note, des arômes cochés. Une cave
/// enregistre aussi les gestes, qui coûtent plus cher que cocher une case et sont donc
/// plus crédibles. Ces données étaient en base et rien ne les lisait.
void main() {
  Bottle btl({
    required String wineId,
    required DateTime achat,
    int quantity = 1,
    String? source,
    String status = 'in_cellar',
    DateTime? consomme,
    String grape = 'Syrah',
    String region = 'Rhône',
  }) =>
      Bottle(
        id: '$wineId-${achat.millisecondsSinceEpoch}-${consomme?.day ?? 0}',
        cellarId: 'c1',
        wineId: wineId,
        addedBy: 'u1',
        ownerId: 'u1',
        createdAt: achat,
        purchaseDate: achat,
        quantity: quantity,
        sourceType: source,
        status: status,
        consumedAt: consomme,
        wine: Wine(
          id: wineId,
          name: 'Cuvée $wineId',
          type: 'Rouge',
          country: 'France',
          region: region,
          grapes: [Grape(name: grape)],
        ),
      );

  group('🔁 Le rachat', () {
    test('un rachat n\'est pas une quantité', () {
      // Six bouteilles d'un coup, c'est UNE décision — prise avant d'avoir goûté.
      final unSeulAchat = [
        btl(wineId: 'w1', achat: DateTime(2026, 3, 1), quantity: 6),
      ];
      expect(CellarBehaviourEvidence.vinsRachetes(unSeulAchat), isEmpty,
          reason: 'Un carton de six n\'est pas un rachat, c\'est un seul geste.');
    });

    test('revenir des mois plus tard en est un', () {
      final deuxAchats = [
        btl(wineId: 'w1', achat: DateTime(2026, 3, 1)),
        btl(wineId: 'w1', achat: DateTime(2026, 9, 12)),
      ];
      expect(CellarBehaviourEvidence.vinsRachetes(deuxAchats), equals({'w1'}),
          reason: 'La seconde décision est prise en connaissance de cause : c\'est elle '
              'qui vaut quelque chose.');
    });

    test('deux lignes du même jour restent un seul acte', () {
      // Saisie fractionnée — deux formats, deux emplacements — pas un rachat.
      final memeJour = [
        btl(wineId: 'w1', achat: DateTime(2026, 3, 1)),
        btl(wineId: 'w1', achat: DateTime(2026, 3, 1), quantity: 3),
      ];
      expect(CellarBehaviourEvidence.vinsRachetes(memeJour), isEmpty);
    });

    test('on ne rachète pas un cadeau', () {
      final cadeaux = [
        btl(wineId: 'w1', achat: DateTime(2026, 1, 5), source: 'gift'),
        btl(wineId: 'w1', achat: DateTime(2026, 6, 5), source: 'gift'),
      ];
      expect(CellarBehaviourEvidence.vinsRachetes(cadeaux), isEmpty,
          reason: 'Recevoir deux fois le même vin dit le goût de qui l\'offre.');
    });

    test('un cépage racheté ne compte qu\'une fois par vin', () {
      final bottles = [
        btl(wineId: 'w1', achat: DateTime(2026, 1, 1), grape: 'Mondeuse'),
        btl(wineId: 'w1', achat: DateTime(2026, 5, 1), grape: 'Mondeuse', quantity: 12),
        btl(wineId: 'w2', achat: DateTime(2026, 2, 1), grape: 'Mondeuse'),
      ];
      // w1 est racheté, w2 non. Une grosse commande ne doit pas faire double emploi.
      expect(CellarBehaviourEvidence.cepagesRachetes(bottles), equals({'Mondeuse': 1}));
    });

    test('la région rachetée suit la même règle', () {
      final bottles = [
        btl(wineId: 'w1', achat: DateTime(2026, 1, 1), region: 'Jura'),
        btl(wineId: 'w1', achat: DateTime(2026, 8, 1), region: 'Jura'),
      ];
      expect(CellarBehaviourEvidence.regionsRachetees(bottles), equals({'Jura': 1}));
    });
  });

  group('⏱️ Le délai avant ouverture', () {
    test('une bouteille ouverte dans la quinzaine traduit une envie', () {
      final b = btl(
        wineId: 'w1',
        achat: DateTime(2026, 9, 1),
        status: 'consumed',
        consomme: DateTime(2026, 9, 6),
      );
      expect(CellarBehaviourEvidence.ouverteAvecEmpressement(b), isTrue);
      expect(CellarBehaviourEvidence.delaiAvantOuverture(b), equals(const Duration(days: 5)));
    });

    test('une bouteille gardée longtemps ne dit RIEN', () {
      // Point délibéré : garder peut vouloir dire « j\'attends son apogée » — une marque
      // d\'estime — ou « je l\'évite ». Rien ne permet de trancher, donc on n\'en tire
      // aucun signal plutôt que d\'inventer un dégoût.
      final b = btl(
        wineId: 'w1',
        achat: DateTime(2020, 1, 1),
        status: 'consumed',
        consomme: DateTime(2026, 6, 1),
      );
      expect(CellarBehaviourEvidence.ouverteAvecEmpressement(b), isFalse);
      expect(CellarBehaviourEvidence.delaiAvantOuverture(b), isNotNull,
          reason: 'Le délai reste mesurable ; c\'est son interprétation qu\'on refuse.');
    });

    test('une bouteille encore en cave n\'a pas de délai', () {
      expect(
        CellarBehaviourEvidence.delaiAvantOuverture(
            btl(wineId: 'w1', achat: DateTime(2026, 1, 1))),
        isNull,
      );
    });

    test('une date de consommation antérieure à l\'achat est ignorée', () {
      // Saisie rétroactive incohérente : on ne fabrique pas un délai négatif.
      final b = btl(
        wineId: 'w1',
        achat: DateTime(2026, 9, 1),
        status: 'consumed',
        consomme: DateTime(2026, 8, 1),
      );
      expect(CellarBehaviourEvidence.delaiAvantOuverture(b), isNull);
    });
  });

  group('🏅 Le rachat entre dans les favoris', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('un vin racheté devient favori sans qu\'aucune note soit saisie', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();
      expect(p.favoriteRegions, isEmpty);

      await service.applyCellarBehaviour(p.id, [
        btl(wineId: 'w1', achat: DateTime(2026, 1, 10), region: 'Jura', grape: 'Trousseau'),
        btl(wineId: 'w1', achat: DateTime(2026, 7, 4), region: 'Jura', grape: 'Trousseau'),
      ]);

      final apres = await service.getPrimaryProfile();
      expect(apres.favoriteRegions, contains('Jura'),
          reason: 'Hiérarchie de preuves : revenir acheter coûte plus cher que noter 9/10, '
              'donc en dit plus.');
      expect(apres.favoriteGrapes, contains('Trousseau'));
    });

    test('un achat unique ne suffit pas', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();

      await service.applyCellarBehaviour(p.id, [
        btl(wineId: 'w1', achat: DateTime(2026, 1, 10), region: 'Jura', quantity: 12),
      ]);

      final apres = await service.getPrimaryProfile();
      expect(apres.favoriteRegions, isEmpty,
          reason: 'Douze bouteilles achetées d\'un coup, avant d\'avoir goûté, ne prouvent '
              'rien sur le goût.');
    });

    test('rejouer la synchronisation ne duplique rien', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();
      final bottles = [
        btl(wineId: 'w1', achat: DateTime(2026, 1, 10), region: 'Jura'),
        btl(wineId: 'w1', achat: DateTime(2026, 7, 4), region: 'Jura'),
      ];

      await service.applyCellarBehaviour(p.id, bottles);
      await service.applyCellarBehaviour(p.id, bottles);

      final apres = await service.getPrimaryProfile();
      expect(apres.favoriteRegions.where((r) => r == 'Jura').length, equals(1),
          reason: 'Le provider se déclenche à chaque chargement de la cave.');
    });
  });
}
