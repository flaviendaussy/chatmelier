import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/presentation/taste_profile_edit_sheet.dart';
import 'package:chatmelier/features/cellar/domain/cellar_filter_state.dart';
import 'package:chatmelier/features/cellar/presentation/cellar_filter_sheet.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:chatmelier/shared/utils/valeurs_rangees.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les valeurs rangées en français, lues dans la langue de l'écran (V2.3 · H8).
void main() {
  tearDown(() => Langue.code = 'fr');

  test('la valeur rangée se lit dans la langue de l\'écran ; l\'inconnue telle quelle', () {
    Langue.code = 'es';
    expect(valeurAffichee('Bourgogne'), 'Borgoña');
    expect(valeurAffichee('Rouge'), 'Tinto');
    expect(valeurAffichee('Trop tannique'), 'Demasiado tánico');
    expect(valeurAffichee('Amériques'), 'Américas');
    expect(valeurAffichee('Clos des Papes'), 'Clos des Papes', reason: 'une saisie libre ne se traduit pas');
    Langue.code = 'en';
    expect(valeurAffichee('Vallée du Rhône'), 'Rhône Valley');
    expect(valeurAffichee('Bulles'), 'Sparkling');
    Langue.code = 'fr';
    expect(valeurAffichee('Bourgogne'), 'Bourgogne');
  });

  // Des mots que seul le français affiche : aucun ne doit rester sur un écran en espagnol.
  const temoins = ['Bourgogne', 'Vallée', 'Rouge', 'Trop ', 'Tanins', 'Moelleux', 'Vins ', 'Italie', 'Espagne', 'Amériques'];

  Future<void> enEspagnol(WidgetTester tester, Widget ecran) async {
    Langue.code = 'es';
    tester.view.physicalSize = const Size(1600, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ecran),
      ),
    ));
    await tester.pumpAndSettle();
  }

  List<String> textesFrancais(WidgetTester tester) => [
        for (final t in tester.widgetList<Text>(find.byType(Text)))
          if (temoins.any((m) => (t.data ?? t.textSpan?.toPlainText() ?? '').contains(m)))
            t.data ?? t.textSpan!.toPlainText(),
      ];

  testWidgets('l\'éditeur du profil, en espagnol, ne montre aucune valeur en français', (tester) async {
    await enEspagnol(
      tester,
      const TasteProfileEditSheet(
        profile: TasteProfile(
          id: 'moi',
          name: 'Lucía',
          isPrimary: true,
          favoriteTypes: ['Rouge', 'Rouge puissant & structuré'],
          favoriteRegions: ['Bourgogne', 'Vallée du Rhône'],
          dislikedCharacteristics: ['Trop tannique'],
        ),
      ),
    );

    expect(find.text('Borgoña'), findsOneWidget);
    expect(find.text('Tinto potente y estructurado'), findsOneWidget);
    expect(textesFrancais(tester), isEmpty);
  });

  testWidgets('le filtre de la cave, en espagnol : pays et continents traduits', (tester) async {
    await enEspagnol(
      tester,
      CellarFilterSheet(initialFilter: const CellarFilterState(), onApply: (_) {}),
    );

    expect(find.text('Continente'), findsOneWidget);
    expect(find.text('Italia'), findsOneWidget);
    expect(find.text('Américas'), findsOneWidget);
    expect(textesFrancais(tester), isEmpty);
  });
}
