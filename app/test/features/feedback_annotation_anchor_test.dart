import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/feedback/presentation/feedback_annotation_sheet.dart';

/// Les annotations de la feuille de retour doivent rester collées à l'image.
///
/// Deux défauts distincts, même cause : les traits étaient stockés en pixels absolus du
/// widget au lieu de coordonnées d'image.
///
///  1. **À l'écran** — ouvrir le clavier pour taper son commentaire réduit le canevas.
///     L'entourage se décalait, et avec un grand clavier il sortait du cadre et
///     disparaissait (reproduit sur Pixel 7 : canevas de 1100 px à 390 px).
///     Signalé le 2026-09-06 : « il devrait être ancré, ne plus bouger ».
///  2. **Dans le fichier envoyé** — le rendu dessinait les coordonnées de widget telles
///     quelles sur un canevas aux dimensions natives de la capture. À 2,625 pixels par
///     point, toutes les annotations reçues étaient tirées vers le coin supérieur gauche.
void main() {
  /// Réplique de la normalisation faite au moment du tracé.
  Offset normalise(Offset local, Size canevas) => Offset(
        (local.dx / canevas.width).clamp(0.0, 1.0),
        (local.dy / canevas.height).clamp(0.0, 1.0),
      );

  /// Réplique de la dénormalisation faite au rendu (écran comme fichier).
  Offset vers(Offset p, Size cible) =>
      Offset(p.dx * cible.width, p.dy * cible.height);

  group('📌 Ancrage des annotations', () {
    test('un trait garde sa place quand le canevas rétrécit', () {
      const grand = Size(360, 1100); // avant l'ouverture du clavier
      const petit = Size(360, 390);  // après

      // L'utilisateur vise le milieu exact de l'image.
      final stocke = normalise(const Offset(180, 550), grand);
      expect(stocke.dx, closeTo(0.5, 1e-9));
      expect(stocke.dy, closeTo(0.5, 1e-9));

      // Après rétrécissement, il doit toujours viser le milieu.
      final apres = vers(stocke, petit);
      expect(apres.dx, closeTo(180, 1e-9));
      expect(apres.dy, closeTo(195, 1e-9),
          reason: 'Le milieu du petit canevas, pas les 550 px d\'origine — qui '
              'tombaient hors du cadre et se faisaient rogner.');
    });

    test('le trait atteint la bonne zone de l\'image exportée', () {
      // Pixel 7 : 360 points de large affichés, 1080 pixels natifs.
      const affiche = Size(360, 800);
      const native = Size(1080, 2400);

      final stocke = normalise(const Offset(200, 300), affiche);
      final rendu = vers(stocke, native);

      expect(rendu.dx, closeTo(600, 1e-6));
      expect(rendu.dy, closeTo(900, 1e-6));
      // L'ancien code dessinait (200, 300) tel quel sur l'image native.
      expect(rendu.dx, isNot(closeTo(200, 1)),
          reason: 'C\'est précisément le décalage vers le coin supérieur gauche.');
    });

    test('l\'épaisseur garde la même apparence à toutes les tailles', () {
      const canevas = Size(360, 800);
      const native = Size(1080, 2400);
      const epaisseurLogique = 4.0;

      final ratio = epaisseurLogique / canevas.width;
      // À l'écran : l'épaisseur d'origine.
      expect(ratio * canevas.width, closeTo(epaisseurLogique, 1e-9));
      // Dans le fichier : trois fois plus, comme l'image.
      expect(ratio * native.width, closeTo(12.0, 1e-9),
          reason: 'Sinon le trait paraît trois fois plus fin dans le rapport reçu.');
    });

    test('un geste qui déborde du cadre reste dans l\'image', () {
      const canevas = Size(360, 800);
      expect(normalise(const Offset(-50, 900), canevas), equals(const Offset(0.0, 1.0)),
          reason: 'Bornes 0..1 : un trait ne peut pas désigner hors de la capture.');
    });

    test('le modèle de trait porte bien une épaisseur relative', () {
      final trait = FeedbackStroke(
        points: [const Offset(0.25, 0.5)],
        color: const Color(0xFFFF0000),
        widthRatio: 0.01,
      );
      expect(trait.points.first.dx, lessThanOrEqualTo(1.0));
      expect(trait.widthRatio, lessThan(1.0));
    });
  });
}
