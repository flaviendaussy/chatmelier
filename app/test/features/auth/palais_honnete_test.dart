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

  // V2.6 : le palais s'apprend par famille (rouges ; blancs, rosés, bulles). Ces essais
  // gardent l'intention de Q5, lue sur la famille du vin goûté.
  double? axe(TasteProfile p, String famille, String a) => p.valeurPalais(famille, a);
  int obs(TasteProfile p, String famille, String a) => p.observationsSur(famille, a);

  group('un pas par axe et par dégustation', () {
    test('trois mesures de l\'acidité d\'un même vin font un seul pas, vers leur moyenne', () async {
      await depart(const TasteProfile(
          id: 'moi', name: 'Moi', isPrimary: true, palais: {'blanc': {'acidity': 0.5}}, observationsPalais: {'blanc': {'acidity': 3}}));

      await service.applyQuestionnaireResult(
        result: degustation(acidite: 0.9, toucher: 'crisp_salivating', fruit: 'crunchy_tart'),
        wineType: 'white',
      );

      final p = await moi();
      expect(axe(p, 'blanc', 'acidity'), closeTo(0.5 * 0.75 + (0.9 + 0.85 + 0.75) / 3 * 0.25, 1e-9),
          reason: 'Avant Q5 : trois pas de suite (réponse, toucher, fruit) ; une bouteille pesait pour trois.');
      expect(obs(p, 'blanc', 'acidity'), 4);
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
      expect(axe(p, 'blanc', 'acidity'), closeTo(0.3, 0.03));
      expect(obs(p, 'blanc', 'acidity'), 20);
      expect(axe(p, 'blanc', 'body'), 0.5);
      expect(obs(p, 'blanc', 'body'), 20,
          reason: 'Vingt corps identiques sont vingt preuves, pas une : la confiance doit monter.');
      expect(p.palais['rouge'], isNull, reason: 'des blancs n\'apprennent rien du palais des rouges');
    });

    test('une mesure qui confirme compte, et se décompte avec sa dégustation', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true));
      await service.applyQuestionnaireResult(result: degustation(toucher: 'crisp_salivating'), wineType: 'white', tastingId: 'a');
      await service.applyQuestionnaireResult(result: degustation(toucher: 'crisp_salivating'), wineType: 'white', tastingId: 'b');

      final p = await moi();
      expect(axe(p, 'blanc', 'acidity'), 0.85);
      expect(obs(p, 'blanc', 'acidity'), 2);

      final registre = await TasteEvidenceLedger.ouvrir();
      final r = TasteUndo.annuler(profil: p, contributions: registre.pourDegustation('b'), registre: registre);
      expect(obs(r.profil, 'blanc', 'acidity'), 1);
      expect(axe(r.profil, 'blanc', 'acidity'), 0.85);
    });
  });

  group('le cépage et les données du vin : des déductions, jamais des mesures', () {
    test('une Syrah aimée tire le palais des rouges, sans rien compter', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true));

      await service.applyQuestionnaireResult(
          result: degustation(note: 8.5), wineGrapes: ['Syrah'], wineType: 'red', tastingId: 'syrah');

      final p = await moi();
      expect(p.valeurPropre('rouge', 'body'), isNotNull);
      expect(p.valeurPropre('rouge', 'tannin'), isNotNull);
      for (final a in ['body', 'tannin', 'acidity', 'oak', 'sweetness']) {
        expect(obs(p, 'rouge', a), 0, reason: '$a : le radar doit le dessiner flou, rien n\'a été dit');
      }
      final trace = (await TasteEvidenceLedger.ouvrir()).pour('axe:rouge:body').single;
      expect(trace.effet, contains('déduit d\'un vin aimé'));
      expect(trace.compte, isFalse);
    });

    test('la première mesure remplace la déduction au lieu de s\'y mêler', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true));
      await service.applyQuestionnaireResult(result: degustation(note: 8.5), wineGrapes: ['Syrah'], wineType: 'red');

      await service.applyQuestionnaireResult(result: degustation(note: 8, corps: 0.3), wineType: 'red');

      final p = await moi();
      expect(axe(p, 'rouge', 'body'), 0.3, reason: 'la déduction ne pèse plus rien face à ce que la personne a dit');
      expect(obs(p, 'rouge', 'body'), 1);
    });

    test('une déduction ne recouvre pas ce que la personne a déclaré à l\'accueil', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true, palaisDeDepart: {'tannin': 3.0}));

      await service.applyQuestionnaireResult(result: degustation(note: 8.5), wineGrapes: ['Syrah'], wineType: 'red');

      final p = await moi();
      final deduit = p.valeurPropre('rouge', 'tannin')! * 10;
      final affiche = p.palaisPour('rouge');
      expect(affiche.valeur('tannin'), closeTo(3.0 * 0.5 + deduit * 0.5, 1e-9));
      expect(affiche.confianceDe('tannin'), 0);
    });

    test('supprimer la dégustation défait la déduction sans toucher aux observations', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true));
      await service.applyQuestionnaireResult(
          result: degustation(note: 8.5), wineGrapes: ['Syrah'], wineType: 'red', tastingId: 'syrah');

      final registre = await TasteEvidenceLedger.ouvrir();
      final r = TasteUndo.annuler(profil: await moi(), contributions: registre.pourDegustation('syrah'), registre: registre);

      expect(r.profil.palais['rouge'], isNull);
      expect(obs(r.profil, 'rouge', 'body'), 0);
      expect(r.complete, isTrue);
    });
  });

  group('une déception apprend aussi', () {
    test('un vin décevant proche du palais l\'en éloigne d\'un pas', () async {
      await depart(const TasteProfile(
          id: 'moi', name: 'Moi', isPrimary: true, palais: {'blanc': {'acidity': 0.7}}, observationsPalais: {'blanc': {'acidity': 3}}));

      await service.applyQuestionnaireResult(result: degustation(note: 3, acidite: 0.8), wineType: 'white');

      final p = await moi();
      expect(axe(p, 'blanc', 'acidity'), closeTo(0.7 - 0.0625, 1e-9));
      expect(obs(p, 'blanc', 'acidity'), 4);
    });

    test('un vin décevant loin du palais ne fait que le confirmer', () async {
      await depart(const TasteProfile(
          id: 'moi', name: 'Moi', isPrimary: true, palais: {'blanc': {'acidity': 0.2}}, observationsPalais: {'blanc': {'acidity': 3}}));

      await service.applyQuestionnaireResult(result: degustation(note: 3, acidite: 0.9), wineType: 'white');

      final p = await moi();
      expect(axe(p, 'blanc', 'acidity'), 0.2);
      expect(obs(p, 'blanc', 'acidity'), 3);
    });

    test('une déception n\'invente rien sur un axe jamais observé', () async {
      await depart(const TasteProfile(id: 'moi', name: 'Moi', isPrimary: true));

      await service.applyQuestionnaireResult(result: degustation(note: 2, acidite: 0.9, corps: 0.8), wineType: 'red');

      final p = await moi();
      expect(p.palais, isEmpty);
      expect(p.observationsPalais, isEmpty);
    });

    test('des déceptions des deux côtés ne font pas dériver un palais établi', () async {
      await depart(const TasteProfile(
          id: 'moi', name: 'Moi', isPrimary: true, palais: {'blanc': {'acidity': 0.6}}, observationsPalais: {'blanc': {'acidity': 10}}));

      for (var i = 0; i < 10; i++) {
        await service.applyQuestionnaireResult(result: degustation(note: 8, acidite: 0.6), wineType: 'white');
        await service.applyQuestionnaireResult(result: degustation(note: 3, acidite: 0.85), wineType: 'white');
        await service.applyQuestionnaireResult(result: degustation(note: 8, acidite: 0.6), wineType: 'white');
        await service.applyQuestionnaireResult(result: degustation(note: 3, acidite: 0.35), wineType: 'white');
      }

      // Une oscillation autour de 0,6 qui se stabilise (0,636 après le dernier pas vers le
      // haut), pas une dérive.
      expect(axe(await moi(), 'blanc', 'acidity'), closeTo(0.6, 0.04));
    });
  });

  group('un défaut nommé ne s\'apprend pas comme un goût', () {
    test('aimé malgré une acidité « trop » marquée : l\'axe descend au lieu de monter', () async {
      await depart(const TasteProfile(
          id: 'moi', name: 'Moi', isPrimary: true, palais: {'blanc': {'acidity': 0.85}}, observationsPalais: {'blanc': {'acidity': 3}}));

      await service.applyQuestionnaireResult(
          result: degustation(note: 8, acidite: 0.9, defauts: {'trop_acide'}), wineType: 'white');

      final p = await moi();
      expect(axe(p, 'blanc', 'acidity'), closeTo(0.85 * 0.75 + 0.7 * 0.25, 1e-9),
          reason: 'trop acide à 0,9 : la préférence est en deçà (0,7), pas vers le vin');
    });

    test('« trop léger » demande davantage de corps', () async {
      await depart(const TasteProfile(
          id: 'moi', name: 'Moi', isPrimary: true, palais: {'rouge': {'body': 0.35}}, observationsPalais: {'rouge': {'body': 2}}));

      await service.applyQuestionnaireResult(
          result: degustation(note: 6, corps: 0.3, defauts: {'trop_leger'}), wineType: 'red');

      expect(axe(await moi(), 'rouge', 'body'), closeTo(0.35 * 0.75 + 0.5 * 0.25, 1e-9));
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
