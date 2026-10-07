import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../domain/admin_console.dart';
import 'admin_metrics_service.dart';
import 'admin_personnes_service.dart';

/// La console, deuxième version (V2.4 · R9, migration 060) : réglages, retours suivis,
/// économie et erreurs jour par jour, versions installées. Comme le reste de la console :
/// la session de l'administrateur, et des fonctions serveur qui vérifient est_admin().
class AdminConsoleService {
  final SupabaseClient _client;
  AdminConsoleService(this._client);

  Future<ReglagesDeLaConsole> reglages() async =>
      ReglagesDeLaConsole.fromJson(_objet(await _client.rpc('admin_reglages')));

  /// Écrit un réglage d'app_config ; le serveur vérifie sa forme et le journalise.
  Future<void> regler(String cle, Object? valeur) =>
      _client.rpc('admin_regler', params: {'p_cle': cle, 'p_valeur': valeur});

  Future<List<RetourSuivi>> retours(int jours) async =>
      _liste(await _client.rpc('admin_retours', params: {'p_jours': jours})).map(RetourSuivi.fromJson).toList();

  /// [note] nulle : la note reste ; vide : elle s'efface.
  Future<void> suivreRetour(String id, StatutDeRetour statut, {String? note}) => _client.rpc(
        'admin_suivre_retour',
        params: {'p_id': id, 'p_statut': statut.code, 'p_note': note},
      );

  Future<DetailEconomique> economie(int jours, {bool inclureTests = false}) async => DetailEconomique.fromJson(
      _objet(await _client.rpc('admin_economie_detail', params: {'p_jours': jours, 'p_inclure_tests': inclureTests})));

  Future<List<JourDErreurs>> erreursParJour(int jours) async =>
      _liste(await _client.rpc('admin_erreurs_par_jour', params: {'p_jours': jours}))
          .map(JourDErreurs.fromJson)
          .toList();

  Future<List<Occurrence>> occurrences(String tag, String forme, int jours) async =>
      _liste(await _client.rpc('admin_occurrences', params: {'p_tag': tag, 'p_forme': forme, 'p_jours': jours}))
          .map(Occurrence.fromJson)
          .toList();

  Future<List<VersionInstallee>> versions(int jours) async =>
      _liste(await _client.rpc('admin_versions', params: {'p_jours': jours})).map(VersionInstallee.fromJson).toList();

  /// L'adresse, valable cinq minutes, d'une capture jointe à un retour : la fonction
  /// `sign-feedback-capture` vérifie que l'appelant est administrateur avant de signer.
  Future<String?> adresseDeCapture(String chemin) async {
    final r = await _client.functions.invoke('sign-feedback-capture', body: {'path': chemin});
    final d = r.data;
    return d is Map ? d['url'] as String? : null;
  }

  static Map<String, dynamic> _objet(dynamic r) => r is Map ? Map<String, dynamic>.from(r) : const {};

  static List<Map<String, dynamic>> _liste(dynamic r) => r is List
      ? [
          for (final e in r)
            if (e is Map) Map<String, dynamic>.from(e)
        ]
      : const [];
}

final adminConsoleServiceProvider = Provider<AdminConsoleService>((ref) {
  return AdminConsoleService(ref.read(supabaseProvider));
});

final adminReglagesProvider = FutureProvider<ReglagesDeLaConsole>((ref) {
  return ref.read(adminConsoleServiceProvider).reglages();
});

/// Les retours se regardent sur trente jours au moins : un retour de la semaine dernière
/// n'est pas résolu parce que la fenêtre a changé.
final adminRetoursProvider = FutureProvider<List<RetourSuivi>>((ref) {
  final jours = ref.watch(adminPeriodeProvider);
  return ref.read(adminConsoleServiceProvider).retours(jours < 30 ? 30 : jours);
});

final adminEconomieDetailProvider = FutureProvider<DetailEconomique>((ref) {
  return ref.read(adminConsoleServiceProvider).economie(
        ref.watch(adminPeriodeProvider),
        inclureTests: ref.watch(adminInclureTestsProvider),
      );
});

final adminErreursParJourProvider = FutureProvider<List<JourDErreurs>>((ref) {
  return ref.read(adminConsoleServiceProvider).erreursParJour(ref.watch(adminPeriodeProvider));
});

final adminVersionsProvider = FutureProvider<List<VersionInstallee>>((ref) {
  return ref.read(adminConsoleServiceProvider).versions(ref.watch(adminPeriodeProvider));
});

final adminOccurrencesProvider = FutureProvider.family<List<Occurrence>, (String, String)>((ref, cle) {
  return ref.read(adminConsoleServiceProvider).occurrences(cle.$1, cle.$2, ref.watch(adminPeriodeProvider));
});
