import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/sommelier/domain/carte_des_terroirs.dart';
import 'package:chatmelier/features/sommelier/domain/taste_frontier_engine.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les terroirs d'un palais (V2.3 · J3) : goûtés, en cave, à explorer.
void main() {
  setUp(() => Langue.code = 'fr');

  VinSitue vin(String nom, {String? region, String? appellation, String pays = 'France'}) =>
      (pays: pays, region: region, appellation: appellation, nom: nom);

  // Un palais bien connu partout, sauf sur le boisé.
  const palais = TasteProfile(
    id: 'moi',
    name: 'Moi',
    isPrimary: true,
    axisObservations: {'tannin': 12, 'body': 12, 'acidity': 12, 'minerality': 12},
  );

  test('goûtés, en cave sans avoir été goûtés, et ce qui reste à découvrir', () {
    final carte = CarteDesTerroirs.dresser(
      goutes: [
        vin('Chablis 1er Cru', appellation: 'Chablis', region: 'Bourgogne'),
        vin('Chambolle-Musigny', region: 'Bourgogne'), // l'appellation est dans le nom
        vin('Gevrey-Chambertin', region: 'Bourgogne'), // même région que le Chambolle
        vin('Cuvée maison', region: 'Autre'), // rien à situer
        vin('Le Rouge du Patron', appellation: 'Vin de France'), // une catégorie, pas un terroir
        vin('Les Vignes d\'à Côté', appellation: 'Vin de France', region: 'Bourgogne'), // la région parle
      ],
      enCave: [
        vin('Cornas', appellation: 'Cornas', region: 'Vallée du Rhône'),
        vin('Petit Chablis', appellation: 'Chablis'), // déjà goûté
      ],
      profil: palais,
    );

    expect(carte.goutes.map((t) => t.libelle), ['Chablis', 'Chambolle-Musigny', 'Bourgogne']);
    expect(carte.enCave.map((t) => t.libelle), ['Cornas']);
    expect(carte.explorees, 4, reason: 'Chablis, Côte de Nuits, Bourgogne régional, Rhône nord');
    expect(carte.total, greaterThan(90));
  });

  test('la prochaine région éclaire l\'axe le moins connu, et jamais une région déjà vue', () {
    final neuf = CarteDesTerroirs.dresser(goutes: const [], enCave: const [], profil: palais);
    expect(neuf.prochaine?.nom, 'Rioja');
    expect(neuf.prochaine?.phrase,
        'Prochaine région à explorer : Rioja. Ses vins vous diraient ce que vous pensez du boisé.');

    final apresUnRioja = CarteDesTerroirs.dresser(
      goutes: [vin('Viña Tondonia', appellation: 'Rioja', region: 'Rioja', pays: 'Espagne')],
      enCave: const [],
      profil: palais,
    );
    expect(apresUnRioja.prochaine?.nom, 'Meursault');
  });

  test('sans palais, ou quand tout est connu, pas de suggestion', () {
    expect(CarteDesTerroirs.dresser(goutes: const [], enCave: const []).prochaine, isNull);
    const toutConnu = TasteProfile(
      id: 'moi',
      name: 'Moi',
      axisObservations: {'tannin': 12, 'body': 12, 'acidity': 12, 'minerality': 12, 'oak': 12},
    );
    expect(CarteDesTerroirs.dresser(goutes: const [], enCave: const [], profil: toutConnu).prochaine, isNull);
  });

  test('le nom de la région suit la langue de l\'écran', () {
    const moselle = ProchaineRegion('Moselle', 'acidity');
    Langue.code = 'en';
    expect(moselle.phrase, startsWith('Next region to explore: Mosel.'));
  });

  test('« mais est-ce que j\'ai un Meursault ?? » : une bouteille de la cave passe avant (13/10)', () {
    // Un Crozes boisé jamais goûté attend en cave : il éclaire le boisé, l'axe inconnu.
    final crozes = (
      lieu: vin('Crozes-Hermitage', appellation: 'Crozes-Hermitage', region: 'Vallée du Rhône'),
      nomDuVin: 'Domaine Combier Clos des Grives 2019',
      profil: const ProfilDeVin({'oak': 8.0, 'tannin': 6.0, 'body': 7.0}),
    );
    final carte = CarteDesTerroirs.dresser(
      goutes: const [],
      enCave: [crozes.lieu],
      profil: palais,
      aOuvrir: [crozes],
    );
    expect(carte.prochaine?.nom, 'Crozes-Hermitage');
    expect(carte.prochaine?.vinDeLaCave, 'Domaine Combier Clos des Grives 2019');
    expect(carte.prochaine?.phrase, contains('déjà dans votre cave'));
    expect(carte.prochaine?.phrase, contains('Ouvrez votre Domaine Combier Clos des Grives 2019'));

    // Déjà goûté, ce terroir n'est plus « à explorer » : la région hors cave revient.
    final dejaGoute = CarteDesTerroirs.dresser(
      goutes: [crozes.lieu],
      enCave: [crozes.lieu],
      profil: palais,
      aOuvrir: [crozes],
    );
    expect(dejaGoute.prochaine?.vinDeLaCave, isNull);
    expect(dejaGoute.prochaine?.nom, 'Rioja');
  });
}
