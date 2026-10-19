// V2.5 · Q2 (revue du 18/10) — une cave créée « hors ligne » perdait ses bouteilles.
//
// La création basculait hors ligne sur n'importe quelle erreur (en production, une colonne
// absente jusqu'à la migration 074 : chaque cave après la première), sous un identifiant
// provisoire sans le préfixe « temp_ » que la synchronisation attend. La cave était recréée
// sur le serveur sous un autre identifiant, mais les bouteilles ajoutées entre-temps
// gardaient l'ancien : refusées par la clé étrangère, ou rangées dans la première cave venue.

import 'dart:convert';

import 'package:chatmelier/features/cellar/data/cellar_repository.dart';
import 'package:chatmelier/features/offline/data/offline_storage_service.dart';
import 'package:chatmelier/features/offline/data/sync_service.dart';
import 'package:chatmelier/features/offline/domain/offline_action.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const _moi = '11111111-1111-4111-8111-111111111111';

/// PostgREST réduit à ce que touchent la création d'une cave et l'ajout d'une bouteille,
/// avec la clé étrangère des bouteilles vers les caves.
class _FausseBase {
  final caves = <String, Map<String, dynamic>>{};
  final vins = <String, Map<String, dynamic>>{};
  final bouteilles = <String, Map<String, dynamic>>{};
  bool coupureSurLesCaves = false;
  bool refusDesCaves = false;

  http.Response _json(Object? corps, int statut) =>
      http.Response(jsonEncode(corps), statut, headers: {'content-type': 'application/json; charset=utf-8'});

  Future<http.Response> repondre(http.Request req) async {
    final table = req.url.path.replaceFirst('/rest/v1/', '');
    if (table == 'cellars' && req.method == 'POST' && coupureSurLesCaves) {
      throw http.ClientException('Failed host lookup: test.supabase.co', req.url);
    }
    final r = _repondre(req, table);
    return http.Response.bytes(r.bodyBytes, r.statusCode, headers: r.headers, request: req);
  }

