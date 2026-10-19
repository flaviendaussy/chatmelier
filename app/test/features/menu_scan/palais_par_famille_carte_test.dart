// V2.6 · lot P — l'expérience du 19/10, devenue un garde-fou.
//
// Trois palais types, nourris par le vrai code d'apprentissage, puis la même carte classée
// par le vrai « Pour vous » et par le moteur de table. Avant : un palais « blancs légers et
// rouges puissants » mettait à 99 % le Meursault boisé et un Côtes-du-Rhône moyen ; un Sancerre
// détesté par qui aime les vins tendres sortait « Taillé pour vous » ; une Gran Reserva 2008
// et une Crianza 2022 faisaient jeu égal chez qui aime les vins évolués.

import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';
import 'package:chatmelier/features/menu_scan/domain/explication_du_score.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_table_matcher_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

MenuWine carte(String nom, String type,
        {double t = 0, double a = 5, double b = 5, double o = 3, double s = 1.5, int? millesime, List<String> cepages = const []}) =>
    MenuWine(
      id: nom,
      name: nom,
      producer: '',
      wineType: type,
      vintage: millesime,
      grapes: cepages,
      metrics: MenuWineRadarMetrics(tannins: t, acidity: a, body: b, oak: o, sweetness: s),
    );

final chablis = carte('Chablis 1er cru', 'white', a: 8.5, b: 3, o: 1.5, cepages: ['Chardonnay']);
final sancerre = carte('Sancerre', 'white', a: 8.5, b: 3.5, o: 1, cepages: ['Sauvignon Blanc']);
final vouvray = carte('Vouvray demi-sec', 'white', a: 8, b: 4.5, o: 1, s: 5.5, cepages: ['Chenin Blanc']);
final meursault = carte('Meursault', 'white', a: 5.5, b: 7, o: 7, cepages: ['Chardonnay']);
final coteRotie = carte('Côte-Rôtie', 'red', t: 7.5, a: 6, b: 8, o: 5, cepages: ['Syrah']);
final cdr = carte('Côtes-du-Rhône', 'red', t: 5, a: 5, b: 5.5, o: 2, cepages: ['Grenache', 'Syrah']);
final granReserva = carte('Rioja Gran Reserva', 'red', t: 5.5, a: 6, b: 6.5, o: 6.5, millesime: 2008, cepages: ['Tempranillo']);
final crianza = carte('Rioja Crianza', 'red', t: 5.5, a: 6, b: 6.5, o: 5, millesime: 2024, cepages: ['Tempranillo']);

TastingQuestionnaireResult avis(double note, {Map<String, String> jugements = const {}}) => TastingQuestionnaireResult(
      emojiImpression: 3,
      noteOutOf10: note,
      perceivedAromas: const {},
      aromaIntensity: 0.5,
      length: 0.5,
      wouldBuyAgain: note >= 7.5 ? 'yes' : 'no',
      idealMoment: '',
      whatLikedMost: const {},
      whatDislikedMost: const {},
      jugements: jugements,
      profileId: 'p',
      profileName: 'P',
    );

Wine vin(String nom, String type, {String? appellation, String region = '', int? millesime, List<String> cepages = const []}) => Wine(
      id: nom,
      name: nom,
      type: type,
      country: 'France',
      region: region,
      appellation: appellation,
      vintage: millesime,
      grapes: [for (final c in cepages) Grape(name: c)],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TasteProfileService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = TasteProfileService();
    await service.saveProfiles([const TasteProfile(id: 'p', name: 'P', isPrimary: true)]);
  });

  Future<TasteProfile> palais() async => (await service.getProfiles()).single;
  double score(MenuWine w, TasteProfile p) => ExplicationDuScore.expliquer(w, p)!.score;

  test('deux styles : les blancs légers et les rouges puissants passent devant les vins moyens', () async {
    final petitChablis = vin('Chablis', 'white', appellation: 'Chablis', region: 'Bourgogne', millesime: 2023, cepages: ['Chardonnay']);
    final cornas = vin('Cornas', 'red', appellation: 'Cornas', region: 'Vallée du Rhône', millesime: 2018, cepages: ['Syrah']);
    for (var i = 0; i < 4; i++) {
      await service.applyQuestionnaireResult(
          result: avis(9, jugements: {'body': 'juste', 'acidity': 'juste'}), wineType: 'white', vin: petitChablis);
      await service.applyQuestionnaireResult(
          result: avis(9, jugements: {'body': 'juste', 'tannin': 'juste'}), wineType: 'red', vin: cornas);
    }
    final p = await palais();
    expect(score(chablis, p), greaterThan(score(meursault, p)), reason: 'un blanc léger et vif avant un blanc ample et boisé');
    expect(score(sancerre, p), greaterThan(score(meursault, p)), reason: 'le même style, sans en avoir l\'étiquette');
    expect(score(coteRotie, p), greaterThan(score(cdr, p)), reason: 'un rouge puissant avant un rouge moyen');

    final table = MenuTableMatcherEngine.classerLaCarte(
        menuWines: [chablis, sancerre, meursault, coteRotie, cdr], guests: [GuestProfile.fromTasteProfile(p)]);
    final rang = [for (final r in table) r.menuWine.name];
    expect(rang.indexOf('Chablis 1er cru'), lessThan(rang.indexOf('Meursault')));
    expect(rang.indexOf('Côte-Rôtie'), lessThan(rang.indexOf('Côtes-du-Rhône')));
  });

  test('la douceur : qui aime les blancs tendres n\'a plus son Sancerre détesté « taillé pour lui »', () async {
    final vouvrayDemiSec = vin('Vouvray Demi-Sec', 'white', appellation: 'Vouvray', region: 'Loire', millesime: 2022, cepages: ['Chenin Blanc']);
    final sancerreSec = vin('Sancerre', 'white', appellation: 'Sancerre', region: 'Loire', millesime: 2023, cepages: ['Sauvignon Blanc']);
    for (var i = 0; i < 3; i++) {
      await service.applyQuestionnaireResult(result: avis(9, jugements: {'sweetness': 'juste'}), wineType: 'white', vin: vouvrayDemiSec);
      await service.applyQuestionnaireResult(result: avis(3, jugements: {'sweetness': 'pas_assez'}), wineType: 'white', vin: sancerreSec);
    }
    final p = await palais();
    expect(p.valeurPalais('blanc', 'sweetness')!, greaterThan(0.3));
    expect(score(vouvray, p), greaterThanOrEqualTo(ExplicationDuScore.seuilTaillePourVous));
    expect(score(sancerre, p), lessThan(ExplicationDuScore.seuilTaillePourVous));
    expect(score(vouvray, p), greaterThan(score(sancerre, p)));
  });

  test('les vins évolués : la Gran Reserva passe devant la Crianza de l\'année', () async {
    final vieux = vin('Rioja Gran Reserva', 'red', appellation: 'Rioja', region: 'La Rioja', millesime: 2005, cepages: ['Tempranillo']);
    final jeune = vin('Rioja Joven', 'red', appellation: 'Rioja', region: 'La Rioja', millesime: 2025, cepages: ['Tempranillo']);
    for (var i = 0; i < 4; i++) {
      await service.recordTastingExperience(nameOrId: 'p', wine: vieux, rating: 9);
      await service.recordTastingExperience(nameOrId: 'p', wine: jeune, rating: 4);
    }
    final p = await palais();
    expect(p.observationsSur('rouge', 'evolution'), greaterThan(0), reason: 'l\'âge du vin se lit sur son millésime');
    expect(score(granReserva, p), greaterThan(score(crianza, p)));
  });
}
