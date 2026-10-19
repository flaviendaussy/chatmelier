import 'package:chatmelier/features/auth/domain/palais.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/cellar_gap_engine.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/sommelier/domain/angle_mort_de_la_cave.dart';
import 'package:chatmelier/features/sommelier/domain/profil_du_vin.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'angle mort de la cave (V2.3 · J2) : ce qui lui manque pour mieux connaître un palais.
/// V2.6 : chaque axe dans sa famille — le boisé des blancs, les tanins des rouges.
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

  /// Un palais dont chaque axe jugeable est observé douze fois, sauf ceux de [sauf]
  /// (famille, axe) qui le sont [n] fois.
  TasteProfile palaisConnu({Set<(String, String)> sauf = const {}, int n = 0, List<String> aversions = const []}) {
    final observations = <String, Map<String, int>>{};
    final valeurs = <String, Map<String, double>>{};
    for (final (famille, axe) in AngleMortDeLaCave.axesJugeables) {
      final k = sauf.contains((famille, axe)) ? n : 12;
      if (k == 0) continue;
      (observations[famille] ??= {})[axe] = k;
      (valeurs[famille] ??= {})[axe] = 0.5;
    }
    return TasteProfile(
      id: 'moi',
      name: 'Moi',
      isPrimary: true,
      dislikedCharacteristics: aversions,
      palais: valeurs,
      observationsPalais: observations,
    );
  }

  // Un palais bien connu partout, sauf sur le boisé des blancs.
  final palais = palaisConnu(sauf: {(FamillesDeVins.blanc, AxesDuPalais.boise)});

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
    expect(premiere.diagnosis, contains('du boisé sur un blanc'));
    expect(premiere.sommelierAdvice, 'Ce qui vous manque pour mieux vous connaître : un blanc boisé. '
        'Un Meursault ou un Rioja blanc de garde vous le dirait.');
    expect(premiere.recommendedAppellations, contains('Meursault'));
    expect(analyse.shoppingWishlist.first, 'Meursault');
  });

  test('un Meursault en cave répond déjà : pas de lacune', () {
    final bouteilles = [bouteille(chablis), bouteille(morgon), bouteille(meursault)];
    expect(AngleMortDeLaCave.trouver(palais, bouteilles, annee: annee), isNull);
  });

  test('un rouge boisé ne dit rien du boisé des blancs', () {
    final pauillac = vin('pauillac', 'Pauillac', 'red', 'Bordeaux',
        appellation: 'Pauillac', cepages: ['Cabernet Sauvignon', 'Merlot']);
    expect(ProfilDuVin.deLaCave(pauillac, le: DateTime(annee, 6)).sur10(AxesDuPalais.boise), greaterThanOrEqualTo(6.0),
        reason: 'le Pauillac montre bien le bois');
    final angle = AngleMortDeLaCave.trouver(palais, [bouteille(chablis), bouteille(pauillac)], annee: annee);
    expect(angle?.axe, AxesDuPalais.boise);
    expect(angle?.famille, FamillesDeVins.blanc);
  });

  test('qui a dit fuir le bois ne se le voit pas conseiller', () {
    final fuitLeBois = palaisConnu(sauf: {(FamillesDeVins.blanc, AxesDuPalais.boise)}, aversions: ['Trop boisé']);
    expect(AngleMortDeLaCave.trouver(fuitLeBois, [bouteille(chablis)], annee: annee), isNull);
  });

  test('l\'axe le moins connu d\'abord ; un axe observé ne motive rien', () {
    // La douceur des blancs jamais observée, leur boisé une fois.
    final palaisNeuf = palaisConnu(sauf: {(FamillesDeVins.blanc, AxesDuPalais.douceur)})
        .avecAxeDuPalais(FamillesDeVins.blanc, AxesDuPalais.boise, 0.5, observations: 1);
    // Ni douceur ni bois en cave : la douceur, jamais observée, passe avant le bois.
    final seul = AngleMortDeLaCave.trouver(palaisNeuf, [bouteille(morgon)], annee: annee);
    expect((seul?.famille, seul?.axe), (FamillesDeVins.blanc, AxesDuPalais.douceur));
    expect(seul?.conseil.style, 'un blanc tendre ou doux');
    // Un gewurztraminer de vendanges tardives tranche la douceur : reste le bois.
    final vt = vin('vt', 'Gewurztraminer Vendanges Tardives', 'white', 'Alsace',
        appellation: 'Alsace', cepages: ['Gewurztraminer']);
    expect(AngleMortDeLaCave.trouver(palaisNeuf, [bouteille(morgon), bouteille(vt)], annee: annee)?.axe, AxesDuPalais.boise);
  });

  test('une bouteille finie ne compte plus', () {
    final bouteilles = [bouteille(chablis), bouteille(meursault, quantite: 0)];
    expect(AngleMortDeLaCave.trouver(palais, bouteilles, annee: annee)?.axe, AxesDuPalais.boise);
  });

  test('un palais d\'avant, appris toutes couleurs confondues, garde ce qu\'il sait', () {
    // Le palais de la V2.5 : douze observations par axe, sans famille. Les rouges et les
    // blancs en héritent chacun la moitié — assez pour ne rien redemander.
    const ancien = TasteProfile(
      id: 'moi',
      name: 'Moi',
      isPrimary: true,
      avgTanninPreference: 0.6,
      avgBodyPreference: 0.5,
      avgAcidityPreference: 0.6,
      avgOakPreference: 0.3,
      axisObservations: {'tannin': 12, 'body': 12, 'acidity': 12, 'oak': 12},
    );
    final restent = AngleMortDeLaCave.axesAApprendre(ancien);
    expect(restent, isNot(contains((FamillesDeVins.rouge, AxesDuPalais.tanins))));
    expect(restent, isNot(contains((FamillesDeVins.blanc, AxesDuPalais.boise))));
    // Ce que le palais d'avant ne mesurait pas reste à apprendre.
    expect(restent, contains((FamillesDeVins.blanc, AxesDuPalais.douceur)));
    expect(restent, contains((FamillesDeVins.rouge, AxesDuPalais.evolution)));
  });
}
