import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/cellar/domain/wine_service_advisor.dart';

/// L'élevage doit finir par s'AFFICHER.
///
/// La migration 034 crée les colonnes, le backfill les remplit depuis la table des 90
/// régions — et la fiche continuait d'afficher « données techniques non fournies par le
/// domaine », parce qu'elle ne lisait que l'ancien champ de texte libre. Des colonnes
/// écrites que rien ne lit : exactement le motif qu'on a retiré quatre fois ailleurs dans
/// ce dépôt, cette fois de mon fait.
void main() {
  OenologyAdvice conseil({
    String? texteLibre,
    String? type,
    int? mois,
  }) =>
      WineOenologyAdvisor.computeAdvice(
        wineType: 'red',
        vintage: 2019,
        region: 'Bandol',
        explicitBarrelAging: texteLibre,
        elevageType: type,
        elevageMois: mois,
      );

  group('🛢️ Ce que la fiche montre de l\'élevage', () {
    test('le contenant et la durée deviennent une phrase', () {
      final a = conseil(type: 'foudre', mois: 18);
      expect(a.barrelAgingDuration, equals('18 mois en foudre de chêne'));
      expect(a.hasTechnicalData, isTrue,
          reason: 'sinon la fiche affiche « non fourni » alors qu\'on sait');
    });

    test('le texte du domaine prime sur la règle d\'appellation', () {
      // Plus précis que le cahier des charges : c'est ce que le domaine dit de SON vin.
      final a = conseil(texteLibre: '24 mois en barriques neuves', type: 'foudre', mois: 18);
      expect(a.barrelAgingDuration, equals('24 mois en barriques neuves'));
    });

    test('sans durée, le contenant seul suffit', () {
      expect(conseil(type: 'inox').barrelAgingDuration, equals('cuve inox'));
    });

    test('ne rien savoir reste « rien »', () {
      final a = conseil();
      expect(a.barrelAgingDuration, isNull);
      expect(a.hasTechnicalData, isFalse,
          reason: '« non fourni » est vrai ; une phrase creuse ne le serait pas');
    });

    test('un type inconnu n\'invente pas de contenant', () {
      expect(conseil(type: 'cuve-en-or', mois: 12).barrelAgingDuration, equals('12 mois'));
    });
  });
}
