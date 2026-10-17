import 'package:chatmelier/features/journal/domain/tasting_entry.dart';
import 'package:chatmelier/features/journal/presentation/journal_screen.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/shared/l10n/fallback_localizations_delegates.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 13/10, Flavien : « ajoute le drapeau du pays pour chaque vin […] et ajoute des filtres
/// (pays, appellation, couleur, etc...) » ; dans le Journal (16/10).
void main() {
  setUp(() => Langue.code = 'fr');

  Future<void> ouvrirLeJournal(WidgetTester tester) async {
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
                  wineName: 'Menudo',
                  producer: 'Bodegas Luzón',
                  vintage: 2021,
                  country: 'Spain',
                  wineType: 'red',
                  appellation: 'Jumilla',
                  locationName: 'Barrafina',
                  rating: 7,
                  consumedAt: DateTime(2026, 10, 16),
                ),
                TastingEntry(
                  id: 't2',
                  wineId: 'w2',
                  wineName: 'Chablis Premier Cru',
                  country: 'France',
                  wineType: 'white',
                  appellation: 'Chablis',
                  rating: 9,
                  consumedAt: DateTime(2026, 10, 12),
                ),
                TastingEntry(
                  id: 't3',
                  wineId: 'w3',
                  wineName: 'Bandol Rouge',
                  vintage: 2019,
                  country: 'France',
                  wineType: 'red',
                  appellation: 'Bandol',
                  consumedAt: DateTime(2026, 10, 2),
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
  }

  testWidgets('chaque vin porte son drapeau et son pays dans la langue de l\'écran', (tester) async {
    await ouvrirLeJournal(tester);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('🇪🇸 Menudo'), findsOneWidget);
    expect(find.textContaining('🇫🇷 Bandol Rouge'), findsOneWidget);
    // « Spain » écrit par le scan, « Espagne » à l'écran.
    expect(find.textContaining('Jumilla • Espagne'), findsOneWidget);
    expect(find.textContaining('Spain'), findsNothing);
    // Un millésime inconnu n'est pas un « non millésimé ».
    expect(find.textContaining('(NV)'), findsNothing);
  });

  testWidgets('filtrer par pays, voir ce qui reste, retirer le filtre d\'un geste', (tester) async {
    await ouvrirLeJournal(tester);
    await tester.tap(find.byKey(const ValueKey('journal-filtres')));
    await tester.pumpAndSettle();

    expect(find.text('Filtrer le journal'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('filtre-pays-ES')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir 1 dégustation'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Menudo'), findsOneWidget);
    expect(find.textContaining('Chablis Premier Cru'), findsNothing);
    expect(find.text('Filtres · 1'), findsOneWidget);
    expect(find.text('1 dégustation sur 3'), findsOneWidget);

    // La pastille du filtre choisi, qu'on retire d'un geste.
    final pastille = find.widgetWithText(InputChip, '🇪🇸 Espagne');
    expect(pastille, findsOneWidget);
    await tester.tap(find.descendant(of: pastille, matching: find.byTooltip('Retirer ce filtre')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chablis Premier Cru'), findsOneWidget);
    expect(find.text('Filtres'), findsOneWidget);
  });

  testWidgets('couleur et note se combinent ; « Coups de cœur » est la note d\'au moins 8', (tester) async {
    await ouvrirLeJournal(tester);
    await tester.tap(find.byKey(const ValueKey('journal-filtres')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filtre-couleur-rouge')));
    await tester.pumpAndSettle();
    // Parmi les rouges, aucun n'atteint 8 : le seuil le dit avant qu'on le choisisse.
    final huit = find.byKey(const ValueKey('filtre-note-8'));
    expect(find.descendant(of: huit, matching: find.textContaining('0')), findsOneWidget);
    await tester.tap(find.text('Tout effacer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir les 3 dégustations'));
    await tester.pumpAndSettle();

    // La rangée défile : le raccourci est hors de l'écran depuis l'arrivée de « Filtres ».
    await tester.ensureVisible(find.text('Coups de Cœur (≥ 8/10)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coups de Cœur (≥ 8/10)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chablis Premier Cru'), findsOneWidget);
    expect(find.textContaining('Menudo'), findsNothing);
    expect(find.widgetWithText(InputChip, 'Note ≥ 8/10'), findsOneWidget);
  });
}
