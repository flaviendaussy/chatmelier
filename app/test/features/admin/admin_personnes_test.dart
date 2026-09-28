import 'package:chatmelier/features/admin/data/admin_personnes_service.dart';
import 'package:chatmelier/features/admin/domain/admin_personnes.dart';
import 'package:chatmelier/features/admin/presentation/admin_onglets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FauxService extends Fake implements AdminPersonnesService {
  final bool modeNominatif;
  _FauxService({this.modeNominatif = true});

  @override
  Future<bool> nominatif() async => modeNominatif;

  @override
  Future<List<Personne>> personnes(int jours) async => [
        Personne.fromJson({
          'user_id': 'a',
          'prenom': 'Caro',
          'anonyme': false,
          'derniere_activite': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'plateforme': 'web',
          'version': 'dev',
          'degustations': 3,
          'scans_carte': 2,
          'messages': 4,
          'erreurs': 0,
        }),
        Personne.fromJson({
          'user_id': 'b',
          'prenom': 'Anonyme 3f2a',
          'anonyme': true,
          'derniere_activite': null,
          'degustations': 0,
        }),
        Personne.fromJson({
          'user_id': 'c',
          'prenom': 'edith',
          'derniere_activite': DateTime.now().subtract(const Duration(days: 6)).toIso8601String(),
          'bouteilles': 2,
          'erreurs': 2,
        }),
      ];

  @override
  Future<List<Usage>> usages(int jours) async => [
        Usage(jour: DateTime(2026, 9, 26), fonctionnalite: 'Scan de carte', userId: 'a', prenom: 'Caro', usages: 1),
        Usage(jour: DateTime(2026, 9, 25), fonctionnalite: 'Scan de carte', userId: 'f', prenom: 'Flavien', usages: 4),
        Usage(jour: DateTime(2026, 9, 26), fonctionnalite: 'Matchmaker', userId: 'a', prenom: 'Caro', usages: 1),
      ];
}

Widget _app(Widget enfant, {bool nominatif = true}) => ProviderScope(
      overrides: [adminPersonnesServiceProvider.overrideWithValue(_FauxService(modeNominatif: nominatif))],
      child: MaterialApp(home: Scaffold(body: Column(children: [const BandeauModeTest(), Expanded(child: enfant)]))),
    );

void main() {
  test('les fonctionnalités s\'agrègent, la plus utilisée d\'abord, avec qui', () {
    final bilans = BilanDeFonctionnalite.depuis([
      Usage(jour: DateTime(2026, 9, 26), fonctionnalite: 'Scan de carte', userId: 'a', prenom: 'Caro', usages: 1),
      Usage(jour: DateTime(2026, 9, 25), fonctionnalite: 'Scan de carte', userId: 'f', prenom: 'Flavien', usages: 4),
      Usage(jour: DateTime(2026, 9, 24), fonctionnalite: 'Scan de carte', userId: 'f', prenom: 'Flavien', usages: 1),
      Usage(jour: DateTime(2026, 9, 26), fonctionnalite: 'Matchmaker', userId: 'a', prenom: 'Caro', usages: 1),
    ]);
    expect(bilans.map((b) => b.nom), ['Scan de carte', 'Matchmaker']);
    expect(bilans.first.usages, 6);
    expect(bilans.first.parPersonne.map((e) => '${e.key}:${e.value}'), ['Flavien:5', 'Caro:1']);
  });

  testWidgets('la liste des personnes, avec le bandeau du mode test', (tester) async {
    await tester.pumpWidget(_app(const OngletPersonnes()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Mode test — données nominatives'), findsOneWidget);
    expect(find.text('Caro'), findsOneWidget);
    expect(find.textContaining('3 comptes, dont 1 anonymes'), findsOneWidget);
    expect(find.textContaining('3 dég.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'edi');
    await tester.pumpAndSettle();
    expect(find.text('Caro'), findsNothing);
    expect(find.text('edith'), findsOneWidget);
  });

  testWidgets('opacifiée, la console le dit', (tester) async {
    await tester.pumpWidget(_app(const OngletPersonnes(), nominatif: false));
    await tester.pumpAndSettle();
    expect(find.textContaining('Données opacifiées'), findsOneWidget);
  });

  testWidgets('qui utilise quoi', (tester) async {
    await tester.pumpWidget(_app(const OngletFonctionnalites()));
    await tester.pumpAndSettle();
    expect(find.text('Scan de carte'), findsOneWidget);
    expect(find.textContaining('Flavien (4)'), findsOneWidget);
  });
}
