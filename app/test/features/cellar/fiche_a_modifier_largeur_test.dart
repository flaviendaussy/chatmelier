// La fiche à modifier, sur un téléphone de 360 px : le choix « Couleur / Type » se calait sur
// son plus long libellé (« Cognac / Armagnac ») et débordait de sa demi-ligne de 41 px.

import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/presentation/bottle_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('le choix du type tient dans sa demi-ligne, même pour un Cognac', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    const vin = Wine(id: 'w1', name: 'Fine Champagne VSOP', type: 'cognac', country: 'France', region: 'Cognac');
    final bouteille = Bottle(
      id: 'b1',
      cellarId: 'c1',
      wineId: 'w1',
      addedBy: 'u1',
      ownerId: 'u1',
      createdAt: DateTime(2026, 10, 1),
      quantity: 1,
      status: 'in_cellar',
      wine: vin,
    );
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: BottleEditSheet(bottle: bouteille, wine: vin, onSaved: () {})),
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull, reason: 'aucun débordement');
    expect(find.text('🍷 Cognac / Armagnac'), findsOneWidget);
  });
}
