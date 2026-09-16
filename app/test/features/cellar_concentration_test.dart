import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_evidence.dart';

import 'package:chatmelier/features/auth/domain/cellar_concentration.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';

/// La composition d'une cave est une preuve en soi.
///
/// Une cave n'est pas un échantillon aléatoire : c'est une suite de choix. Accumuler
/// quinze Syrah en dit autant qu'une note, et souvent plus tôt — on achète avant de
/// déguster.
void main() {
  var compteur = 0;
  Bottle btl({
    String region = 'Rhône',
    String? appellation,
    String grape = 'Syrah',
    String type = 'Rouge',
    int quantity = 1,
    int? millesime,
    String? source,
    String status = 'in_cellar',
  }) {
    compteur++;
    return Bottle(
      id: 'b$compteur',
      cellarId: 'c1',
      wineId: 'w$compteur',
      addedBy: 'u1',
      ownerId: 'u1',
      createdAt: DateTime(2026, 1, 1),
      quantity: quantity,
      sourceType: source,
      status: status,
      wine: Wine(
        id: 'w$compteur',
        name: 'Cuvée $compteur',
        type: type,
        country: 'France',
        region: region,
        appellation: appellation,
        vintage: millesime,
        grapes: [Grape(name: grape)],
      ),
    );
  }

  List<Bottle> caveDe(int n, {String grape = 'Syrah', String region = 'Rhône'}) =>
      List.generate(n, (_) => btl(grape: grape, region: region));

  group('📊 « Beaucoup » est relatif, jamais absolu', () {
    test('cinq Syrah dans une cave de dix est une préférence', () {
      final cave = [
        ...caveDe(5, grape: 'Syrah'),
        ...caveDe(5, grape: 'Chardonnay', region: 'Bourgogne'),
      ];
      final signaux = CellarConcentration.detecter(cave);
      expect(signaux.any((s) => s.cible == 'cepage:Syrah'), isTrue);
    });

    test('cinq Syrah dans une cave de deux cents est du bruit', () {
      final cave = [
        ...caveDe(5, grape: 'Syrah'),
        ...caveDe(195, grape: 'Chardonnay', region: 'Bourgogne'),
      ];
      final signaux = CellarConcentration.detecter(cave);
      expect(signaux.any((s) => s.cible == 'cepage:Syrah'), isFalse,
          reason: 'Même compte absolu, sens opposé : c\'est la part qui décide.');
      expect(signaux.any((s) => s.cible == 'cepage:Chardonnay'), isTrue);
    });

    test('une cave trop petite ne produit aucun signal', () {
      // 100 % de Syrah sur trois bouteilles ne veut rien dire.
      expect(CellarConcentration.detecter(caveDe(3)), isEmpty);
    });

    test('une part forte sur trop peu de bouteilles ne suffit pas', () {
      // 2 bouteilles sur 8 = 25 %, mais deux bouteilles ne font pas une habitude.
      final cave = [
        ...caveDe(2, grape: 'Mondeuse'),
        ...caveDe(6, grape: 'Gamay', region: 'Beaujolais'),
      ];
      final signaux = CellarConcentration.detecter(cave);
      expect(signaux.any((s) => s.cible == 'cepage:Mondeuse'), isFalse);
    });
  });

  group('🏷️ Toutes les dimensions, pas seulement le cépage', () {
    test('une appellation sur-représentée ressort', () {
      final cave = [
        ...List.generate(6, (_) => btl(appellation: 'Saint-Joseph')),
        ...List.generate(6, (_) => btl(appellation: 'Chablis', region: 'Bourgogne')),
      ];
      final signaux = CellarConcentration.detecter(cave);
      expect(signaux.map((s) => s.cible), contains('appellation:Saint-Joseph'));
    });

    test('une façon de boire ressort du millésime', () {
      final annee = DateTime.now().year;
      final cave = [
        ...List.generate(8, (_) => btl(millesime: annee - 1)),
        ...List.generate(4, (_) => btl(millesime: annee - 15)),
      ];
      final signaux = CellarConcentration.detecter(cave);
      expect(signaux.map((s) => s.cible), contains('age:Jeune (0-2 ans)'),
          reason: 'Une cave de millésimes récents et une cave de vieilles bouteilles '
              'décrivent deux façons de boire.');
    });

    test('les quantités comptent, pas les lignes', () {
      final cave = [
        btl(grape: 'Mourvèdre', quantity: 9),
        ...caveDe(3, grape: 'Gamay', region: 'Beaujolais'),
      ];
      final signaux = CellarConcentration.detecter(cave);
      expect(signaux.map((s) => s.cible), contains('cepage:Mourvèdre'));
    });
  });

  group('🚫 Ce qui ne compte pas', () {
    test('les cadeaux sont exclus, ici comme ailleurs', () {
      final cave = [
        ...List.generate(6, (_) => btl(grape: 'Merlot', source: 'gift')),
        ...caveDe(6, grape: 'Gamay', region: 'Beaujolais'),
      ];
      final signaux = CellarConcentration.detecter(cave);
      expect(signaux.any((s) => s.cible == 'cepage:Merlot'), isFalse,
          reason: 'Une cave de cadeaux décrit le goût de l\'entourage.');
    });

    test('les bouteilles bues ne comptent plus dans la composition', () {
      final cave = [
        ...List.generate(6, (_) => btl(grape: 'Merlot', status: 'consumed')),
        ...caveDe(6, grape: 'Gamay', region: 'Beaujolais'),
      ];
      final signaux = CellarConcentration.detecter(cave);
      expect(signaux.any((s) => s.cible == 'cepage:Merlot'), isFalse,
          reason: 'La composition décrit ce qu\'on garde, pas ce qu\'on a bu — que la '
              'dégustation couvre déjà.');
    });

    test('« Autre » n\'est pas une valeur', () {
      final cave = List.generate(10, (_) => btl(region: 'Autre'));
      expect(
        CellarConcentration.detecter(cave).any((s) => s.dimension == 'region'),
        isFalse,
      );
    });
  });

  test('les signaux sortent du plus marqué au moins marqué', () {
    final cave = [
      ...caveDe(8, grape: 'Syrah'),
      ...caveDe(4, grape: 'Grenache'),
    ];
    final signaux = CellarConcentration.detecter(cave);
    expect(signaux.first.part, greaterThanOrEqualTo(signaux.last.part));
  });

  group('🏅 Ce que la cave apprend au profil', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('une concentration entre dans les favoris et se justifie', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();

      await service.applyCellarConcentration(p.id, [
        ...caveDe(8, grape: 'Syrah', region: 'Rhône'),
        ...caveDe(4, grape: 'Gamay', region: 'Beaujolais'),
      ]);

      final apres = await service.getPrimaryProfile();
      expect(apres.favoriteGrapes, contains('Syrah'));
      expect(apres.favoriteRegions, contains('Rhône'));

      final traces = (await TasteEvidenceLedger.ouvrir()).pour('cepage:Syrah');
      expect(traces, hasLength(1));
      expect(traces.first.source, equals('cave'));
      expect(traces.first.effet, contains('% de votre cave'));
    });

    test('recharger la cave ne réécrit pas le registre', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();
      final cave = caveDe(10, grape: 'Syrah', region: 'Rhône');

      await service.applyCellarConcentration(p.id, cave);
      await service.applyCellarConcentration(p.id, cave);
      await service.applyCellarConcentration(p.id, cave);

      expect((await TasteEvidenceLedger.ouvrir()).pour('cepage:Syrah'), hasLength(1),
          reason: 'Le fournisseur se déclenche à chaque ouverture de l\'écran de profil.');
    });

    test('les dimensions hors favoris sont tracées sans piloter le profil', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();

      await service.applyCellarConcentration(p.id, [
        ...List.generate(10, (_) => btl(appellation: 'Saint-Joseph')),
      ]);

      final registre = await TasteEvidenceLedger.ouvrir();
      expect(registre.pour('appellation:Saint-Joseph'), hasLength(1),
          reason: 'L\'appellation explique le profil sans que celui-ci sache la porter.');
    });
  });
}
