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

  /// L'URL de la capture jointe, s'il y en avait une.
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
  /// Supprimer la ligne sans l'image laisserait la capture d'écran accessible dans un
  /// bucket public à qui en connaît l'URL — un retrait qui ne retire rien de ce qui
  /// compte le plus.
  Future<bool> retirer(RetourEnvoye retour) async {
    try {
      await _client.from('app_diagnostic_logs').delete().eq('id', retour.id);
    } catch (e) {
      AppLogger.warning('FEEDBACK', 'Retrait impossible (${retour.id}): $e');
      return false;
    }
    final chemin = cheminDeLaCapture(retour.capture);
    if (chemin != null) {
      try {
        await _client.storage.from('labels').remove([chemin]);
      } catch (e) {
        // La ligne est partie ; l'image résiduelle est signalée, pas masquée.
        AppLogger.warning('FEEDBACK', 'Capture non supprimée ($chemin): $e');
      }
    }
    return true;
  }

  /// Retrouve le chemin dans le bucket à partir de l'URL publique.
  static String? cheminDeLaCapture(String? url) {
    if (url == null || url.isEmpty) return null;
    const marqueur = '/labels/';
    final i = url.indexOf(marqueur);
    if (i < 0) return null;
    final chemin = url.substring(i + marqueur.length).split('?').first;
    return chemin.isEmpty ? null : chemin;
  }
}

final feedbackHistoryServiceProvider = Provider<FeedbackHistoryService>((ref) {
  return FeedbackHistoryService(ref.read(supabaseProvider));
});

final mesRetoursProvider = FutureProvider<List<RetourEnvoye>>((ref) {
  return ref.read(feedbackHistoryServiceProvider).mesRetours();
});
