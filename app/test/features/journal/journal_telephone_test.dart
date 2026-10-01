import 'package:chatmelier/features/journal/domain/tasting_entry.dart';
import 'package:chatmelier/features/journal/presentation/journal_screen.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/shared/l10n/fallback_localizations_delegates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le journal sur un téléphone, avec des dégustations (01/10).
///
/// Un `Spacer` ajouté pour la grille de la tablette (cartes de hauteur fixe) se retrouvait
/// dans la liste du téléphone, où la hauteur n'est pas bornée : la mise en page échouait
/// et, en debug, l'onglet entier restait vide. Aucun test ne construisait la liste.
void main() {
  testWidgets('la liste des dégustations s\'affiche sans erreur de mise en page', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tastingLogProvider.overrideWith((ref) async => [
                TastingEntry(
                  id: 't1',
                  wineId: 'w1',
                  wineName: 'Clio',
                  vintage: 2023,
                  consumedAt: DateTime(2026, 9, 30),
                  tastingNotes: 'Puissant, fruits noirs, tanins mûrs.',
                ),
                TastingEntry(
                  id: 't2',
                  wineId: 'w2',
                  wineName: 'Bandol Rouge',
                  vintage: 2019,
                  consumedAt: DateTime(2026, 9, 12),
                ),
              ]),
        ],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: kAppLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: JournalScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Clio'), findsWidgets);
    expect(find.textContaining('Bandol Rouge'), findsWidgets);
  });
}
