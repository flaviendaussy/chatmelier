import 'package:chatmelier/features/config/garde_de_version.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _exigence71 = ExigenceDeVersion(build: 71, lien: 'https://play.google.com/store/apps/details?id=x');

extension on ExigenceDeVersion {
  ExigenceDeVersion copieAvecIos(int? buildIos) =>
      ExigenceDeVersion(build: build, lien: lien, message: message, buildIos: buildIos);
}

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

  test('l\'iPhone a sa propre exigence : sans elle, aucun iPhone n\'est bloqué', () {
    expect(doitMettreAJour('1.6.0+76', _exigence71.copieAvecIos(null), iphone: true), isFalse);
    final deuxMagasins = ExigenceDeVersion.depuis({
      'build': 77,
      'lien': 'https://play.google.com/store/apps/details?id=x',
      'build_ios': 76,
    })!;
    expect(doitMettreAJour('1.6.0+76', deuxMagasins), isTrue, reason: 'Android : 77 exigée');
    expect(doitMettreAJour('1.6.0+76', deuxMagasins, iphone: true), isFalse, reason: 'iPhone : 76 suffit');
    expect(doitMettreAJour('1.6.0+75', deuxMagasins, iphone: true), isTrue);
    expect(deuxMagasins.lienPour(iphone: true), ExigenceDeVersion.lienTestFlight,
        reason: 'jamais le Play Store pour un iPhone');
    expect(deuxMagasins.lienPour(iphone: false), startsWith('https://play.google.com'));
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
