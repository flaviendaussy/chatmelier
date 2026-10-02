import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/sommelier/domain/carte_des_terroirs.dart';
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
      ],
      enCave: [
        vin('Cornas', appellation: 'Cornas', region: 'Vallée du Rhône'),
        vin('Petit Chablis', appellation: 'Chablis'), // déjà goûté
      ],
      profil: palais,
    );

    expect(carte.goutes.map((t) => t.libelle), ['Chablis', 'Chambolle-Musigny']);
    expect(carte.enCave.map((t) => t.libelle), ['Cornas']);
    expect(carte.explorees, 3, reason: 'Chablis, Côte de Nuits, Rhône nord');
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
}
