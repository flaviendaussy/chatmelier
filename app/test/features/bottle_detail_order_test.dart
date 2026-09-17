import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// L'ordre de la fiche d'une bouteille.
///
/// « On voit direct la valeur, mais ça aurait plus de sens d'avoir les actions
/// disponibles, serving and tasting advice d'abord, puis la description, puis le pic ou
/// le terroir. »
///
/// Cet ordre est une décision de produit, pas un hasard de rédaction : ouvrir sur le prix
/// répond à une question que personne ne se pose en tenant la bouteille. Un test de
/// structure le fige — l'écran fait 2 800 lignes dans une seule colonne, et une section
/// déplacée à l'occasion d'autre chose n'y laisserait aucune trace visible.
void main() {
  final source = File('lib/features/cellar/presentation/bottle_detail_screen.dart')
      .readAsStringSync();

  int position(String marqueur) {
    final i = source.indexOf(marqueur);
    expect(i, isNot(-1), reason: 'section introuvable : $marqueur');
    return i;
  }

  group('🍾 Ce qu\'on voit en ouvrant une bouteille', () {
    test('agir vient avant informer', () {
      expect(position('AGIR SUR CETTE BOUTEILLE'),
          lessThan(position('SOMMELIER SERVICE & TEMPERATURE ADVICE')));
      expect(position('SOMMELIER SERVICE & TEMPERATURE ADVICE'),
          lessThan(position('TASTING NOTES & FOOD PAIRINGS')));
    });

    test('la description précède l\'apogée et le terroir', () {
      expect(position('TASTING NOTES & FOOD PAIRINGS'),
          lessThan(position('DRINKING WINDOW GAUSSIAN CURVE')));
      expect(position('VERIFIED VINEYARD KNOWLEDGE'),
          lessThan(position('DRINKING WINDOW GAUSSIAN CURVE')));
      expect(position('DRINKING WINDOW GAUSSIAN CURVE'),
          lessThan(position('TERROIR & GEOGRAPHY MAP')));
    });

    test('la valeur ne s\'impose plus en premier', () {
      final valeur = position('VALUATION & PRICE CARD');
      for (final avant in const [
        'AGIR SUR CETTE BOUTEILLE',
        'SOMMELIER SERVICE & TEMPERATURE ADVICE',
        'TASTING NOTES & FOOD PAIRINGS',
        'DRINKING WINDOW GAUSSIAN CURVE',
        'TERROIR & GEOGRAPHY MAP',
        'GRAPES COMPOSITION',
      ]) {
        expect(position(avant), lessThan(valeur),
            reason: '« $avant » doit précéder le prix');
      }
    });

    test('supprimer une bouteille n\'est pas à portée de pouce distrait', () {
      // Les quatre boutons étaient empilés ensemble, et les remonter en tête aurait mis
      // « Supprimer définitivement » juste sous le titre.
      expect(position('TENIR LA CAVE'), greaterThan(position('VALUATION & PRICE CARD')));

      // Une seule porte de sortie, et elle porte son nom en toutes lettres : la corbeille
      // rouge de la barre de titre faisait doublon, sans autre garde-fou que la boîte de
      // confirmation.
      final appels = 'DeleteBottleDialog.show'.allMatches(source).length;
      expect(appels, equals(1), reason: 'un seul chemin de suppression sur cet écran');
      expect(source.indexOf('DeleteBottleDialog.show'),
          greaterThan(position('TENIR LA CAVE')));
    });

    test('aucun bouton ne fait rien du tout', () {
      // « Partager » avait un `onPressed` vide : on appuyait, rien ne se passait, et rien
      // ne disait si c'était l'app ou soi.
      expect(source.contains('// Share bottle details'), isFalse);
      expect(RegExp(r'onPressed:\s*\(\)\s*\{\s*\}').hasMatch(source), isFalse,
          reason: 'un bouton inerte est pire que pas de bouton');
    });

    test('l\'entretien de la fiche passe après ce qu\'elle raconte', () {
      // Enrichissement IA et « tout modifier » sont de la maintenance de données : utiles,
      // mais pas ce qu'on vient chercher en ouvrant une bouteille.
      expect(position('ACTIONS: AI ENRICHMENT & EDIT ALL FIELDS'),
          greaterThan(position('USER PERSONAL NOTES')));
    });
  });
}
