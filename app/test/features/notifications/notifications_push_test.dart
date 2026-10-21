import 'dart:convert';

import 'package:chatmelier/features/auth/domain/user_profile.dart';
import 'package:chatmelier/features/friends/data/friends_repository.dart';
import 'package:chatmelier/features/notifications/data/notification_preferences_service.dart';
import 'package:chatmelier/features/notifications/data/notifications_push.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Les notifications push (lot N, version 86) côté app : ce que le serveur apprend des
/// préférences, et les demandes d'ami qui passent par le serveur — seule une notification
/// écrite par le serveur part en push (migration 075).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le serveur reçoit ce que la personne a coupé, et ses heures calmes', () {
    const tout = NotificationPreferences();
    expect(NotificationsPush.preferencesDuServeur(tout), {
      'activite_cave': true,
      'amis': true,
      'degustations': true,
      'heures_calmes': true,
      'calme_debut': 22,
      'calme_fin': 8.5,
    });
    final coupe = tout.copyWith(sharedCellarActivityEnabled: false, friendRequestsEnabled: false, quietHoursEnabled: false);
    expect(NotificationsPush.preferencesDuServeur(coupe), {
      'activite_cave': false,
      'amis': false,
      'degustations': false,
      'heures_calmes': false,
      'calme_debut': 22,
      'calme_fin': 8.5,
    });
  });

  test('sans identifiants Firebase (tests, web, builds de développement), les push restent éteints', () {
    expect(NotificationsPush.disponible, isFalse);
  });

  group('demandes d\'ami par le serveur', () {
    late List<http.Request> recues;
    late bool fonctionsAbsentes;

    Future<FriendsRepository> depot() async {
      final client = SupabaseClient(
        'https://test.supabase.co',
        'cle-publique-de-test',
        httpClient: MockClient((req) async {
          recues.add(req);
          if (req.url.path.startsWith('/rest/v1/rpc/') && fonctionsAbsentes) {
            return http.Response(
              jsonEncode({'code': 'PGRST202', 'message': 'Could not find the function public.demander_amitie'}),
              404,
              headers: {'content-type': 'application/json'},
              request: req,
            );
          }
          return http.Response(req.url.path.startsWith('/rest/v1/rpc/') ? '{"success": true}' : '', req.method == 'POST' ? 201 : 200,
              headers: {'content-type': 'application/json'}, request: req);
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      await client.auth.setInitialSession(jsonEncode({
        'access_token': 'jeton-de-test',
        'token_type': 'bearer',
        'user': {
          'id': '11111111-1111-4111-8111-111111111111',
          'aud': 'authenticated',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{'display_name': 'Flavien'},
          'created_at': '2026-09-01T00:00:00Z',
        },
      }));
      return FriendsRepository(client);
    }

    const caro = UserProfile(id: '22222222-2222-4222-8222-222222222222', displayName: 'Caro');

    setUp(() {
      recues = [];
      fonctionsAbsentes = false;
    });

    test('demander : un seul appel, à demander_amitie — rien d\'écrit directement', () async {
      await (await depot()).sendFriendRequest(caro);
      expect(recues.map((r) => r.url.path), ['/rest/v1/rpc/demander_amitie']);
      expect(jsonDecode(recues.single.body), {'p_ami': caro.id});
    });

    test('accepter : accepter_amitie, avec le demandeur', () async {
      await (await depot()).acceptFriendRequest('amitie-1', caro.id);
      expect(recues.map((r) => r.url.path), ['/rest/v1/rpc/accepter_amitie']);
      expect(jsonDecode(recues.single.body), {'p_demandeur': caro.id});
    });

    test('fonction absente du serveur : l\'ancien chemin prend le relais', () async {
      fonctionsAbsentes = true;
      await (await depot()).sendFriendRequest(caro);
      expect(recues.map((r) => r.url.path),
          ['/rest/v1/rpc/demander_amitie', '/rest/v1/friendships', '/rest/v1/user_notifications']);
    });
  });
}
