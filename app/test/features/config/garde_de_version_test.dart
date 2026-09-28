import 'package:chatmelier/features/config/garde_de_version.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _exigence71 = ExigenceDeVersion(build: 71, lien: 'https://play.google.com/store/apps/details?id=x');

Widget _app(String version, ExigenceDeVersion? exigence) => ProviderScope(
      overrides: [exigenceDeVersionProvider.overrideWith((ref) async => exigence)],
      child: MaterialApp(
        home: GardeDeVersion(versionInstallee: version, child: const Text('La cave')),
      ),
    );

void main() {
  test('le numéro de build se lit après le « + »', () {
    expect(numeroDeBuild('1.4.0+70'), 70);
    expect(numeroDeBuild('1.2.0'), isNull);
    expect(numeroDeBuild('dev'), isNull);
  });

  test('on ne bloque que ce qui est sûr', () {
    expect(doitMettreAJour('1.4.0+70', _exigence71), isTrue);
    expect(doitMettreAJour('1.4.0+71', _exigence71), isFalse);
    expect(doitMettreAJour('1.4.0+70', null), isFalse, reason: 'hors ligne : on laisse passer');
    expect(doitMettreAJour('dev', _exigence71), isFalse, reason: 'build de développement');
    expect(doitMettreAJour('1.4.0+70', const ExigenceDeVersion(build: 0, lien: 'x')), isFalse,
        reason: 'build 0 : rien n\'est exigé tant qu\'on ne l\'a pas relevé');
  });

  test('l\'exigence se lit dans app_config', () {
    final e = ExigenceDeVersion.depuis({'build': 71, 'lien': 'https://x', 'message': 'Mettez à jour'});
    expect(e?.build, 71);
    expect(ExigenceDeVersion.depuis({'build': 'soixante'}), isNull);
    expect(ExigenceDeVersion.depuis(null), isNull);
  });

  testWidgets('une version trop ancienne est bloquée, en le disant', (tester) async {
    await tester.pumpWidget(_app('1.4.0+70', _exigence71));
    await tester.pumpAndSettle();
    expect(find.text('La cave'), findsNothing);
    expect(find.text('An update is required'), findsOneWidget);
    expect(find.text('Required during the test phase only.'), findsOneWidget);
  });

  testWidgets('une version à jour passe', (tester) async {
    await tester.pumpWidget(_app('1.4.0+71', _exigence71));
    await tester.pumpAndSettle();
    expect(find.text('La cave'), findsOneWidget);
  });
}
