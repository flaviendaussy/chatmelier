import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/menu_scan/data/table_session_service.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/presentation/menu_table_consensus_sheet.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _carte = ScannedMenu(
  id: 'carte',
  restaurantName: 'Chez Paul',
  scannedAt: DateTime(2026, 10, 8),
  pagePhotoPaths: const [],
  wines: const [
    MenuWine(id: 'r', name: 'Saint-Joseph', producer: 'Gonon', wineType: 'red',
        metrics: MenuWineRadarMetrics(tannins: 7, body: 7, acidity: 5)),
    MenuWine(id: 'b', name: 'Chablis', producer: 'Fèvre', wineType: 'white',
        metrics: MenuWineRadarMetrics(tannins: 0, body: 5, acidity: 8, minerality: 8)),
  ],
);

/// Sans serveur : la table reste en local, l'hôte seul à l'écran.
class _TableHorsLigne extends Fake implements TableSessionService {
  @override
  Future<TableOuverte> ouvrir({required String restaurantName, required ScannedMenu menu}) async =>
      throw Exception('hors ligne');
}

void main() {
  setUp(() => Langue.estFr = true);

  testWidgets('l\'hôte dit ce qu\'il mange en touchant son nom (R4)', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tableSessionServiceProvider.overrideWithValue(_TableHorsLigne()),
        tasteProfilesListProvider.overrideWith((ref) async => const [TasteProfile(id: 'moi', name: 'Moi', isPrimary: true)]),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(body: MenuTableConsensusSheet(menu: _carte)),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Touchez votre nom'), findsOneWidget);
    await tester.tap(find.byType(InputChip).first);
    await tester.pumpAndSettle();
    expect(find.text('Ce que vous mangez (le plus proche)'), findsOneWidget);
    await tester.tap(find.text('🐟 Poisson & Crustacés'));
    await tester.pumpAndSettle();

    expect(find.textContaining('· 🐟'), findsOneWidget);
  });
}
