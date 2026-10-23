import 'package:chatmelier/features/auth/domain/palais.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/opportunites_de_cave.dart';
import 'package:chatmelier/features/cellar/domain/styles_de_vin.dart';
import 'package:chatmelier/features/cellar/domain/vins_connus/vins_connus.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/sommelier/domain/angle_mort_de_la_cave.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les opportunités de la cave (23/10) : des styles très différents de ceux qu'elle a,
/// l'angle mort du palais, et le classement des bouteilles qui les fonde.
void main() {
  setUp(() => Langue.code = 'fr');
  const annee = 2026;
  var n = 0;

  Wine vin(String nom, String type, {String? de, String? appellation, String region = '', String pays = 'France', int? millesime, List<String> cepages = const []}) =>
      Wine(
        id: 'w${n++}',
        name: nom,
        producer: de,
        type: type,
        appellation: appellation,
        region: region,
        country: pays,
        vintage: millesime ?? 2021,
        grapes: [for (final c in cepages) Grape(name: c)],
      );

  Bottle bouteille(Wine w, {int quantite = 2}) =>
      Bottle(id: 'b_${w.id}', cellarId: 'cave', wineId: w.id, addedBy: 'moi', ownerId: 'moi', createdAt: DateTime(2026), quantity: quantite, wine: w);

  String style(Wine w) => StylesDeVin.de(w, annee: annee).first.id;

  group('chaque bouteille dans son style', () {
    test('les rouges : le lieu en Europe, le cépage ailleurs', () {
      expect(style(vin('Bandol', 'red', de: 'Domaine Tempier', appellation: 'Bandol')), 'rouge_garrigue');
      expect(style(vin('Chinon', 'red', de: 'Charles Joguet', appellation: 'Chinon')), 'rouge_loire');
      expect(style(vin('Château Pontet-Canet', 'red', appellation: 'Pauillac')), 'rouge_bordelais');
      expect(style(vin('Château Gazin', 'red', appellation: 'Pomerol')), 'rouge_merlot');
      expect(style(vin('Morgon', 'red', de: 'Marcel Lapierre', appellation: 'Morgon')), 'rouge_leger');
      expect(style(vin('Côte-Rôtie', 'red', de: 'Domaine Jamet')), 'rouge_syrah_nord');
      expect(style(vin('Cuvée Vieilles Vignes', 'red', de: 'Domaine Guinand', appellation: 'Languedoc')), 'rouge_mediterraneen',
          reason: 'l\'encépagement moyen d\'un Languedoc n\'en fait pas une syrah du Rhône nord');
      expect(style(vin('Barolo', 'red', de: 'G.D. Vajra', appellation: 'Barolo', pays: 'Italy')), 'rouge_nebbiolo');
      expect(style(vin('Chianti Classico', 'red', de: 'Fèlsina', appellation: 'Chianti Classico', pays: 'Italy')), 'rouge_toscan');
      expect(style(vin('Viña Ardanza', 'red', de: 'La Rioja Alta', appellation: 'Rioja', pays: 'Spain')), 'rouge_tempranillo');
      expect(style(vin('Masseto', 'red', appellation: 'Toscana IGT', pays: 'Italy')), 'rouge_merlot', reason: 'un supertoscan tout merlot');
      expect(style(vin('Pinot Noir', 'red', de: 'Kosta Browne', region: 'Sonoma Coast', pays: 'United States')), 'rouge_pinot');
      expect(style(vin('Bin 28 Kalimna Shiraz', 'red', de: 'Penfolds', pays: 'Australia')), 'rouge_puissant');
      expect(style(vin('Château Montus', 'red', appellation: 'Madiran')), 'rouge_tannat');
      expect(style(vin('Valpolicella Ripasso Superiore', 'red', pays: 'Italy')), 'rouge_amarone');
    });

    test('les blancs : vif, boisé, solaire, riesling, chenin, aromatique, voile', () {
      expect(style(vin('Chablis Premier Cru', 'white', appellation: 'Chablis Premier Cru')), 'blanc_vif');
      expect(style(vin('Meursault Les Charmes', 'white', appellation: 'Meursault')), 'blanc_boise');
      expect(style(vin('Condrieu', 'white', de: 'Domaine Georges Vernay')), 'blanc_rhone');
      expect(style(vin('Erdener Treppchen Kabinett', 'white', de: 'Markus Molitor', region: 'Mosel', pays: 'Germany')), 'blanc_riesling');
      expect(style(vin('Le Haut-Lieu Sec', 'white', de: 'Domaine Huet', appellation: 'Vouvray')), 'blanc_chenin');
      expect(style(vin('Gewurztraminer', 'white', de: 'Cave de Turckheim', appellation: 'Alsace')), 'blanc_aromatique');
      expect(style(vin('Sauvignon Blanc', 'white', de: 'Cloudy Bay', region: 'Marlborough', pays: 'New Zealand')), 'blanc_aromatique');
      expect(style(vin('Château-Chalon', 'white', de: 'Jean Macle')), 'blanc_voile');
      expect(style(vin('Tío Pepe Fino', 'fortified', de: 'González Byass', pays: 'Spain')), 'blanc_voile', reason: 'un fino est un vin de voile, pas un porto');
      expect(style(vin('Ribolla', 'orange', de: 'Gravner', pays: 'Italy')), 'vin_orange');
    });

    test('rosés, bulles, doux, mutés', () {
      expect(style(vin('Bandol Rosé', 'rosé', de: 'Domaine Tempier', appellation: 'Bandol')), 'rose_gastronomique');
      expect(style(vin('Whispering Angel', 'rosé', appellation: 'Côtes de Provence')), 'rose_pale');
      expect(style(vin('Château Turcaud Bordeaux Clairet', 'rosé', appellation: 'Bordeaux Clairet')), 'rose_gastronomique');
      expect(style(vin('Brut Réserve', 'sparkling', de: 'Pol Roger', appellation: 'Champagne')), 'bulles_tradition');
      expect(style(vin('Prosecco Superiore Rustico', 'sparkling', de: 'Nino Franco', pays: 'Italy')), 'bulles_fruitees');
      expect(style(vin('So Sauternes', 'dessert', de: 'Château Bastor-Lamontagne', appellation: 'Sauternes')), 'liquoreux');
      expect(style(vin('10 Year Old Tawny Port', 'fortified', de: "Taylor's", pays: 'Portugal')), 'vin_mute');
    });

    test('un rouge au bout de sa garde est aussi « patiné par l\'âge » ; un spiritueux n\'a pas de style', () {
      final vieux = StylesDeVin.de(vin('Château Pontet-Canet', 'red', appellation: 'Pauillac', millesime: 1982), annee: annee);
      expect([for (final s in vieux) s.id], ['rouge_bordelais', 'rouge_evolue']);
      // Un Rioja Reserva de vingt ans est encore au milieu de sa garde.
      final enGarde = StylesDeVin.de(vin('Viña Tondonia Reserva', 'red', de: 'López de Heredia', appellation: 'Rioja', pays: 'Spain', millesime: 2004), annee: annee);
      expect([for (final s in enGarde) s.id], ['rouge_tempranillo']);
      expect(StylesDeVin.de(vin('Pastis', 'spirit'), annee: annee), isEmpty);
    });
  });

  group('les styles eux-mêmes', () {
    test('chaque style a trois vins de la base pour le goûter', () {
      for (final s in StylesDeVin.tous) {
        expect(OpportunitesDeCave.exemplesDe(s), hasLength(3), reason: s.id);
      }
    });

    test('chacun a un nom et un portrait, en français comme en anglais', () {
      for (final code in ['fr', 'en']) {
        Langue.code = code;
        for (final s in StylesDeVin.tous) {
          expect(s.nom, isNot(s.id));
          expect(s.portrait, isNotEmpty, reason: s.id);
        }
      }
    });

    test('les appellations et cépages qu\'ils citent existent dans la base', () {
      final appellations = {for (final a in VinsConnus.appellations) a.nom};
      for (final s in StylesDeVin.tous) {
        for (final a in s.appellations) {
          expect(appellations, contains(a), reason: '${s.id} cite « $a »');
        }
      }
    });

    test('un vin jaune est plus loin d\'un Chablis qu\'un Muscadet', () {
      final vif = StylesDeVin.parId('blanc_vif');
      expect(vif.distance(StylesDeVin.parId('blanc_voile')), greaterThan(vif.distance(StylesDeVin.parId('blanc_chenin'))));
      expect(vif.distance(vif), 0);
    });
  });

  group('les opportunités', () {
    // Une cave du Sud : Bandol, Provence, Rhône, Bordeaux, Loire, Champagne.
    final caveDuSud = [
      bouteille(vin('Bandol', 'red', de: 'Domaine Tempier', appellation: 'Bandol')),
      bouteille(vin('Bandol Rosé', 'rosé', de: 'Domaine de Terrebrune', appellation: 'Bandol')),
      bouteille(vin('Whispering Angel', 'rosé', appellation: 'Côtes de Provence')),
      bouteille(vin('Gigondas', 'red', de: 'Domaine Santa Duc', appellation: 'Gigondas')),
      bouteille(vin('Crozes-Hermitage', 'red', de: 'Domaine Combier', appellation: 'Crozes-Hermitage')),
      bouteille(vin('Château Lynch-Bages', 'red', appellation: 'Pauillac')),
      bouteille(vin('Sancerre', 'white', de: 'Domaine Vacheron', appellation: 'Sancerre')),
      bouteille(vin('Brut Réserve', 'sparkling', de: 'Pol Roger', appellation: 'Champagne')),
    ];

    test('trois styles absents, très loin de la cave, qui ne se ressemblent pas, un seul singulier', () {
      final carte = OpportunitesDeCave.analyser(caveDuSud, annee: annee);
      expect(carte.opportunites, hasLength(3));
      final ids = [for (final o in carte.opportunites) o.style.id];
      expect(ids.toSet(), hasLength(3));
      for (final o in carte.opportunites) {
        expect(carte.bouteilles.containsKey(o.style.id), isFalse, reason: '${o.style.id} est déjà en cave');
        expect(o.plusProche, isNotNull);
        expect(o.exemples, hasLength(3));
      }
      expect(carte.opportunites.where((o) => o.style.singulier), hasLength(1));
      // « Le plus proche » se dit dans la même couleur quand la cave en a : un vin de voile
      // est rapproché d'un blanc, pas d'un rosé.
      for (final o in carte.opportunites) {
        final memeCouleur = carte.bouteilles.keys.map(StylesDeVin.parId).any((c) => c.groupe == o.style.groupe);
        if (memeCouleur) expect(o.plusProche!.groupe, o.style.groupe, reason: o.style.id);
      }
      // Le premier est le plus loin de la cave : aucun style absent n'en est plus éloigné.
      final premier = carte.opportunites.first;
      for (final s in StylesDeVin.tous.where((s) => !carte.bouteilles.containsKey(s.id))) {
        final d = [for (final c in StylesDeVin.tous.where((c) => carte.bouteilles.containsKey(c.id))) s.distance(c)]
            .reduce((a, b) => a < b ? a : b);
        expect(premier.distance, greaterThanOrEqualTo(d), reason: s.id);
      }
    });

    test('jamais un style qui heurte une aversion déclarée', () {
      const fuitLeSucreEtLesTanins = TasteProfile(id: 'moi', name: 'Moi', isPrimary: true, dislikedCharacteristics: ['Vins sucrés', 'Tanins durs']);
      final carte = OpportunitesDeCave.analyser(caveDuSud, profil: fuitLeSucreEtLesTanins, annee: annee);
      for (final o in carte.opportunites) {
        expect(o.style.axes['sweetness']! < 4.5, isTrue, reason: o.style.id);
        expect((o.style.axes['tannin'] ?? 0) < 6.5, isTrue, reason: o.style.id);
      }
    });

    test('l\'angle mort a sa proposition : un boisé des blancs inconnu fait proposer un blanc boisé', () {
      final observations = <String, Map<String, int>>{};
      final valeurs = <String, Map<String, double>>{};
      for (final (famille, axe) in AngleMortDeLaCave.axesJugeables) {
        if (famille == FamillesDeVins.blanc && axe == AxesDuPalais.boise) continue;
        (observations[famille] ??= {})[axe] = 12;
        (valeurs[famille] ??= {})[axe] = 0.5;
      }
      final palais = TasteProfile(id: 'moi', name: 'Moi', isPrimary: true, palais: valeurs, observationsPalais: observations);
      final carte = OpportunitesDeCave.analyser(caveDuSud, profil: palais, annee: annee);
      expect(carte.angleMort?.axe, AxesDuPalais.boise);
      final comble = carte.opportunites.where((o) => o.angleMort).single;
      expect(comble.style.id, 'blanc_boise');
      expect(comble.axe, AxesDuPalais.boise);
    });

    test('une cave vide : pas d\'opportunité inventée', () {
      final carte = OpportunitesDeCave.analyser(const [], annee: annee);
      expect(carte.opportunites, isEmpty);
      expect(carte.stylesPresents, 0);
    });
  });
}
