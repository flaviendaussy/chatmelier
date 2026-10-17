import 'dart:io';

import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/presentation/taste_profiles_dialog.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 17/10, vu à l'émulateur en vérifiant les cases de Gandalf : « Annuler » sur un nouveau
/// profil, puis l'écran rouge — « A TextEditingController was used after being disposed »,
/// puis « '_dependents.isEmpty': is not true ». Les contrôleurs étaient libérés dès le retour
/// de `showDialog`, alors que la boîte, en train de disparaître, s'en servait encore.
void main() {
  setUp(() => Langue.code = 'en');

  testWidgets('annuler un nouveau profil : rien ne sert après avoir été libéré', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tasteProfilesListProvider.overrideWith((ref) async => const [TasteProfile(id: 'primary_user', name: 'Moi', isPrimary: true)]),
      ],
      child: const MaterialApp(home: Scaffold(body: TasteProfilesDialog())),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Papa');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('New profile'), findsNothing);
  });

  test('aucun contrôleur libéré dès le retour d\'un dialogue', () {
    // `final x = TextEditingController(…)`, puis `await showDialog(…)`, puis `x.dispose()`.
    final cree = RegExp(r'final (\w+) = TextEditingController\(');
    final dialogue = RegExp(r'await show(Dialog|ModalBottomSheet|GeneralDialog)');
    final fautes = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final texte = f.readAsStringSync();
      for (final m in cree.allMatches(texte)) {
        final suite = texte.substring(m.end, (m.end + 6000).clamp(0, texte.length));
        final libere = RegExp('\\b${m.group(1)}\\.dispose\\(\\)').firstMatch(suite);
        if (libere != null && dialogue.hasMatch(suite.substring(0, libere.start))) {
          fautes.add('${f.path}:${'\n'.allMatches(texte.substring(0, m.start)).length + 1} ${m.group(1)}');
        }
      }
    }
    expect(fautes, isEmpty);
  });
}
