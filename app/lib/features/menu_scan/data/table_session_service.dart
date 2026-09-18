import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../sommelier/domain/guest_matcher_engine.dart';
import '../domain/menu_wine.dart';

/// Ce que l'ouverture d'une table rend.
class TableOuverte {
  final String sessionId;

  /// Six caractères à dire à voix haute. C'est lui qui remplace le QR quand la photo ne
  /// passe pas — lumière basse, écran rayé, téléphone sans appareil photo.
  final String code;

  final DateTime expireLe;

  const TableOuverte({
    required this.sessionId,
    required this.code,
    required this.expireLe,
  });
}

/// Ce qu'un invité reçoit en rejoignant.
class TableRejointe {
  final String sessionId;
  final ScannedMenu menu;
  final DateTime expireLe;

  const TableRejointe({
    required this.sessionId,
    required this.menu,
    required this.expireLe,
  });
}

/// Pourquoi rejoindre a échoué, en des termes qui veulent dire quelque chose.
enum EchecDeTable {
  /// Code inconnu, ou table expirée. Les deux appellent le même geste : redemander le code.
  introuvable,

  /// Le réseau, ou le serveur. Réessayer a un sens.
  reseau,
}

class TableSessionException implements Exception {
  final EchecDeTable cause;
  const TableSessionException(this.cause);
}

/// Les tables de restaurant, côté serveur.
///
/// **Ce que ça remplace.** Une table n'existait que dans une `static Map` en mémoire du
/// téléphone hôte : l'invité ne pouvait recevoir la carte que par l'URL du QR — d'où la
/// compression et son plafond de seize vins — rien ne revenait en sens inverse, fermer
/// l'app perdait tout, et le « code de partage » affiché à l'écran ne correspondait à
/// rien. Le QR reste utile ; il n'est plus la seule voie.
class TableSessionService {
  final SupabaseClient _client;
  TableSessionService(this._client);

  /// Ouvre une table. Demande un compte — c'est l'hôte qui engage le repas.
  Future<TableOuverte> ouvrir({
    required String restaurantName,
    required ScannedMenu menu,
  }) async {
    try {
      final res = await _client.rpc('open_table_session', params: {
        'p_restaurant_name': restaurantName,
        'p_menu': menu.toJson(),
      });
      final row = _premiere(res);
      if (row == null) throw const TableSessionException(EchecDeTable.reseau);
      return TableOuverte(
        sessionId: row['session_id'].toString(),
        code: row['code'].toString(),
        expireLe: DateTime.tryParse(row['expires_at']?.toString() ?? '') ??
            DateTime.now().add(const Duration(hours: 4)),
      );
    } catch (e) {
      AppLogger.warning('TABLE', 'Ouverture impossible: $e');
      throw const TableSessionException(EchecDeTable.reseau);
    }
  }

  /// Rejoint une table par son code. Ne demande AUCUN compte : exiger une inscription au
  /// moment où l'on tend son téléphone à un ami tuerait la seule boucle virale du produit.
  Future<TableRejointe> rejoindre({
    required String code,
    required String nom,
    GuestProfile? profil,
  }) async {
    try {
      final res = await _client.rpc('join_table_session', params: {
        'p_code': code.trim().toUpperCase(),
        'p_guest_name': nom.trim(),
        'p_profile': profil?.toJson() ?? <String, dynamic>{},
      });
      final row = _premiere(res);
      if (row == null) throw const TableSessionException(EchecDeTable.introuvable);

      final brut = row['menu'];
      final menu = brut is Map
          ? ScannedMenu.fromJson(Map<String, dynamic>.from(brut))
          : null;
      if (menu == null || menu.wines.isEmpty) {
        // Une table sans carte lisible ne vaut pas mieux qu'une table absente : mieux vaut
        // le dire que d'ouvrir un écran vide.
        throw const TableSessionException(EchecDeTable.introuvable);
      }

      return TableRejointe(
        sessionId: row['session_id'].toString(),
        menu: menu,
        expireLe: DateTime.tryParse(row['expires_at']?.toString() ?? '') ??
            DateTime.now().add(const Duration(hours: 4)),
      );
    } on TableSessionException {
      rethrow;
    } catch (e) {
      // `table_introuvable` est levé par la fonction SQL ; tout le reste est du réseau.
      final introuvable = e.toString().contains('table_introuvable');
      AppLogger.warning('TABLE', 'Jointure impossible ($code): $e');
      throw TableSessionException(
          introuvable ? EchecDeTable.introuvable : EchecDeTable.reseau);
    }
  }

  /// Qui est à table, et avec quels goûts.
  ///
  /// Le code est redemandé à chaque appel : c'est lui qui tient lieu d'autorisation, et un
  /// identifiant de session capté ailleurs ne doit pas suffire.
  Future<List<GuestProfile>> convives(String code) async {
    try {
      final res = await _client.rpc('read_table_session_guests', params: {
        'p_code': code.trim().toUpperCase(),
      });
      if (res is! List) return const [];
      return [
        for (final r in res)
          if (r is Map)
            GuestProfile.fromJson(
              r['guest_name']?.toString() ?? 'convive',
              {
                'name': r['guest_name'],
                ...(r['profile'] is Map
                    ? Map<String, dynamic>.from(r['profile'] as Map)
                    : const <String, dynamic>{}),
              },
            ),
      ];
    } catch (e) {
      AppLogger.warning('TABLE', 'Lecture des convives impossible ($code): $e');
      return const [];
    }
  }

  /// Les fonctions renvoient une table d'une ligne ; PostgREST la rend en liste.
  static Map<String, dynamic>? _premiere(dynamic res) {
    if (res is List && res.isNotEmpty && res.first is Map) {
      return Map<String, dynamic>.from(res.first as Map);
    }
    if (res is Map) return Map<String, dynamic>.from(res);
    return null;
  }
}

final tableSessionServiceProvider = Provider<TableSessionService>((ref) {
  return TableSessionService(ref.read(supabaseProvider));
});
