import 'dart:convert';

import 'package:chatmelier/features/offline/data/offline_storage_service.dart';
import 'package:chatmelier/features/offline/data/sync_service.dart';
import 'package:chatmelier/features/offline/domain/offline_action.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Une base PostgREST réduite à ce que touche la synchronisation d'une dégustation :
/// `wines`, `tasting_log`, `bottles`, avec les deux contraintes qui ont fait perdre le
/// Margaux du 16/09 — la colonne `type` inconnue et la clé étrangère vers `wines`.
class _FausseBase {
  final wines = <String, Map<String, dynamic>>{};
  final degustations = <String, Map<String, dynamic>>{};
  final bouteilles = <String, Map<String, dynamic>>{};
  bool refuserDegustations = false;
  int decomptes = 0;

  http.Response _json(Object? body, int status) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Map<String, dynamic> _avecJointure(String table, Map<String, dynamic> ligne) => {
        ...ligne,
        if (table != 'wines') 'wines': wines[ligne['wine_id']],
      };

  /// postgrest-dart lit `response.request` : MockClient ne le renseigne que si la réponse
  /// renvoyée par le gestionnaire le porte.
  Future<http.Response> repondre(http.Request req) async {
    final r = _repondre(req);
    return http.Response.bytes(r.bodyBytes, r.statusCode, headers: r.headers, request: req);
  }

  http.Response _repondre(http.Request req) {
    final chemin = req.url.path;
    if (chemin == '/rest/v1/' || chemin == '/rest/v1') return http.Response('{}', 200);
    final table = chemin.replaceFirst('/rest/v1/', '');
    final q = req.url.queryParameters;
    final objetAttendu = (req.headers['accept'] ?? '').contains('vnd.pgrst.object');
    final source = switch (table) {
      'wines' => wines,
      'tasting_log' => degustations,
      _ => bouteilles,
    };

    switch (req.method) {
      case 'GET':
        final id = q['id']?.substring(3); // « eq.<uuid> »
        final lignes = [
          for (final l in source.values)
            if (id == null || l['id'] == id) _avecJointure(table, l),
        ];
        return _json(lignes, 200);

      case 'POST':
        final corps = jsonDecode(req.body);
        final ligne = Map<String, dynamic>.from((corps is List ? corps.first : corps) as Map);
        if (table == 'wines') {
          if (ligne.containsKey('type')) {
            return _json({
              'code': 'PGRST204',
              'message': "Could not find the 'type' column of 'wines' in the schema cache",
              'details': null,
              'hint': null,
            }, 400);
          }
          ligne['id'] ??= const Uuid().v4();
          wines[ligne['id'] as String] = ligne;
        } else if (table == 'tasting_log') {
          if (refuserDegustations) {
            return _json({'code': '42501', 'message': 'refus', 'details': null, 'hint': null}, 403);
          }
          if (!wines.containsKey(ligne['wine_id'])) {
            return _json({
              'code': '23503',
              'details': 'Key is not present in table "wines".',
              'hint': null,
              'message': 'insert or update on table "tasting_log" violates foreign key '
                  'constraint "tasting_log_wine_id_fkey"',
            }, 409);
          }
          ligne['id'] ??= const Uuid().v4();
          if (degustations.containsKey(ligne['id'])) {
            return _json({
              'code': '23505',
              'details': 'Key (id) already exists.',
              'hint': null,
              'message': 'duplicate key value violates unique constraint "tasting_log_pkey"',
            }, 409);
          }
          degustations[ligne['id'] as String] = ligne;
        }
        if (!q.containsKey('select')) return http.Response('', 201);
        final cree = _avecJointure(table, ligne);
        return _json(objetAttendu ? cree : [cree], 201);

      case 'PATCH':
        final id = q['id']!.substring(3);
        bouteilles[id]!.addAll(Map<String, dynamic>.from(jsonDecode(req.body) as Map));
        decomptes++;
        return http.Response('', 204);
    }
    return http.Response('inconnu', 404);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FausseBase base;
  late MockClient client;
  late SupabaseClient supabase;
  late OfflineStorageService stockage;
  late SyncService sync;

  const utilisateur = '11111111-1111-4111-8111-111111111111';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stockage = OfflineStorageService(await SharedPreferences.getInstance());
    base = _FausseBase();
    client = MockClient(base.repondre);
    supabase = SupabaseClient(
      'https://test.supabase.co',
      'cle-publique-de-test',
      httpClient: client,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    // Un jeton opaque n'a pas d'expiration lisible : aucune tentative de rafraîchissement.
    await supabase.auth.setInitialSession(jsonEncode({
      'access_token': 'jeton-de-test',
      'token_type': 'bearer',
      'user': {
        'id': utilisateur,
        'aud': 'authenticated',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'created_at': '2026-09-01T00:00:00Z',
      },
    }));
    sync = SyncService(supabase: supabase, offlineStorage: stockage, enrichir: false);
  });

