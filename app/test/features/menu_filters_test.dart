import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';

/// Séparer ce que le sommelier remarque de ce qu'on peut se payer.
///
/// Un seul interrupteur « Pépites & Bons plans » fusionnait les deux, ce qui est
/// exactement à l'envers du besoin : une pépite est une cuvée rare qu'on accepte de
/// payer cher, un bon plan une bouteille au prix juste. Qui cherche l'une ne cherche pas
/// l'autre — et le filtre budget, lui, existait dans la logique sans aucune interface.
void main() {
  MenuWine vin(String nom, {double? prix, MenuWineFlagType? drapeau}) => MenuWine(
        id: nom,
        name: nom,
        producer: 'Domaine $nom',
        wineType: 'Rouge',
        bottlePrice: prix,
        flag: drapeau == null
            ? null
            : MenuWineFlag(type: drapeau, label: drapeau.name),
      );

  group('🏷️ Les deux natures ne se confondent pas', () {
    final carte = [
      vin('A', prix: 30, drapeau: MenuWineFlagType.deal),
      vin('B', prix: 180, drapeau: MenuWineFlagType.gem),
      vin('C', prix: 55, drapeau: MenuWineFlagType.tasteMatch),
      vin('D', prix: 40),
    ];

    test('filtrer sur les bons plans ne rend pas les pépites', () {
      final r = carte.where((w) => w.flag?.type == MenuWineFlagType.deal).toList();
      expect(r.map((w) => w.name), equals(['A']));
    });

    test('filtrer sur les pépites ne rend pas les bons plans', () {
      final r = carte.where((w) => w.flag?.type == MenuWineFlagType.gem).toList();
      expect(r.map((w) => w.name), equals(['B']));
    });

    test('un vin sans drapeau n\'apparaît sous aucun des deux', () {
      for (final t in MenuWineFlagType.values) {
        expect(carte.where((w) => w.flag?.type == t).map((w) => w.name),
            isNot(contains('D')));
      }
    });
  });

  group('💶 Les plafonds viennent de la carte, pas d\'une table fixe', () {
    // Des seuils fixes seraient absurdes sur une carte de bistrot comme sur une carte
    // étoilée. La logique reproduite ici est celle de l'écran.
    List<double> plafonds(List<double> prixBruts) {
      final prix = [...prixBruts]..sort();
      if (prix.length < 6) return const [];
      double quantile(double q) =>
          prix[(prix.length * q).floor().clamp(0, prix.length - 1)];
      final out = <double>[];
      for (final q in const [0.33, 0.66]) {
        final v = (quantile(q) / 5).ceil() * 5.0;
        if (v > 0 && !out.contains(v)) out.add(v);
      }
      return out;
    }

    test('une carte de bistrot donne des seuils de bistrot', () {
      final p = plafonds([18, 22, 24, 28, 32, 35, 40, 48, 55]);
      expect(p, isNotEmpty);
      expect(p.every((v) => v <= 60), isTrue,
          reason: 'un seuil à 100 € n\'aurait aucun sens sur cette carte');
    });

    test('une carte étoilée donne des seuils étoilés', () {
      final p = plafonds([80, 120, 160, 220, 300, 450, 700, 1200]);
      expect(p.first, greaterThan(100),
          reason: 'un seuil à 20 € ne filtrerait rien du tout ici');
    });

    test('les seuils sont arrondis au multiple de cinq', () {
      for (final v in plafonds([18, 22, 24, 28, 32, 35, 40, 48, 55])) {
        expect(v % 5, equals(0));
      }
    });

    test('une carte trop courte ne propose aucun seuil', () {
      // Trois vins ne se découpent pas en tiers : un filtre qui ne filtre rien est pire
      // qu'un filtre absent.
      expect(plafonds([25, 40, 60]), isEmpty);
    });

    test('deux seuils identiques ne sont pas proposés deux fois', () {
      final p = plafonds([30, 30, 30, 30, 30, 30, 30, 30]);
      expect(p.length, equals(p.toSet().length));
    });
  });
}
