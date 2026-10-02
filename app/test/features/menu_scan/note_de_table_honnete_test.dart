import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_table_matcher_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Une note de table honnête (V2.3 · K1). Relevé le 02/10 en production : un palais connu à
/// 6 %, déclaré « Rouge », s'affichait « Adepte de Minéralité » pendant que la table le
/// servait en Pauillac, Madiran et Crozes, choisis sur des tanins seulement devinés.
void main() {
  setUp(() => Langue.code = 'fr');

  MenuWine vin(String id, String nom, String type, MenuWineRadarMetrics m) =>
      MenuWine(id: id, name: nom, producer: '', wineType: type, metrics: m, bottlePrice: 50);

  final chablis = vin('chablis', 'Chablis 1er Cru', 'White',
      const MenuWineRadarMetrics(acidity: 9, body: 5.5, fruit: 5, oak: 1.5, minerality: 9.5));
  final meursault = vin('meursault', 'Meursault', 'White',
      const MenuWineRadarMetrics(acidity: 6, body: 7.5, fruit: 6, oak: 7.5, minerality: 5));
  final pauillac = vin('pauillac', 'Pauillac', 'Red',
      const MenuWineRadarMetrics(tannins: 8.5, acidity: 6.5, body: 8.5, fruit: 6, oak: 7.5, minerality: 4));

  // Un palais vif et minéral, qui aime peu le bois.
  TasteProfile palais({Map<String, int> observations = const {}, List<String> styles = const []}) => TasteProfile(
        id: 'p',
        name: 'Léa',
        isPrimary: true,
        avgAcidityPreference: 0.85,
        avgMineralityPreference: 0.85,
        avgOakPreference: 0.2,
        avgTanninPreference: 0.45,
        avgBodyPreference: 0.5,
        avgFreshFruitPreference: 0.6,
        axisObservations: observations,
        favoriteTypes: styles,
      );
  const toutObserve = {
    'tannin': 8, 'body': 8, 'oak': 8, 'ripeFruit': 8, 'spice': 8, 'freshFruit': 8, 'minerality': 8, 'acidity': 8,
  };

  double note(GuestProfile convive, MenuWine w) => MenuTableMatcherEngine.rankTop3WinesForTable(
        menuWines: [w],
        guests: [convive],
      ).single.guestScores[convive.id]!;

  group('l\'étiquette du palais', () {
    test('un palais deviné se résume par son style déclaré, pas par son radar', () {
      expect(GuestProfile.fromTasteProfile(palais(styles: ['Rouge'])).archetype, 'Amateur de Rouges');
      expect(GuestProfile.fromTasteProfile(palais(styles: ['Blanc'])).archetype, 'Amateur de Blancs');
      expect(GuestProfile.fromTasteProfile(palais()).archetype, 'Curieux & Éclectique');
      expect(GuestProfile.fromTasteProfile(palais(styles: ['Rouge', 'Blanc'])).archetype, 'Curieux & Éclectique');
    });

    test('un palais observé garde l\'étiquette de son radar', () {
      final observe = palais(observations: {'acidity': 4, 'minerality': 4}, styles: ['Rouge']);
      expect(GuestProfile.fromTasteProfile(observe).archetype, 'Adepte de Minéralité & Fraîcheur Droite');
    });

    test('les nouvelles étiquettes se lisent dans la langue de l\'écran', () {
      expect(GuestProfile.archetypeAffiche('Amateur de Rouges', false), 'Red wine lover');
      expect(GuestProfile.archetypeAffiche('Amateur de Rouges', true), 'Amateur de Rouges');
    });
  });

  group('la note de table', () {
    test('un axe deviné pèse un tiers, un axe observé presque plein, un axe déclaré plein', () {
      final devine = GuestProfile.fromTasteProfile(palais());
      final observe = GuestProfile.fromTasteProfile(palais(observations: toutObserve));
      const declare = GuestProfile(id: 'web', name: 'Paul');
      expect(devine.poidsDeLAxe('tannin'), closeTo(0.35, 0.001));
      expect(observe.poidsDeLAxe('tannin'), greaterThan(0.7));
      expect(declare.poidsDeLAxe('tannin'), 1.0);
    });

    test('un palais vif et minéral observé : le Chablis passe devant le Pauillac et le Meursault boisé', () {
      final observe = GuestProfile.fromTasteProfile(palais(observations: toutObserve));
      final classement = MenuTableMatcherEngine.rankTop3WinesForTable(
        menuWines: [pauillac, meursault, chablis],
        guests: [observe],
      );
      expect(classement.map((r) => r.menuWine.id), ['chablis', 'meursault', 'pauillac']);
    });

    test('deviné, le même palais tranche moins : les écarts se resserrent', () {
      final observe = GuestProfile.fromTasteProfile(palais(observations: toutObserve));
      final devine = GuestProfile.fromTasteProfile(palais());
      final ecartObserve = note(observe, chablis) - note(observe, pauillac);
      final ecartDevine = note(devine, chablis) - note(devine, pauillac);
      expect(ecartObserve, greaterThan(0));
      expect(ecartDevine, lessThan(ecartObserve));
    });

    test('la minéralité juge les blancs, pas les rouges ; le bois juge tout le monde', () {
      final observe = GuestProfile.fromTasteProfile(palais(observations: toutObserve));
      MenuWine avec(MenuWine w, {double? minerality, double? oak}) => MenuWine(
            id: w.id,
            name: w.name,
            producer: '',
            wineType: w.wineType,
            bottlePrice: 50,
            metrics: MenuWineRadarMetrics(
              tannins: w.metrics.tannins,
              acidity: w.metrics.acidity,
              body: w.metrics.body,
              fruit: w.metrics.fruit,
              oak: oak ?? w.metrics.oak,
              minerality: minerality ?? w.metrics.minerality,
            ),
          );
      expect(note(observe, avec(chablis, minerality: 4)), lessThan(note(observe, chablis)),
          reason: 'un blanc peu minéral plaît moins à qui aime la minéralité');
      expect(note(observe, avec(pauillac, minerality: 9)), note(observe, pauillac),
          reason: 'la minéralité d\'un rouge ne se juge pas');
      expect(note(observe, avec(pauillac, oak: 2)), greaterThan(note(observe, pauillac)),
          reason: 'qui aime peu le bois préfère un rouge peu boisé');
    });

    test('la confiance voyage avec le profil, au dixième près ; un invité web compte plein', () {
      final hote = GuestProfile.fromTasteProfile(palais(observations: {'acidity': 4}));
      final json = hote.toJson();
      expect((json['confiance'] as Map)['acidity'], 0.4);
      final relu = GuestProfile.fromJson('hote', json);
      expect(relu.poidsDeLAxe('acidity'), closeTo(0.35 + 0.65 * 0.4, 0.001));
      expect(relu.poidsDeLAxe('tannin'), closeTo(0.35, 0.001));

      final invite = GuestProfile.fromJson('web', {
        'name': 'Paul',
        'radar': {'tannin': 7, 'body': 6, 'acidity': 5, 'minerality': 5, 'oak': 3, 'fresh_fruit': 5},
      });
      expect(invite.poidsDeLAxe('tannin'), 1.0);
    });
  });
}
