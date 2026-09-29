import 'dart:convert';

import 'package:chatmelier/features/auth/data/ai_cost_tracker_service.dart';
import 'package:chatmelier/features/auth/domain/ai_cost_event.dart';
import 'package:chatmelier/shared/services/envoi_par_lots.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// La mesure (S5) : coûts IA et pubs partent au serveur par lots, sans rien bloquer,
/// sans rien perdre, sans rien compter deux fois.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> recues;
  late int statut;
  late SupabaseClient supabase;

  Future<SupabaseClient> client({bool connecte = true}) async {
    final c = SupabaseClient(
      'https://test.supabase.co',
      'cle-publique-de-test',
      httpClient: MockClient((req) async {
        recues.add(req);
        return http.Response('', statut, request: req);
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    if (connecte) {
      await c.auth.setInitialSession(jsonEncode({
        'access_token': 'jeton-de-test',
        'token_type': 'bearer',
        'user': {
          'id': '11111111-1111-4111-8111-111111111111',
          'aud': 'authenticated',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'created_at': '2026-09-01T00:00:00Z',
        },
      }));
    }
    return c;
  }

  Map<String, dynamic> ligne(String id) => {'event_id': id, 'feature': 'menu_scan_vision'};

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    recues = [];
    statut = 201;
    supabase = await client();
  });

  test('un lot part en un seul appel, sans doublon possible, et la file se vide', () async {
    final envoi = EnvoiParLots(table: 'ai_cost_events', cleLocale: 'test_file', envoiAutomatique: false, client: () => supabase);
    await envoi.ajouter(ligne('a'));
    await envoi.ajouter(ligne('b'));
    expect(await envoi.enAttente(), 2);

    expect(await envoi.envoyer(), 2);
    expect(recues, hasLength(1), reason: 'un lot, un appel');
    final req = recues.single;
    expect(req.method, 'POST');
    expect(req.url.path, '/rest/v1/ai_cost_events');
    expect(req.url.queryParameters['on_conflict'], 'event_id');
    expect(req.headers['Prefer'], contains('resolution=ignore-duplicates'),
        reason: 'renvoyer un lot après une coupure ne compte rien deux fois');
    expect((jsonDecode(req.body) as List).map((l) => l['event_id']), ['a', 'b']);
    expect(await envoi.enAttente(), 0);
  });

  test('un échec garde la file intacte pour le prochain passage', () async {
    statut = 500;
    final envoi = EnvoiParLots(table: 'ad_impressions', cleLocale: 'test_file', envoiAutomatique: false, client: () => supabase);
    await envoi.ajouter(ligne('a'));
    expect(await envoi.envoyer(), 0);
    expect(await envoi.enAttente(), 1, reason: 'rien n\'est perdu');
    statut = 201;
    expect(await envoi.envoyer(), 1);
    expect(await envoi.enAttente(), 0);
  });

  test('sans session, rien ne part et rien ne se perd', () async {
    final sansCompte = await client(connecte: false);
    final envoi = EnvoiParLots(table: 'ai_cost_events', cleLocale: 'test_file', envoiAutomatique: false, client: () => sansCompte);
    await envoi.ajouter(ligne('a'));
    expect(await envoi.envoyer(), 0);
    expect(recues, isEmpty);
    expect(await envoi.enAttente(), 1);
  });

  test('la file est plafonnée : les plus anciens tombent d\'abord', () async {
    final envoi = EnvoiParLots(table: 't', cleLocale: 'test_file', maxEnAttente: 3, envoiAutomatique: false, client: () => null);
    for (final id in ['1', '2', '3', '4', '5']) {
      await envoi.ajouter(ligne(id));
    }
    final prefs = await SharedPreferences.getInstance();
    final file = jsonDecode(prefs.getString('test_file')!) as List;
    expect(file.map((l) => l['event_id']), ['3', '4', '5']);
  });

  test('la ligne serveur d\'un coût IA respecte la table 047', () {
    final e = AiCostEvent(
      id: 'e1',
      model: 'gemini-3.8-flash',
      feature: 'menu_scan_vision',
      promptTokens: 1200,
      candidatesTokens: 800,
      totalTokens: 2000,
      isSearchGrounded: false,
      costEur: 0.00123456789,
      costUsd: 0.0013,
      timestamp: DateTime.utc(2026, 9, 29, 20, 5),
    );
    final l = AiCostTrackerService.ligneServeur(e);
    expect(l['event_id'], 'e1');
    expect(l['occurred_at'], '2026-09-29T20:05:00.000Z');
    expect(l['build_mode'], anyOf('release', 'profile', 'debug'));
    expect(l['platform'], anyOf('android', 'ios', 'web', 'other'));
    expect(l['prompt_tokens'], 1200);
    expect(l['output_tokens'], 800);
    expect(l['grounded'], isFalse);
    expect(l['cost_eur'], 0.001235, reason: 'six décimales, comme NUMERIC(12, 6)');
  });
}
