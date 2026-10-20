import 'dart:convert';

import 'package:chatmelier/shared/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Les journaux de diagnostic (T3, revue du 20/10) : chaque ligne arrivait deux ou trois
/// fois en production — un lot « expiré » au bout de 5 s était souvent arrivé quand même,
/// restait en file et repartait. Chaque ligne porte désormais son identifiant ; le serveur
/// refuse un doublon (clé primaire, 23505) et l'app le tient pour rangé.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Le serveur : la table, sa clé primaire, et ce qu'il répond.
  late Map<String, Map<String, dynamic>> table;
  late int appels;
  late bool rangeMaisRepondUneErreur;
  late bool coupure;

  http.Response repondre(http.Request req) {
    appels++;
    if (coupure) throw http.ClientException('Connection refused');
    final lignes = [for (final l in jsonDecode(req.body) as List) Map<String, dynamic>.from(l as Map)];
    if (lignes.any((l) => table.containsKey(l['id']))) {
      // PostgREST : une violation d'unicité annule tout l'insert et répond 409.
      return http.Response(
        jsonEncode({'code': '23505', 'message': 'duplicate key value violates unique constraint "app_diagnostic_logs_pkey"'}),
        409,
        headers: {'content-type': 'application/json'},
        request: req,
      );
    }
    for (final l in lignes) {
      table[l['id'] as String] = l;
    }
    // L'envoi est arrivé, mais l'app ne l'a pas su (délai dépassé, réponse perdue).
    if (rangeMaisRepondUneErreur) return http.Response('', 504, request: req);
    return http.Response('', 201, request: req);
  }

  setUp(() {
    table = {};
    appels = 0;
    rangeMaisRepondUneErreur = false;
    coupure = false;
    AppLogger.clear();
    AppLogger.init(SupabaseClient(
      'https://test.supabase.co',
      'cle-publique-de-test',
      httpClient: MockClient((req) async => repondre(req)),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    ));
  });

  test('chaque ligne part avec son identifiant et la version du build', () async {
    AppLogger.info('ESSAI', 'un');
    AppLogger.info('ESSAI', 'deux');
    expect(await AppLogger.flushToServer(), 2);
    expect(table, hasLength(2));
    expect(table.keys.toSet(), AppLogger.logs.map((e) => e.id).toSet());
    expect(table.values.map((l) => l['app_version']).toSet(), {'dev-debug'},
        reason: 'un essai hors release ne se fait pas passer pour la version publiée');
    expect(AppLogger.pendingCount, 0);
  });

  test('un lot arrivé sans que l\'app le sache n\'est pas enregistré une seconde fois', () async {
    AppLogger.info('ESSAI', 'un');
    AppLogger.info('ESSAI', 'deux');
    rangeMaisRepondUneErreur = true;
    expect(await AppLogger.flushToServer(), 0);
    expect(AppLogger.pendingCount, 2, reason: 'l\'app croit l\'envoi perdu et garde les lignes');
    expect(table, hasLength(2), reason: 'elles sont pourtant arrivées');

    rangeMaisRepondUneErreur = false;
    AppLogger.info('ESSAI', 'trois');
    expect(await AppLogger.flushToServer(), 3);
    expect(table, hasLength(3), reason: 'trois lignes, aucune en double');
    expect(table.values.map((l) => l['message']), unorderedEquals(['un', 'deux', 'trois']));
    expect(AppLogger.pendingCount, 0, reason: 'les doublons refusés sont tenus pour rangés');
  });

  test('une coupure de réseau garde toute la file', () async {
    AppLogger.info('ESSAI', 'un');
    coupure = true;
    expect(await AppLogger.flushToServer(), 0);
    expect(AppLogger.pendingCount, 1);
    coupure = false;
    expect(await AppLogger.flushToServer(), 1);
    expect(table, hasLength(1));
  });

  test('le niveau debug reste sur l\'appareil', () async {
    AppLogger.debug('ESSAI', 'détail');
    expect(AppLogger.pendingCount, 0);
    expect(await AppLogger.flushToServer(), 0);
    expect(appels, 0);
  });
}
