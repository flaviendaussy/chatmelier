import 'package:chatmelier/features/journal/data/tasting_deletion_service.dart';
import 'package:chatmelier/features/journal/domain/tasting_entry.dart';
import 'package:chatmelier/features/journal/presentation/journal_screen.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/shared/l10n/fallback_localizations_delegates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supprimer une dégustation d'un geste, avec « Annuler » (V2.4 · R3).
///
/// Dimitri (04/10) voulait pouvoir supprimer vite ; il fallait ouvrir la fiche, trouver le
/// menu, confirmer. Désormais : balayer la carte vers la gauche. La suppression réelle
/// (serveur, cache, profils de goût) n'a lieu qu'une fois le bandeau refermé sans
/// « Annuler » : défaire une suppression déjà faite demanderait de rejouer ce qu'elle
/// avait appris au profil.
class _FausseSuppression implements TastingDeletionService {
  final supprimees = <String>[];

  @override
  Future<ResultatSuppression> supprimer(String tastingId) async {
    supprimees.add(tastingId);
    return const ResultatSuppression(supprimeeEnLigne: true, profilsTouches: 1, restes: []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FausseSuppression suppression;
  late List<TastingEntry> journal;

  Future<void> ouvrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    suppression = _FausseSuppression();
    journal = [
      TastingEntry(id: 't1', wineId: 'w1', wineName: 'Clio', vintage: 2023, consumedAt: DateTime(2026, 9, 30)),
      TastingEntry(id: 't2', wineId: 'w2', wineName: 'Bandol Rouge', vintage: 2019, consumedAt: DateTime(2026, 9, 12)),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Le journal relu après la suppression ne contient plus ce qui a été supprimé.
          tastingLogProvider.overrideWith(
            (ref) async => journal.where((e) => !suppression.supprimees.contains(e.id)).toList(),
          ),
          tastingDeletionServiceProvider.overrideWithValue(suppression),
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

  Future<void> balayer(WidgetTester tester, String vin) async {
    await tester.drag(find.textContaining(vin).first, const Offset(-600, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('balayer cache la dégustation, « Annuler » la rend sans rien supprimer', (tester) async {
    await ouvrir(tester);
    await balayer(tester, 'Clio');

    expect(find.textContaining('Clio (2023)'), findsNothing);
    expect(find.text('« Clio » supprimé du journal.'), findsOneWidget);
    expect(suppression.supprimees, isEmpty, reason: 'rien n\'est supprimé tant que le bandeau est là');

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Clio (2023)'), findsOneWidget);
    expect(suppression.supprimees, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sans « Annuler », la dégustation est vraiment supprimée à la fermeture du bandeau', (tester) async {
    await ouvrir(tester);
    await balayer(tester, 'Clio');

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(suppression.supprimees, ['t1']);
    expect(find.textContaining('Clio (2023)'), findsNothing);
    expect(find.textContaining('Bandol Rouge'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un second balayage valide le premier sans attendre', (tester) async {
    await ouvrir(tester);
    await balayer(tester, 'Clio');
    await balayer(tester, 'Bandol Rouge');

    expect(suppression.supprimees, ['t1'], reason: 'le premier bandeau s\'est refermé : sa suppression part');
    expect(find.text('« Bandol Rouge » supprimé du journal.'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(suppression.supprimees, ['t1']);
    expect(find.textContaining('Bandol Rouge'), findsWidgets);
  });
}
