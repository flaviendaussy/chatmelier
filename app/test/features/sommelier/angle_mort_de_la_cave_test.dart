import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/cellar_gap_engine.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/sommelier/domain/angle_mort_de_la_cave.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'angle mort de la cave (V2.3 · J2) : ce qui lui manque pour mieux connaître un palais.
void main() {
  setUp(() => Langue.code = 'fr');
  const annee = 2026;

  Bottle bouteille(Wine w, {int quantite = 2}) => Bottle(
      id: 'b_${w.id}',
      cellarId: 'cave',
      wineId: w.id,
      addedBy: 'moi',
      ownerId: 'moi',
      createdAt: DateTime(2026),
      quantity: quantite,
      wine: w);

  Wine vin(String id, String nom, String type, String region, {String? appellation, List<String> cepages = const []}) =>
      Wine(
        id: id,
        name: nom,
        type: type,
        region: region,
        appellation: appellation,
        country: 'France',
        grapes: [for (final c in cepages) Grape(name: c)],
        vintage: 2021,
      );

  final chablis = vin('chablis', 'Chablis', 'white', 'Bourgogne', appellation: 'Chablis', cepages: ['Chardonnay']);
  final morgon = vin('morgon', 'Morgon', 'red', 'Beaujolais', appellation: 'Morgon');
  final meursault = vin('meursault', 'Meursault', 'white', 'Bourgogne', appellation: 'Meursault');

  // Un palais bien connu partout, sauf sur le boisé.
  const palais = TasteProfile(
    id: 'moi',
    name: 'Moi',
    isPrimary: true,
    axisObservations: {'tannin': 12, 'body': 12, 'acidity': 12, 'minerality': 12},
  );

  test('une cave sans blanc boisé et un boisé mal connu : la lacune passe en tête', () {
    final bouteilles = [bouteille(chablis), bouteille(morgon)];
    final analyse = AngleMortDeLaCave.completer(
      CellarGapEngine.analyzeCellar(bouteilles),
      profil: palais,
      bouteilles: bouteilles,
      annee: annee,
    );

    final premiere = analyse.gaps.first;
    expect(premiere.title, 'Pour mieux vous connaître');
    expect(premiere.diagnosis, contains('du boisé'));
    expect(premiere.sommelierAdvice, 'Ce qui vous manque pour mieux vous connaître : un blanc boisé. '
        'Un Meursault ou un Rioja blanc de garde vous le dirait.');
    expect(premiere.recommendedAppellations, contains('Meursault'));
    expect(analyse.shoppingWishlist.first, 'Meursault');
  });

  test('un Meursault en cave répond déjà : pas de lacune', () {
    final bouteilles = [bouteille(chablis), bouteille(morgon), bouteille(meursault)];
    expect(AngleMortDeLaCave.trouver(palais, bouteilles, annee: annee), isNull);
  });

  test('qui a dit fuir le bois ne se le voit pas conseiller', () {
    const fuitLeBois = TasteProfile(
      id: 'moi',
      name: 'Moi',
      isPrimary: true,
      dislikedCharacteristics: ['Trop boisé'],
      axisObservations: {'tannin': 12, 'body': 12, 'acidity': 12, 'minerality': 12},
    );
    expect(AngleMortDeLaCave.trouver(fuitLeBois, [bouteille(chablis)], annee: annee), isNull);
  });

  test('l\'axe le moins connu d\'abord ; un axe observé ne motive rien', () {
    const palaisNeuf = TasteProfile(
      id: 'moi',
      name: 'Moi',
      isPrimary: true,
      axisObservations: {'oak': 1, 'minerality': 0, 'tannin': 12, 'body': 12, 'acidity': 12},
    );
    // Ni bois ni minéralité en cave : la minéralité, jamais observée, passe avant le bois.
    expect(AngleMortDeLaCave.trouver(palaisNeuf, [bouteille(morgon)], annee: annee)?.axe, 'minerality');
    // Un Chablis tranche la minéralité : reste le bois.
    expect(AngleMortDeLaCave.trouver(palaisNeuf, [bouteille(morgon), bouteille(chablis)], annee: annee)?.axe, 'oak');
  });

  test('une bouteille finie ne compte plus', () {
    final bouteilles = [bouteille(chablis), bouteille(meursault, quantite: 0)];
    expect(AngleMortDeLaCave.trouver(palais, bouteilles, annee: annee)?.axe, 'oak');
  });
}
