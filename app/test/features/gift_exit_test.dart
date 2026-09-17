import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/checkout/data/post_tasting_notification_service.dart';
import 'package:chatmelier/features/checkout/domain/gift_exit.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';

/// Sortir une bouteille pour l'offrir.
///
/// Jusqu'ici le seul chemin hors de la cave passait par l'écran de dégustation, qui
/// réclame une note. On notait donc un vin qu'on n'avait pas bu, et cette note partait
/// nourrir le profil de goût : le modèle apprenait un palais à partir d'un cadeau.
void main() {
  group('🎁 Ce qu\'offrir veut dire', () {
    test('un cadeau sans destinataire n\'en est pas un', () {
      const sansNom = SortieCadeau(
        destinataire: '   ',
        quantite: 1,
        suite: SuiteDuCadeau.aucuneSuite,
      );
      expect(sansNom.valide, isFalse,
          reason: 'la question « à qui ? » est la seule qui compte ici');
    });

    test('offrir zéro bouteille n\'est pas offrir', () {
      const rien = SortieCadeau(
        destinataire: 'Édith',
        quantite: 0,
        suite: SuiteDuCadeau.aucuneSuite,
      );
      expect(rien.valide, isFalse);
    });

    test('la relance tombe assez loin pour que l\'occasion ait eu lieu', () {
      expect(SortieCadeau.delaiDeRelance.inDays, greaterThanOrEqualTo(14),
          reason: 'relancer le lendemain d\'un cadeau serait absurde');
      expect(SortieCadeau.delaiDeRelance.inDays, lessThanOrEqualTo(60),
          reason: 'six mois plus tard, personne ne s\'en souvient');
    });
  });

  group('🧠 Un cadeau n\'apprend rien sur son propre palais', () {
    final source =
        File('lib/features/checkout/presentation/gift_exit_sheet.dart')
            .readAsStringSync();

    test('la feuille cadeau ne touche jamais au profil de goût', () {
      // C'est le pendant exact de l'exclusion des bouteilles REÇUES en cadeau
      // (`_originesExclues`), que le modèle comptait jusqu'ici comme des préférences.
      for (final interdit in const [
        'recordTastingExperience',
        'applyQuestionnaireResult',
        'updateProfile',
      ]) {
        expect(source.contains(interdit), isFalse,
            reason: 'offrir ne dit rien de ce qu\'on aime : $interdit');
      }
    });

    test('elle n\'écrit aucune ligne de dégustation', () {
      expect(source.contains("'tasting_log'"), isFalse,
          reason: 'une bouteille offerte n\'a pas été goûtée');
    });

    test('elle marque la date du cadeau, pas celle d\'une consommation', () {
      expect(source.contains("'gifted_at'"), isTrue);
      expect(source.contains("'consumed_at'"), isFalse,
          reason: 'consumed_at affirmerait qu\'elle a été bue');
    });
  });

  group('📗 Une bouteille offerte se relit', () {
    test('le modèle distingue offerte de bue', () {
      final offerte = Bottle.fromJson({
        'id': 'b1',
        'cellar_id': 'c1',
        'wine_id': 'w1',
        'added_by': 'u1',
        'owner_id': 'u1',
        'status': 'gifted',
        'gifted_to': 'Édith',
        'gifted_at': '2026-09-16T19:00:00.000Z',
      });
      expect(offerte.isGifted, isTrue);
      expect(offerte.isConsumed, isFalse,
          reason: 'une bouteille offerte n\'a pas été bue');
      expect(offerte.giftedTo, equals('Édith'));
      expect(offerte.consumedAt, isNull,
          reason: 'consumed_at ferait entrer un vin jamais goûté dans l\'histoire du palais');
    });

    test('le destinataire fait l\'aller-retour par le JSON', () {
      final b = Bottle.fromJson({
        'id': 'b1',
        'cellar_id': 'c1',
        'wine_id': 'w1',
        'added_by': 'u1',
        'owner_id': 'u1',
        'status': 'gifted',
        'gifted_to': 'mes parents',
        'gifted_at': '2026-09-16T19:00:00.000Z',
      });
      final relu = Bottle.fromJson(b.toJson());
      expect(relu.giftedTo, equals('mes parents'));
      expect(relu.giftedAt, isNotNull);
    });
  });

  group('⏰ Une relance programmée doit pouvoir sonner', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('un report d\'un mois survit à l\'enregistrement', () async {
      final service = PostTastingNotificationService();
      await service.schedulePostCheckout(
        bottleId: 'b1',
        wineName: 'Bandol rouge',
        delayAfterCheckout: SortieCadeau.delaiDeRelance,
      );

      final prefs = await SharedPreferences.getInstance();
      final brut = prefs.getString('pending_tasting_notifications');
      expect(brut, isNotNull);
      expect(brut, contains('Bandol rouge'),
          reason: 'la purge se mesurait depuis la SORTIE de la bouteille : toute '
              'relance au-delà de 48 h était effacée avant même de sonner');
    });

    test('une échéance passée depuis longtemps, elle, disparaît', () async {
      final service = PostTastingNotificationService();
      await service.schedulePostCheckout(
        bottleId: 'b2',
        wineName: 'Vieux souvenir',
        delayAfterCheckout: const Duration(hours: 1),
      );
      // Rejouer l'enregistrement avec une échéance vieille de plusieurs jours.
      final prefs = await SharedPreferences.getInstance();
      final ancien = DateTime.now().subtract(const Duration(days: 5));
      await prefs.setString(
        'pending_tasting_notifications',
        '[{"bottleId":"b2","wineName":"Vieux souvenir",'
            '"scheduledAt":"${ancien.toIso8601String()}",'
            '"checkedOutAt":"${ancien.toIso8601String()}"}]',
      );
      await service.schedulePostCheckout(
        bottleId: 'b3',
        wineName: 'Nouvelle',
        delayAfterCheckout: const Duration(hours: 1),
      );
      final apres = prefs.getString('pending_tasting_notifications') ?? '';
      expect(apres.contains('Vieux souvenir'), isFalse,
          reason: 'la purge doit toujours empêcher l\'accumulation');
      expect(apres, contains('Nouvelle'));
    });
  });
}
