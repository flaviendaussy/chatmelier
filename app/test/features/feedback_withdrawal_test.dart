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
    test('un chemin nu désigne le bucket privé', () {
      final ou = EmplacementCapture.depuis(
          '3f2b1c00-0000-4000-8000-000000000000/abc.png');
      expect(ou!.bucket, equals('feedback'));
      expect(ou.chemin, equals('3f2b1c00-0000-4000-8000-000000000000/abc.png'));
    });

    test('une ancienne URL publique garde son bucket d\'origine', () {
      final ou = EmplacementCapture.depuis(
          'https://x.supabase.co/storage/v1/object/public/labels/feedback/abc.png');
      expect(ou!.bucket, equals('labels'),
          reason: 'les remontées d\'avant la migration 036 vivent encore dans labels');
      expect(ou.chemin, equals('feedback/abc.png'));
    });

    test('les paramètres de requête ne font pas partie du chemin', () {
      expect(
        EmplacementCapture.depuis(
                'https://x.supabase.co/storage/v1/object/public/labels/feedback/abc.png?t=1')!
            .chemin,
        equals('feedback/abc.png'),
      );
    });

    test('pas de capture, pas d\'emplacement', () {
      expect(EmplacementCapture.depuis(null), isNull);
      expect(EmplacementCapture.depuis(''), isNull);
      expect(EmplacementCapture.depuis('aucune'), isNull);
      expect(EmplacementCapture.depuis('https://ailleurs/photo.png'), isNull,
          reason: 'une URL qui ne vient pas du stockage ne désigne aucun objet');
    });
  });
}