  http.Response _repondre(http.Request req, String table) {
    final objet = (req.headers['accept'] ?? '').contains('vnd.pgrst.object');
    if (req.method == 'GET') {
      final source = switch (table) { 'cellars' => caves, 'wines' => vins, _ => bouteilles };
      return _json(objet ? null : source.values.toList(), 200);
    }
    if (req.method != 'POST') return http.Response('', 204);
    final corps = jsonDecode(req.body);
    final ligne = Map<String, dynamic>.from((corps is List ? corps.first : corps) as Map);
    switch (table) {
      case 'cellars':
        if (refusDesCaves) {
          return _json({'code': 'PGRST204', 'message': "Could not find the 'radius_meters' column", 'details': null, 'hint': null}, 400);
        }
        ligne['id'] = const Uuid().v4();
        ligne['created_at'] = '2026-10-19T10:00:00Z';
        caves[ligne['id'] as String] = ligne;
      case 'cellar_members':
        return http.Response('', 201);
      case 'wines':
        ligne['id'] = const Uuid().v4();
        vins[ligne['id'] as String] = ligne;
      case 'bottles':
        if (!caves.containsKey(ligne['cellar_id'])) {
          return _json({
            'code': '23503',
            'details': 'Key is not present in table "cellars".',
            'hint': null,
            'message': 'insert or update on table "bottles" violates foreign key constraint "bottles_cellar_id_fkey"',
          }, 409);
        }
        ligne['id'] = const Uuid().v4();
        bouteilles[ligne['id'] as String] = ligne;
        return _json({...ligne, 'wines': vins[ligne['wine_id']]}, 201);
      default:
        return http.Response('', 201);
    }
    return _json(objet ? ligne : [ligne], 201);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FausseBase base;
  late SupabaseClient supabase;
  late OfflineStorageService stockage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stockage = OfflineStorageService(await SharedPreferences.getInstance());
    base = _FausseBase();
    supabase = SupabaseClient('https://test.supabase.co', 'cle-publique-de-test',
        httpClient: MockClient(base.repondre), authOptions: const AuthClientOptions(autoRefreshToken: false));
    await supabase.auth.setInitialSession(jsonEncode({
      'access_token': 'jeton-de-test',
      'token_type': 'bearer',
      'user': {
        'id': _moi,
        'aud': 'authenticated',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'created_at': '2026-09-01T00:00:00Z',
      },
    }));
  });

  OfflineAction bouteilleDansLaCave(String caveId) => OfflineAction(
        id: const Uuid().v4(),
        type: OfflineActionType.addBottle,
        cellarId: caveId,
        createdAt: DateTime(2026, 10, 19, 10, 5),
        data: {
          'temp_bottle_id': 'temp_${const Uuid().v4()}',
          'cellar_id': caveId,
          'wine_name': 'Crozes-Hermitage',
          'vintage': 2021,
          'producer': 'Alain Graillot',
          'wine_type': 'red',
          'country': 'France',
          'region': 'Vallée du Rhône',
          'appellation': 'Crozes-Hermitage',
          'quantity': 2,
        },
      );

  group('créer une cave', () {
    test('un refus du serveur se dit : pas de cave fantôme sur le téléphone', () async {
      base.refusDesCaves = true;
      final depot = CellarRepository(supabase, stockage);
      await expectLater(depot.createCellar(name: 'Cave de Vosges'), throwsA(anything));
      expect(stockage.getCachedCellars(), isEmpty);
      expect(stockage.getQueue(), isEmpty);
    });

    test('une coupure donne une cave provisoire « temp_ », à recréer', () async {
      base.coupureSurLesCaves = true;
      final depot = CellarRepository(supabase, stockage);
      final cave = await depot.createCellar(name: 'Cave de Vosges', latitude: 48.1, longitude: 6.9);
      expect(cave.id, startsWith('temp_'));
      expect(stockage.getQueue().single.type, OfflineActionType.createCellar);
      expect(stockage.getQueue().single.cellarId, cave.id);
    });
  });

  group('la synchronisation d\'une cave créée hors ligne', () {
    test('la cave est recréée avec son lieu, et ses bouteilles la suivent', () async {
      base.coupureSurLesCaves = true;
      final depot = CellarRepository(supabase, stockage);
      final provisoire = await depot.createCellar(name: 'Cave de Vosges', latitude: 48.1, longitude: 6.9);
      await stockage.enqueueAction(bouteilleDansLaCave(provisoire.id));
      await stockage.saveLastSelectedCellarId(provisoire.id);

      base.coupureSurLesCaves = false;
      final remplacements = <(String, String)>[];
      final abonnement = SyncService.cavesRecreees.listen(remplacements.add);
      final resultat = await SyncService(supabase: supabase, offlineStorage: stockage, enrichir: false).processPendingActions();
      await abonnement.cancel();

      expect(resultat.failed, 0, reason: resultat.errors.join('\n'));
      final reelle = base.caves.values.single;
      expect(reelle['latitude'], 48.1);
      expect(base.bouteilles.values.single['cellar_id'], reelle['id']);
      expect(stockage.getLastSelectedCellarId(), reelle['id']);
      expect(stockage.getCachedCellars().map((c) => c.id), [reelle['id']]);
      expect(remplacements, [(provisoire.id, reelle['id'])]);
    });

    test('tant que sa cave n\'existe pas, une bouteille attend, au lieu de partir dans une autre', () async {
      base.caves['autre'] = {'id': 'autre', 'name': 'Ma Cave', 'owner_id': _moi};
      base.coupureSurLesCaves = true;
      final depot = CellarRepository(supabase, stockage);
      final provisoire = await depot.createCellar(name: 'Cave de Vosges');
      await stockage.enqueueAction(bouteilleDansLaCave(provisoire.id));

      final resultat = await SyncService(supabase: supabase, offlineStorage: stockage, enrichir: false).processPendingActions();
      expect(resultat.failed, 2);
      expect(base.bouteilles, isEmpty);
      final bouteille = stockage.getQueue().firstWhere((a) => a.type == OfflineActionType.addBottle);
      expect(bouteille.errorMessage, contains('pas encore créée'));

      base.coupureSurLesCaves = false;
      final ensuite = await SyncService(supabase: supabase, offlineStorage: stockage, enrichir: false).processPendingActions();
      expect(ensuite.failed, 0, reason: ensuite.errors.join('\n'));
      expect(base.bouteilles.values.single['cellar_id'], isNot('autre'));
    });
  });
}
