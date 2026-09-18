import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/admin_metrics.dart';

/// Les chiffres d'usage, lus par l'administrateur.
///
/// **Aucune clé n'est embarquée.** L'app envoie la session de la personne ; les fonctions
/// SQL vérifient `profiles.is_admin` et décident. C'est la différence exacte avec la
/// console précédente, qui portait un jeton `service_role` en clair dans une page
/// publique : ici, une console volée ne donne rien de plus qu'un compte volé.
class AdminMetricsService {
  final SupabaseClient _client;
  AdminMetricsService(this._client);

  Future<TableauDeBord> tableauDeBord(int jours) async {
    // Trois appels plutôt qu'un : chacun agrège des tables différentes, et les faire
    // ensemble obligerait à une requête que personne ne saurait relire dans six mois.
    final res = await Future.wait([
      _client.rpc('admin_resume', params: {'p_jours': jours}),
      _client.rpc('admin_metriques_quotidiennes', params: {'p_jours': jours}),
      _client.rpc('admin_repartitions', params: {'p_jours': jours}),
    ]);

    final resume = _premiere(res[0]);
    return TableauDeBord(
      resume: resume == null ? ResumeDUsage.vide : ResumeDUsage.fromJson(resume),
      jours: _liste(res[1]).map(JourDUsage.fromJson).toList(),
      parts: _liste(res[2]).map(Part.fromJson).toList(),
    );
  }

  static List<Map<String, dynamic>> _liste(dynamic r) => r is List
      ? [for (final e in r) if (e is Map) Map<String, dynamic>.from(e)]
      : const [];

  static Map<String, dynamic>? _premiere(dynamic r) {
    final l = _liste(r);
    if (l.isNotEmpty) return l.first;
    return r is Map ? Map<String, dynamic>.from(r) : null;
  }
}

final adminMetricsServiceProvider = Provider<AdminMetricsService>((ref) {
  return AdminMetricsService(ref.read(supabaseProvider));
});

/// La période regardée, en jours.
final adminPeriodeProvider = StateProvider<int>((ref) => 30);

final adminTableauProvider = FutureProvider<TableauDeBord>((ref) async {
  final jours = ref.watch(adminPeriodeProvider);
  try {
    return await ref.read(adminMetricsServiceProvider).tableauDeBord(jours);
  } catch (e) {
    // `reserve_admin` est le refus attendu pour un compte ordinaire ; le reste est du
    // réseau. Les deux se disent différemment à l'écran.
    AppLogger.warning('ADMIN', 'Tableau de bord indisponible: $e');
    rethrow;
  }
});
