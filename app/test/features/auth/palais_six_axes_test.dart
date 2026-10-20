// V2.6 · lot P — le palais en six axes, appris par famille de vins.
//
// L'expérience du 19/10 sur trois palais types : quelqu'un qui aime les blancs légers et les
// rouges puissants recevait un corps « moyen » qui ne lui allait pour aucun des deux ; la
// douceur et l'âge, qui partagent le plus les gens, n'avaient pas d'axe ; une déception due à
// l'âge du vin faisait dériver les tanins.

import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/apprentissage_du_palais.dart';
import 'package:chatmelier/features/auth/domain/palais.dart';
import 'package:chatmelier/features/auth/domain/taste_evidence.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/domain/taste_undo.dart';
import 'package:chatmelier/features/cellar/domain/douceur_du_vin.dart';
import 'package:chatmelier/features/cellar/domain/evolution_du_vin.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';
import 'package:chatmelier/features/sommelier/domain/profil_du_vin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('la douceur d\'un vin', () {
    DouceurDuVin d(String nom, {String type = 'white', String? appellation, String? pays, List<String> cepages = const []}) =>
        DouceurDuVin.estimer(type: type, nom: nom, appellation: appellation, pays: pays, cepages: cepages);

    test('ce que dit l\'étiquette est sûr', () {
      expect(d('Champagne Brut', type: 'sparkling').valeur, 0.1);
      expect(d('Champagne Brut Nature', type: 'sparkling').valeur, 0.02);
      expect(d('Champagne Demi-Sec', type: 'sparkling').valeur, 0.45);
      expect(d('Vouvray Demi-Sec').valeur, 0.45);
      expect(d('Riesling Spätlese', pays: 'Allemagne').valeur, 0.55);
      expect(d('Riesling Spätlese trocken', pays: 'Allemagne').valeur, 0.05);
      expect(d('Jurançon sec').valeur, 0.05);
      expect(d('Champagne Demi-Sec', type: 'sparkling').sure, isTrue);
    });

    test('sur une bulle, « sec » et « dry » disent un vin tendre', () {
      expect(d('Champagne Sec', type: 'sparkling').valeur, 0.3,
          reason: 'un Champagne Sec est plus doux qu\'un Brut');
      expect(d('Prosecco Dry', type: 'sparkling').valeur, 0.3);
      expect(d('Prosecco Extra Dry', type: 'sparkling').valeur, 0.2);
    });

    test('une appellation qui n\'existe qu\'en doux, sans se tromper d\'homonyme', () {
      expect(d('Château Suduiraut', appellation: 'Sauternes').valeur, 0.85);
      expect(d('Château Suduiraut', appellation: 'Sauternes').sure, isTrue);
      expect(d('Clos du Maury', type: 'red', appellation: 'Côtes du Roussillon Villages').valeur, 0.03);
      expect(d('Château Biac', type: 'red', appellation: 'Cadillac Côtes de Bordeaux').valeur, 0.03);
      expect(d('Graham\'s 10 Year Old Tawny Port', type: 'fortified').valeur, 0.85);
    });

    test('quand l\'étiquette se tait : l\'usage, deviné', () {
      expect(d('Vouvray', appellation: 'Vouvray').valeur, 0.25);
      expect(d('Vouvray', appellation: 'Vouvray').sure, isFalse);
      expect(d('Gewurztraminer', appellation: 'Alsace').valeur, 0.3);
      expect(d('Sancerre', appellation: 'Sancerre').valeur, 0.08);
      expect(d('Pauillac', type: 'red').valeur, 0.03);
    });
  });

  group('l\'évolution d\'un vin', () {
    test('lue sur sa fenêtre de garde : jeune, à l\'apogée, au-delà', () {
      double e(int annee) =>
          EvolutionDuVin.surLaFenetre(annee: annee, millesime: 2015, debut: 2020, apogeeDebut: 2025, apogeeFin: 2032, fin: 2040);
      expect(e(2016), closeTo(0.09, 0.01));
      expect(e(2025), closeTo(0.45, 1e-9));
      expect(e(2030), inInclusiveRange(0.45, 0.65));
      expect(e(2050), greaterThan(0.85));
    });

    test('sans millésime, on ne sait pas', () {
      expect(EvolutionDuVin.estimer(millesime: null, annee: 2026, type: 'red'), isNull);
    });
  });

  group('ce qu\'une dégustation apprend', () {
    const rouge = FamillesDeVins.rouge;
    ProfilDuVin vin(Map<String, double> v, {Set<String> surs = const {}}) => ProfilDuVin(famille: rouge, valeurs: v, surs: surs);
    ChangementDAxe sur(List<ChangementDAxe> cs, String axe) => cs.singleWhere((c) => c.axe == axe);

    test('« trop tannique » place la préférence en deçà du vin, et compte', () {
      const p = TasteProfile(id: 'p', name: 'P', palais: {'rouge': {'tannin': 0.6}}, observationsPalais: {'rouge': {'tannin': 3}});
      final cs = ApprentissageDuPalais.apprendre(
          profil: p, famille: rouge, note: 6, jugements: {'tannin': 'trop'}, vin: vin({'tannin': 0.9}));
      final c = sur(cs, 'tannin');
      expect(c.apres, closeTo(0.6 * 0.75 + 0.7 * 0.25, 1e-9));
      expect(c.compte, isTrue);
      expect(c.motif, 'jugement');
    });

    test('« juste » sur un axe inconnu le fixe au niveau du vin', () {
      const p = TasteProfile(id: 'p', name: 'P');
      final c = sur(ApprentissageDuPalais.apprendre(
          profil: p, famille: rouge, note: 4, jugements: {'body': 'juste'}, vin: vin({'body': 0.4})), 'body');
      expect(c.apres, 0.4, reason: 'même sur un vin peu aimé : le corps n\'était pas en cause');
    });

    test('un vin aimé sans réponse tire d\'un demi-pas, sans compter ; son âge compte', () {
      const p = TasteProfile(id: 'p', name: 'P', palais: {'rouge': {'body': 0.5}});
      final cs = ApprentissageDuPalais.apprendre(
          profil: p, famille: rouge, note: 8, vin: vin({'body': 0.7, 'evolution': 0.6}, surs: {'evolution'}));
      expect(sur(cs, 'body').apres, closeTo(0.5 * 0.875 + 0.7 * 0.125, 1e-9));
      expect(sur(cs, 'body').compte, isFalse);
      expect(sur(cs, 'evolution').apres, 0.6);
      expect(sur(cs, 'evolution').compte, isTrue);
    });

    test('une déception éloigne seulement de ce qui peut l\'expliquer', () {
      const p = TasteProfile(id: 'p', name: 'P', palais: {'rouge': {'acidity': 0.5, 'body': 0.5}});
      final cs = ApprentissageDuPalais.apprendre(
          profil: p, famille: rouge, note: 3, mesures: {'acidity': 0.8, 'body': 0.55}, vin: vin({}));
      expect(cs.map((c) => c.axe), ['acidity']);
      expect(sur(cs, 'acidity').apres, closeTo(0.5 - 0.0625, 1e-9));
    });

    test('déjà expliquée, ou sans cause visible : une déception n\'apprend rien aux axes', () {
      const p = TasteProfile(id: 'p', name: 'P', palais: {'rouge': {'acidity': 0.3, 'tannin': 0.5}});
      expect(ApprentissageDuPalais.apprendre(
          profil: p, famille: rouge, note: 3, vin: vin({'acidity': 0.9, 'tannin': 0.55})), isEmpty,
          reason: 'l\'acidité, bien plus haute que la préférence, explique la déception');
      expect(ApprentissageDuPalais.apprendre(
          profil: p, famille: rouge, note: 3, vin: vin({'acidity': 0.32, 'tannin': 0.55})), isEmpty,
          reason: 'un vin semblable au palais sur tous les axes : la cause est ailleurs (le correctif de Q5)');
    });

    test('les défauts nommés valent des « pour vous », le « pour vous » l\'emporte', () {
      expect(ApprentissageDuPalais.jugementsDe({'body': 'juste'}, {'trop_tannique', 'trop_leger', 'rien'}),
          {'tannin': 'trop', 'body': 'juste'});
      expect(ApprentissageDuPalais.jugementsDe(const {}, {'trop_sucre'}), {'sweetness': 'trop'});
    });
  });

  group('le palais par famille', () {
    test('rouges ; blancs, rosés, bulles, liquoreux ; ni muté ni spiritueux', () {
      expect(TasteProfile.familleDe('red'), 'rouge');
      expect(TasteProfile.familleDe('Rouge'), 'rouge');
      for (final t in ['white', 'rosé', 'sparkling', 'dessert', 'orange']) {
        expect(TasteProfile.familleDe(t), 'blanc', reason: t);
      }
      expect(TasteProfile.familleDe('fortified'), isNull);
      expect(TasteProfile.familleDe('whisky'), isNull);
    });

    test('le palais d\'avant sert de repli : ses observations partagées selon les couleurs aimées', () {
      const p = TasteProfile(
          id: 'p', name: 'P', avgBodyPreference: 0.7, avgTanninPreference: 0.8, axisObservations: {'body': 6, 'tannin': 4});
      expect(p.valeurPalais('blanc', 'body'), 0.7);
      expect(p.observationsSur('blanc', 'body'), 3, reason: 'sans couleur préférée : la moitié à chaque famille');
      expect(p.valeurPalais('blanc', 'tannin'), isNull, reason: 'les tanins ne se jugent que sur un rouge');
      expect(p.observationsSur('rouge', 'tannin'), 4, reason: 'les tanins ne s\'observaient que sur des rouges : en entier');
      const rougesSeulement = TasteProfile(
          id: 'p', name: 'P', favoriteTypes: ['Rouge'], avgBodyPreference: 0.7, axisObservations: {'body': 6});
      expect(rougesSeulement.observationsSur('rouge', 'body'), 6);
      expect(rougesSeulement.observationsSur('blanc', 'body'), 0, reason: 'appris sur des rouges : deviné pour les blancs');
    });

    test('les couleurs, régions et cépages préférés n\'ajoutent plus rien aux axes', () {
      const etiquettes = TasteProfile(
          id: 'p', name: 'P', favoriteTypes: ['Rouge'], favoriteRegions: ['Bordeaux', 'Rhône'], favoriteGrapes: ['Syrah', 'Cabernet']);
      final r = etiquettes.palaisPour('rouge');
      for (final axe in AxesDuPalais.de('rouge')) {
        expect(r.valeur(axe), AxesDuPalais.neutre('rouge', axe), reason: axe);
        expect(r.confianceDe(axe), 0);
      }
    });

    test('appris, il s\'affiche ; déclaré, aussi, mais sans confiance', () {
      const p = TasteProfile(
          id: 'p',
          name: 'P',
          palais: {'blanc': {'acidity': 0.8}},
          observationsPalais: {'blanc': {'acidity': 5}},
          palaisDeDepart: {'sweetness': 2.0});
      final b = p.palaisPour('blanc');
      expect(b.valeur('acidity'), closeTo(8.0, 1e-9));
      expect(b.confianceDe('acidity'), 0.5);
      expect(b.valeur('sweetness'), 2.0);
      expect(b.confianceDe('sweetness'), 0);
      expect(b.connus, {'acidity', 'sweetness'});
    });

    test('il se relit tel qu\'il s\'écrit', () {
      const p = TasteProfile(
          id: 'p', name: 'P', palais: {'rouge': {'tannin': 0.4}}, observationsPalais: {'rouge': {'tannin': 2}});
      final relu = TasteProfile.fromJson(p.toJson());
      expect(relu.palais, p.palais);
      expect(relu.observationsPalais, p.observationsPalais);
    });
  });

  group('le service', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    TastingQuestionnaireResult avis(double note, {Map<String, String> jugements = const {}}) => TastingQuestionnaireResult(
          emojiImpression: 3,
          noteOutOf10: note,
          perceivedAromas: const {},
          aromaIntensity: 0.5,
          length: 0.5,
          wouldBuyAgain: 'maybe',
          idealMoment: '',
          whatLikedMost: const {},
          whatDislikedMost: const {},
          jugements: jugements,
          profileId: 'p',
          profileName: 'P',
        );

    const chablis = Wine(id: 'c', name: 'Chablis', type: 'white', country: 'France', region: 'Bourgogne', appellation: 'Chablis', vintage: 2022);
    const cornas = Wine(id: 'r', name: 'Cornas', type: 'red', country: 'France', region: 'Vallée du Rhône', appellation: 'Cornas', vintage: 2019);

    test('un blanc n\'apprend qu\'au palais des blancs, et se défait', () async {
      final service = TasteProfileService();
      await service.saveProfiles([const TasteProfile(id: 'p', name: 'P', isPrimary: true)]);

      await service.applyQuestionnaireResult(
          result: avis(8, jugements: {'acidity': 'juste'}), wineType: 'white', vin: chablis, tastingId: 'chablis');

      final p = (await service.getProfiles()).single;
      expect(p.valeurPropre('blanc', 'acidity'), isNotNull);
      expect(p.observationsSur('blanc', 'acidity'), 1);
      expect(p.palais['rouge'], isNull, reason: 'les rouges n\'ont rien appris');
      expect(p.questionnairesCompleted, 1);

      final registre = await TasteEvidenceLedger.ouvrir();
      expect(registre.pour('axe:blanc:acidity').single.effet, contains('« Juste » à vos yeux'));
      final r = TasteUndo.annuler(profil: p, contributions: registre.pourDegustation('chablis'), registre: registre);
      expect(r.profil.valeurPropre('blanc', 'acidity'), isNull);
      expect(r.profil.observationsSur('blanc', 'acidity'), 0);
      expect(r.complete, isTrue);
    });

    test('deux styles : le corps des blancs et celui des rouges ne se moyennent plus', () async {
      final service = TasteProfileService();
      await service.saveProfiles([const TasteProfile(id: 'p', name: 'P', isPrimary: true)]);
      for (var i = 0; i < 4; i++) {
        await service.applyQuestionnaireResult(result: avis(9, jugements: {'body': 'juste'}), wineType: 'white', vin: chablis);
        await service.applyQuestionnaireResult(result: avis(9, jugements: {'body': 'juste'}), wineType: 'red', vin: cornas);
      }
      final p = (await service.getProfiles()).single;
      expect(p.valeurPalais('blanc', 'body')!, lessThan(p.valeurPalais('rouge', 'body')! - 0.2));
      expect(p.observationsSur('blanc', 'body'), 4);
      expect(p.observationsSur('rouge', 'body'), 4);
    });

    test('une note seule apprend aussi : l\'âge du vin compte', () async {
      final service = TasteProfileService();
      await service.saveProfiles([const TasteProfile(id: 'p', name: 'P', isPrimary: true)]);
      await service.recordTastingExperience(nameOrId: 'p', wine: cornas, rating: 9);
      final p = (await service.getProfiles()).single;
      expect(p.observationsSur('rouge', 'evolution'), 1);
      expect(p.observationsSur('rouge', 'body'), 0, reason: 'déduit d\'un vin aimé : deviné, pas observé');
      expect(p.valeurPropre('rouge', 'body'), isNotNull);
    });
  });
}
