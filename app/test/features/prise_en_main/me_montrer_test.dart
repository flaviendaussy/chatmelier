import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/prise_en_main/presentation/demonstration_apogee.dart';
import 'package:chatmelier/shared/widgets/bottle_card.dart';
import 'package:chatmelier/shared/widgets/gaussian_drinking_curve.dart';
import 'package:chatmelier/shared/widgets/projecteur.dart';

/// 16/10 : « je viens de cliquer sur "me montrer" sur une recommandation qui parlait de
/// comment voir l'apogée, mais ça n'a pas marché. ça aurait dû passer en cave simulée, ouvrir
/// une bouteille, scroller vers l'apogée, et isoler visuellement la zone ».
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget app(Widget ecran) => ProviderScope(
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('fr'), Locale('en')],
          home: ecran,
        ),
      );

  /// Les attentes du projecteur sont de vrais délais : l'horloge du test avance d'elle-même.
  Future<void> laisserPasser(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('le projecteur éclaire sa cible, dit quoi regarder, et se referme d\'un geste', (tester) async {
    final cible = GlobalKey();
    late BuildContext contexte;
    await tester.pumpWidget(app(Scaffold(
      body: Builder(builder: (c) {
        contexte = c;
        return SingleChildScrollView(
          child: Column(children: [
            const SizedBox(height: 1500),
            Container(key: cible, height: 80, color: Colors.red),
            const SizedBox(height: 300),
          ]),
        );
      }),
    )));
    final fini = Projecteur.eclairer(contexte, cible, 'Voici la jauge');
    await laisserPasser(tester);
    expect(find.byType(VueDuProjecteur), findsOneWidget);
    expect(find.text('Voici la jauge'), findsOneWidget);
    // La cible a été ramenée à l'écran.
    expect(tester.getRect(find.byKey(cible)).top, lessThan(800));
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byType(VueDuProjecteur), findsNothing);
    await fini;
  });

  testWidgets('la démonstration : une cave simulée, on ouvre le Bandol, sa courbe de garde', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const DemonstrationApogee(pasAPas: true)));
    await laisserPasser(tester);
    expect(find.byType(BottleCard), findsNWidgets(3));
    expect(find.textContaining('rien n\'est enregistré'), findsOneWidget);

    await tester.tap(find.byType(BottleCard).at(1));
    await laisserPasser(tester);
    expect(find.byType(GaussianDrinkingCurve), findsOneWidget);
    expect(find.text('Quand l\'ouvrir ?'), findsOneWidget);
    await tester.ensureVisible(find.text('Terminer la démonstration'));
    await tester.tap(find.text('Terminer la démonstration'));
    await laisserPasser(tester);
    expect(find.byType(DemonstrationApogee), findsNothing, reason: 'la démonstration se referme entière');
  });

  test('la légende dit ce que la courbe dessine, et c\'est plausible pour un Bandol rouge 2019', () {
    final vin = DemonstrationApogee.bandol.wine!;
    final f = GaussianDrinkingCurve.fenetreDe(vin);
    expect(f.drinkStart <= f.peakStart && f.peakStart <= f.peakEnd && f.peakEnd <= f.drinkEnd, isTrue);
    // Un Bandol rouge est un vin de garde : pas d'apogée avant cinq ans, ni après trente.
    expect(f.peakStart, greaterThanOrEqualTo(2024));
    expect(f.peakEnd, lessThanOrEqualTo(2049));
    final legende = FicheDeDemonstration.legende(vin);
    expect(legende, contains('${f.peakStart}'));
    expect(legende, contains('${f.peakEnd}'));
  });
}
