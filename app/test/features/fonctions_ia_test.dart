import 'package:chatmelier/features/auth/data/ai_cost_tracker_service.dart';
import 'package:chatmelier/shared/services/fonctions_ia.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Les appels aux fonctions IA du serveur (V2.3 · B2, C3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('une réponse rend ses données et enregistre ses coûts', () async {
    final suivi = AiCostTrackerService();
    await suivi.clearHistory();
    final ia = FonctionsIa.pourEssai((f, c) async => {
          'reply': 'Ouvrez le Bandol.',
          'couts': [
            {
              'fonction': 'chat_sommelier',
              'modele': 'gemini-3.8-flash',
              'usageMetadata': {'promptTokenCount': 2000, 'candidatesTokenCount': 150, 'thoughtsTokenCount': 50},
            }
          ],
        }, suivi: suivi);
    final r = await ia.appeler('chat', {'message': 'Quel vin ce soir ?'});
    expect(r.ok, isTrue);
    expect(r.donnees!['reply'], 'Ouvrez le Bandol.');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final evts = (await suivi.getStats()).recentEvents;
    expect(evts.single.feature, 'chat_sommelier');
    expect(evts.single.candidatesTokens, 200, reason: 'la réflexion est comptée avec la sortie');
  });

  test('sans session, une session anonyme est ouverte et l\'appel rejoué une fois', () async {
    var appels = 0;
    var sessions = 0;
    final ia = FonctionsIa.pourEssai((f, c) async {
      appels++;
      if (appels == 1) throw const FunctionException(status: 401, details: {'error': 'session_requise'});
      return {'wines': []};
    }, assurerUneSession: () async {
      sessions++;
      return const User(id: 'anonyme', appMetadata: {}, userMetadata: {}, aud: 'authenticated', createdAt: '');
    });
    final r = await ia.appeler('scan-menu', {}, enregistrerLesCouts: false);
    expect(r.ok, isTrue);
    expect(appels, 2);
    expect(sessions, 1);
  });

  test('un second refus de session ne boucle pas', () async {
    var appels = 0;
    final ia = FonctionsIa.pourEssai((f, c) async {
      appels++;
      throw const FunctionException(status: 401, details: {'error': 'session_requise'});
    }, assurerUneSession: () async =>
        const User(id: 'anonyme', appMetadata: {}, userMetadata: {}, aud: 'authenticated', createdAt: ''));
    final r = await ia.appeler('scan-menu', {}, enregistrerLesCouts: false);
    expect(r.erreur, 'session_requise');
    expect(appels, 2);
  });

  test('la limite du jour se lit, et se dit différemment à un invité web', () async {
    final ia = FonctionsIa.pourEssai((f, c) async =>
        throw const FunctionException(status: 429, details: {'error': 'limite_du_jour', 'limite': 3, 'anonyme': true}));
    final r = await ia.appeler('scan-menu', {}, enregistrerLesCouts: false);
    expect(r.limiteAtteinte, isTrue);
    expect(r.limite, 3);
    expect(r.messageDeLimite(web: true), contains('installez l\'app'));
    expect(r.messageDeLimite(web: false), contains('limite du jour'));
  });

  test('une panne réseau ne lève rien', () async {
    final ia = FonctionsIa.pourEssai((f, c) async => throw Exception('hors ligne'));
    final r = await ia.appeler('chat', {}, enregistrerLesCouts: false);
    expect(r.erreur, 'reseau');
    expect(r.ok, isFalse);
  });
}
