import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/prise_en_main/data/preferences_de_prise_en_main.dart';
import 'package:chatmelier/features/prise_en_main/presentation/guide_de_prise_en_main.dart';

void main() {
  Future<void> ouvrirLeGuide(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(onPressed: () => GuideDePriseEnMain.ouvrir(context), child: const Text('ouvrir')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('« Passer », en un geste, ferme le guide et le retient', (tester) async {
    await ouvrirLeGuide(tester);
    expect(find.text('Bienvenue dans Chatmelier'), findsOneWidget);
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue dans Chatmelier'), findsNothing);
    expect(await PreferencesDePriseEnMain.guideVu(), isTrue);
  });

  testWidgets('chaque étape fait faire le geste, et rien n\'avance avant', (tester) async {
    await ouvrirLeGuide(tester);
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.text('Votre cave'), findsOneWidget);
    // Le bouton attend le geste.
    final suivant = find.widgetWithText(FilledButton, 'Faites le geste ci-dessus');
    expect(tester.widget<FilledButton>(suivant).onPressed, isNull);
    await tester.tap(find.text('Bandol rouge 2019'));
    await tester.pumpAndSettle();
    expect(find.textContaining('à partir de 2028'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter une bouteille'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rien n\'est enregistré'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    // Au restaurant : « à prix égal ».
    await tester.tap(find.text('Saint-Joseph 2020'));
    await tester.pumpAndSettle();
    expect(find.textContaining('plus proche de vos goûts que le Morgon'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('😍'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.sms_rounded));
    await tester.pumpAndSettle();
    expect(find.textContaining('Meursault'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('C\'est parti !'), findsOneWidget);
    expect(find.text('Passer'), findsNothing);
    await tester.tap(find.text('C\'est parti'));
    await tester.pumpAndSettle();
    expect(find.text('C\'est parti !'), findsNothing);
    expect(await PreferencesDePriseEnMain.guideVu(), isTrue);
  });

  testWidgets('le retour du téléphone vaut « Passer »', (tester) async {
    await ouvrirLeGuide(tester);
    final NavigatorState nav = tester.state(find.byType(Navigator).first);
    nav.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue dans Chatmelier'), findsNothing);
    expect(await PreferencesDePriseEnMain.guideVu(), isTrue);
  });
}
