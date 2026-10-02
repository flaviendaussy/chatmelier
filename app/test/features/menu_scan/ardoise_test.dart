import 'dart:convert';
import 'dart:typed_data';

import 'package:chatmelier/features/menu_scan/data/menu_scan_service.dart';
import 'package:chatmelier/features/menu_scan/data/wine_knowledge_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// L'ardoise d'un bar (V2.3 · J4) : le serveur la lit en mode ardoise, et la carte qui en
/// sort le sait.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(Map<String, dynamic>, bool)> scanner({required bool ardoise}) async {
    SharedPreferences.setMockInitialValues({});
    final client = SupabaseClient('https://test.supabase.co', 'cle-publique-de-test',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    // Une session déjà là : pas d'inscription anonyme pendant l'essai.
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
            'restaurant_name': 'Le Bar à Vins',
            'currency': 'EUR',
            'mode': ardoise ? 'ardoise' : 'carte',
            'wines': [
              {
                'name': 'Morgon Côte du Py',
                'producer': 'Jean Foillard',
                'wine_type': 'red',
                'bottle_price': null,
                'glass_prices': [
                  {'format': 'verre', 'price': 9},
                ],
              },
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
      ardoise: ardoise,
    );
    return (envoye!, carte.ardoise);
  }

  test('l\'ardoise part en mode ardoise, et la carte qui en revient le sait', () async {
    final (corps, ardoise) = await scanner(ardoise: true);
    expect(corps['mode'], 'ardoise');
    expect(ardoise, isTrue);
  });

  test('une carte ordinaire ne dit rien de plus : la fonction déjà déployée la lit comme avant', () async {
    final (corps, ardoise) = await scanner(ardoise: false);
    expect(corps.containsKey('mode'), isFalse);
    expect(ardoise, isFalse);
  });
}
