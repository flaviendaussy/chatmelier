import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/presentation/menu_matchmaker_sheet.dart';

void main() {
  // Build a realistic 21-wine restaurant menu matching the user's scan
  final List<MenuWine> sample21Wines = [
    // 11 Reds
    const MenuWine(
      id: 'r1',
      name: 'Château Lynch-Bages',
      producer: 'Famille Cazes',
      vintage: 2016,
      wineType: 'red',
      bottlePrice: 180.0,
      tags: ['tannique', 'puissant', 'boisé'],
      metrics: MenuWineRadarMetrics(tannins: 8.8, body: 8.5, oak: 8.0, acidity: 5.5, fruit: 7.0),
    ),
    const MenuWine(
      id: 'r2',
      name: 'Saint-Joseph Offerus',
      producer: 'J.L. Chave Sélection',
      vintage: 2020,
      wineType: 'red',
      bottlePrice: 58.0,
      glassPrices: [MenuWineGlassPrice(format: '125ml', price: 11.0)],
      tags: ['tannique', 'épicé', 'fruité'],
      metrics: MenuWineRadarMetrics(tannins: 7.0, body: 7.5, oak: 6.0, acidity: 6.0, fruit: 8.0),
    ),
    const MenuWine(
      id: 'r3',
      name: 'Bourgogne Pinot Noir',
      producer: 'Domaine Dujac',
      vintage: 2021,
      wineType: 'red',
      bottlePrice: 72.0,
      tags: ['léger', 'fruité', 'frais'],
      metrics: MenuWineRadarMetrics(tannins: 3.5, body: 4.5, oak: 4.0, acidity: 7.0, fruit: 8.5),
    ),
    const MenuWine(
      id: 'r4',
      name: 'Morgon Côte du Py',
      producer: 'Jean Foillard',
      vintage: 2022,
      wineType: 'red',
      bottlePrice: 42.0,
      glassPrices: [MenuWineGlassPrice(format: '125ml', price: 8.5)],
      tags: ['fruité', 'léger', 'minéral'],
      metrics: MenuWineRadarMetrics(tannins: 3.0, body: 4.0, oak: 2.0, acidity: 6.5, fruit: 9.0),
    ),
    const MenuWine(
      id: 'r5',
      name: 'Châteauneuf-du-Pape',
      producer: 'Château de Beaucastel',
      vintage: 2019,
      wineType: 'red',
      bottlePrice: 130.0,
      tags: ['puissant', 'tannique', 'rond'],
      metrics: MenuWineRadarMetrics(tannins: 8.0, body: 9.0, oak: 7.0, acidity: 5.0, fruit: 8.0),
    ),
    const MenuWine(
      id: 'r6',
      name: 'Côtes du Rhône Parallèle 45',
      producer: 'Paul Jaboulet Aîné',
      vintage: 2021,
      wineType: 'red',
      bottlePrice: 28.0,
      glassPrices: [MenuWineGlassPrice(format: '125ml', price: 6.0)],
      tags: ['fruité', 'épicé'],
      metrics: MenuWineRadarMetrics(tannins: 5.5, body: 6.0, oak: 4.0, acidity: 5.5, fruit: 7.0),
    ),
    const MenuWine(
      id: 'r7',
      name: 'Chinon Les Granges',
      producer: 'Bernard Baudry',
      vintage: 2022,
      wineType: 'red',
      bottlePrice: 34.0,
      tags: ['frais', 'fruité', 'léger'],
      metrics: MenuWineRadarMetrics(tannins: 4.0, body: 4.5, oak: 2.0, acidity: 7.0, fruit: 8.0),
    ),
    const MenuWine(
      id: 'r8',
      name: 'Barolo Castiglione',
      producer: 'Vietti',
      vintage: 2018,
      wineType: 'red',
      bottlePrice: 95.0,
      tags: ['tannique', 'puissant', 'boisé'],
      metrics: MenuWineRadarMetrics(tannins: 9.0, body: 8.5, oak: 8.0, acidity: 7.5, fruit: 6.5),
    ),
    const MenuWine(
      id: 'r9',
      name: 'Crozes-Hermitage',
      producer: 'Alain Graillot',
      vintage: 2021,
      wineType: 'red',
      bottlePrice: 48.0,
      tags: ['épicé', 'tannique'],
      metrics: MenuWineRadarMetrics(tannins: 6.5, body: 6.5, oak: 5.0, acidity: 6.5, fruit: 7.5),
    ),
    const MenuWine(
      id: 'r10',
      name: 'Pic Saint-Loup',
      producer: 'Château La Roque',
      vintage: 2021,
      wineType: 'red',
      bottlePrice: 38.0,
      tags: ['gourmand', 'fruité'],
      metrics: MenuWineRadarMetrics(tannins: 5.0, body: 6.0, oak: 3.5, acidity: 5.5, fruit: 7.5),
    ),
    const MenuWine(
      id: 'r11',
      name: 'Pessac-Léognan Rouge',
      producer: 'Château Carbonnieux',
      vintage: 2018,
      wineType: 'red',
      bottlePrice: 75.0,
      tags: ['tannique', 'boisé'],
      metrics: MenuWineRadarMetrics(tannins: 7.5, body: 7.5, oak: 7.5, acidity: 6.0, fruit: 6.5),
    ),

    // 6 Whites
    const MenuWine(
      id: 'w1',
      name: 'Chablis Premier Cru Montée de Tonnerre',
      producer: 'Louis Michel',
      vintage: 2020,
      wineType: 'white',
      bottlePrice: 65.0,
      glassPrices: [MenuWineGlassPrice(format: '125ml', price: 12.5)],
      tags: ['minéral', 'frais'],
      metrics: MenuWineRadarMetrics(tannins: 0.0, minerality: 8.5, acidity: 8.0, butteriness: 2.0, oak: 2.0),
    ),
    const MenuWine(
      id: 'w2',
      name: 'Meursault Les Narvaux',
      producer: 'Vincent Girardin',
      vintage: 2020,
      wineType: 'white',
      bottlePrice: 110.0,
      tags: ['beurré', 'boisé', 'rond'],
      metrics: MenuWineRadarMetrics(tannins: 0.0, minerality: 6.0, acidity: 5.5, butteriness: 8.0, oak: 7.5),
    ),
    const MenuWine(
      id: 'w3',
      name: 'Sancerre d\'Antan',
      producer: 'Henri Bourgeois',
      vintage: 2021,
      wineType: 'white',
      bottlePrice: 55.0,
      glassPrices: [MenuWineGlassPrice(format: '125ml', price: 10.5)],
      tags: ['minéral', 'frais'],
      metrics: MenuWineRadarMetrics(tannins: 0.0, minerality: 8.0, acidity: 8.5, butteriness: 2.0, oak: 4.0),
    ),
    const MenuWine(
      id: 'w4',
      name: 'Condrieu Les Chaillets',
      producer: 'Yves Cuilleron',
      vintage: 2021,
      wineType: 'white',
      bottlePrice: 85.0,
      tags: ['floral', 'rond', 'beurré'],
      metrics: MenuWineRadarMetrics(tannins: 0.0, minerality: 4.5, acidity: 4.5, butteriness: 6.5, oak: 5.0),
    ),
    const MenuWine(
      id: 'w5',
      name: 'Muscadet Sèvre et Maine Clisson',
      producer: 'Domaine de la Pépière',
      vintage: 2020,
      wineType: 'white',
      bottlePrice: 32.0,
      glassPrices: [MenuWineGlassPrice(format: '125ml', price: 7.0)],
      tags: ['minéral', 'frais'],
      metrics: MenuWineRadarMetrics(tannins: 0.0, minerality: 9.0, acidity: 8.0, butteriness: 1.5, oak: 1.0),
    ),
    const MenuWine(
      id: 'w6',
      name: 'Riesling Grand Cru Rangen',
      producer: 'Zind-Humbrecht',
      vintage: 2019,
      wineType: 'white',
      bottlePrice: 90.0,
      tags: ['minéral', 'puissant'],
      metrics: MenuWineRadarMetrics(tannins: 0.0, minerality: 9.0, acidity: 8.0, butteriness: 3.0, oak: 3.0),
    ),

    // 2 Champagnes / Bulles
    const MenuWine(
      id: 'c1',
      name: 'Champagne Brut Réserve',
      producer: 'Billecart-Salmon',
      vintage: null,
      wineType: 'sparkling',
      bottlePrice: 85.0,
      glassPrices: [MenuWineGlassPrice(format: '125ml', price: 16.0)],
      tags: ['frais', 'bulles'],
      metrics: MenuWineRadarMetrics(tannins: 0.0, acidity: 8.5, minerality: 7.0, fruit: 7.0),
    ),
    const MenuWine(
      id: 'c2',
      name: 'Champagne Grand Cru Blanc de Blancs',
      producer: 'Pierre Peters',
      vintage: 2017,
      wineType: 'sparkling',
      bottlePrice: 120.0,
      tags: ['minéral', 'frais', 'bulles'],
      metrics: MenuWineRadarMetrics(tannins: 0.0, acidity: 9.0, minerality: 8.5, fruit: 6.5),
    ),

    // 2 Rosés
    const MenuWine(
      id: 'ro1',
      name: 'Côtes de Provence Clos Mireille',
      producer: 'Domaines Ott',
      vintage: 2022,
      wineType: 'rose',
      bottlePrice: 48.0,
      glassPrices: [MenuWineGlassPrice(format: '125ml', price: 9.5)],
      tags: ['frais', 'fruité'],
      metrics: MenuWineRadarMetrics(tannins: 0.5, acidity: 7.0, fruit: 8.0, minerality: 6.0),
    ),
    const MenuWine(
      id: 'ro2',
      name: 'Bandol Rosé',
      producer: 'Domaine Tempier',
      vintage: 2022,
      wineType: 'rose',
      bottlePrice: 52.0,
      tags: ['frais', 'rond', 'épicé'],
      metrics: MenuWineRadarMetrics(tannins: 1.0, acidity: 6.5, fruit: 7.5, minerality: 6.5),
    ),
  ];

  testWidgets('Live Matchmaker Simulation on 21 Scanned Wines: Non-Red never gets asked about tannins', (tester) async {
    expect(sample21Wines.length, 21);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MenuMatchmakerSheet(allWines: sample21Wines),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial State: All 21 wines are in play
    expect(find.text('21 vins en lice sur 21 au total'), findsOneWidget);

    // First question should be about Red wine (color)
    expect(find.text('Envie de vin Rouge ce soir ?'), findsOneWidget);

    // 2. User says NON to Red Wine (taps the NON button)
    final nonButton = find.widgetWithText(OutlinedButton, 'NON');
    expect(nonButton, findsOneWidget);
    await tester.tap(nonButton);
    await tester.pumpAndSettle();

    // 3. Pool must now be reduced: 21 - 11 reds = 10 wines remaining
    expect(find.text('10 vins en lice sur 21 au total'), findsOneWidget);
    expect(find.text('-\$11'), findsNothing);
    expect(find.text('-11'), findsOneWidget); // Visual eliminated badge

    // 4. CRITICAL CHECK: The current question must NEVER be "Amateur de Tannins & Structure ?"
    expect(find.text('Amateur de Tannins & Structure ?'), findsNothing);

    // Next question should be relevant to the 10 remaining wines (e.g. Bulles or Minéralité)
    final hasBubbles = find.text('Plutôt Bulles festives / Champagne ?').evaluate().isNotEmpty;
    final hasMinerality = find.text('Recherche de Minéralité & Vivacité ?').evaluate().isNotEmpty;
    expect(hasBubbles || hasMinerality, isTrue);

    // 5. User says NON to the second question
    await tester.tap(find.widgetWithText(OutlinedButton, 'NON'));
    await tester.pumpAndSettle();

    // Pool count should be further reduced
    expect(find.textContaining('vins en lice sur 21 au total'), findsOneWidget);
    // Tannins question must STILL be absent!
    expect(find.text('Amateur de Tannins & Structure ?'), findsNothing);
  });
}
