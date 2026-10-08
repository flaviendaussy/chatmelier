import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/admin/domain/capture_de_retour.dart';

void main() {
  test('une capture d\'avant le 22/09 est une adresse, qui s\'ouvre telle quelle', () {
    expect(CaptureDeRetour.estUneAdresse('https://projet.supabase.co/storage/v1/object/public/labels/u/a.png'), isTrue);
    expect(CaptureDeRetour.estUneAdresse('dc3af2f2-6359-4236-a795-ea42ecfd16c5/6fca70c0.png'), isFalse);
  });

  test('la console dit la vraie cause, sans demander si la fonction est déployée quand elle l\'est', () {
    expect(CaptureDeRetour.cause(statut: 404, details: {'error': 'Object not found'}), contains('n\'existe plus'));
    expect(CaptureDeRetour.cause(statut: 404, details: {'code': 'NOT_FOUND', 'message': 'Requested function was not found'}),
        contains('pas déployée'));
    expect(CaptureDeRetour.cause(statut: 403, details: {'error': 'Forbidden'}), contains('administrateurs'));
    expect(CaptureDeRetour.cause(statut: 401), contains('reconnecte'));
  });

  test('une image qui ne vient pas : le réseau n\'est pas le fichier (08/10)', () {
    expect(CaptureDeRetour.causeDuTelechargement(erreur: TimeoutException('lent')), contains('30 secondes'));
    expect(
        CaptureDeRetour.causeDuTelechargement(
            erreur: 'HttpException: Connection closed before full header was received'),
        contains('pas de réseau'));
    expect(CaptureDeRetour.causeDuTelechargement(statut: 404), contains('n\'existe plus'));
    expect(CaptureDeRetour.causeDuTelechargement(statut: 403), contains('expiré'));
    expect(CaptureDeRetour.causeDuTelechargement(statut: 500), 'erreur 500');
  });
}

