import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:chatmelier/features/offline/data/connectivity_service.dart';

/// 15/10, Pascal (iPhone, en Wi-Fi) : « je suis en wifi et toi tu m'indiques hors ligne ».
/// La sonde unique, 1.1.1.1, était bloquée par son réseau ; ses bouteilles partaient en ligne.
void main() {
  http.Client reseau(int? Function(Uri) reponse, {Duration attente = Duration.zero}) => MockClient((requete) async {
        await Future<void>.delayed(attente);
        final code = reponse(requete.url);
        if (code == null) throw http.ClientException('injoignable', requete.url);
        return http.Response('', code);
      });

  test('1.1.1.1 bloqué, le serveur répond (même par un refus) : en ligne', () async {
    final client = reseau((u) => u.host.contains('supabase') ? 401 : null);
    expect(await ConnectivityService.joignable(client: client), isTrue);
  });

  test('le serveur injoignable mais Google répond : en ligne', () async {
    final client = reseau((u) => u.host == 'www.google.com' ? 204 : null);
    expect(await ConnectivityService.joignable(client: client), isTrue);
  });

  test('rien ne répond : hors ligne', () async {
    expect(await ConnectivityService.joignable(client: reseau((_) => null)), isFalse);
  });

  test('rien ne répond à temps : hors ligne, après une seule attente', () async {
    final debut = DateTime.now();
    final client = reseau((_) => 200, attente: const Duration(seconds: 2));
    expect(await ConnectivityService.joignable(client: client, delai: const Duration(milliseconds: 200)), isFalse);
    expect(DateTime.now().difference(debut), lessThan(const Duration(seconds: 1)));
  });

  test('le serveur de l\'app est sondé en premier', () {
    expect(ConnectivityService.sondes.first.path, '/auth/v1/health');
  });
}
