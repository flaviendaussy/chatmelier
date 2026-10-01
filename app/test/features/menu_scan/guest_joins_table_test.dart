import 'package:chatmelier/features/auth/data/auth_repository.dart';
import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/journal/data/degustation_rapide.dart';
import 'package:chatmelier/features/menu_scan/domain/fin_de_soiree.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_table_matcher_engine.dart';
import 'package:chatmelier/features/menu_scan/data/menu_table_session_manager.dart';
import 'package:chatmelier/features/menu_scan/data/table_session_service.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/presentation/menu_table_consensus_guest_screen.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:chatmelier/shared/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

final _carte = ScannedMenu(
  id: 'carte',
  restaurantName: 'The Kitchin',
  scannedAt: DateTime(2026, 9, 23),
  pagePhotoPaths: const [],
  wines: const [
    MenuWine(id: '1', name: 'Barolo', producer: 'Vietti', wineType: 'red'),
    MenuWine(id: '2', name: 'Chablis', producer: 'Fèvre', wineType: 'white'),
  ],
);

/// La table côté serveur : l'hôte y est assis, avec son vrai palais.
class _FausseTable extends Fake implements TableSessionService {
  final arrivees = <(String, String)>[];
  final profils = <GuestProfile?>[];
  List<GuestProfile> aTable = const [
    GuestProfile(id: 'hote', name: 'Flavien', favoriteTypes: ['Rouge']),
  ];

  @override
  Future<TableRejointe> rejoindre({required String code, required String nom, GuestProfile? profil}) async {
    arrivees.add((code, nom));
    profils.add(profil);
    aTable = [
      for (final g in aTable)
        if (g.name != nom) g,
      GuestProfile.fromJson(nom, {...?profil?.toJson(), 'name': nom}),
    ];
    return TableRejointe(sessionId: 'session', menu: _carte, expireLe: DateTime(2030));
  }

  @override
  Future<List<GuestProfile>> convives(String code) async => aTable;

  @override
  Future<List<GuestProfile>?> lireConvives(String code) async => aTable;

  /// Ce que l'hôte a indiqué avoir commandé (E2).
  List<VinChoisi> choix = const [];

  @override
  Future<EtatDeTable?> lireEtat(String code) async => EtatDeTable(choix: choix);
}

/// Le palais Chatmelier de l'appareil : douze dégustations, un goût des rouges charpentés.
class _PalaisDeLAppareil extends Fake implements TasteProfileService {
  final TasteProfile? palais;
  _PalaisDeLAppareil(this.palais);

  @override
  Future<TasteProfile> getPrimaryProfile() async => palais ?? const TasteProfile(id: 'vide', name: 'Moi');
}

/// La dégustation rapide, sans base : on garde ce qui aurait été enregistré.
class _FausseDegustation extends Fake implements DegustationRapide {
  VinBuDehors? recu;

  @override
  Future<({String id, bool enLigne})> enregistrer(VinBuDehors v) async {
    recu = v;
    return (id: 'degustation', enLigne: true);
  }
}

class _FauxCompte extends Fake implements AuthRepository {
  @override
  Future<User?> assurerUneSession() async => null;

  // Pas de session : l'écran ne propose pas de garder la soirée.
  @override
  bool get aUneSession => false;

  @override
  bool get estAnonyme => false;
}

