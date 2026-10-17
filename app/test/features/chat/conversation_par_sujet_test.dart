import 'dart:convert';

import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/cellar/data/cellar_repository.dart';
import 'package:chatmelier/features/cellar/domain/bottle.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/chat/data/chat_service.dart';
import 'package:chatmelier/features/chat/domain/sujet_de_chat.dart';
import 'package:chatmelier/features/menu_scan/presentation/menu_chat_assistant_sheet.dart';
import 'package:chatmelier/features/offline/data/offline_storage_service.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 13/10, Flavien : « à chaque fois qu'on ouvre le Chatmelier à partir d'un vin, d'un menu,
/// etc... ça devrait spin une nouvelle instance du Chatmelier dédiée à cet item, avec son
/// propre historique, et avec un message d'accueil personnalisé sur l'item ».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => Langue.code = 'fr');

  const wineId = '5f0c2e1a-0d3b-4c2e-9f61-2b7d3c4e5a6b';
  final crozes = SujetDeChat.depuisLAdresse({
    'bottleId': 'b-crozes',
    'wineId': wineId,
    'wineName': 'Crozes-Hermitage',
    'vintage': '2024',
    'producer': 'Domaine Combier',
    'appellation': 'Crozes-Hermitage',
    'region': 'Vallée du Rhône',
    'wineType': 'red',
  })!;

  test('la fiche d\'une bouteille ouvre la conversation de son vin, avec son accueil', () {
    expect(crozes.cle, 'vin:$wineId');
    expect(crozes.titre, 'Crozes-Hermitage 2024');
    // L'appellation est déjà dans le nom : la région la remplace.
    expect(crozes.sousTitre, 'Domaine Combier · Vallée du Rhône');
    expect(crozes.accueil, startsWith('Parlons de votre Crozes-Hermitage 2024.'));
    // Sans identifiant de vin utilisable : le chat général, comme avant.
    expect(SujetDeChat.depuisLAdresse({'wineName': 'Crozes-Hermitage'}), isNull);
    expect(SujetDeChat.depuisLAdresse({'wineId': 'a b', 'wineName': 'Crozes'}), isNull);
  });

  test('le sommelier reçoit le vin en tête de son contexte, avec ce que la cave en sait', () {
    final bouteille = Bottle(
      id: 'b-crozes',
      cellarId: 'c',
      wineId: wineId,
      addedBy: 'u',
      ownerId: 'u',
      quantity: 2,
      rack: 'B3',
      createdAt: DateTime(2026),
      wine: const Wine(
        id: wineId,
        name: 'Crozes-Hermitage',
        producer: 'Domaine Combier',
        vintage: 2024,
        type: 'red',
        country: 'France',
        region: 'Vallée du Rhône',
        appellation: 'Crozes-Hermitage',
        grapes: [Grape(name: 'Syrah')],
      ),
    );
    final contexte = crozes.contexte([bouteille]);
    expect(contexte, startsWith('CURRENT TOPIC'));
    expect(contexte, contains('Grapes: Syrah'));
    expect(contexte, contains('In the cellar: 2 bottle(s), rack B3'));
    expect(contexte, contains('Drinking window:'));
  });

  group('l\'historique d\'un sujet à la fois', () {
    late List<http.BaseRequest> requetes;

    Future<ChatService> service(http.Response Function(http.Request) reponse) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      requetes = [];
      final client = SupabaseClient('https://test.supabase.co', 'cle-publique-de-test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((req) async {
            requetes.add(req);
            final r = reponse(req);
            // Postgrest relit la requête dans la réponse.
            return http.Response(r.body, r.statusCode, headers: r.headers, request: req);
          }));
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
      final stockage = OfflineStorageService(prefs);
      return ChatService(client, CellarRepository(client, stockage), stockage, TasteProfileService());
    }

    http.Response json(Object corps, [int code = 200]) =>
        http.Response(jsonEncode(corps), code, headers: {'content-type': 'application/json; charset=utf-8'});

    test('le vin lit sa conversation, le chat général la sienne', () async {
      final s = await service((_) => json([]));
      await s.getChatHistory('cave-1', sujet: crozes);
      await s.getChatHistory('cave-1');
      expect(requetes[0].url.query, contains('sujet=eq.vin%3A$wineId'));
      expect(requetes[0].url.query, contains('user_id=eq.11111111-1111-4111-8111-111111111111'));
      expect(requetes[1].url.query, contains('sujet=is.null'));
    });

    test('« Effacer » n\'efface que la conversation ouverte', () async {
      final s = await service((_) => json([]));
      await s.clearChatHistory('cave-1', sujet: crozes);
      await s.clearChatHistory('cave-1');
      expect(requetes.map((r) => r.method), ['DELETE', 'DELETE']);
      expect(requetes[0].url.query, contains('sujet=eq.vin%3A$wineId'));
      expect(requetes[1].url.query, contains('sujet=is.null'));
    });

    test('avant la migration 071 : le chat général relit tout, le vin part de zéro', () async {
      final sansColonne = json({'code': '42703', 'message': 'column chat_messages.sujet does not exist'}, 400);
      final s = await service((req) => req.url.query.contains('sujet') ? sansColonne : json([
            {'id': 'm1', 'role': 'user', 'content': 'Que boire ce soir ?', 'created_at': '2026-10-17T10:00:00Z'},
          ]));
      final general = await s.getChatHistory('cave-1');
      expect(general.single.content, 'Que boire ce soir ?');
      expect(await s.getChatHistory('cave-1', sujet: crozes), isEmpty);
    });
  });

  group('la conversation d\'une carte, gardée sur le téléphone', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    MenuChatMessage m(String t, {bool user = true, bool hors = false}) =>
        MenuChatMessage(text: t, isUser: user, time: DateTime(2026, 10, 17), horsEchange: hors);

    test('l\'échange revient à la réouverture, sans l\'accueil ni les erreurs', () async {
      await ConversationsDeCarte.ecrire('carte-1', [
        m('Bonjour !', user: false, hors: true),
        m('Un rouge léger ?'),
        m('Le Morgon de Lapierre, 48 €.', user: false),
        m('Désolé, une erreur est survenue', user: false, hors: true),
      ]);
      final relus = await ConversationsDeCarte.lire('carte-1');
      expect(relus.map((x) => (x.text, x.isUser)), [('Un rouge léger ?', true), ('Le Morgon de Lapierre, 48 €.', false)]);
      await ConversationsDeCarte.effacer('carte-1');
      expect(await ConversationsDeCarte.lire('carte-1'), isEmpty);
    });

    test('peu de chose : les douze derniers messages, de cinq cartes au plus', () async {
      await ConversationsDeCarte.ecrire('carte-0', [for (var i = 0; i < 20; i++) m('message $i')]);
      final relus = await ConversationsDeCarte.lire('carte-0');
      expect(relus.length, ConversationsDeCarte.messagesGardes);
      expect(relus.first.text, 'message 8');
      for (var i = 1; i <= 5; i++) {
        await ConversationsDeCarte.ecrire('carte-$i', [m('question $i')]);
      }
      // La plus ancienne est partie ; les cinq dernières restent.
      expect(await ConversationsDeCarte.lire('carte-0'), isEmpty);
      expect((await ConversationsDeCarte.lire('carte-5')).single.text, 'question 5');
    });
  });
}
