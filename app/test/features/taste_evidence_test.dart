import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_evidence.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';

/// Le registre des preuves — condition de la lisibilité du modèle.
///
/// Sans lui, le profil affirme « vous aimez le Jura » et personne, pas même nous, ne
/// peut dire pourquoi. Un modèle qu'on ne peut pas interroger n'est pas compréhensible,
/// il est seulement affiché.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Wine vin(String region, String cepage) => Wine(
        id: 'w_${region}_$cepage',
        name: 'Cuvée $region',
        type: 'Rouge',
        country: 'France',
        region: region,
        grapes: [Grape(name: cepage)],
      );

  group('🧾 Ce qui justifie une conviction', () {
    test('une dégustation enthousiaste laisse sa trace', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();

      await service.recordTastingExperience(
        nameOrId: p.id,
        wine: vin('Madiran', 'Tannat'),
        rating: 9.0,
      );

      final traces = (await TasteEvidenceLedger.ouvrir()).pour('region:Madiran');
      expect(traces, hasLength(1));
      expect(traces.first.source, equals('degustation'));
      expect(traces.first.effet, contains('9.0/10'));
      expect(traces.first.vin, equals('Cuvée Madiran'));
    });

    test('une déception laisse aussi la sienne', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();

      await service.recordTastingExperience(
        nameOrId: p.id, wine: vin('Madiran', 'Tannat'), rating: 9.0);
      await service.recordTastingExperience(
        nameOrId: p.id, wine: vin('Madiran', 'Tannat'), rating: 2.0);

      final traces = (await TasteEvidenceLedger.ouvrir()).pour('region:Madiran');
      expect(traces, hasLength(2),
          reason: 'Le retrait doit être aussi traçable que l\'ajout : sinon on ne peut '
              'pas expliquer pourquoi une région a DISPARU des favoris.');
      expect(traces.first.effet, contains('retiré'));
      expect(traces.last.effet, contains('ajouté'));
    });

    test('une note intermédiaire ne trace rien', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();
      await service.recordTastingExperience(
          nameOrId: p.id, wine: vin('Chablis', 'Chardonnay'), rating: 6.0);
      expect((await TasteEvidenceLedger.ouvrir()).lire(), isEmpty,
          reason: 'Rien n\'a bougé dans le profil : il n\'y a rien à justifier.');
    });

    test('un rachat se justifie par le geste, pas par une note', () async {
      final service = TasteProfileService();
      final p = await service.getPrimaryProfile();

      Bottle b(DateTime d) => Bottle(
            id: 'b${d.millisecondsSinceEpoch}',
            cellarId: 'c1',
            wineId: 'w1',
            addedBy: 'u1',
            ownerId: 'u1',
            createdAt: d,
            purchaseDate: d,
            wine: vin('Jura', 'Trousseau'),
          );

      await service.applyCellarBehaviour(
          p.id, [b(DateTime(2026, 1, 10)), b(DateTime(2026, 7, 4))]);

      final traces = (await TasteEvidenceLedger.ouvrir()).pour('region:Jura');
      expect(traces, hasLength(1));
      expect(traces.first.source, equals('rachat'));
      expect(traces.first.effet, contains('revenu'));
    });

    test('les plus récentes viennent en premier', () async {
      final registre = await TasteEvidenceLedger.ouvrir();
      await registre.ajouter([
        TasteEvidenceEntry(
            quand: DateTime(2026, 1, 1), source: 'degustation', cible: 'axe:acidity', effet: 'vieux'),
      ]);
      await registre.ajouter([
        TasteEvidenceEntry(
            quand: DateTime(2026, 9, 1), source: 'gorgee', cible: 'axe:acidity', effet: 'récent'),
      ]);
      expect(registre.lire().first.effet, equals('récent'));
    });

    test('le registre est borné', () async {
      final registre = await TasteEvidenceLedger.ouvrir();
      for (var i = 0; i < TasteEvidenceLedger.tailleMax + 40; i++) {
        await registre.ajouter([
          TasteEvidenceEntry(
              quand: DateTime(2026, 1, 1), source: 'test', cible: 'axe:body', effet: 'e$i'),
        ]);
      }
      expect(registre.lire(), hasLength(TasteEvidenceLedger.tailleMax),
          reason: 'Une cave active produit plusieurs entrées par dégustation ; sans borne '
              'le journal finirait par peser sur le démarrage.');
      expect(registre.lire().first.effet, equals('e${TasteEvidenceLedger.tailleMax + 39}'));
    });

    test('un registre corrompu ne fait pas tomber l\'app', () async {
      SharedPreferences.setMockInitialValues(
          {'chatmelier_taste_evidence_v1': 'pas du json'});
      expect((await TasteEvidenceLedger.ouvrir()).lire(), isEmpty);
    });
  });
}
