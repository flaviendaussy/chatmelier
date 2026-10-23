import 'package:chatmelier/features/cellar/domain/vins_connus/vins_connus.dart';
import 'package:flutter_test/flutter_test.dart';

/// La base des vins connus (23/10) : les appellations et leurs vins, les cépages qu'elle
/// leur prête, et ceux qu'elle ne leur prête pas.
///
/// Les cas viennent du catalogue de production du 23/10 : 225 fiches sur 294 n'avaient pas
/// de cépages.
List<String>? cepages(String nom, {String? de, String? appellation, String? region, String? pays, String? type}) =>
    VinsConnus.trouver(nom: nom, producteur: de, appellation: appellation, region: region, pays: pays, type: type)?.cepages;

void main() {
  group('la base elle-même', () {
    test('des centaines d\'appellations et plus de mille vins', () {
      expect(VinsConnus.appellations.length, greaterThan(200));
      expect(VinsConnus.nombreDeVins, greaterThan(1200));
    });

    test('aucun vin en double dans son appellation (même nom, même couleur, même domaine)', () {
      for (final a in VinsConnus.appellations) {
        final vus = <String>{};
        for (final v in a.vins) {
          final cle = '${VinsConnus.normaliser(v.nom)}|${v.couleur}|${VinsConnus.normaliser(v.de)}';
          expect(vus.add(cle), isTrue, reason: '« ${v.nom} » deux fois dans ${a.nom}');
        }
      }
    });

    test('chaque vin d\'une appellation précise a des cépages, les siens ou les siens par défaut', () {
      for (final a in VinsConnus.appellations.where((a) => !a.generique)) {
        for (final v in a.vins) {
          expect(VinTrouve(v, a).cepages, isNotEmpty, reason: '${v.nom} (${a.nom}, ${v.couleur})');
        }
      }
    });

    test('aucun nom trop court pour être reconnu sans son domaine', () {
      for (final a in VinsConnus.appellations) {
        for (final v in a.vins) {
          if (v.de != null) continue;
          for (final n in [v.nom, ...v.alias]) {
            expect(VinsConnus.normaliser(n).length, greaterThanOrEqualTo(3), reason: '« $n » (${a.nom})');
          }
        }
      }
    });
  });

  group('les vins du catalogue sans cépages', () {
    test('les grands bordeaux : leur assemblage, le cabernet en tête au Médoc', () {
      expect(cepages('Château Margaux Premier Grand Cru', de: 'Château Margaux', type: 'red')!.first, Cep.cs);
      expect(cepages('Château Pontet-Canet', de: 'Château Pontet-Canet', appellation: 'Pauillac', type: 'red')!.first, Cep.cs);
      expect(cepages('Pétrus', type: 'red'), [Cep.merlot]);
      expect(cepages('Château Cheval Blanc', appellation: 'Saint-Émilion Grand Cru', type: 'red')!.first, Cep.cf);
      expect(cepages('Château Chasse-Spleen', appellation: 'Moulis-en-Médoc', type: 'red'), contains(Cep.cs));
    });

    test('un château inconnu prend l\'encépagement de son appellation, pour sa couleur', () {
      expect(VinsConnus.cepagesPour(nom: 'Château Turcaud Bordeaux Clairet', appellation: 'Bordeaux Clairet', type: 'rosé'),
          [Cep.merlot, Cep.cs, Cep.cf]);
      expect(VinsConnus.cepagesPour(nom: 'Chablis Grand Cru', appellation: 'Chablis Grand Cru', type: 'white'), [Cep.ch]);
      expect(VinsConnus.cepagesPour(nom: 'Inconnu', appellation: 'Sauternes', type: 'dessert').first, Cep.semillon);
    });

    test('ailleurs dans le monde : Rioja, Marlborough, Barossa, Salta, Maipo', () {
      expect(cepages('Gran Reserva 904', de: 'La Rioja Alta S.A.', appellation: 'Rioja DOCa', type: 'red'), [Cep.tempranillo, Cep.graciano]);
      expect(cepages('Sauvignon Blanc', de: 'Cloudy Bay', region: 'Marlborough', pays: 'New Zealand', type: 'white'), [Cep.sb]);
      expect(cepages('Koonunga Hill Shiraz Cabernet', de: 'Penfolds', pays: 'Australia', type: 'red'), [Cep.shiraz, Cep.cs]);
      expect(cepages('Finca Notables Tannat', de: 'El Esteco', region: 'Salta', pays: 'Argentina', type: 'red'), [Cep.tannat]);
      expect(cepages('Ungrafted Cinsault', de: 'De Martino', region: 'Maipo Valley', pays: 'Chile', type: 'red'), [Cep.cinsault]);
      expect(cepages('Erdener Treppchen Kabinett', de: 'Markus Molitor', region: 'Mosel', pays: 'Germany', type: 'white'), [Cep.riesling]);
      expect(cepages('Rosy', de: 'Pio Cesare', region: 'Piedmont', pays: 'Italy', type: 'rose'), [Cep.nebbiolo]);
    });

    test('Bandol : le mourvèdre de Tempier, en rouge comme en rosé', () {
      expect(cepages('Bandol Pour Lulu', de: 'Domaine Tempier', region: 'Bandol', type: 'red')!.first, Cep.mourvedre);
      expect(cepages('Bandol', de: 'Domaine Tempier', type: 'rosé')!.first, Cep.mourvedre);
      expect(VinsConnus.trouver(nom: 'Bandol', producteur: 'Domaine Tempier', type: 'rosé')!.vin.couleur, 'rose');
    });

    test('les champagnes : la signature de chaque maison', () {
      expect(cepages('Pol Roger Réserve Brut', de: 'Pol Roger', type: 'sparkling'), [Cep.pn, Cep.meunier, Cep.ch]);
      expect(cepages('Comtes de Champagne', de: 'Taittinger', type: 'sparkling'), [Cep.ch]);
      expect(cepages('Cristal', de: 'Louis Roederer', type: 'sparkling'), [Cep.pn, Cep.ch]);
      expect(cepages('Moët et Chandon Impérial Brut', type: 'Champagne'), [Cep.pn, Cep.meunier, Cep.ch]);
    });

    test('le porto, le xérès, Musar en rouge et en blanc', () {
      expect(cepages('Velhotes 10 Anos Tawny Porto', de: 'Real Companhia Velha', type: 'fortified')!.first, Cep.tourigaNacional);
      expect(cepages('Tío Pepe Fino', de: 'González Byass', type: 'fortified'), [Cep.palomino]);
      expect(cepages('Château Musar', type: 'red'), [Cep.cs, Cep.cinsault, Cep.carignan]);
      expect(cepages('Château Musar', type: 'white'), [Cep.obaideh, Cep.merwah]);
    });
  });

  group('ce que la base ne confond pas', () {
    test('Latour-Martillac n\'est pas Latour, Menetou-Salon n\'est pas Salon', () {
      expect(VinsConnus.trouver(nom: 'Château Latour-Martillac', appellation: 'Pessac-Léognan', type: 'red')?.vin.nom,
          'Château Latour-Martillac');
      expect(VinsConnus.trouver(nom: 'Menetou-Salon Morogues', type: 'white')?.vin.nom, isNot(contains('Salon Le Mesnil')));
      expect(VinsConnus.trouver(nom: 'Cos Labory', type: 'red')?.vin.nom, 'Château Cos Labory', reason: 'pas le COS de Vittoria');
    });

    test('la couleur écarte : le Château Margaux blanc n\'est pas le grand vin rouge', () {
      expect(VinsConnus.trouver(nom: 'Château Margaux', type: 'white'), isNull);
      expect(VinsConnus.trouver(nom: 'Pavillon Blanc du Château Margaux', type: 'white')!.cepages, [Cep.sb]);
      expect(VinsConnus.trouver(nom: "Château d'Yquem", type: 'white')!.vin.couleur, 'sweet',
          reason: 'un sauternes saisi « blanc » reste un sauternes');
    });

    test('le pays écarte : un « Chablis » de Californie n\'est pas un chablis', () {
      expect(VinsConnus.appellation(appellation: 'Chablis', pays: 'United States'), isNull);
      expect(VinsConnus.appellation(appellation: 'Chablis', pays: 'France')!.nom, 'Chablis');
    });

    test('le plus précis l\'emporte : Lussac avant Saint-Émilion, Petit Chablis avant Chablis', () {
      expect(VinsConnus.appellation(appellation: 'Lussac-Saint-Émilion')!.nom, 'Satellites de Saint-Émilion');
      expect(VinsConnus.appellation(appellation: 'Petit Chablis')!.nom, 'Petit Chablis');
      expect(VinsConnus.appellation(appellation: 'Muscat de Beaumes-de-Venise')!.nom, 'Muscat de Beaumes-de-Venise');
    });

    test('ni spiritueux, ni liqueur', () {
      expect(VinsConnus.trouver(nom: 'Bou Barroeta Pisco', type: 'spirit'), isNull);
      expect(VinsConnus.cepagesPour(nom: 'Limoncello', type: 'liqueur'), isEmpty);
    });

    test('une maison de négoce rangée sous « Bourgogne » prend l\'appellation de sa fiche', () {
      final jadot = VinsConnus.trouver(nom: 'Beaujolais-Villages', producteur: 'Louis Jadot', appellation: 'Beaujolais-Villages', type: 'red')!;
      expect(jadot.cepages, [Cep.gamay]);
      expect(jadot.cepagesDeLaCuvee, isFalse);
    });
  });

  // Seul, il en faut une centaine de millisecondes ; la limite laisse de la marge à une
  // suite qui tourne en parallèle, et attrape un retour au parcours de toute la base.
  test('assez rapide pour une cave entière : trois cents vins en moins d\'une seconde', () {
    VinsConnus.trouver(nom: 'Château Margaux', type: 'red');
    final chrono = Stopwatch()..start();
    for (var i = 0; i < 300; i++) {
      VinsConnus.trouver(nom: 'Château numéro $i Cuvée Prestige', producteur: 'Domaine du Clos $i', appellation: 'Bordeaux Supérieur', type: 'red');
    }
    expect(chrono.elapsedMilliseconds, lessThan(1000));
  });
}
