import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/menu_scan/presentation/explication_de_la_video.dart';

/// 13/10 : expliquer la vidéo du scan de carte (coût de l'IA, gratuit sans rien de bridé,
/// aucun temps perdu), jusqu'à « Ne plus montrer ».
void main() {
  Future<void> ouvrir(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => ExplicationDeLaVideo.montrerSiBesoin(context),
            child: const Text('scanner'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('scanner'));
    await tester.pumpAndSettle();
  }

  testWidgets('elle dit pourquoi, et se ferme sur la carte', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ouvrir(tester);
    expect(find.text('Pourquoi une vidéo ?'), findsOneWidget);
    expect(find.textContaining('entièrement gratuit'), findsOneWidget);
    expect(find.textContaining('pas attendu une seconde de plus'), findsOneWidget);
    await tester.tap(find.text('Voir ma carte'));
    await tester.pumpAndSettle();
    expect(find.text('Pourquoi une vidéo ?'), findsNothing);
    expect((await SharedPreferences.getInstance()).getBool(ExplicationDeLaVideo.cleMasquee), isNull);
  });

  testWidgets('« Ne plus montrer » la fait taire pour de bon', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ouvrir(tester);
    await tester.tap(find.text('Ne plus montrer'));
    await tester.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getBool(ExplicationDeLaVideo.cleMasquee), isTrue);
    await tester.tap(find.text('scanner'));
    await tester.pumpAndSettle();
    expect(find.text('Pourquoi une vidéo ?'), findsNothing);
  });
}
