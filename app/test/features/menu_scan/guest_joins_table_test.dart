import 'package:chatmelier/features/auth/data/auth_repository.dart';
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
  List<GuestProfile> aTable = const [
    GuestProfile(id: 'hote', name: 'Flavien', favoriteTypes: ['Rouge']),
  ];

  @override
  Future<TableRejointe> rejoindre({required String code, required String nom, GuestProfile? profil}) async {
    arrivees.add((code, nom));
    aTable = [...aTable, GuestProfile(id: nom, name: nom)];
    return TableRejointe(sessionId: 'session', menu: _carte, expireLe: DateTime(2030));
  }

  @override
  Future<List<GuestProfile>> convives(String code) async => aTable;
}

class _FauxCompte extends Fake implements AuthRepository {
  @override
  Future<User?> assurerUneSession() async => null;
}

void main() {
  test('le QR porte le code de la table côté serveur', () {
    final url = MenuTableSessionManager.buildQrUrl(sessionId: 'table-1', menu: _carte, code: 'kyz3yz');
    expect(Uri.parse(url).queryParameters['code'], 'KYZ3YZ');
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
        GuestProfile(id: 'invite', name: 'Invité'),
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

    final valider = find.byIcon(Icons.group_add_rounded);
    await tester.ensureVisible(valider);
    await tester.tap(valider); // le champ garde « Invité », déjà pris
    await tester.pumpAndSettle();

    expect(table.arrivees.single.$2, 'Invité (2)');
  });
}
