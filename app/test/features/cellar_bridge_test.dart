import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/cellar/domain/cellar_gap_engine.dart';
import 'package:chatmelier/features/menu_scan/domain/cellar_bridge.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';

/// Le pont entre la cave et le restaurant.
///
/// `menu_scan` ne contenait aucune référence à la cave ni au journal : les deux moitiés
/// du produit s'ignoraient. C'est pourtant la phrase que ni Vivino ni CellarTracker ne
/// peuvent produire — ils savent ce que le monde pense d'un vin, pas ce que VOUS en avez
/// pensé, ni ce que vous l'avez payé le mois dernier.
///
/// Le risque assumé est l'inverse de l'habituel : rater un rapprochement ne coûte qu'une
/// occasion ; en inventer un dit à quelqu'un qu'il a bu un vin qu'il n'a jamais ouvert.
void main() {
  MenuWine carteVin(
    String nom, {
    String? producteur,
    double? prix,
    String? appellation,
    String? region,
  }) =>
      MenuWine(
        id: nom,
        name: nom,
        producer: producteur ?? '',
        wineType: 'Rouge',
        bottlePrice: prix,
        appellation: appellation,
        region: region,
      );

  LienAvecMaCave? lien(MenuWine v, ContexteDeCave c) =>
      CellarBridgeEngine.lier([v], c).first.pontDeCave;

  group('📓 Vous connaissez ce vin', () {
    test('un vin déjà goûté est reconnu par son domaine, et la note revient', () {
      final l = lien(
        carteVin('Bandol Rouge', producteur: 'Domaine de Terrebrune', prix: 78),
        ContexteDeCave(journal: [
          VinDejaGoute(
            nom: 'Bandol',
            producteur: 'Domaine de Terrebrune',
            note: 8.5,
            quand: DateTime(2026, 3, 12),
          ),
        ]),
      );
      expect(l?.type, equals(TypeDeLien.dejaGoute));
      expect(l?.detail, contains('8.5/10'));
      expect(l?.detail, contains('mars 2026'));
    });

    test('le millésime ne bloque pas le rapprochement', () {
      // Avoir goûté le 2019 dit quelque chose d'utile sur le 2020 ; l'exiger ferait rater
      // presque tous les rapprochements.
      final l = lien(
        carteVin('Bandol', producteur: 'Terrebrune'),
        const ContexteDeCave(journal: [
          VinDejaGoute(nom: 'Bandol', producteur: 'Terrebrune', millesime: 2019),
        ]),
      );
      expect(l?.type, equals(TypeDeLien.dejaGoute));
    });

    test('un autre domaine dans la même appellation N\'EST PAS le même vin', () {
      final l = lien(
        carteVin('Bandol Rouge', producteur: 'Château Pradeaux'),
        const ContexteDeCave(journal: [
          VinDejaGoute(nom: 'Bandol Rouge', producteur: 'Domaine de Terrebrune', note: 9),
        ]),
      );
      expect(l, isNull,
          reason: 'affirmer qu\'on a bu un vin qu\'on n\'a pas ouvert détruit la confiance');
    });

    test('un seul mot commun ne suffit pas', () {
      // « Bandol Rouge » et « Bandol Rosé » partagent « bandol » et ne sont pas le même vin.
      final l = lien(
        carteVin('Bandol Rouge'),
        const ContexteDeCave(journal: [VinDejaGoute(nom: 'Bandol Rosé')]),
      );
      expect(l, isNull);
    });

    test('deux mots significatifs suffisent, sans producteur', () {
      final l = lien(
        carteVin('Gevrey-Chambertin les Platières'),
        const ContexteDeCave(
            journal: [VinDejaGoute(nom: 'Gevrey Chambertin Platières 2021')]),
      );
      expect(l?.type, equals(TypeDeLien.dejaGoute));
    });

    test('les mots creux ne comptent pas comme correspondance', () {
      // « Domaine », « Château », « Vieilles Vignes », « Rouge » : présents partout.
      final l = lien(
        carteVin('Château Vieilles Vignes Rouge'),
        const ContexteDeCave(
            journal: [VinDejaGoute(nom: 'Domaine des Vieilles Vignes Rouge')]),
      );
      expect(l, isNull);
    });
  });

  group('🏠 Vous en avez chez vous', () {
    test('le prix payé est rappelé, et l\'écart calculé', () {
      final l = lien(
        carteVin('Bandol', producteur: 'Terrebrune', prix: 78),
        const ContexteDeCave(cave: [
          VinDeMaCave(nom: 'Bandol Rouge', producteur: 'Terrebrune', prixAchat: 30),
        ]),
      );
      expect(l?.type, equals(TypeDeLien.enCave));
      expect(l?.detail, contains('30 €'));
      expect(l?.detail, contains('48 €'),
          reason: '78 − 30 : c\'est l\'écart qui fait réfléchir, pas le prix seul');
    });

    test('sans prix d\'achat, on dit simplement qu\'on en a', () {
      final l = lien(
        carteVin('Bandol', producteur: 'Terrebrune', prix: 78),
        const ContexteDeCave(cave: [
          VinDeMaCave(nom: 'Bandol', producteur: 'Terrebrune', quantite: 3),
        ]),
      );
      expect(l?.detail, contains('3 en cave'));
    });

    test('avoir goûté prime sur avoir en cave', () {
      // Un jugement déjà formé tranche une hésitation mieux qu'un inventaire.
      final l = lien(
        carteVin('Bandol', producteur: 'Terrebrune'),
        const ContexteDeCave(
          cave: [VinDeMaCave(nom: 'Bandol', producteur: 'Terrebrune')],
          journal: [VinDejaGoute(nom: 'Bandol', producteur: 'Terrebrune', note: 8)],
        ),
      );
      expect(l?.type, equals(TypeDeLien.dejaGoute));
    });
  });

  group('🧩 Comblerait un manque', () {
    CellarGapAnalysis lacune(List<String> appellations) => CellarGapAnalysis(
          totalBottles: 20,
          redRatio: 0.9,
          whiteRatio: 0.1,
          roseRatio: 0,
          sparklingRatio: 0,
          readyToDrinkCount: 5,
          inAgingCount: 15,
          pastPeakCount: 0,
          gaps: [
            CellarGapCategory(
              title: 'Blancs',
              status: 'critical',
              diagnosis: 'Presque aucun blanc',
              sommelierAdvice: 'Ouvrez-vous aux blancs de garde',
              recommendedAppellations: appellations,
            ),
          ],
          shoppingWishlist: const [],
        );

    test('un vin d\'une appellation manquante est signalé', () {
      final l = lien(
        carteVin('Chablis Premier Cru', appellation: 'Chablis'),
        ContexteDeCave(lacunes: lacune(['Chablis', 'Sancerre'])),
      );
      expect(l?.type, equals(TypeDeLien.combleUneLacune));
    });

    test('le conseil est rationné à deux par carte', () {
      // Deux suggestions éclairent ; huit deviennent un bruit qu'on cesse de lire.
      final vins = [
        for (var i = 0; i < 6; i++)
          carteVin('Chablis numéro $i', appellation: 'Chablis'),
      ];
      final lies = CellarBridgeEngine.lier(
          vins, ContexteDeCave(lacunes: lacune(['Chablis'])));
      final n = lies
          .where((v) => v.pontDeCave?.type == TypeDeLien.combleUneLacune)
          .length;
      expect(n, equals(2));
    });

    test('une catégorie équilibrée ne produit aucun conseil', () {
      final equilibre = CellarGapAnalysis(
        totalBottles: 20,
        redRatio: 0.5, whiteRatio: 0.5, roseRatio: 0, sparklingRatio: 0,
        readyToDrinkCount: 10, inAgingCount: 10, pastPeakCount: 0,
        gaps: const [
          CellarGapCategory(
            title: 'Blancs',
            status: 'balanced',
            diagnosis: 'Bien fourni',
            sommelierAdvice: '',
            recommendedAppellations: ['Chablis'],
          ),
        ],
        shoppingWishlist: const [],
      );
      final l = lien(carteVin('Chablis', appellation: 'Chablis'),
          ContexteDeCave(lacunes: equilibre));
      expect(l, isNull);
    });
  });

  group('🤫 Sans rien à dire, on ne dit rien', () {
    test('un contexte vide ne pose aucun lien', () {
      final vins = [carteVin('Bandol'), carteVin('Chablis')];
      final lies = CellarBridgeEngine.lier(vins, const ContexteDeCave());
      expect(lies.every((v) => v.pontDeCave == null), isTrue);
    });

    test('un vin inconnu de la cave reste muet', () {
      final l = lien(
        carteVin('Barolo', producteur: 'Giacomo Conterno'),
        const ContexteDeCave(
          cave: [VinDeMaCave(nom: 'Bandol', producteur: 'Terrebrune')],
          journal: [VinDejaGoute(nom: 'Chablis', producteur: 'Laroche')],
        ),
      );
      expect(l, isNull);
    });
  });
}
