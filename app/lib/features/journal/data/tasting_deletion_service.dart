import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/langue.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../auth/domain/taste_evidence.dart';
import '../../auth/domain/taste_undo.dart';
import '../../offline/data/offline_storage_service.dart';
import '../../offline/presentation/sync_provider.dart';

/// Ce qu'une suppression a réellement fait.
class ResultatSuppression {
  /// La ligne a disparu du serveur (ou n'y avait jamais été écrite).
  final bool supprimeeEnLigne;

  /// Profils dont une conviction a été rendue à son état antérieur.
  final int profilsTouches;

  /// Ce qui n'a pas pu être défait, en clair — vide si tout l'a été.
  final List<String> restes;

  const ResultatSuppression({
    required this.supprimeeEnLigne,
    required this.profilsTouches,
    required this.restes,
  });

  bool get complete => restes.isEmpty;
}

/// Supprime une dégustation, partout où elle a laissé quelque chose.
///
/// Une dégustation n'est pas une ligne : c'est une ligne, une entrée de cache, parfois une
/// action en attente de synchronisation, et des traces dans un ou plusieurs profils de
/// goût. N'effacer que la ligne laisserait le journal vide et le profil toujours convaincu
/// — le contraire de ce qu'on demande quand on supprime.
class TastingDeletionService {
  final SupabaseClient _client;
  final OfflineStorageService _offline;
  final TasteProfileService _profils;

  TastingDeletionService(this._client, this._offline, this._profils);

  Future<ResultatSuppression> supprimer(String tastingId) async {
    // 1. Le serveur. La RLS borne déjà la suppression aux lignes de la personne ; un échec
    //    réseau ne doit pas empêcher le reste, mais doit être dit.
    var enLigne = false;
    try {
      await _client.from('tasting_log').delete().eq('id', tastingId);
      enLigne = true;
    } catch (e) {
      AppLogger.warning('TASTING_DELETE', 'Suppression distante impossible ($tastingId): $e');
    }

    // 2. Le cache local, sinon le journal continue de l'afficher.
    final cache = _offline.getCachedTastings()
      ..removeWhere((t) => t['id']?.toString() == tastingId);
    await _offline.saveCachedTastings(cache);

    // 3. L'action en attente, sinon la prochaine synchronisation la ressusciterait.
    for (final a in _offline.getQueue()) {
      if (a.data['tasting_id']?.toString() == tastingId) {
        await _offline.removeAction(a.id);
      }
    }

    // 4. Les profils de goût. Chaque profil a pu recevoir sa propre part de la dégustation
    //    (les convives goûtent le même vin), donc on les passe tous.
    final registre = await TasteEvidenceLedger.ouvrir();
    final contributions = registre.pourDegustation(tastingId);
    final restes = <String>[];
    var touches = 0;

    if (contributions.isNotEmpty) {
      final profils = await _profils.getProfiles();
      for (final p in profils) {
        final r = TasteUndo.annuler(
          profil: p,
          contributions: contributions,
          registre: registre,
        );
        if (r.defaites.isEmpty && r.nonDefaites.isEmpty) continue;
        if (r.defaites.isNotEmpty) {
          await _profils.updateProfile(r.profil);
          touches++;
        }
        for (final c in r.nonDefaites) {
          if (!restes.contains(c)) restes.add(c);
        }
      }
      await registre.retirer(tastingId);
    }

    AppLogger.info('TASTING_DELETE',
        'Dégustation $tastingId supprimée (en ligne: $enLigne, profils: $touches, '
        'non défait: ${restes.length})');

    return ResultatSuppression(
      supprimeeEnLigne: enLigne,
      profilsTouches: touches,
      restes: restes,
    );
  }

  /// Dit, en clair, ce qui n'a pas pu être défait.
  ///
  /// Une liste de clés techniques ne dit rien à personne ; et taire la limite ferait croire
  /// à une suppression complète qui n'a pas eu lieu.
  static String? phraseDesRestes(List<String> restes) {
    if (restes.isEmpty) return null;
    final noms = restes.map(_nomDeLaCible).toSet().toList();
    final liste = noms.length == 1 ? noms.first : '${noms.take(noms.length - 1).join(', ')}${tr(' et ', ' and ')}${noms.last}';
    return noms.length == 1
        ? tr('Votre goût pour {liste} a évolué depuis : il reste tel quel.',
            'Your taste for {liste} has changed since: it stays as it is.', {'liste': liste})
        : tr('Vos goûts pour {liste} ont évolué depuis : ils restent tels quels.',
            'Your tastes for {liste} have changed since: they stay as they are.', {'liste': liste});
  }

  /// `axe:acidity` (palais d'avant la V2.6) ou `axe:blanc:acidity` (palais d'une famille).
  static String _nomDeLaCible(String cible) {
    final morceaux = cible.replaceFirst('axe:', '').split(':');
    final nom = switch (morceaux.last) {
      'acidity' => tr('la fraîcheur', 'freshness'),
      'sweetness' => tr('la douceur', 'sweetness'),
      'body' => tr('le corps', 'body'),
      'tannin' => tr('les tanins', 'tannins'),
      'oak' => tr('le boisé', 'oak'),
      'evolution' => tr('l\'évolution', 'maturity'),
      'ripeFruit' => tr('le fruit mûr', 'ripe fruit'),
      'spice' => tr('les épices', 'spice'),
      'freshFruit' => tr('le fruit frais', 'fresh fruit'),
      'minerality' => tr('la minéralité', 'minerality'),
      _ => cible,
    };
    if (morceaux.length < 2) return nom;
    return morceaux.first == 'rouge'
        ? tr('{nom} des rouges', '{nom} in reds', {'nom': nom})
        : tr('{nom} des blancs', '{nom} in whites', {'nom': nom});
  }
}


final tastingDeletionServiceProvider = Provider<TastingDeletionService>((ref) {
  return TastingDeletionService(
    ref.read(supabaseProvider),
    ref.read(offlineStorageServiceProvider),
    ref.read(tasteProfileServiceProvider),
  );
});
