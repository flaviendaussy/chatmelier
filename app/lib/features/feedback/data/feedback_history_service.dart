import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';

/// Un retour envoyé, tel que la personne peut le revoir.
class RetourEnvoye {
  final String id;
  final DateTime quand;

  /// Le commentaire seul, extrait du message journalisé.
  final String commentaire;

  /// La capture jointe, s'il y en avait une.
  ///
  /// Deux formes coexistent : un CHEMIN dans le bucket privé `feedback` (depuis la
  /// migration 036), ou une ancienne URL publique du bucket `labels`. Les anciennes
  /// remontées ne sont pas réécrites — leurs URL circulent déjà et le dépouillement en
  /// cours perdrait ses pièces jointes.
  final String? capture;

  const RetourEnvoye({
    required this.id,
    required this.quand,
    required this.commentaire,
    this.capture,
  });

  /// Le message est journalisé sous la forme
  /// `Commentaire: … | Capture: … | Annotations: …` (voir feedback_annotation_sheet).
  /// On le relit plutôt que d'ajouter des colonnes : la table est un journal technique,
  /// pas un modèle de données, et la lui faire porter en serait une déformation.
  factory RetourEnvoye.depuisLog(Map<String, dynamic> row) {
    final brut = row['message']?.toString() ?? '';
    String entre(String debut, String? fin) {
      final i = brut.indexOf(debut);
      if (i < 0) return '';
      final depart = i + debut.length;
      final j = fin == null ? -1 : brut.indexOf(fin, depart);
      return (j < 0 ? brut.substring(depart) : brut.substring(depart, j)).trim();
    }

    final commentaire = entre('Commentaire: ', ' | Capture:');
    final capture = entre('| Capture: ', ' | Annotations:');
    return RetourEnvoye(
      id: row['id'].toString(),
      quand: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
      commentaire: commentaire.isEmpty ? brut : commentaire,
      capture: (capture.isEmpty || capture == 'aucune') ? null : capture,
    );
  }
}

/// Ce que la personne a envoyé, et comment le retirer.
class FeedbackHistoryService {
  final SupabaseClient _client;
  FeedbackHistoryService(this._client);

  Future<List<RetourEnvoye>> mesRetours({int limite = 50}) async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];
    try {
      final res = await _client
          .from('app_diagnostic_logs')
          .select('id, message, created_at')
          .eq('user_id', user.id)
          .eq('tag', 'USER_FEEDBACK')
          .order('created_at', ascending: false)
          .limit(limite)
          .timeout(const Duration(seconds: 6));
      return List<Map<String, dynamic>>.from(res as List)
          .map(RetourEnvoye.depuisLog)
          .toList();
    } catch (e) {
      AppLogger.warning('FEEDBACK', 'Lecture des retours impossible: $e');
      return const [];
    }
  }

  /// Retire un retour : la ligne ET la capture.
  ///
  /// Supprimer la ligne sans l'image laisserait la capture d'écran dans le stockage — un
  /// retrait qui ne retire pas ce qui compte le plus.
  Future<bool> retirer(RetourEnvoye retour) async {
    try {
      await _client.from('app_diagnostic_logs').delete().eq('id', retour.id);
    } catch (e) {
      AppLogger.warning('FEEDBACK', 'Retrait impossible (${retour.id}): $e');
      return false;
    }
    final ou = EmplacementCapture.depuis(retour.capture);
    if (ou != null) {
      try {
        await _client.storage.from(ou.bucket).remove([ou.chemin]);
      } catch (e) {
        // La ligne est partie ; l'image résiduelle est signalée, pas masquée.
        AppLogger.warning('FEEDBACK', 'Capture non supprimée (${ou.chemin}): $e');
      }
    }
    return true;
  }

  /// Une URL pour afficher sa propre capture, valable quelques minutes.
  ///
  /// Le bucket est privé : il n'existe pas d'URL permanente à montrer. La RLS autorise
  /// chacun à relire son propre dossier, donc la signature se fait avec la session de la
  /// personne — aucun secret ne quitte le serveur.
  Future<String?> urlDeLaCapture(String? capture) async {
    final ou = EmplacementCapture.depuis(capture);
    if (ou == null) return null;
    if (ou.bucket != 'feedback') return capture; // ancienne URL publique, déjà affichable
    try {
      return await _client.storage
          .from(ou.bucket)
          .createSignedUrl(ou.chemin, 300);
    } catch (e) {
      AppLogger.warning('FEEDBACK', 'Signature impossible (${ou.chemin}): $e');
      return null;
    }
  }
}

/// Où vit une capture : dans quel bucket, sous quel chemin.
class EmplacementCapture {
  final String bucket;
  final String chemin;
  const EmplacementCapture(this.bucket, this.chemin);

  /// Lit les deux formes possibles sans avoir à demander laquelle c'est.
  ///
  /// Une ancienne remontée porte une URL publique complète ; une nouvelle porte un simple
  /// chemin dans le bucket privé. La présence de `://` suffit à trancher.
  static EmplacementCapture? depuis(String? valeur) {
    if (valeur == null || valeur.isEmpty || valeur == 'aucune') return null;

    if (!valeur.contains('://')) {
      // Chemin nu : bucket privé `feedback`, sous le dossier de son auteur.
      final propre = valeur.split('?').first;
      return propre.isEmpty ? null : EmplacementCapture('feedback', propre);
    }

    // URL publique historique : .../object/public/<bucket>/<chemin>
    const marqueur = '/public/';
    final i = valeur.indexOf(marqueur);
    if (i < 0) return null;
    final reste = valeur.substring(i + marqueur.length).split('?').first;
    final coupe = reste.indexOf('/');
    if (coupe <= 0 || coupe == reste.length - 1) return null;
    return EmplacementCapture(reste.substring(0, coupe), reste.substring(coupe + 1));
  }
}

final feedbackHistoryServiceProvider = Provider<FeedbackHistoryService>((ref) {
  return FeedbackHistoryService(ref.read(supabaseProvider));
});

final mesRetoursProvider = FutureProvider<List<RetourEnvoye>>((ref) {
  return ref.read(feedbackHistoryServiceProvider).mesRetours();
});
