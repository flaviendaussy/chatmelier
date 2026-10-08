import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../../auth/data/taste_profile_service.dart';
import '../domain/questionnaire_de_degustation.dart';
import '../domain/tasting_questionnaire_result.dart';

/// La dégustation faite pour un ami, et celle qu'un ami a faite pour soi (V2.4 · R4,
/// migration 066) : proposée, puis acceptée ou refusée par celui à qui elle revient.
class DegustationsPartagees {
  final SupabaseClient _supabase;
  final TasteProfileService _gout;

  DegustationsPartagees(this._supabase, this._gout);

  /// Propose à un ami la dégustation faite pour lui ([propositionDeDegustation]).
  Future<void> proposer(Map<String, dynamic> proposition) async {
    await _supabase.rpc('proposer_degustation', params: proposition);
  }

  /// Accepte une dégustation proposée : elle entre au journal (côté serveur), puis l'app en
  /// apprend le palais — sauf bouteille défectueuse — et écrit les arômes dans sa langue.
  Future<void> accepter(String id) async {
    final brut = await _supabase.rpc('accepter_degustation', params: {'p_id': id});
    final r = brut is Map ? Map<String, dynamic>.from(brut) : const <String, dynamic>{};
    final journal = r['tasting_log_id']?.toString();
    final q = r['questionnaire'];
    if (journal == null || q is! Map) return;
    final vin = r['vin'] is Map ? Map<String, dynamic>.from(r['vin'] as Map) : const <String, dynamic>{};
    try {
      final profils = await _gout.getProfiles();
      final principal = profils.where((p) => p.isPrimary).firstOrNull ?? profils.firstOrNull;
      if (principal == null) return;
      final resultat = TastingQuestionnaireResult.fromJson(
          {...Map<String, dynamic>.from(q), 'profile_id': principal.id, 'profile_name': principal.name});
      if (r['defaut'] == null) {
        await _gout.applyQuestionnaireResult(
          result: resultat,
          wineRegion: vin['region']?.toString(),
          wineGrapes: [for (final g in (vin['cepages'] as List? ?? const [])) '$g'],
          wineType: vin['couleur']?.toString(),
          tastingId: journal,
          wineName: vin['nom']?.toString(),
        );
      } else {
        AppLogger.info('DEGUSTATION_PARTAGEE', 'Palais non modifié : bouteille défectueuse (${r['defaut']})');
      }
      final aromes = libellesDesAromes(resultat.perceivedAromas);
      if (aromes.isNotEmpty) {
        await _supabase
            .from('tasting_log')
            .update({'tasting_notes': tr('Arômes : {v1}', 'Aromas: {v1}', {'v1': aromes.join(', ')})})
            .eq('id', journal);
      }
    } catch (e) {
      // La dégustation est au journal ; le palais et les arômes se rattraperont pas, mais rien
      // n'est perdu de ce que l'ami a noté.
      AppLogger.warning('DEGUSTATION_PARTAGEE', 'Acceptée, palais ou arômes non écrits : $e');
    }
  }

  Future<void> refuser(String id) async {
    await _supabase.rpc('refuser_degustation', params: {'p_id': id});
  }
}

final degustationsPartageesProvider = Provider<DegustationsPartagees>(
  (ref) => DegustationsPartagees(ref.read(supabaseProvider), ref.read(tasteProfileServiceProvider)),
);
