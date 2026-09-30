import 'package:chatmelier/features/menu_scan/presentation/palais_express.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chaque mot du palais a son exemple concret (V2.3 · G3).
void main() {
  Future<void> monter(WidgetTester tester, bool fr) async {
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PalaisExpress(isFr: fr, libelleValider: 'OK', onValider: (_) {}),
        ),
      ),
    ));
  }

  testWidgets('replié par défaut, le lexique s\'ouvre et explique les tanins par le thé', (tester) async {
    await monter(tester, true);
    expect(find.textContaining('thé trop infusé'), findsNothing);
    await tester.tap(find.text('Que veulent dire ces mots ?'));
    await tester.pump();
    expect(find.textContaining('thé trop infusé'), findsOneWidget);
    expect(find.textContaining('pierre mouillée'), findsOneWidget);
  });

  testWidgets('en anglais aussi', (tester) async {
    await monter(tester, false);
    await tester.tap(find.text('What do these words mean?'));
    await tester.pump();
    expect(find.textContaining('over-brewed tea'), findsOneWidget);
  });
}
