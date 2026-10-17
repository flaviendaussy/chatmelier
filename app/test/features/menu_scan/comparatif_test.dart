import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/presentation/menu_wine_compare_sheet.dart';
import 'package:chatmelier/shared/widgets/wine_type_badge.dart';

/// 13/10, sur la carte du vol BA484 : « on ne voit plus quel vin est rosé, lequel est blanc »,
/// et « je dois pouvoir slider ici en glissant mon doigt pour passer des rouges aux autres ».
void main() {
  MenuWine vin(String nom, String type) => MenuWine(id: nom, name: nom, producer: 'Domaine', wineType: type);

  Future<void> ouvrir(WidgetTester tester, List<MenuWine> vins) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('fr'), Locale('en')],
      home: Scaffold(body: MenuWineCompareSheet(selectedWines: vins)),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('les autres gardent tous les vins qui ne sont pas rouges, chacun avec sa couleur', (tester) async {
    await ouvrir(tester, [vin('Pauillac', 'red'), vin('Chablis', 'white'), vin('Sauternes', 'dessert'), vin('Porto', 'fortified')]);
    expect(find.text('Rouges (1)'), findsOneWidget);
    expect(find.text('Autres (3)'), findsOneWidget, reason: 'le moelleux et le muté ne disparaissent plus');
    await tester.tap(find.text('Autres (3)'));
    await tester.pumpAndSettle();
    for (final nom in ['Chablis', 'Sauternes', 'Porto']) {
      expect(find.text(nom), findsOneWidget, reason: nom);
    }
    expect(find.byType(WineTypeBadge), findsNWidgets(3));
    expect(find.text('BLANC'), findsOneWidget);
  });

  testWidgets('glisser du doigt passe des rouges aux autres', (tester) async {
    await ouvrir(tester, [vin('Pauillac', 'red'), vin('Chablis', 'white')]);
    expect(find.text('Pauillac'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Chablis'), findsOneWidget);
    final bouton = tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>));
    expect(bouton.selected, {1}, reason: 'le bouton suit la page');
  });
}
