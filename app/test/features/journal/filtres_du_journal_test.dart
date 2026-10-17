import 'package:chatmelier/features/cellar/domain/wine_world/wine_world.dart';
import 'package:chatmelier/features/journal/domain/filtres_du_journal.dart';
import 'package:chatmelier/features/journal/domain/tasting_entry.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// 13/10, Flavien : « ajoute le drapeau du pays pour chaque vin […] et ajoute des filtres
/// (pays, appellation, couleur, etc...) ».
void main() {
  setUp(() => Langue.code = 'fr');
  tearDown(() => Langue.code = 'fr');

  TastingEntry degustation(
    String id, {
    String? pays,
    String? type,
    String? appellation,
    String? region,
    String? lieu,
    double? note,
  }) =>
      TastingEntry(
        id: id,
        wineId: 'w$id',
        wineName: 'Vin $id',
        country: pays,
        wineType: type,
        appellation: appellation,
        region: region,
        locationName: lieu,
        rating: note,
        consumedAt: DateTime(2026, 10, 16),
      );

  final journal = [
    degustation('1', pays: 'Spain', type: 'red', appellation: 'Ribera del Duero', note: 8),
    degustation('2', pays: 'Espagne', type: 'tinto', appellation: 'Jumilla', lieu: 'Barrafina', note: 7),
    degustation('3', pays: 'France', type: 'white', appellation: 'Chablis', lieu: 'Barrafina', note: 9),
    degustation('4', pays: 'France', type: 'Rouge', region: 'Bourgogne'),
    degustation('5', pays: 'France', type: 'sparkling', appellation: 'Champagne', note: 6),
    degustation('6', pays: 'Spain', type: 'red', appellation: 'Ribera Del Duero', note: 8.5),
  ];

  test('« Spain » et « Espagne » sont un même pays, écrit avec son drapeau dans la langue de l\'écran', () {
    final pays = FiltresDuJournal.vides.choix(journal, FamilleDeFiltre.pays);
    expect(pays.map((c) => (c.libelle, c.nombre)), [('🇪🇸 Espagne', 3), ('🇫🇷 France', 3)]);
    // À égalité, l'ordre alphabétique dans la langue de l'écran.
    Langue.code = 'en';
    expect(FiltresDuJournal.vides.choix(journal, FamilleDeFiltre.pays).map((c) => c.libelle),
        ['🇫🇷 France', '🇪🇸 Spain']);
  });

  test('un vin bu dehors, sans pays, prend celui de son appellation quand elle ne laisse aucun doute', () {
    // Le journal de Flavien, 17/10 : Morgon, Bourgogne Côte d'Or, sans pays ni drapeau.
    expect(WineWorld.paysDe(appellation: 'Morgon'), 'France');
    expect(WineWorld.paysDe(appellation: 'Bourgogne Côte d\'Or'), 'France');
    expect(WineWorld.paysDe(appellation: 'Collines Rhodaniennes'), 'France');
    expect(WineWorld.paysDe(appellation: 'Ribera del Duero'), 'Espagne');
    expect(WineWorld.paysDe(appellation: '', region: 'Jumilla'), 'Espagne');
    expect(WineWorld.paysDe(region: 'Galicia'), 'Espagne');
    // Mot à mot : « Castilla » contient « asti », ce n'est pas un vin italien.
    expect(WineWorld.paysDe(region: 'Castilla y León'), isNot('Italie'));
    // Un cépage, un mot partagé : on ne sait pas.
    expect(WineWorld.paysDe(appellation: 'Albariño'), isNull);
    expect(WineWorld.paysDe(appellation: 'Crémant de Luxembourg'), isNull);
    expect(WineWorld.paysDe(region: 'Central Valley'), isNull);
    expect(WineWorld.paysDe(appellation: 'Cuvée du patron'), isNull);

    final morgon = degustation('8', appellation: 'Morgon');
    expect(FiltresDuJournal.paysDe(morgon), 'France');
    expect(FiltresDuJournal.vides.choix([morgon], FamilleDeFiltre.pays).single.libelle, '🇫🇷 France');
    // Le pays écrit passe avant : une « Syrah » d'Australie reste australienne.
    expect(FiltresDuJournal.paysDe(degustation('9', pays: 'Australia', appellation: 'Barossa')), 'Australia');
  });

  test('la couleur se lit dans toutes les langues du journal', () {
    final lectures = {
      'red': 'rouge', 'Rouge': 'rouge', 'tinto': 'rouge', 'white': 'blanc', 'Blanco': 'blanc',
      'rosé': 'rose', 'Rosado': 'rose', 'sparkling': 'bulles', 'Champagne': 'bulles', 'Crémant': 'bulles',
      'dessert': 'moelleux', 'Liquoreux': 'moelleux', 'fortified': 'mute', 'Porto': 'mute',
      'orange': 'orange', 'whisky': 'spiritueux', 'Gin': 'spiritueux', 'cidre': 'autre',
    };
    for (final MapEntry(key: type, value: couleur) in lectures.entries) {
      expect(FiltresDuJournal.couleurDe(type), couleur, reason: type);
    }
    expect(FiltresDuJournal.couleurDe(null), isNull);
    expect(FiltresDuJournal.couleurDe('  '), isNull);
  });

  test('choisir un pays ne propose plus que ses appellations ; la valeur choisie reste à retirer', () {
    final espagne = FiltresDuJournal.vides.basculer(FamilleDeFiltre.pays, 'ES');
    expect(espagne.appliquer(journal).map((e) => e.id), ['1', '2', '6']);
    expect(espagne.choix(journal, FamilleDeFiltre.appellation).map((c) => (c.libelle, c.nombre)),
        [('Ribera del Duero', 2), ('Jumilla', 1)],
        reason: '« Ribera Del Duero » est la même appellation, écrite autrement');
    // Les pays restent tous proposés : on peut en ajouter un second.
    expect(espagne.choix(journal, FamilleDeFiltre.pays).length, 2);

    final chablis = FiltresDuJournal.vides.basculer(FamilleDeFiltre.appellation, 'chablis');
    final etEspagne = chablis.basculer(FamilleDeFiltre.pays, 'ES');
    expect(etEspagne.appliquer(journal), isEmpty);
    expect(etEspagne.choix(journal, FamilleDeFiltre.appellation).map((c) => (c.libelle, c.nombre)),
        contains(('Chablis', 0)));
  });

  test('sans appellation, la région compte ; un vin sans pays ni lieu n\'est proposé nulle part', () {
    final appellations = FiltresDuJournal.vides.choix(journal, FamilleDeFiltre.appellation);
    expect(appellations.map((c) => c.libelle), contains('Bourgogne'));
    final lieux = FiltresDuJournal.vides.choix(journal, FamilleDeFiltre.lieu);
    expect(lieux.map((c) => (c.libelle, c.nombre)), [('Barrafina', 2)]);
    final sansRien = degustation('7');
    for (final f in FamilleDeFiltre.values) {
      expect(FiltresDuJournal.cleDe(f, sansRien), isNull, reason: f.name);
    }
  });

  test('la couleur suit l\'ordre de la cave, les autres familles le nombre', () {
    expect(FiltresDuJournal.vides.choix(journal, FamilleDeFiltre.couleur).map((c) => c.cle),
        ['rouge', 'blanc', 'bulles']);
  });

  test('une note minimale écarte les vins non notés', () {
    final huit = FiltresDuJournal.vides.avecNoteMin(8);
    expect(huit.appliquer(journal).map((e) => e.id), ['1', '3', '6']);
    expect(FiltresDuJournal.vides.nombreAuMoins(journal, 8), 3);
    expect(huit.nombreActifs, 1);
  });

  test('les filtres choisis s\'écrivent pour être retirés d\'un geste', () {
    final f = FiltresDuJournal.vides
        .basculer(FamilleDeFiltre.pays, 'ES')
        .basculer(FamilleDeFiltre.couleur, 'rouge')
        .avecNoteMin(8);
    expect(f.etiquettes(journal).map((e) => e.libelle), ['🇪🇸 Espagne', 'Rouge', 'Note ≥ 8/10']);
    expect(f.nombreActifs, 3);
    final sansPays = f.basculer(FamilleDeFiltre.pays, 'ES');
    expect(sansPays.de(FamilleDeFiltre.pays), isEmpty);
    expect(sansPays.nombreActifs, 2);
  });
}
