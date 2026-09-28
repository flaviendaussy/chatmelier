import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/presentation/menu_matchmaker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MenuWine vin(String nom, String type, double prix, {double tanins = 0}) => MenuWine(
      id: nom,
      name: nom,
      producer: 'Domaine',
      wineType: type,
      bottlePrice: prix,
      devise: 'GBP',
      metrics: MenuWineRadarMetrics(tannins: tanins),
    );

void main() {
  testWidgets('le « pourquoi » part des réponses, en devise de la carte (Caro, 26/09)', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MenuMatchmakerSheet(allWines: [
          vin('Sancerre', 'white', 42),
          vin('Barolo', 'red', 95, tanins: 9),
          vin('Chablis', 'white', 48),
          vin('Pinot Noir', 'red', 38, tanins: 4),
        ]),
      ),
    ));
    await tester.pumpAndSettle();

    // Première question : la couleur. Oui au rouge : il reste deux vins, le podium s'ouvre.
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.textContaining('you wanted red'), findsNWidgets(2));
    // Les prix sont en livres, pas en euros.
    expect(find.textContaining('£'), findsWidgets);
    expect(find.textContaining('€'), findsNothing);
    // Ce qui distingue les deux finalistes est dit.
    expect(find.textContaining('The most structured of the two'), findsOneWidget);
    expect(find.textContaining('the cheapest (£38)'), findsOneWidget);
    // Et on peut les comparer d'un geste.
    expect(find.text('Compare the 2 finalists'), findsOneWidget);
  });
}
