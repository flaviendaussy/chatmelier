import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/presentation/enriched_menu_screen.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 13/10, Flavien : « ça m'affiche "taillé pour vous". je devrais pouvoir cliquer sur chaque
/// vin pour savoir pourquoi un vin est taillé pour moi ou pas, voir son spider vs le mien,
/// voir ses détails, etc ».
void main() {
  setUp(() => Langue.code = 'fr');

  final palais = TasteProfile(
    id: 'moi',
    name: 'Moi',
    isPrimary: true,
    favoriteTypes: const ['Rouge'],
    favoriteRegions: const ['Bourgogne'],
    favoriteGrapes: const ['Pinot Noir'],
    dislikedCharacteristics: const ['Trop boisé'],
    // Un palais des rouges bien établi (V2.6), proche du Volnay.
    palais: const {
      'rouge': {'tannin': 0.45, 'body': 0.55, 'acidity': 0.5, 'oak': 0.4, 'sweetness': 0.05},
    },
    observationsPalais: const {
      'rouge': {'tannin': 20, 'body': 20, 'acidity': 20, 'oak': 20, 'sweetness': 20},
    },
  );

  ScannedMenu carte({double scoreDuVolnayAuScan = 99}) => ScannedMenu(
        id: 'c',
        restaurantName: 'Chez Robin',
        scannedAt: DateTime(2026, 10, 13),
        pagePhotoPaths: const [],
        currency: 'EUR',
        wines: [
          MenuWine(
            id: 'volnay',
            name: 'Volnay',
            producer: 'Domaine de Montille',
            vintage: 2020,
            wineType: 'red',
            appellation: 'Volnay',
            region: 'Bourgogne',
            country: 'France',
            grapes: const ['Pinot Noir'],
            bottlePrice: 68,
            metrics: const MenuWineRadarMetrics(tannins: 4.5, body: 5.5, oak: 4),
            userMatchScore: scoreDuVolnayAuScan,
            flag: const MenuWineFlag(
                type: MenuWineFlagType.tasteMatch, label: 'Match Profil 99%', reason: 'Très proche de vos goûts'),
          ),
          const MenuWine(
            id: 'madiran',
            name: 'Madiran',
            producer: 'Château Montus',
            vintage: 2016,
            wineType: 'red',
            appellation: 'Madiran',
            region: 'Sud-Ouest',
            country: 'France',
            grapes: ['Tannat'],
            bottlePrice: 72,
            metrics: MenuWineRadarMetrics(tannins: 9.5, body: 9, oak: 8.5),
            userMatchScore: 61,
          ),
        ],
      );

  Future<void> ouvrir(WidgetTester tester, ScannedMenu menu) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [tasteProfilesListProvider.overrideWith((ref) async => [palais])],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('fr'), Locale('en')],
        home: EnrichedMenuScreen(menu: menu),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('toucher un vin : pourquoi il ne vous va pas, son profil face au vôtre, ses détails', (tester) async {
    await ouvrir(tester, carte());
    await tester.tap(find.text('Madiran').first);
    await tester.pumpAndSettle();

    expect(find.text('POUR VOUS'), findsOneWidget);
    expect(find.text('46 %'), findsOneWidget);
    expect(find.text('Loin de vos goûts'), findsOneWidget);
    expect(find.text('Un boisé marqué, que vous n\'aimez pas'), findsOneWidget);
    expect(find.text('−25'), findsOneWidget);
    expect(find.text('Vous aimez les rouges'), findsOneWidget);
    expect(find.text('SON PROFIL FACE AU VÔTRE'), findsOneWidget);
    expect(find.text('Tannat'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Le retenir pour le comparatif, depuis la fiche : la case de la carte suit.
    await tester.tap(find.text('Ajouter au comparatif'));
    await tester.pumpAndSettle();
    expect(find.text('Retenu pour le comparatif'), findsOneWidget);
    Navigator.of(tester.element(find.text('POUR VOUS'))).pop();
    await tester.pumpAndSettle();
    expect(tester.widgetList<Checkbox>(find.byType(Checkbox)).where((c) => c.value == true), hasLength(1));
  });

  testWidgets('taillé pour vous : la somme dépasse 99 %, et la fiche le dit', (tester) async {
    await ouvrir(tester, carte());
    await tester.tap(find.text('Volnay').first);
    await tester.pumpAndSettle();
    expect(find.text('99 %'), findsOneWidget);
    expect(find.text('Taillé pour vous'), findsOneWidget);
    expect(find.text('Bourgogne, l\'une de vos régions préférées'), findsOneWidget);
    expect(find.textContaining('La somme dépasse 99 %'), findsOneWidget);
    expect(find.textContaining('Au moment du scan'), findsNothing);
  });

  testWidgets('un palais qui a changé depuis le scan : le pourcentage d\'aujourd\'hui, et celui d\'alors', (tester) async {
    await ouvrir(tester, carte(scoreDuVolnayAuScan: 90));
    await tester.tap(find.text('Volnay').first);
    await tester.pumpAndSettle();
    expect(find.text('99 %'), findsOneWidget);
    expect(find.textContaining('Au moment du scan, il était à 90 %'), findsOneWidget);
  });
}
