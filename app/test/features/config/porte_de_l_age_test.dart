import 'package:chatmelier/features/config/porte_de_l_age.dart';
import 'package:chatmelier/features/offline/presentation/sync_provider.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L'âge légal, demandé une fois (PROD_MIGRATION.md · Alcool).
void main() {
  setUp(() => Langue.code = 'fr');

  Future<SharedPreferences> ouvrir(WidgetTester tester, Map<String, Object> valeurs) async {
    SharedPreferences.setMockInitialValues(valeurs);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesInstanceProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: PorteDeLAge(child: Text('La cave'))),
    ));
    await tester.pumpAndSettle();
    return prefs;
  }

  testWidgets('à la première ouverture, la question ; une fois dit, plus jamais', (tester) async {
    final prefs = await ouvrir(tester, {});
    expect(find.text('La cave'), findsNothing);
    expect(find.text('Chatmelier parle de vin'), findsOneWidget);
    expect(find.textContaining('À consommer avec modération'), findsOneWidget);

    await tester.tap(find.text('J\'ai l\'âge légal'));
    await tester.pumpAndSettle();
    expect(find.text('La cave'), findsOneWidget);
    expect(prefs.getBool(PorteDeLAge.cle), isTrue);
  });

  testWidgets('déjà déclaré : l\'app s\'ouvre directement', (tester) async {
    await ouvrir(tester, {PorteDeLAge.cle: true});
    expect(find.text('La cave'), findsOneWidget);
  });

  testWidgets('un « non » ne laisse pas passer, et n\'est pas retenu', (tester) async {
    final prefs = await ouvrir(tester, {});
    await tester.tap(find.text('Je ne l\'ai pas'));
    await tester.pumpAndSettle();
    expect(find.text('La cave'), findsNothing);
    expect(find.text('À bientôt'), findsOneWidget);
    expect(prefs.getBool(PorteDeLAge.cle), isNull);
    await tester.tap(find.text('Revenir'));
    await tester.pumpAndSettle();
    expect(find.text('Chatmelier parle de vin'), findsOneWidget);
  });
}
