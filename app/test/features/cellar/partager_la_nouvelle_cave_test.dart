import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:chatmelier/features/cellar/data/cellar_repository.dart';
import 'package:chatmelier/features/cellar/domain/cellar.dart';
import 'package:chatmelier/features/cellar/presentation/create_cellar_dialog.dart';
import 'package:chatmelier/features/offline/presentation/sync_provider.dart';
import 'package:chatmelier/shared/providers/cellar_provider.dart';

/// Une cave créée sans toucher au serveur.
class _DepotFactice extends CellarRepository {
  _DepotFactice() : super(SupabaseClient('http://localhost:1', 'cle-de-test'));

  @override
  Future<Cellar> createCellar({
    required String name,
    String? nickname,
    String? locationName,
    String? description,
    double? latitude,
    double? longitude,
    String? wifiSsid,
    int radiusMeters = 300,
  }) async =>
      Cellar(id: 'cave-1', name: name, ownerId: 'moi', createdAt: DateTime(2026, 10, 17));
}

/// 16/10 : « quand quelqu'un déclare une cave, il faudrait leur demander s'ils veulent la
/// partager avec quelqu'un, et leur dire qu'ils peuvent quand même le faire après ».
void main() {
  // Hors de l'horloge du test : le client factice lance un minuteur qui ne s'arrête pas.
  final depot = _DepotFactice();

  Future<String?> creer(WidgetTester tester, {required bool partager}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    String? ouvert;
    final routeur = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog(context: context, builder: (_) => const CreateCellarDialog()),
            child: const Text('nouvelle cave'),
          ),
        ),
      ),
      GoRoute(path: '/sharing/:id', builder: (_, etat) {
        ouvert = etat.uri.toString();
        return const Scaffold(body: Text('Partages'));
      }),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        cellarRepositoryProvider.overrideWithValue(depot),
        sharedPreferencesInstanceProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp.router(routerConfig: routeur, locale: const Locale('fr')),
    ));
    await tester.tap(find.text('nouvelle cave'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Maison');
    await tester.tap(find.text('Créer la cave'));
    await tester.pumpAndSettle();

    expect(find.text('Cave « Maison » créée'), findsOneWidget);
    expect(find.textContaining('Partages & Accès'), findsOneWidget, reason: 'on peut toujours le faire après');
    await tester.tap(find.text(partager ? 'Partager' : 'Plus tard'));
    await tester.pumpAndSettle();
    expect(find.text('Cave « Maison » créée'), findsNothing);
    return ouvert;
  }

  testWidgets('« Partager » ouvre les partages de la nouvelle cave', (tester) async {
    expect(await creer(tester, partager: true), '/sharing/cave-1?name=Maison');
  });

  testWidgets('« Plus tard » ferme sans rien ouvrir', (tester) async {
    expect(await creer(tester, partager: false), isNull);
  });
}
