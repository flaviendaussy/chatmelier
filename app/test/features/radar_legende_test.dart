import 'package:chatmelier/features/auth/presentation/widgets/radar_legende.dart';
import 'package:chatmelier/features/auth/presentation/widgets/wine_taste_radar_chart.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le radar dit ce qu'il sait (29/09) : la légende nomme les trois tracés, dans la
/// langue de l'écran, et un radar mi-observé mi-deviné se dessine sans erreur.
void main() {
  Widget ecran(Locale locale, Widget enfant) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: enfant)),
      );

  testWidgets('la légende en français', (tester) async {
    await tester.pumpWidget(ecran(const Locale('fr'), const LegendeDuRadar()));
    await tester.pumpAndSettle();
    expect(find.text('Observé'), findsOneWidget);
    expect(find.text('Deviné'), findsOneWidget);
    expect(find.text("Marge d'incertitude"), findsOneWidget);
  });

  testWidgets('la légende en anglais', (tester) async {
    await tester.pumpWidget(ecran(const Locale('en'), const LegendeDuRadar()));
    await tester.pumpAndSettle();
    expect(find.text('Observed'), findsOneWidget);
    expect(find.text('Guessed'), findsOneWidget);
    expect(find.text('Uncertainty'), findsOneWidget);
  });

  testWidgets('un radar mi-observé, mi-deviné se dessine', (tester) async {
    await tester.pumpWidget(ecran(
      const Locale('fr'),
      const SizedBox(
        width: 260,
        height: 190,
        child: WineTasteRadarChart(datasets: [
          RadarChartDataset(
            label: 'Moi',
            color: Color(0xFF8B1E3F),
            customValues: [7, 6, 4, 6, 5, 7, 6, 7],
            confidences: [0.8, 0.5, 0.0, 0.17, 0.0, 0.67, 0.3, 0.9],
          ),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('le compte de dégustations par axe se décline', (tester) async {
    late AppLocalizations fr;
    await tester.pumpWidget(ecran(const Locale('fr'), Builder(builder: (context) {
      fr = AppLocalizations.of(context)!;
      return const SizedBox();
    })));
    expect(fr.radarAxisTastings(0), 'Deviné');
    expect(fr.radarAxisTastings(1), '1 dégustation');
    expect(fr.radarAxisTastings(12), '12 dégustations');
  });
}
