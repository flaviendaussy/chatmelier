import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import 'taste_profile_service.dart';

/// Toutes mes données, en un fichier (RGPD, droits d'accès et de portabilité, articles 15
/// et 20). Manquant au 28/09 (`PROD_MIGRATION.md`, V2.1 · 0.6) : la suppression du
/// compte existait, l'export non. Fait le 08/10.
///
/// Ce que la personne peut lire d'elle-même, sous ses propres droits (RLS) : rien n'est
/// lu au-delà. Une partie illisible (réseau, table absente) n'empêche pas le reste, et le
/// fichier dit ce qui manque plutôt que de se taire.
class ExportDesDonnees {
  final SupabaseClient _client;
  final TasteProfileService _profils;

  ExportDesDonnees(this._client, this._profils);

  static const format = 'chatmelier-export-v1';

  /// Les journaux de diagnostic les plus récents : au-delà, le fichier deviendrait
  /// illisible sans rien apprendre de plus à la personne.
  static const journauxAuPlus = 2000;

  Future<Map<String, dynamic>> rassembler({DateTime? maintenant}) async {
    final moi = _client.auth.currentUser;
    if (moi == null) throw StateError('sans_session');
    final manquants = <String>[];

    Future<T?> lire<T>(String partie, Future<T> Function() requete) async {
      try {
        return await requete();
      } catch (e) {
        manquants.add(partie);
        AppLogger.warning('EXPORT_DONNEES', '$partie illisible : $e');
        return null;
      }
    }

    final compte = await lire('compte', () => _client.from('profiles').select().eq('id', moi.id).maybeSingle());
    final caves = await lire(
        'caves', () => _client.from('cellar_members').select('role, cellar_id, cellars(*)').eq('user_id', moi.id));
    final caveIds = [for (final m in caves ?? const <dynamic>[]) (m as Map)['cellar_id']].whereType<String>().toList();
    final bouteilles = caveIds.isEmpty
        ? const <dynamic>[]
        : await lire('bouteilles', () => _client.from('bottles').select('*, wines(*)').inFilter('cellar_id', caveIds));
    final degustations = await lire('degustations',
        () => _client.from('tasting_log').select('*, wines(*)').eq('user_id', moi.id).order('consumed_at'));
    final conversations = await lire(
        'conversations',
        () => _client
            .from('chat_messages')
            .select('cellar_id, role, content, created_at')
            .eq('user_id', moi.id)
            .order('created_at'));
    final amis = await lire('amis',
        () => _client.from('friendships').select('id, user_id, friend_id, status, created_at').or('user_id.eq.${moi.id},friend_id.eq.${moi.id}'));
    final palaisServeur =
        await lire('palais_serveur', () => _client.from('palais_utilisateur').select().eq('user_id', moi.id).maybeSingle());
    final journaux = await lire(
        'journaux',
        () => _client
            .from('app_diagnostic_logs')
            .select('created_at, level, tag, message, platform, app_version')
            .eq('user_id', moi.id)
            .order('created_at', ascending: false)
            .limit(journauxAuPlus));
    final palaisLocal = await lire('palais_appareil', () async => [for (final p in await _profils.getProfiles()) p.toJson()]);

    return {
      'format': format,
      'exporte_le': (maintenant ?? DateTime.now()).toUtc().toIso8601String(),
      'compte': {
        'id': moi.id,
        'email': moi.email,
        'cree_le': moi.createdAt,
        'anonyme': moi.isAnonymous,
        if (compte != null) 'profil': compte,
      },
      'caves': caves ?? const [],
      'bouteilles': bouteilles ?? const [],
      'degustations': degustations ?? const [],
      'palais': {
        'sur_cet_appareil': palaisLocal ?? const [],
        'sur_le_serveur': palaisServeur,
      },
      'conversations_avec_le_sommelier': conversations ?? const [],
      'amis': amis ?? const [],
      'journaux_de_diagnostic': journaux ?? const [],
      if (manquants.isNotEmpty) 'non_exporte': manquants,
    };
  }

  /// Le fichier JSON, daté, partagé (téléphone) ou téléchargé (web). Rend le nombre de
  /// parties qui n'ont pas pu être lues.
  Future<int> partager() async {
    final donnees = await rassembler();
    final octets = utf8.encode(const JsonEncoder.withIndent('  ').convert(donnees));
    final nom = 'chatmelier-mes-donnees-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
    await Share.shareXFiles(
      [XFile.fromData(Uint8List.fromList(octets), mimeType: 'application/json', name: nom)],
      fileNameOverrides: [nom],
      subject: tr('Mes données Chatmelier', 'My Chatmelier data'),
    );
    return (donnees['non_exporte'] as List?)?.length ?? 0;
  }
}

final exportDesDonneesProvider = Provider<ExportDesDonnees>((ref) {
  return ExportDesDonnees(ref.read(supabaseProvider), ref.read(tasteProfileServiceProvider));
});
