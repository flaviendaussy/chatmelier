import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/journal/data/degustation_rapide.dart';
import 'package:chatmelier/features/menu_scan/data/table_session_service.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:chatmelier/features/menu_scan/presentation/comptoir_screen.dart';
import 'package:chatmelier/features/sommelier/domain/guest_matcher_engine.dart';
import 'package:chatmelier/l10n/app_localizations.dart';
import 'package:chatmelier/shared/providers/auth_provider.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _morgon = MenuWine(
  id: 'm',
  name: 'Morgon',
  producer: 'Foillard',
  vintage: 2022,
  wineType: 'red',
  glassPrices: [MenuWineGlassPrice(format: 'verre', price: 9)],
);
const _muscadet = MenuWine(
  id: 'u',
  name: 'Muscadet',
  producer: 'L\'Écu',
  vintage: 2023,
  wineType: 'white',
  glassPrices: [MenuWineGlassPrice(format: '12cl', price: 7)],
);
final _ardoise = ScannedMenu(
  id: 'ardoise',
  restaurantName: 'Le Bar à Vins',
  scannedAt: DateTime(2026, 10, 2),
  pagePhotoPaths: const [],
  wines: const [_morgon, _muscadet],
  currency: 'EUR',
  ardoise: true,
);

/// Le comptoir côté serveur : Paul y a déjà noté le Morgon.
class _FauxComptoir extends Fake implements TableSessionService {
  final profils = <GuestProfile?>[];
  List<GuestProfile> aTable = [
    GuestProfile(id: 'Paul', name: 'Paul', verres: {_morgon.cacheKey: 9.5}),
  ];

  @override
  Future<TableOuverte> ouvrir({required String restaurantName, required ScannedMenu menu}) async =>
      TableOuverte(sessionId: 'session', code: 'BAR123', expireLe: DateTime(2030));

  @override
  Future<TableRejointe> rejoindre({required String code, required String nom, GuestProfile? profil}) async {
    profils.add(profil);
    aTable = [
      for (final g in aTable)
        if (g.name != nom) g,
      GuestProfile.fromJson(nom, {...?profil?.toJson(), 'name': nom}),
    ];
    return TableRejointe(sessionId: 'session', menu: _ardoise, expireLe: DateTime(2030));
  }

  @override
  Future<List<GuestProfile>?> lireConvives(String code) async => aTable;
}

class _FausseDegustation extends Fake implements DegustationRapide {
  VinBuDehors? recu;

  @override
  Future<({String id, bool enLigne})> enregistrer(VinBuDehors v) async {
    recu = v;
    return (id: 'degustation', enLigne: true);
  }
}

/// Le comptoir à plusieurs (V2.3 · J4), vu par celui qui l'ouvre.
void main() {
  setUp(() {
    Langue.code = 'fr';
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ouvrir le comptoir, noter un verre d\'un geste, et voir qui a aimé quoi', (tester) async {
    tester.view.physicalSize = const Size(1600, 3600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final comptoir = _FauxComptoir();
    final degustation = _FausseDegustation();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        tableSessionServiceProvider.overrideWithValue(comptoir),
        degustationRapideProvider.overrideWithValue(degustation),
        tasteProfilesListProvider.overrideWith((ref) async => const [TasteProfile(id: 'moi', name: 'Léa', isPrimary: true)]),
        currentUserProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ComptoirScreen(ardoise: _ardoise),
      ),
    ));
    await tester.pumpAndSettle();

    // Le comptoir est ouvert, l'hôte s'y est assis sous son prénom.
    expect(find.textContaining('BAR123'), findsWidgets);
    expect(comptoir.profils.single?.name, 'Léa');
    expect(find.text('😍 Paul'), findsOneWidget, reason: 'la note de Paul est visible sur le Morgon');

    // Noter le Morgon d'un geste.
    await tester.tap(find.text('Le noter d\'un geste').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('😊').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(degustation.recu?.nom, 'Morgon', reason: 'la note entre au journal');
    expect(degustation.recu?.lieu, 'Le Bar à Vins');
    expect(comptoir.profils.last?.verres, {_morgon.cacheKey: 8.0}, reason: 'et part au comptoir avec le profil');
    expect(find.text('Qui a aimé quoi'), findsOneWidget);
    expect(find.textContaining('Le préféré du comptoir : Morgon 2022'), findsOneWidget);
  });
}
