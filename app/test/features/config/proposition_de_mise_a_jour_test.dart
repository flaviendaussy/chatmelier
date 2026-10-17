import 'package:chatmelier/features/config/garde_de_version.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 17/10, Flavien : « est-ce que tu peux implémenter maintenant le prompt qui prévient qu'une
/// nouvelle version est dispo ? jld semble en utiliser une vieille » — la 74, deux semaines
/// après la 81.
void main() {
  setUp(() => Langue.code = 'fr');

  const disponible = ExigenceDeVersion(
    build: 84,
    lien: 'https://play.google.com/store/apps/details?id=com.chatmelier.chatmelier',
    buildIos: 84,
  );
  final jeudi = DateTime(2026, 10, 22, 9);

  test('proposée à qui a une version plus ancienne, une fois par jour, jamais à un build de développement', () {
    expect(PropositionDeMiseAJour.aProposer('1.10.0+83', disponible, iphone: false, maintenant: jeudi), isTrue);
    expect(PropositionDeMiseAJour.aProposer('1.11.0+84', disponible, iphone: false, maintenant: jeudi), isFalse);
    expect(PropositionDeMiseAJour.aProposer('dev', disponible, iphone: false, maintenant: jeudi), isFalse);
    expect(PropositionDeMiseAJour.aProposer('1.10.0+83', null, iphone: false, maintenant: jeudi), isFalse);
    // Déjà proposée ce jour-là : pas deux fois.
    expect(
        PropositionDeMiseAJour.aProposer('1.10.0+83', disponible,
            iphone: false, maintenant: jeudi, dejaProposee: '84|2026-10-22'),
        isFalse);
    // Le lendemain, ou pour une version plus récente encore : de nouveau.
    expect(
        PropositionDeMiseAJour.aProposer('1.10.0+83', disponible,
            iphone: false, maintenant: jeudi.add(const Duration(days: 1)), dejaProposee: '84|2026-10-22'),
        isTrue);
    // Sur l'iPhone, seulement si une version iPhone est annoncée.
    const androidSeul = ExigenceDeVersion(build: 84, lien: 'https://play.google.com/store/apps/details?id=x');
    expect(PropositionDeMiseAJour.aProposer('1.10.0+83', androidSeul, iphone: true, maintenant: jeudi), isFalse);
  });

  Future<bool?> ouvrir(WidgetTester tester, {required bool iphone}) async {
    bool? montree;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => montree = await PropositionDeMiseAJour.montrerSiBesoin(context, disponible,
                versionInstallee: '1.6.0+74', iphone: iphone, maintenant: jeudi),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    return montree;
  }

  testWidgets('la feuille dit la version, propose le bon magasin, et « Plus tard » la referme', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ouvrir(tester, iphone: false);
    expect(find.text('Une nouvelle version est disponible'), findsOneWidget);
    expect(find.text('Mettre à jour'), findsOneWidget);
    expect(find.text('Installée : 1.6.0+74 · disponible : build 84'), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    expect(find.text('Une nouvelle version est disponible'), findsNothing);
    expect((await SharedPreferences.getInstance()).getString(PropositionDeMiseAJour.cle), '84|2026-10-22');

    // Le même jour, elle ne revient pas.
    expect(await ouvrir(tester, iphone: false), isFalse);
    expect(find.text('Une nouvelle version est disponible'), findsNothing);
  });

  testWidgets('sur l\'iPhone, c\'est TestFlight', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await ouvrir(tester, iphone: true);
    expect(find.text('Ouvrir TestFlight'), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
  });
}
