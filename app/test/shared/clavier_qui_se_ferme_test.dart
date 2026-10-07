import 'package:chatmelier/shared/widgets/clavier_qui_se_ferme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le clavier se ferme en touchant ailleurs (V2.4 · R3).
void main() {
  Future<void> ouvrir(WidgetTester tester, {VoidCallback? surBouton}) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => ClavierQuiSeFerme(child: child!),
      home: Scaffold(
        body: Column(
          children: [
            const TextField(key: Key('champ')),
            const SizedBox(height: 200, child: Center(child: Text('Un espace vide'))),
            ElevatedButton(onPressed: surBouton ?? () {}, child: const Text('Enregistrer')),
          ],
        ),
      ),
    ));
  }

  bool champActif(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

  testWidgets('toucher un espace vide referme le champ', (tester) async {
    await ouvrir(tester);
    await tester.tap(find.byKey(const Key('champ')));
    await tester.pump();
    expect(champActif(tester), isTrue);

    await tester.tap(find.text('Un espace vide'));
    await tester.pump();
    expect(champActif(tester), isFalse);
  });

  testWidgets('toucher le champ lui-même le laisse ouvert, un bouton garde son action', (tester) async {
    var enregistre = 0;
    await ouvrir(tester, surBouton: () => enregistre++);
    await tester.tap(find.byKey(const Key('champ')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('champ')));
    await tester.pump();
    expect(champActif(tester), isTrue);

    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(enregistre, 1, reason: 'le bouton reçoit son toucher, le détecteur de la racine ne le vole pas');
  });

  testWidgets('le focus d\'un bouton (clavier physique) n\'est pas retiré', (tester) async {
    await ouvrir(tester);
    final bouton = Focus.of(tester.element(find.text('Enregistrer')));
    bouton.requestFocus();
    await tester.pump();
    ClavierQuiSeFerme.fermer();
    await tester.pump();
    expect(bouton.hasFocus, isTrue);
  });
}