  Future<SyncResult> synchroniser() =>
      http.runWithClient(() => sync.processPendingActions(), () => client);

  OfflineAction degustationExterne({required String wineId, String? id}) => OfflineAction(
        id: id,
        type: OfflineActionType.consumeBottle,
        data: {
          'wine_id': wineId,
          'wine_name': 'Château Margaux',
          'vintage': 2015,
          'region': 'Bordeaux',
          'wine_type': 'red',
          'rating': 7.5,
          'occasion': 'Joubert Street',
          'is_external': true,
          'rating_scale': 10,
        },
      );

  test('le cas du Margaux : un vin jamais créé est recréé sous son identifiant', () async {
    // Le dialogue du 16/09 avait généré l'identifiant du vin, puis raté son insert.
    final vinFantome = const Uuid().v4();
    final action = degustationExterne(wineId: vinFantome);
    await stockage.queueAction(action);

    final resultat = await synchroniser();

    expect(resultat.failed, 0, reason: resultat.errors.join('\n'));
    expect(base.wines[vinFantome]?['wine_type'], 'red');
    expect(base.wines[vinFantome]?.containsKey('type'), isFalse);
    expect(base.degustations[action.id]?['wine_id'], vinFantome);
    expect(stockage.getQueue(), isEmpty);
  });

  test('une dégustation refusée reste en file, puis passe à la tentative suivante', () async {
    final vin = const Uuid().v4();
    final action = degustationExterne(wineId: vin);
    await stockage.queueAction(action);

    base.refuserDegustations = true;
    final premier = await synchroniser();

    expect(premier.failed, 1);
    final enFile = stockage.getQueue().single;
    expect(enFile.status, OfflineActionStatus.failed);
    expect(enFile.retryCount, 1);
    expect(
      stockage.getCachedTastings().single[OfflineStorageService.pendingSyncKey],
      isTrue,
      reason: 'la dégustation reste visible dans le journal en attendant',
    );

    base.refuserDegustations = false;
    final second = await synchroniser();

    expect(second.failed, 0, reason: second.errors.join('\n'));
    expect(base.degustations.keys, [action.id]);
    expect(stockage.getQueue(), isEmpty);
    expect(stockage.getCachedTastings().single[OfflineStorageService.pendingSyncKey], isNull);
  });

  test('sortie de cave : une nouvelle tentative ne décompte pas la bouteille deux fois', () async {
    final vin = const Uuid().v4();
    final bouteille = const Uuid().v4();
    base.wines[vin] = {'id': vin, 'name': 'Penfolds Bin 389', 'wine_type': 'red'};
    base.bouteilles[bouteille] = {'id': bouteille, 'wine_id': vin, 'quantity': 3};
    final action = OfflineAction(
      type: OfflineActionType.consumeBottle,
      data: {'bottle_id': bouteille, 'wine_id': vin, 'quantity': 1, 'rating': 8.0},
    );
    await stockage.queueAction(action);

    base.refuserDegustations = true;
    await synchroniser();
    expect(base.bouteilles[bouteille]!['quantity'], 2);
    expect(stockage.getQueue().single.status, OfflineActionStatus.failed);

    base.refuserDegustations = false;
    final second = await synchroniser();

    expect(second.failed, 0, reason: second.errors.join('\n'));
    expect(base.bouteilles[bouteille]!['quantity'], 2, reason: 'décomptée une seule fois');
    expect(base.decomptes, 1);
    expect(base.degustations.keys, [action.id]);
  });

  test('une dégustation sans note arrive sans note — pas de 5,0 inventé', () async {
    final vin = const Uuid().v4();
    base.wines[vin] = {'id': vin, 'name': 'Penfolds Bin 389', 'wine_type': 'red'};
    final action = degustationExterne(wineId: vin);
    action.data.remove('rating');
    await stockage.queueAction(action);

    final resultat = await synchroniser();

    expect(resultat.failed, 0, reason: resultat.errors.join('\n'));
    expect(base.degustations[action.id]!.containsKey('rating'), isTrue);
    expect(base.degustations[action.id]!['rating'], isNull);
  });

  test('une réponse perdue ne crée pas de doublon : la ligne déjà écrite est relue', () async {
    final vin = const Uuid().v4();
    base.wines[vin] = {'id': vin, 'name': 'Château Margaux', 'wine_type': 'red'};
    final action = degustationExterne(wineId: vin);
    // Écrite en base lors d'une tentative dont la réponse ne serait jamais arrivée.
    base.degustations[action.id] = {'id': action.id, 'wine_id': vin, 'user_id': utilisateur, 'rating': 7.5};
    await stockage.queueAction(action);

    final resultat = await synchroniser();

    expect(resultat.failed, 0, reason: resultat.errors.join('\n'));
    expect(base.degustations, hasLength(1));
    expect(stockage.getQueue(), isEmpty);
  });
}
