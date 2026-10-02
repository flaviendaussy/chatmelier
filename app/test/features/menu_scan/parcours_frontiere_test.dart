import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/menu_scan/domain/cellar_bridge.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_flight_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/presentation/menu_flight_sheet.dart';
import 'package:chatmelier/features/sommelier/domain/taste_frontier_engine.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le parcours qui vous apprend quelque chose (V2.3 · J4) : un verre aimé, les plus
/// instructifs, une valeur sûre pour finir.
void main() {
  setUp(() => Langue.code = 'fr');

  MenuWine verre(String id, String nom, String type, double plaisir, MenuWineRadarMetrics m, {double prix = 9}) => MenuWine(
        id: id,
        name: nom,
        producer: '',
        wineType: type,
        userMatchScore: plaisir,
        metrics: m,
        glassPrices: [MenuWineGlassPrice(format: '125ml', price: prix)],
      );

  // L'ardoise d'un bar à vins : chaque vin y est servi au verre.
  final ardoise = [
    verre('morgon', 'Morgon', 'Red', 88, const MenuWineRadarMetrics(tannins: 4, acidity: 6, body: 5, fruit: 8, oak: 2, minerality: 4)),
    verre('meursault', 'Meursault', 'White', 72, const MenuWineRadarMetrics(tannins: 0, acidity: 5.5, body: 7.5, fruit: 6, oak: 8.5, minerality: 5)),
    verre('chablis', 'Chablis', 'White', 70, const MenuWineRadarMetrics(tannins: 0, acidity: 8.5, body: 4, fruit: 5, oak: 1, minerality: 9)),
    verre('madiran', 'Madiran', 'Red', 66, const MenuWineRadarMetrics(tannins: 9, acidity: 6, body: 8, fruit: 6, oak: 6, minerality: 4)),
    verre('cdr', 'Côtes-du-Rhône', 'Red', 80, const MenuWineRadarMetrics(tannins: 5, acidity: 5, body: 6, fruit: 7, oak: 3, minerality: 4)),
    verre('muscadet', 'Muscadet', 'White', 64, const MenuWineRadarMetrics(tannins: 0, acidity: 8, body: 3.5, fruit: 5, oak: 1, minerality: 7.5)),
  ];
  ScannedMenu menuDe(List<MenuWine> vins) =>
      ScannedMenu(id: 'ardoise', restaurantName: 'Le Comptoir', scannedAt: DateTime(2026, 10, 2), pagePhotoPaths: const [], wines: vins);
  final carte = menuDe(ardoise);

  // Un palais qui ne sait rien du boisé ni de la minéralité ; les tanins, il les connaît.
  const palais = TasteProfile(
    id: 'moi',
    name: 'Moi',
    isPrimary: true,
    axisObservations: {'tannin': 12, 'body': 12, 'acidity': 12},
  );

  test('trois verres : un verre aimé, le plus instructif, une valeur sûre — servis du plus léger au plus intense', () {
    final p = MenuFlightEngine.buildFrontierFlight(menu: carte, palais: palais);
    final parRole = {for (final s in p.steps) s.sommelierRole: s.wine.name};
    expect(parRole['Un style que vous aimez'], 'Morgon', reason: 'le style que la personne aime le plus');
    expect(parRole['Une valeur sûre'], 'Côtes-du-Rhône');
    final instructif = p.steps.singleWhere((s) => s.sommelierRole.startsWith('Pour savoir ce que vous pensez '));
    expect(['Meursault', 'Chablis'], contains(instructif.wine.name), reason: 'le boisé ou la minéralité, inconnus');
    // Le blanc d'abord : un rouge juste avant fausserait la lecture de sa minéralité.
    expect(p.steps.first.wine.name, instructif.wine.name);
    expect(p.steps.map((s) => s.wine.name).skip(1), ['Morgon', 'Côtes-du-Rhône'], reason: 'du plus souple au plus charpenté');
    expect(p.title, contains('Pour mieux vous connaître'));
  });

  test('cinq verres : chaque verre du milieu apprend quelque chose de différent', () {
    // Trois axes inconnus cette fois : le boisé, la minéralité et les tanins.
    const neuf = TasteProfile(id: 'moi', name: 'Moi', isPrimary: true, axisObservations: {'body': 12, 'acidity': 12});
    final p = MenuFlightEngine.buildFrontierFlight(menu: carte, palais: neuf, format: FlightFormat.fiveGlasses);
    expect(p.steps, hasLength(5));
    final milieu = [
      for (final s in p.steps)
        if (s.sommelierRole.startsWith('Pour savoir ce que vous pensez ')) s.sommelierRole,
    ];
    expect(milieu.toSet(), hasLength(3), reason: p.steps.map((s) => '${s.wine.name} : ${s.sommelierRole}').join(' · '));
    expect(milieu.where((r) => r.contains('du boisé')), hasLength(1));
    expect(milieu.where((r) => r.contains('de la minéralité')), hasLength(1));
    expect(milieu.where((r) => r.contains('des tanins')), hasLength(1));
  });

  test('deux axes inconnus seulement : le troisième verre du milieu en reprend un', () {
    final p = MenuFlightEngine.buildFrontierFlight(menu: carte, palais: palais, format: FlightFormat.fiveGlasses);
    expect(p.steps, hasLength(5));
    expect(p.steps.map((s) => s.wine.name).toSet(), hasLength(5), reason: 'jamais deux fois le même vin');
  });

  test('qui fuit le bois ne se le voit pas servir pour apprendre', () {
    const fuitLeBois = TasteProfile(
      id: 'moi',
      name: 'Moi',
      isPrimary: true,
      dislikedCharacteristics: ['Trop boisé'],
      axisObservations: {'tannin': 12, 'body': 12, 'acidity': 12},
    );
    final p = MenuFlightEngine.buildFrontierFlight(menu: carte, palais: fuitLeBois);
    expect(p.steps.map((s) => s.wine.name), isNot(contains('Meursault')));
  });

  test('un vin déjà goûté n\'apprend plus rien : il ne passe pas au milieu', () {
    final dejaGoute = [
      for (final w in ardoise)
        w.id == 'meursault' || w.id == 'chablis'
            ? w.copyWith(pontDeCave: const LienAvecMaCave(type: TypeDeLien.dejaGoute, libelle: 'Déjà goûté'))
            : w,
    ];
    final p = MenuFlightEngine.buildFrontierFlight(menu: menuDe(dejaGoute), palais: palais);
    final instructif = p.steps.singleWhere((s) => s.sommelierRole.startsWith('Pour savoir ce que vous pensez '));
    expect(instructif.wine.name, 'Muscadet', reason: 'le plus minéral qui reste à découvrir');
  });

  testWidgets('sur un téléphone, un rôle long passe à la ligne sans pousser le prix hors de l\'écran', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MenuFlightSheet(menu: carte, palais: palais)),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'aucun débordement');
    expect(find.textContaining('Pour savoir ce que vous pensez'), findsWidgets);
  });

  test('sur une ardoise, « pour mieux vous connaître » reste au milieu des prix du verre, comme le parcours', () {
    // Relevé le 02/10 en production : lue au prix de la bouteille, une ardoise (prix au
    // verre seulement) n'avait aucun plafond. La carte proposait le verre le plus cher, un
    // Madiran, pendant que le parcours en choisissait un autre.
    const sansTaninsNiVivacite = TasteProfile(
      id: 'moi',
      name: 'Moi',
      isPrimary: true,
      axisObservations: {'body': 12, 'oak': 12, 'minerality': 12},
    );
    final bar = menuDe([
      verre('muscadet', 'Muscadet', 'White', 84, const MenuWineRadarMetrics(tannins: 0, acidity: 8, body: 3.5, fruit: 5, oak: 1, minerality: 7.5), prix: 6),
      verre('chablis', 'Chablis', 'White', 78, const MenuWineRadarMetrics(tannins: 0, acidity: 8.5, body: 4, fruit: 5, oak: 1, minerality: 9), prix: 9),
      verre('saumur', 'Saumur-Champigny', 'Red', 80, const MenuWineRadarMetrics(tannins: 5, acidity: 5, body: 5, fruit: 7, oak: 2, minerality: 4), prix: 8),
      verre('morgon', 'Morgon', 'Red', 76, const MenuWineRadarMetrics(tannins: 4, acidity: 5, body: 5, fruit: 8, oak: 2, minerality: 4), prix: 9),
      verre('sancerre', 'Sancerre', 'White', 74, const MenuWineRadarMetrics(tannins: 0, acidity: 8, body: 4, fruit: 6, oak: 1, minerality: 8), prix: 10),
      verre('madiran', 'Madiran', 'Red', 66, const MenuWineRadarMetrics(tannins: 9, acidity: 6, body: 8, fruit: 6, oak: 6, minerality: 4), prix: 11),
    ]);
    SuggestionDeFrontiere<MenuWine>? surLaCarte(double? Function(MenuWine) prix) => TasteFrontierEngine.choisir<MenuWine>(
          TasteFrontierEngine.candidatsDeLaCarte(bar.wines),
          sansTaninsNiVivacite,
          profilDe: ProfilDeVin.depuisLaCarte,
          plaisir: (w) => w.userMatchScore,
          prix: prix,
        );

    expect(surLaCarte((w) => w.bottlePrice)?.vin.name, 'Madiran', reason: 'le défaut : sans prix de bouteille, aucun plafond');

    final juste = surLaCarte(MenuFlightEngine.prixPourApprendre)!;
    expect(juste.vin.name, isNot('Madiran'));
    expect(MenuFlightEngine.prixPourApprendre(juste.vin), lessThanOrEqualTo(9), reason: 'au plus le prix médian du verre');

    final parcours = MenuFlightEngine.buildFrontierFlight(menu: bar, palais: sansTaninsNiVivacite);
    final instructif = parcours.steps.singleWhere((s) => s.sommelierRole.startsWith('Pour savoir ce que vous pensez '));
    expect(instructif.sommelierRole, endsWith(TasteFrontierEngine.ceQueJugeLAxe(juste.axe)),
        reason: 'la carte et le parcours apprennent la même chose');
  });
}
