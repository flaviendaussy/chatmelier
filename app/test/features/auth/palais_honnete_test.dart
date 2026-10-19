// V2.5 · Q5 (revue du 18/10) — un palais honnête.
//
// Le modèle de goût affirmait plus qu'il ne savait : un vin aimé poussait des axes par
// stéréotype de cépage (Chardonnay → minéral et boisé), comptés comme des observations,
// si bien que le radar traçait en plein ce qui n'était que deviné ; une même dégustation
// déplaçait un axe jusqu'à quatre fois ; une déception n'apprenait rien aux axes ; et une
// liste de favoris pleine ne bougeait plus (`take` gardait les plus anciens).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_evidence.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/domain/taste_undo.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TasteProfileService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = TasteProfileService();
  });

  TastingQuestionnaireResult degustation({
    double note = 8.0,
    double? acidite,
    double? corps,
    String? toucher,
    String? fruit,
    Set<String> defauts = const {},
  }) =>
      TastingQuestionnaireResult(
        emojiImpression: 3,
        noteOutOf10: note,
        perceivedAromas: const {},
        aromaIntensity: 0.5,
        acidity: acidite,
        body: corps,
        length: 0.5,
        wouldBuyAgain: note >= 7.5 ? 'yes' : 'no',
        idealMoment: 'repas',
        whatLikedMost: const {},
        whatDislikedMost: defauts,
        mouthfeelTexture: toucher,
        fruitProfile: fruit,
        isExpressMode: acidite == null && corps == null,
        profileId: 'moi',
        profileName: 'Moi',
      );

  Future<TasteProfile> moi() async => (await service.getProfiles()).firstWhere((p) => p.id == 'moi');

  Future<void> depart(TasteProfile p) => service.saveProfiles([p]);

  group('un pas par axe et par dégustation', () {
    test('trois mesures de l\'acidité d\'un même vin font un seul pas, vers leur moyenne', () async {
      await depart(const TasteProfile(
          id: 'moi', name: 'Moi', isPrimary: true, avgAcidityPreference: 0.5, axisObservations: {'acidity': 3}));

      await service.applyQuestionnaireResult(
        result: degustation(acidite: 0.9, toucher: 'crisp_salivating', fruit: 'crunchy_tart'),
        wineType: 'white',
      );

      final p = await moi();
      expect(p.avgAcidityPreference, closeTo(0.5 * 0.75 + (0.9 + 0.85 + 0.75) / 3 * 0.25, 1e-9),
          reason: 'Avant : trois pas de suite (réponse, toucher, fruit) ; une bouteille pesait pour trois.');
      expect(p.axisObservations['acidity'], 4);
    });

    test('un palais qui change est suivi : dix vins vifs, puis dix plus mous', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true));

      for (var i = 0; i < 10; i++) {
        await service.applyQuestionnaireResult(result: degustation(acidite: 0.8, corps: 0.5), wineType: 'white');
      }
      for (var i = 0; i < 10; i++) {
        await service.applyQuestionnaireResult(result: degustation(acidite: 0.3, corps: 0.5), wineType: 'white');
      }

      final p = await moi();
      expect(p.avgAcidityPreference, closeTo(0.3, 0.03));
      expect(p.axisObservations['acidity'], 20);
      expect(p.avgBodyPreference, 0.5);
      expect(p.axisObservations['body'], 20,
          reason: 'Vingt corps identiques sont vingt preuves, pas une : la confiance doit monter.');
    });

    test('une mesure qui confirme compte, et se décompte avec sa dégustation', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true));
      await service.applyQuestionnaireResult(result: degustation(toucher: 'crisp_salivating'), tastingId: 'a');
      await service.applyQuestionnaireResult(result: degustation(toucher: 'crisp_salivating'), tastingId: 'b');

      final p = await moi();
      expect(p.avgAcidityPreference, 0.85);
      expect(p.axisObservations['acidity'], 2);

      final registre = await TasteEvidenceLedger.ouvrir();
      final r = TasteUndo.annuler(profil: p, contributions: registre.pourDegustation('b'), registre: registre);
      expect(r.profil.axisObservations['acidity'], 1);
      expect(r.profil.avgAcidityPreference, 0.85);
    });
  });

  group('le cépage, un a priori et jamais une mesure', () {
    test('une Syrah aimée suppose les épices et le fruit mûr, sans rien compter', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true));

      await service.applyQuestionnaireResult(
          result: degustation(note: 8.5), wineGrapes: ['Syrah'], wineType: 'red', tastingId: 'syrah');

      final p = await moi();
      expect(p.avgSpicePreference, 0.85);
      expect(p.avgRipeFruitPreference, 0.75);
      expect(p.axisObservations['spice'] ?? 0, 0, reason: 'Le radar doit le dessiner flou : rien n\'a été goûté.');
      expect(p.axisConfidence('ripeFruit'), 0);
      final trace = (await TasteEvidenceLedger.ouvrir()).pour('axe:spice').single;
      expect(trace.effet, startsWith('supposé à 0.85 d\'après le cépage'));
    });

    test('ni boisé ni minéralité par le cépage : ils tiennent à l\'élevage et au sol', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true));

      await service.applyQuestionnaireResult(result: degustation(note: 9), wineGrapes: ['Chardonnay'], wineType: 'white');
      await service.applyQuestionnaireResult(
          result: degustation(note: 9), wineGrapes: ['Cabernet Sauvignon', 'Merlot'], wineType: 'red');
      await service.applyQuestionnaireResult(result: degustation(note: 9), wineGrapes: ['Sauvignon Blanc'], wineType: 'white');

      final p = await moi();
      expect(p.avgOakPreference, isNull);
      expect(p.avgMineralityPreference, isNull);
      expect(p.avgTanninPreference, 0.80);
      expect(p.avgAcidityPreference, 0.85);
      expect(p.axisObservations.values.where((n) => n > 0), isEmpty);
    });

    test('la première mesure remplace l\'a priori au lieu de s\'y mêler', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true));
      await service.applyQuestionnaireResult(result: degustation(note: 8.5), wineGrapes: ['Syrah'], wineType: 'red');

      await service.applyQuestionnaireResult(result: degustation(note: 8, fruit: 'deep_ripe'), wineType: 'red');

      final p = await moi();
      expect(p.avgRipeFruitPreference, 0.85, reason: 'Pas 0,775 : le stéréotype ne pèse plus rien.');
      expect(p.axisObservations['ripeFruit'], 1);
    });

    test('un a priori ne recouvre pas ce que la personne a déclaré à l\'accueil', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true, palaisDeDepart: {'spice': 3.0}));

      await service.applyQuestionnaireResult(result: degustation(note: 8.5), wineGrapes: ['Syrah'], wineType: 'red');

      final p = await moi();
      expect(p.avgSpicePreference, isNull);
      expect(p.avgRipeFruitPreference, 0.75);
    });

    test('supprimer la dégustation défait l\'a priori sans toucher aux observations', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true));
      await service.applyQuestionnaireResult(
          result: degustation(note: 8.5), wineGrapes: ['Syrah'], wineType: 'red', tastingId: 'syrah');

      final registre = await TasteEvidenceLedger.ouvrir();
      final r = TasteUndo.annuler(profil: await moi(), contributions: registre.pourDegustation('syrah'), registre: registre);

      expect(r.profil.avgSpicePreference, isNull);
      expect(r.profil.avgRipeFruitPreference, isNull);
      expect(r.profil.axisObservations['spice'] ?? 0, 0);
      expect(r.complete, isTrue);
    });
  });

  group('une déception apprend aussi', () {
    test('un vin décevant proche du palais l\'en éloigne d\'un demi-pas', () async {
      await depart(const TasteProfile(
          id: 'moi', name: 'Moi', isPrimary: true, avgAcidityPreference: 0.7, axisObservations: {'acidity': 3}));

      await service.applyQuestionnaireResult(result: degustation(note: 3, acidite: 0.8), wineType: 'white');

      final p = await moi();
      expect(p.avgAcidityPreference, closeTo(0.7 - 0.125 * (0.5 - 0.1), 1e-9));
      expect(p.axisObservations['acidity'], 4);
    });

    test('un vin décevant loin du palais ne fait que le confirmer', () async {
      await depart(const TasteProfile(
          id: 'moi', name: 'Moi', isPrimary: true, avgAcidityPreference: 0.2, axisObservations: {'acidity': 3}));

      await service.applyQuestionnaireResult(result: degustation(note: 3, acidite: 0.9), wineType: 'white');

      final p = await moi();
      expect(p.avgAcidityPreference, 0.2);
      expect(p.axisObservations['acidity'], 3);
    });

    test('une déception n\'invente rien sur un axe jamais observé', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true));

      await service.applyQuestionnaireResult(result: degustation(note: 2, acidite: 0.9, corps: 0.8), wineType: 'red');

      final p = await moi();
      expect(p.avgAcidityPreference, isNull);
      expect(p.avgBodyPreference, isNull);
      expect(p.axisObservations, isEmpty);
    });

    test('des déceptions des deux côtés ne font pas dériver un palais établi', () async {
      await depart(const TasteProfile(
          id: 'moi', name: 'Moi', isPrimary: true, avgAcidityPreference: 0.6, axisObservations: {'acidity': 10}));

      for (var i = 0; i < 10; i++) {
        await service.applyQuestionnaireResult(result: degustation(note: 8, acidite: 0.6), wineType: 'white');
        await service.applyQuestionnaireResult(result: degustation(note: 3, acidite: 0.85), wineType: 'white');
        await service.applyQuestionnaireResult(result: degustation(note: 8, acidite: 0.6), wineType: 'white');
        await service.applyQuestionnaireResult(result: degustation(note: 3, acidite: 0.35), wineType: 'white');
      }

      expect((await moi()).avgAcidityPreference, closeTo(0.6, 0.02));
    });
  });

  group('un défaut nommé ne s\'apprend pas comme un goût', () {
    test('aimé malgré une acidité « trop » marquée : l\'axe descend au lieu de monter', () async {
      await depart(const TasteProfile(
          id: 'moi', name: 'Moi', isPrimary: true, avgAcidityPreference: 0.7, axisObservations: {'acidity': 3}));

      await service.applyQuestionnaireResult(
          result: degustation(note: 8, acidite: 0.9, defauts: {'trop_acide'}), wineType: 'white');

      final p = await moi();
      expect(p.avgAcidityPreference, closeTo(0.7 - 0.125 * (0.5 - 0.2), 1e-9),
          reason: 'Avant : 0,75, l\'axe montait vers le vin jugé trop acide.');
    });

    test('« trop léger » demande davantage de corps', () async {
      await depart(const TasteProfile(
          id: 'moi', name: 'Moi', isPrimary: true, avgBodyPreference: 0.35, axisObservations: {'body': 2}));

      await service.applyQuestionnaireResult(
          result: degustation(note: 6, corps: 0.3, defauts: {'trop_leger'}), wineType: 'red');

      expect((await moi()).avgBodyPreference, closeTo(0.35 + 0.125 * (0.5 - 0.05), 1e-9));
    });
  });

  group('les favoris par ordre récent', () {
    const pleine = ['Bordeaux', 'Bourgogne', 'Rhône', 'Loire', 'Alsace', 'Jura'];

    Wine vin(String region, String cepage) => Wine(
          id: 'w_$region',
          name: 'Cuvée $region',
          type: 'red',
          country: 'France',
          region: region,
          grapes: [Grape(name: cepage)],
        );

    test('une septième région aimée entre en tête ; la plus ancienne sort', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true, favoriteRegions: pleine));

      await service.recordTastingExperience(nameOrId: 'moi', wine: vin('Champagne', 'Pinot Noir'), rating: 8.5);

      final p = await moi();
      expect(p.favoriteRegions, ['Champagne', 'Bordeaux', 'Bourgogne', 'Rhône', 'Loire', 'Alsace'],
          reason: 'Avant : la liste pleine gardait ses six premières régions, quoi qu\'on goûte.');
    });

    test('une région aimée de nouveau repasse devant, sans doublon ni nouvel « ajouté »', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true, favoriteRegions: pleine));

      await service.applyQuestionnaireResult(result: degustation(note: 8.5), wineRegion: 'Loire', wineType: 'white');
      await service.applyQuestionnaireResult(result: degustation(note: 9), wineRegion: 'Languedoc', wineType: 'red');

      final p = await moi();
      expect(p.favoriteRegions, ['Languedoc', 'Loire', 'Bordeaux', 'Bourgogne', 'Rhône', 'Alsace']);
      final registre = await TasteEvidenceLedger.ouvrir();
      expect(registre.pour('region:Loire'), isEmpty);
      expect(registre.pour('region:Languedoc').single.effet, startsWith('ajouté'));
    });

    test('la cave ajoute s\'il reste de la place, sans pousser dehors une dégustation', () async {
      Bottle rachat(String id, DateTime quand) => Bottle(
            id: id,
            cellarId: 'c1',
            wineId: 'w_Corbières',
            addedBy: 'u1',
            ownerId: 'u1',
            createdAt: quand,
            purchaseDate: quand,
            quantity: 1,
            status: 'in_cellar',
            wine: vin('Corbières', 'Carignan'),
          );
      final cave = [rachat('b1', DateTime(2026, 1, 10)), rachat('b2', DateTime(2026, 7, 4))];

      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true, favoriteRegions: pleine));
      await service.applyCellarBehaviour('moi', cave);
      await service.applyCellarBehaviour('moi', cave);
      expect((await moi()).favoriteRegions, pleine);
      expect((await TasteEvidenceLedger.ouvrir()).pour('region:Corbières'), isEmpty,
          reason: 'Avant : la même entrée était réécrite au registre à chaque ouverture du profil.');

      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true, favoriteRegions: ['Jura']));
      await service.applyCellarBehaviour('moi', cave);
      expect((await moi()).favoriteRegions, ['Jura', 'Corbières']);
    });
  });
}
