import 'dart:convert';
import 'dart:typed_data';

import 'package:chatmelier/features/menu_scan/data/menu_scan_service.dart';
import 'package:chatmelier/features/menu_scan/data/wine_knowledge_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 15/10, Flavien : « quand tu scannes un menu, donne aussi à gemini la liste des lieux
/// proches […] afin de voir s'il est certain que la carte vient de l'un d'entre eux, pour
/// pouvoir donner un titre à la carte (overridable par l'utilisateur) ».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(Map<String, dynamic>, String)> scanner({required List<String> lieux, String? reconnu}) async {
    SharedPreferences.setMockInitialValues({});
    final client = SupabaseClient('https://test.supabase.co', 'cle-publique-de-test',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    await client.auth.setInitialSession(jsonEncode({
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
    Map<String, dynamic>? envoye;
    final service = MenuScanService(
      WineKnowledgeCacheService(),
      client,
      () => MockClient((req) async {
        envoye = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            // Le nom imprimé en tête de la carte, abrégé.
            'restaurant_name': 'BISTROT DU PORT',
            'lieu_reconnu': reconnu,
            'currency': 'EUR',
            'wines': [
              {'name': 'Morgon', 'producer': 'Lapierre', 'wine_type': 'red', 'bottle_price': 48},
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final carte = await service.analyzeMenuPages(
      imagePaths: const [],
      imageBytesList: [Uint8List.fromList(List.filled(64, 7))],
      lieuxProches: lieux,
    );
    return (envoye!, carte.restaurantName);
  }

  test('les noms des lieux proches partent, jamais la position ; le lieu reconnu nomme la carte', () async {
    final (corps, nom) = await scanner(lieux: ['Le Bistrot du Port', 'Chez Paul'], reconnu: 'Le Bistrot du Port');
    expect(corps['lieux_proches'], ['Le Bistrot du Port', 'Chez Paul']);
    expect(corps.keys.where((k) => k.contains('lat') || k.contains('lon') || k.contains('position')), isEmpty);
    expect(nom, 'Le Bistrot du Port');
  });

  test('aucun lieu reconnu : le nom imprimé sur la carte ; aucun lieu proche : rien ne part', () async {
    final (_, nom) = await scanner(lieux: ['Chez Paul'], reconnu: null);
    expect(nom, 'BISTROT DU PORT');
    final (corps, _) = await scanner(lieux: const []);
    expect(corps.containsKey('lieux_proches'), isFalse);
  });
}
