import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../domain/admin_personnes.dart';
import 'admin_metrics_service.dart';

/// La console, personne par personne (migration 044).
///
/// Même principe que les agrégats : aucune clé embarquée, la session de l'administrateur
/// et des fonctions serveur qui vérifient `profiles.is_admin`.
class AdminPersonnesService {
  final SupabaseClient _client;
  AdminPersonnesService(this._client);

  Future<bool> nominatif() async => (await _client.rpc('admin_nominatif')) == true;

  Future<List<Personne>> personnes(int jours) async =>
      _liste(await _client.rpc('admin_personnes', params: {'p_jours': jours})).map(Personne.fromJson).toList();

  Future<List<EvenementDuFil>> fil(String userId, int jours) async => _liste(
          await _client.rpc('admin_fil_personne', params: {'p_user_id': userId, 'p_jours': jours}))
      .map(EvenementDuFil.fromJson)
      .toList();

  Future<List<MessageDeConversation>> conversations(String userId, int jours) async => _liste(
          await _client.rpc('admin_conversations', params: {'p_user_id': userId, 'p_jours': jours}))
      .map(MessageDeConversation.fromJson)
      .toList();

  Future<List<ErreurGroupee>> erreurs(int jours) async =>
      _liste(await _client.rpc('admin_erreurs', params: {'p_jours': jours})).map(ErreurGroupee.fromJson).toList();

  Future<List<Usage>> usages(int jours) async =>
      _liste(await _client.rpc('admin_usages', params: {'p_jours': jours})).map(Usage.fromJson).toList();

  static List<Map<String, dynamic>> _liste(dynamic r) => r is List
      ? [for (final e in r) if (e is Map) Map<String, dynamic>.from(e)]
      : const [];
}

final adminPersonnesServiceProvider = Provider<AdminPersonnesService>((ref) {
  return AdminPersonnesService(ref.read(supabaseProvider));
});

final adminNominatifProvider = FutureProvider<bool>((ref) {
  return ref.read(adminPersonnesServiceProvider).nominatif();
});

final adminPersonnesProvider = FutureProvider<List<Personne>>((ref) {
  return ref.read(adminPersonnesServiceProvider).personnes(ref.watch(adminPeriodeProvider));
});

final adminErreursProvider = FutureProvider<List<ErreurGroupee>>((ref) {
  return ref.read(adminPersonnesServiceProvider).erreurs(ref.watch(adminPeriodeProvider));
});

final adminUsagesProvider = FutureProvider<List<Usage>>((ref) {
  return ref.read(adminPersonnesServiceProvider).usages(ref.watch(adminPeriodeProvider));
});

final adminFilProvider = FutureProvider.family<List<EvenementDuFil>, String>((ref, userId) {
  return ref.read(adminPersonnesServiceProvider).fil(userId, ref.watch(adminPeriodeProvider));
});

/// Les conversations se regardent sur trois mois au moins : une question de juin éclaire
/// souvent celle de septembre.
final adminConversationsProvider = FutureProvider.family<List<MessageDeConversation>, String>((ref, userId) {
  final jours = ref.watch(adminPeriodeProvider);
  return ref.read(adminPersonnesServiceProvider).conversations(userId, jours < 90 ? 90 : jours);
});
