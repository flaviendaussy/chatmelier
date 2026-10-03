import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/menu_scan/domain/fin_de_soiree.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_table_matcher_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un palais deviné le dit (V2.3 · K5). Relevé le 02/10 : un palais connu à 6 %, amateur de
/// rouges, lisait 82 % d'accord sur un rouge, plus que le même palais bien connu (79 %).
/// Moins on en savait, plus l'accord avait l'air sûr.
void main() {
  setUp(() => Langue.code = 'fr');

  MenuWine vin(String id, String nom, String type, MenuWineRadarMetrics m) =>
      MenuWine(id: id, name: nom, producer: '', wineType: type, metrics: m, bottlePrice: 50);

  final chablis = vin('chablis', 'Chablis 1er Cru', 'White',
      const MenuWineRadarMetrics(acidity: 9, body: 5.5, fruit: 5, oak: 1.5, minerality: 9.5));
  final crozes = vin('crozes', 'Crozes-Hermitage', 'Red',
      const MenuWineRadarMetrics(tannins: 5, acidity: 7, body: 5.5, fruit: 6.5, oak: 2.5, minerality: 5));
  // Tout ce que ce palais fuit : tanins massifs, peu d'acidité, beaucoup de bois.
  final amarone = vin('amarone', 'Amarone della Valpolicella', 'Red',
      const MenuWineRadarMetrics(tannins: 9.5, acidity: 4.5, body: 9.5, fruit: 8.5, oak: 9, minerality: 3));

  // Un palais vif, frais, peu boisé, déclaré amateur de rouges.
  TasteProfile palais({Map<String, int> observations = const {}}) => TasteProfile(
        id: 'moi',
        name: 'Moi',
        isPrimary: true,
        avgAcidityPreference: 0.7,
        avgMineralityPreference: 0.6,
        avgOakPreference: 0.25,
        avgTanninPreference: 0.5,
        avgBodyPreference: 0.55,
        avgFreshFruitPreference: 0.65,
        axisObservations: observations,
        favoriteTypes: const ['Rouge'],
      );
  const bienConnu = {
    'tannin': 40, 'body': 40, 'oak': 40, 'ripeFruit': 40, 'spice': 40, 'freshFruit': 40, 'minerality': 40, 'acidity': 40,
  };

  double note(GuestProfile convive, MenuWine w) =>
      MenuTableMatcherEngine.classerLaCarte(menuWines: [w], guests: [convive]).single.guestScores[convive.id]!;

  group('la note', () {
    test('ne rien savoir ne flatte plus : le vin qui lui va le mieux ne monte pas au-dessus du palais connu', () {
      final devine = GuestProfile.fromTasteProfile(palais());
      final connu = GuestProfile.fromTasteProfile(palais(observations: bienConnu));
      expect(note(devine, crozes), lessThan(note(connu, crozes)));
    });

    test('deviné, un vin qui ne lui va pas reste prudent : ni condamné ni recommandé', () {
      final devine = GuestProfile.fromTasteProfile(palais());
      final connu = GuestProfile.fromTasteProfile(palais(observations: bienConnu));
      expect(note(devine, amarone), greaterThan(note(connu, amarone)));
      expect(note(devine, crozes) - note(devine, amarone), lessThan(note(connu, crozes) - note(connu, amarone)));
    });

    test('un palais déclaré (page invité) ne change pas : l\'écart reste l\'écart', () {
      const declare = GuestProfile(id: 'web', name: 'Paul');
      expect(declare.ecartSurLAxe('tannin', 3), 3);
      expect(declare.ecartSurLAxe('tannin', -3), 3);
      expect(declare.ecartCarreSurLAxe('oak', 3), 9);
    });

    test('deviné, l\'écart d\'un axe tient un tiers de l\'écart et deux tiers de l\'ignorance', () {
      final devine = GuestProfile.fromTasteProfile(palais());
      expect(devine.ecartSurLAxe('tannin', 0), closeTo(0.65 * GuestProfile.ecartDIgnorance, 1e-9));
      expect(devine.ecartSurLAxe('tannin', 4), closeTo(0.35 * 4 + 0.65 * GuestProfile.ecartDIgnorance, 1e-9));
      expect(devine.ecartCarreSurLAxe('tannin', 4), closeTo(0.35 * 16 + 0.65 * 4, 1e-9));
    });
  });

  group('l\'écran', () {
    test('connu à 5 % : deviné ; bien connu, ou déclaré : pas deviné', () {
      final peu = GuestProfile.fromTasteProfile(palais(observations: {'acidity': 3}));
      expect((peu.connaissance! * 100).round(), 5);
      expect(peu.palaisDevine, isTrue);
      expect(GuestProfile.fromTasteProfile(palais(observations: bienConnu)).palaisDevine, isFalse);
      const declare = GuestProfile(id: 'web', name: 'Paul');
      expect(declare.connaissance, isNull);
      expect(declare.palaisDevine, isFalse);
    });

    test('un accord deviné s\'affiche « ≈ »', () {
      final devine = GuestProfile.fromTasteProfile(palais());
      const declare = GuestProfile(id: 'web', name: 'Paul');
      expect(PalaisDevine.pourcentage(devine, 73.4), '≈73%');
      expect(PalaisDevine.pourcentage(declare, 73.4), '73%');
    });

    test('la ligne qui l\'explique parle au lecteur, nomme les autres, et se tait sinon', () {
      final moi = GuestProfile.fromTasteProfile(palais(observations: {'acidity': 3}));
      final lea = GuestProfile.fromTasteProfile(palais()).copie(id: 'lea', name: 'Léa');
      const paul = GuestProfile(id: 'web', name: 'Paul');

      expect(PalaisDevine.legende([moi, paul], fr: true, idLecteur: 'moi'),
          '≈ : votre palais est encore deviné (connu à 5 %). Vos accords restent prudents et se précisent à chaque vin noté.');
      expect(PalaisDevine.legende([moi, paul], fr: true, idLecteur: 'web'),
          '≈ : palais encore deviné, Moi (connu à 5 %). Ses accords restent prudents et se précisent à chaque vin noté.');
      expect(PalaisDevine.legende([moi, lea, paul], fr: false, idLecteur: 'web'),
          '≈: palates still guessed, Moi (5% known), Léa (0% known). Their matches stay cautious and sharpen with every wine rated.');
      expect(PalaisDevine.legende([paul], fr: true), isNull);
      expect(PalaisDevine.legende([moi.copie(neBoitPas: true), paul], fr: true), isNull,
          reason: 'qui ne boit pas ce soir n\'a pas d\'accord à nuancer');
    });

    test('la page invité reçoit les palais devinés avec ce qu\'on en sait', () {
      final moi = GuestProfile.fromTasteProfile(palais(observations: {'acidity': 3}));
      const paul = GuestProfile(id: 'web', name: 'Paul');
      final podium = MenuTableMatcherEngine.rankTop3WinesForTable(menuWines: [crozes, chablis], guests: [moi, paul]);
      final r = ResultatDeTable.publier(restaurant: 'Le Petit Zinc', langue: 'fr', convives: [moi, paul], podium: podium);
      expect(r['convives'], [
        {'nom': 'Moi', 'devine': true, 'connu': 5},
        {'nom': 'Paul'},
      ]);
    });
  });
}