void main() {
  test('le QR porte le code de la table côté serveur', () {
    final url = MenuTableSessionManager.buildQrUrl(sessionId: 'table-1', menu: _carte, code: 'kyz3yz');
    expect(Uri.parse(url).queryParameters['table'], 'KYZ3YZ');
    // Jamais `code` : sur le web, Supabase le prendrait pour un retour de connexion OAuth.
    expect(Uri.parse(url).queryParameters.containsKey('code'), isFalse);
  });

  testWidgets('l\'invité arrivé par le QR rejoint vraiment la table (Caro, 23/09)', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final table = _FausseTable();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tableSessionServiceProvider.overrideWithValue(table),
        authRepositoryProvider.overrideWithValue(_FauxCompte()),
      ],
      child: MaterialApp(
        home: MenuTableConsensusGuestScreen(codeTable: 'kyz3yz', prechargedMenu: _carte),
      ),
    ));
    await tester.pumpAndSettle();

    // Le premier sondage remplace l'hôte générique par l'hôte réel.
    expect(find.textContaining('Flavien'), findsWidgets);
    expect(find.textContaining('Hôte de la table'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Caro');
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    final valider = find.byIcon(Icons.group_add_rounded);
    await tester.ensureVisible(valider);
    await tester.tap(valider);
    await tester.pumpAndSettle();

    expect(table.arrivees, [('KYZ3YZ', 'Caro')]);
    expect(find.textContaining('Caro'), findsWidgets);
  });

  testWidgets('deux invités du même nom ne se confondent pas à table', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final table = _FausseTable()
      ..aTable = const [
        GuestProfile(id: 'hote', name: 'Flavien'),
        // Un invité a gardé le prénom proposé ; l'écran est en anglais, le prénom proposé
        // est donc « Guest » (il suit la langue depuis le 29/09).
        GuestProfile(id: 'invite', name: 'Guest'),
      ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tableSessionServiceProvider.overrideWithValue(table),
        authRepositoryProvider.overrideWithValue(_FauxCompte()),
      ],
      child: MaterialApp(
        home: MenuTableConsensusGuestScreen(codeTable: 'KYZ3YZ', prechargedMenu: _carte),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    final valider = find.byIcon(Icons.group_add_rounded);
    await tester.ensureVisible(valider);
    await tester.tap(valider); // le champ garde « Guest », déjà pris
    await tester.pumpAndSettle();

    expect(table.arrivees.single.$2, 'Guest (2)');
  });

  Future<_FausseTable> ouvrir(WidgetTester tester, {TasteProfile? palais}) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final table = _FausseTable();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tableSessionServiceProvider.overrideWithValue(table),
        authRepositoryProvider.overrideWithValue(_FauxCompte()),
        tasteProfileServiceProvider.overrideWithValue(_PalaisDeLAppareil(palais)),
      ],
      child: MaterialApp(
        home: MenuTableConsensusGuestScreen(codeTable: 'KYZ3YZ', prechargedMenu: _carte),
      ),
    ));
    await tester.pumpAndSettle();
    return table;
  }

  testWidgets('« Juste mon prénom » : assis à table, sans préférences transmises', (tester) async {
    final table = await ouvrir(tester);
    await tester.enterText(find.byType(TextField).first, 'Paul');
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    final refus = find.textContaining('Just my name');
    await tester.ensureVisible(refus);
    await tester.tap(refus);
    await tester.pumpAndSettle();

    expect(table.arrivees.single, ('KYZ3YZ', 'Paul'));
    expect(table.profils.single!.sansPreferences, isTrue);
    expect(find.textContaining('You joined without preferences'), findsOneWidget);
  });

  testWidgets('« Je ne bois pas ce soir » : assis à table, sans voter (V2.3 · E3)', (tester) async {
    final table = await ouvrir(tester);
    await tester.enterText(find.byType(TextField).first, 'Léa');
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    final sansBoire = find.text('I\'m not drinking tonight');
    await tester.ensureVisible(sansBoire);
    await tester.tap(sansBoire);
    await tester.pumpAndSettle();

    expect(table.arrivees.single, ('KYZ3YZ', 'Léa'));
    expect(table.profils.single!.neBoitPas, isTrue);
    expect(find.textContaining('without drinking tonight'), findsOneWidget);
  });

  testWidgets('fin de soirée : l\'hôte a choisi, l\'invité le note d\'un geste (V2.3 · E2)', (tester) async {
    Langue.code = 'en';
    addTearDown(() => Langue.code = 'fr');
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final table = _FausseTable()
      ..choix = const [VinChoisi(cle: 'barolo', nom: 'Barolo', producteur: 'Vietti', millesime: 2019)];
    final degustation = _FausseDegustation();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tableSessionServiceProvider.overrideWithValue(table),
        authRepositoryProvider.overrideWithValue(_FauxCompte()),
        tasteProfileServiceProvider.overrideWithValue(_PalaisDeLAppareil(null)),
        degustationRapideProvider.overrideWithValue(degustation),
      ],
      child: MaterialApp(
        home: MenuTableConsensusGuestScreen(codeTable: 'KYZ3YZ', prechargedMenu: _carte),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Paul');
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    final refus = find.textContaining('Just my name');
    await tester.ensureVisible(refus);
    await tester.tap(refus);
    await tester.pumpAndSettle();

    expect(find.text('Tonight, the table chose'), findsOneWidget);
    expect(find.text('Barolo 2019'), findsOneWidget);
    final noter = find.text('Rate it in one tap');
    await tester.ensureVisible(noter);
    await tester.tap(noter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('😊'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final recu = degustation.recu!;
    expect(recu.nom, 'Barolo');
    expect(recu.millesime, 2019);
    expect(recu.note, 8.0);
    expect(recu.lieu, 'The Kitchin');
    expect(recu.convives, ['Flavien'], reason: 'les autres convives, pas soi-même');
    expect(recu.convivesApprennent, isFalse, reason: 'chacun note sur son propre téléphone');
    expect(find.textContaining('rated'), findsOneWidget);
  });

  testWidgets('« Oui, j\'ai un compte » : le palais Chatmelier de l\'appareil part à table', (tester) async {
    final table = await ouvrir(tester, palais: const TasteProfile(
      id: 'moi',
      name: 'Moi',
      questionnairesCompleted: 12,
      favoriteTypes: ['Rouge'],
    ));
    await tester.enterText(find.byType(TextField).first, 'Caro');
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.textContaining('12 tastings'), findsOneWidget);
    await tester.tap(find.text('Join with my palate'));
    await tester.pumpAndSettle();

    expect(table.arrivees.single, ('KYZ3YZ', 'Caro'));
    expect(table.profils.single!.favoriteTypes, ['Rouge']);
    expect(table.profils.single!.sansPreferences, isFalse);
  });

  testWidgets('pas de palais sur l\'appareil : on le dit, et les curseurs s\'ouvrent', (tester) async {
    await ouvrir(tester);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No Chatmelier palate on this device'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(6));
  });

  testWidgets('mettre à jour ses goûts ne renomme pas l\'invité', (tester) async {
    final table = await ouvrir(tester);
    await tester.enterText(find.byType(TextField).first, 'Caro');
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    final valider = find.byIcon(Icons.group_add_rounded);
    await tester.ensureVisible(valider);
    await tester.tap(valider);
    await tester.pumpAndSettle();

    final maj = find.text('Update my preferences');
    await tester.ensureVisible(maj);
    await tester.tap(maj);
    await tester.pumpAndSettle();

    expect(table.arrivees.map((a) => a.$2), ['Caro', 'Caro']);
  });

  test('un convive sans préférences ne change pas le classement de la table', () {
    const flavien = GuestProfile(id: 'f', name: 'Flavien', favoriteTypes: ['Rouge']);
    const paul = GuestProfile(id: 'p', name: 'Paul', sansPreferences: true);
    final seul = MenuTableMatcherEngine.rankTop3WinesForTable(menuWines: _carte.wines, guests: [flavien]);
    final aDeux = MenuTableMatcherEngine.rankTop3WinesForTable(menuWines: _carte.wines, guests: [flavien, paul]);
    expect(aDeux.map((r) => r.menuWine.name), seul.map((r) => r.menuWine.name));
    expect(aDeux.map((r) => r.harmonyScore), seul.map((r) => r.harmonyScore));
    for (final r in aDeux) {
      expect(r.consensusRationale, isNot(contains('Paul')));
    }
  });
}
