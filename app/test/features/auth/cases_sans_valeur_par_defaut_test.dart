import 'dart:convert';
import 'dart:io';

import 'package:chatmelier/features/auth/domain/user_profile.dart';
import 'package:chatmelier/features/auth/presentation/mandatory_username_dialog.dart';
import 'package:chatmelier/features/cellar/presentation/bottle_provenance_picker.dart';
import 'package:chatmelier/shared/providers/auth_provider.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:chatmelier/shared/widgets/owner_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gandalf, 17/10 (Android 81, inscrit avec Google) : « if i cancel the default name your
/// personal name shows up ». Flavien : « enlève les choses prédéfinies dans les cases,
/// comme ce qu'il mentionne ».
void main() {
  setUp(() => Langue.code = 'en');

  // Les testeurs, Flavien compris, et ce qui le situe (ses caves de Londres et des Vosges).
  const personnes = [
    'Flavien', 'Caro', 'Camille', 'Dimitri', 'Pascal', 'Gianpaolo', 'Robin', 'Nono', 'Paul',
    'Aude', 'Pierre', 'Gandalf', 'Bernard', 'Vosges', 'Londres',
  ];
  final unePersonne = RegExp('\\b(${personnes.join('|')})\\b', caseSensitive: false);

  User compte(Map<String, dynamic> meta) =>
      User(id: 'gandalf', appMetadata: const {}, userMetadata: meta, aud: 'authenticated', createdAt: '');

  Future<void> ouvrir(WidgetTester tester, User utilisateur) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [currentUserProvider.overrideWithValue(utilisateur)],
      child: const MaterialApp(home: Scaffold(body: MandatoryUsernameDialog())),
    ));
    await tester.pump();
  }

  List<String> valeurs(WidgetTester tester) =>
      tester.widgetList<EditableText>(find.byType(EditableText)).map((e) => e.controller.text).toList();

  testWidgets('inscrit avec Google : les deux cases vides, et aucun prénom en exemple', (tester) async {
    await ouvrir(tester, compte({'full_name': 'Gandalf the Grey', 'name': 'Gandalf the Grey'}));
    expect(valeurs(tester), ['', '']);

    // Les exemples n'apparaissent qu'une fois la case touchée.
    await tester.tap(find.byType(EditableText).first);
    await tester.pump();
    expect(find.text('syrah_fan'), findsOneWidget);
    await tester.tap(find.byType(EditableText).last);
    await tester.pump();
    expect(find.text('Your first name, or a nickname'), findsOneWidget);

    for (final t in tester.widgetList<Text>(find.byType(Text))) {
      expect(unePersonne.hasMatch(t.data ?? ''), isFalse, reason: t.data);
    }
    expect(find.text('Wine lover'), findsNothing);
    expect(find.text('wine_lover'), findsNothing);
  });

  testWidgets('inscrit par e-mail : son nom revient, le pseudo reste à choisir', (tester) async {
    await ouvrir(tester, compte({'display_name': 'Gandalf'}));
    expect(valeurs(tester), ['', 'Gandalf']);
  });

  testWidgets('« User », mis faute de nom, ne revient pas dans la case', (tester) async {
    await ouvrir(tester, compte({'display_name': 'User'}));
    expect(valeurs(tester), ['', '']);
    expect(UserProfile.estUnNomParDefaut('Amateur de Vin'), isTrue);
    expect(UserProfile.estUnNomParDefaut(' Gandalf '), isFalse);
  });

  testWidgets('provenance : rien de coché d\'office, et le domaine n\'écrit rien dans la case', (tester) async {
    final recu = <(String?, String?)>[];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: BottleProvenancePicker(onChanged: (type, details) => recu.add((type, details))),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).where((c) => c.selected), isEmpty);

    await tester.tap(find.text('🏰 Estate'));
    await tester.pump();
    expect(recu.last, ('estate', null));

    await tester.tap(find.text('🎁 Gift'));
    await tester.pump();
    expect(recu.last, ('gift', null));
    expect(valeurs(tester), ['']);
    expect(find.text('Given by whom? (a friend, your parents…)'), findsOneWidget);

    // Toucher la pastille cochée revient à « pas dit ».
    await tester.tap(find.text('🎁 Gift'));
    await tester.pump();
    expect(recu.last, (null, null));
  });

  testWidgets('sans photo ni nom choisi, une silhouette plutôt que « U »', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Column(children: [OwnerAvatar(), OwnerAvatar(displayName: ' Gandalf ')])),
    ));
    expect(find.text('U'), findsNothing);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
  });

  test('aucun exemple de case ne cite une vraie personne', () {
    // `hintText:`, ou l'exemple rangé à part (`final nameHint = tr(…)`).
    final estUnExemple = RegExp(r'hintText|[hH]int\s*=');
    final fautes = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('/l10n/')) continue;
      final lignes = f.readAsLinesSync();
      for (var i = 0; i < lignes.length; i++) {
        if (!estUnExemple.hasMatch(lignes[i])) continue;
        // La valeur peut tenir sur la ligne suivante.
        final texte = lignes[i] + (i + 1 < lignes.length ? lignes[i + 1] : '');
        if (unePersonne.hasMatch(texte)) fautes.add('${f.path}:${i + 1}');
      }
    }
    for (final arb in Directory('lib/l10n').listSync().whereType<File>().where((f) => f.path.endsWith('.arb'))) {
      final cles = jsonDecode(arb.readAsStringSync()) as Map<String, dynamic>;
      for (final e in cles.entries) {
        if (e.key.endsWith('Hint') && e.value is String && unePersonne.hasMatch(e.value as String)) {
          fautes.add('${arb.path} ${e.key}');
        }
      }
    }
    expect(fautes, isEmpty);
  });

  test('aucune case ne s\'ouvre remplie d\'un mot choisi par l\'app', () {
    // Une quantité (« 1 ») reste permise ; un mot (« Invité », « Convive 3 », « Casier
    // principal », « Domaine ») non, qu'il soit donné à la création ou écrit ensuite.
    const mot = r"""(tr(Si)?\(|'\$\{tr(Si)?\(|'[^'\d$])""";
    final motImpose = [
      RegExp(r'TextEditingController\(text: ([^)]*\?\? )?' + mot),
      RegExp(r'(Ctrl|Controller|ctrl|controller)\.text = ' + mot),
    ];
    final fautes = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final lignes = f.readAsLinesSync();
      for (var i = 0; i < lignes.length; i++) {
        if (motImpose.any((r) => r.hasMatch(lignes[i]))) fautes.add('${f.path}:${i + 1}');
      }
    }
    expect(fautes, isEmpty);
  });
}
