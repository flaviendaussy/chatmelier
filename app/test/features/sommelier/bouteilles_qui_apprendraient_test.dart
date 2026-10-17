import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/auth/presentation/widgets/bouteilles_qui_apprendraient.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/shared/providers/cellar_provider.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 11/10, Flavien : « savoir vite quelles bouteilles en cave pourraient améliorer les axes
/// encore inconnus » (F3) ; et à deux, « pour mieux vous connaître tous les deux » (F2).
void main() {
  setUp(() => Langue.code = 'fr');

  final annee = DateTime.now().year;
  Bottle bouteille(String id, String nom, String type, {List<String> cepages = const [], String? appellation,
          String? elevage, bool prete = true, int quantite = 1, double? alcool}) =>
      Bottle(
        id: id,
        cellarId: 'cave',
        wineId: 'w$id',
        addedBy: 'moi',
        ownerId: 'moi',
        quantity: quantite,
        createdAt: DateTime(2026),
        wine: Wine(
          id: 'w$id',
          name: nom,
          vintage: annee - 6,
          type: type,
          country: 'France',
          region: '',
          appellation: appellation,
          grapes: [for (final c in cepages) Grape(name: c)],
          elevageType: elevage,
          alcoholPct: alcool,
          // Prête : à son apogée cette année ; sinon, en garde pour dix ans.
          drinkStart: prete ? annee - 3 : annee + 4,
          peakStart: prete ? annee - 1 : annee + 8,
          peakEnd: prete ? annee + 2 : annee + 14,
          drinkEnd: prete ? annee + 4 : annee + 20,
        ),
      );

  final cave = [
    bouteille('b1', 'Bandol', 'red', cepages: ['Mourvèdre'], appellation: 'Bandol'),
    bouteille('b2', 'Chablis', 'white', cepages: ['Chardonnay'], appellation: 'Chablis'),
    bouteille('b3', 'Meursault', 'white', appellation: 'Meursault', elevage: 'fût neuf'),
    // En garde : jamais proposée ; bue : plus là.
    bouteille('b4', 'Barolo', 'red', cepages: ['Nebbiolo'], appellation: 'Barolo', prete: false),
    bouteille('b5', 'Madiran', 'red', cepages: ['Tannat'], appellation: 'Madiran', quantite: 0),
    // Un porto est ample par son alcool : il ne dit rien d'un palais de vins secs (17/10).
    bouteille('b6', 'Velhotes 10 Anos Tawny Porto', 'fortified', alcool: 20),
    bouteille('b7', 'Sauternes', 'dessert', appellation: 'Sauternes', alcool: 14.5),
  ];

  Widget ecran(Widget enfant) => ProviderScope(
        overrides: [
          currentCellarIdProvider.overrideWith((ref) => _Cave('cave')),
          bottlesProvider.overrideWith((ref, id) async => cave),
        ],
        child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: enfant))),
      );

  testWidgets('votre radar : axe par axe, la bouteille prête à boire qui le trancherait', (tester) async {
    const moi = TasteProfile(id: 'moi', name: 'Moi', isPrimary: true, axisObservations: {'tannin': 2});
    await tester.pumpWidget(ecran(const BouteillesQuiApprendraient(profil: moi, couleur: Colors.red)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Les bouteilles de votre cave qui m\'apprendraient le plus'), findsOneWidget);
    expect(find.textContaining('Votre Meursault ${annee - 6}, nettement boisé'), findsOneWidget);
    expect(find.textContaining('Votre Bandol ${annee - 6}, très charpenté'), findsWidgets);
    expect(find.textContaining('Votre Chablis ${annee - 6}'), findsWidgets);
    expect(find.textContaining('jamais goûté'), findsWidgets);
    expect(find.textContaining('deviné · 2 dégustations'), findsOneWidget);
    // Le Barolo est en garde, le Madiran bu : ni l'un ni l'autre.
    expect(find.textContaining('Barolo'), findsNothing);
    expect(find.textContaining('Madiran'), findsNothing);
    expect(find.textContaining('Porto'), findsNothing);
    expect(find.textContaining('Sauternes'), findsNothing);
  });

  testWidgets('à deux : ce que Caro et vous ignorez, et la bouteille qui le dirait pour les deux', (tester) async {
    const moi = TasteProfile(
        id: 'moi', name: 'Moi', isPrimary: true, axisObservations: {'tannin': 12, 'body': 12, 'acidity': 12, 'minerality': 12});
    const caro = TasteProfile(
        id: 'caro', name: 'Caro', axisObservations: {'tannin': 12, 'body': 12, 'acidity': 12, 'minerality': 12});
    await tester.pumpWidget(ecran(const PourVousConnaitreTousLesDeux(a: moi, b: caro)));
    await tester.pumpAndSettle();
    expect(find.text('🧭 Pour mieux vous connaître tous les deux'), findsOneWidget);
    expect(
        find.text('Je ne sais pas encore ce que Caro et vous pensez du boisé. '
            'Votre Meursault ${annee - 6}, nettement boisé et prêt à boire, me le dirait pour vous deux.'),
        findsOneWidget);
  });

  testWidgets('un palais déjà connu sur tout ce que la cave sait trancher : rien à proposer', (tester) async {
    const connu = TasteProfile(id: 'moi', name: 'Moi', isPrimary: true, axisObservations: {
      'tannin': 12, 'body': 12, 'oak': 12, 'acidity': 12, 'minerality': 12,
    });
    await tester.pumpWidget(ecran(const BouteillesQuiApprendraient(profil: connu, couleur: Colors.red)));
    await tester.pumpAndSettle();
    expect(find.textContaining('m\'apprendraient'), findsNothing);
  });
}

class _Cave extends StateNotifier<String?> implements CurrentCellarNotifier {
  _Cave(super.state);

  @override
  void selectCellar(String? cellarId) => state = cellarId;
}
