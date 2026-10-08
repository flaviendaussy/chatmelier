import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../domain/carte_du_lieu.dart';
import '../domain/menu_wine.dart';

/// Les cartes des lieux (V2.3 · K6, migration 061) : déposer la carte d'un restaurant,
/// trouver celles d'à côté, en ouvrir une sans rescanner.
///
/// Rien ici ne bloque un parcours : sans réseau, sans la migration 061 ou au-delà du
/// quota, on n'a simplement pas de carte partagée, et le scan reste là.
class CartesDeLieuxService {
  final SupabaseClient _client;
  CartesDeLieuxService(this._client);

  Future<List<CarteProche>> proches(double latitude, double longitude, {int rayonM = 200}) async {
    try {
      final r = await _client.rpc('cartes_proches', params: {'p_lat': latitude, 'p_lon': longitude, 'p_rayon_m': rayonM});
      if (r is! List) return const [];
      return [
        for (final e in r)
          if (e is Map) CarteProche.fromJson(Map<String, dynamic>.from(e)),
      ];
    } catch (e) {
      AppLogger.warning('CARTE_DU_LIEU', 'Cartes proches illisibles : $e');
      return const [];
    }
  }

  /// La carte d'un lieu, brute (voir [CarteDuLieu.recue]), ou nulle si elle n'est plus
  /// récente.
  Future<({Map<String, dynamic> carte, String nom, DateTime deposeeLe})?> ouvrir(String lieuCle) async {
    try {
      final r = await _client.rpc('carte_du_lieu', params: {'p_lieu_cle': lieuCle});
      if (r is! Map || r['carte'] is! Map) return null;
      return (
        carte: Map<String, dynamic>.from(r['carte'] as Map),
        nom: (r['lieu_nom'] ?? '').toString(),
        deposeeLe: DateTime.tryParse('${r['deposee_le']}')?.toLocal() ?? DateTime.now(),
      );
    } catch (e) {
      AppLogger.warning('CARTE_DU_LIEU', 'Carte du lieu $lieuCle illisible : $e');
      return null;
    }
  }

  /// Dépose la carte sous ce lieu : elle remplace la précédente. Rend vrai si c'est fait.
  Future<bool> deposer(ScannedMenu carte, LieuDeLaCarte lieu) async {
    if (carte.wines.isEmpty) return false;
    try {
      await _client.rpc('deposer_carte', params: {
        'p_lieu_cle': lieu.cle,
        'p_lieu_nom': lieu.nom,
        'p_lat': lieu.latitude,
        'p_lon': lieu.longitude,
        'p_carte': CarteDuLieu.aPartager(carte),
        'p_langue': Langue.code,
      });
      AppLogger.info('CARTE_DU_LIEU', 'Carte de « ${lieu.nom} » déposée (${carte.wines.length} vins)');
      return true;
    } catch (e) {
      AppLogger.warning('CARTE_DU_LIEU', 'Dépôt de la carte de « ${lieu.nom} » impossible : $e');
      return false;
    }
  }
}

final cartesDeLieuxServiceProvider = Provider<CartesDeLieuxService>((ref) {
  return CartesDeLieuxService(ref.read(supabaseProvider));
});
