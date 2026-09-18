import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/auth/domain/evening_summary.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';

/// La phrase qu'on montre avant de demander une adresse.
///
/// Elle doit être vraie et vérifiable d'un regard : « vous avez goûté quatre verres » se
/// contrôle, « ne perdez pas vos données ! » n'engage à rien. C'est l'exactitude qui la
/// rend crédible, et une urgence fabriquée se sent — elle abîme la confiance qu'on passe
/// le reste du produit à construire.
void main() {
  const vide = TasteProfile(id: 'p', name: 'Moi', isPrimary: true);

  group('📝 Ce qu\'on annonce doit être vrai', () {
    test('rien accumulé, rien à demander', () {
      expect(EveningSummary.lignes(profil: vide, verresGoutes: 0), isEmpty,
          reason: 'réclamer une adresse pour sauvegarder le vide est la manière la '
              'plus sûre de ne jamais l\'obtenir');
    });

    test('le nombre de verres est celui qu\'on a goûtés', () {
      final l = EveningSummary.lignes(profil: vide, verresGoutes: 4);
      expect(l.first, contains('4 verres'));
    });

    test('un seul verre se dit au singulier', () {
      final l = EveningSummary.lignes(profil: vide, verresGoutes: 1);
      expect(l.first, equals('Un verre goûté'));
    });

    test('le lieu s\'ajoute quand on le connaît', () {
      final l = EveningSummary.lignes(
          profil: vide, verresGoutes: 2, nomDuLieu: 'Le Comptoir');
      expect(l.first, contains('Le Comptoir'));
    });

    test('un axe vu une seule fois ne « se dessine » pas', () {
      // Le dire quand même serait la première exagération d'une phrase qui ne tient que
      // par son exactitude.
      final p = vide.copyWith(axisObservations: {'minerality': 1});
      final l = EveningSummary.lignes(profil: p, verresGoutes: 1);
      expect(l.join(' '), isNot(contains('palais')));
    });

    test('à partir de deux observations, on peut le dire', () {
      final p = vide.copyWith(axisObservations: {'minerality': 3, 'oak': 1});
      final l = EveningSummary.lignes(profil: p, verresGoutes: 2);
      expect(l.join(' '), contains('minéralité'),
          reason: 'c\'est l\'axe le plus observé qui est nommé');
    });

    test('les régions découvertes sont nommées', () {
      final p = vide.copyWith(favoriteRegions: ['Bandol', 'Chablis']);
      final l = EveningSummary.lignes(profil: p, verresGoutes: 2);
      expect(l.join(' '), contains('Bandol'));
    });

    test('les échanges avec le sommelier comptent aussi', () {
      final l = EveningSummary.lignes(
          profil: vide, verresGoutes: 1, messagesEchanges: 5);
      expect(l.join(' '), contains('5 échanges'));
    });
  });
}
