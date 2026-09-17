import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/feedback/data/feedback_history_service.dart';

/// Retirer un retour qu'on a envoyé.
///
/// Un rapport de bug part d'un geste impulsif : on secoue son téléphone et on joint une
/// capture de ce qu'on avait sous les yeux. Pouvoir le retirer ensuite n'est pas un
/// confort — la capture peut montrer plus que prévu.
void main() {
  Map<String, dynamic> log(String message) => {
        'id': '42',
        'created_at': '2026-09-16T20:00:00.000Z',
        'message': message,
      };

  group('📩 Relire ce qu\'on a envoyé', () {
    test('le commentaire et la capture sont extraits du message journalisé', () {
      final r = RetourEnvoye.depuisLog(log(
        'Commentaire: La carte ne charge pas | '
        'Capture: https://x.supabase.co/storage/v1/object/public/labels/feedback/abc.png | '
        'Annotations: oui',
      ));
      expect(r.commentaire, equals('La carte ne charge pas'));
      expect(r.capture, endsWith('feedback/abc.png'));
    });

    test('« aucune » capture n\'est pas une capture', () {
      final r = RetourEnvoye.depuisLog(
          log('Commentaire: Rien de spécial | Capture: aucune | Annotations: non'));
      expect(r.capture, isNull);
    });

    test('un commentaire contenant « | » n\'est pas tronqué au premier séparateur', () {
      final r = RetourEnvoye.depuisLog(log(
          'Commentaire: le bouton A | B ne marche pas | Capture: aucune | Annotations: non'));
      expect(r.commentaire, equals('le bouton A | B ne marche pas'),
          reason: 'la découpe suit les étiquettes, pas le premier tube venu');
    });

    test('un message d\'une autre forme reste lisible plutôt que vide', () {
      final r = RetourEnvoye.depuisLog(log('Ancien format sans étiquettes'));
      expect(r.commentaire, equals('Ancien format sans étiquettes'));
    });
  });

  group('🧹 Retirer emporte aussi la capture', () {
    test('le chemin du bucket se retrouve depuis l\'URL publique', () {
      expect(
        FeedbackHistoryService.cheminDeLaCapture(
            'https://x.supabase.co/storage/v1/object/public/labels/feedback/abc.png'),
        equals('feedback/abc.png'),
        reason: 'sans le chemin, l\'image resterait accessible à qui connaît son URL',
      );
    });

    test('les paramètres de requête ne font pas partie du chemin', () {
      expect(
        FeedbackHistoryService.cheminDeLaCapture(
            'https://x.supabase.co/storage/v1/object/public/labels/feedback/abc.png?t=1'),
        equals('feedback/abc.png'),
      );
    });

    test('pas de capture, pas de chemin', () {
      expect(FeedbackHistoryService.cheminDeLaCapture(null), isNull);
      expect(FeedbackHistoryService.cheminDeLaCapture(''), isNull);
      expect(FeedbackHistoryService.cheminDeLaCapture('https://ailleurs/photo.png'), isNull);
    });
  });
}
