import 'package:chatmelier/features/cellar/data/cote_a_la_demande.dart';
import 'package:chatmelier/shared/services/fonctions_ia.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// V2.5 · F8 : « toucher la valeur (ou « Non cotée ») lance une recherche Google sourcée pour
/// ce vin ; source affichée, quota ; jamais de valeur sans source ».
void main() {
  setUp(() => Langue.code = 'fr');
  const wineId = '5f0c2e1a-0d3b-4c2e-9f61-2b7d3c4e5a6b';

  CoteALaDemande service(Future<Object?> Function(Map<String, dynamic> corps) reponse, {List<String>? fonctions}) =>
      CoteALaDemande(FonctionsIa.pourEssai((f, corps) {
        fonctions?.add(f);
        return reponse(corps);
      }));

  test('une cote sourcée : la valeur, et le site où elle a été relevée', () async {
    final appels = <String>[];
    Map<String, dynamic>? envoye;
    final r = await service((corps) async {
      envoye = corps;
      return {
        'cote': {'valeur': 42, 'devise': 'EUR', 'source': 'https://www.idealwine.com/terrebrune-2019'},
      };
    }, fonctions: appels)
        .chercher(wineId);
    expect(appels, ['update-wine-values']);
    expect(envoye, {'wine_id': wineId});
    expect(r.trouvee, isTrue);
    expect(r.valeur, 42);
    expect(r.message, contains('idealwine.com'));
    expect(r.message, startsWith('Cote trouvée : 42'));
  });

  test('rien de sourcé : pas de prix, et Chatmelier le dit', () async {
    final r = await service((_) async => {'cote': null, 'raison': 'aucune cote sourcée'}).chercher(wineId);
    expect(r.trouvee, isFalse);
    expect(r.valeur, isNull);
    expect(r.message, contains('n\'invente pas de prix'));
  });

  test('la limite du jour, ou une panne : le message qui convient, jamais un prix', () async {
    final limite = await service((_) async =>
        throw const FunctionException(status: 429, details: {'error': 'limite_du_jour', 'limite': 10})).chercher(wineId);
    expect(limite.trouvee, isFalse);
    expect(limite.message, isNotEmpty);
    final panne = await service((_) async => throw const FunctionException(status: 500)).chercher(wineId);
    expect(panne.trouvee, isFalse);
    expect(panne.message, contains('Réessayez plus tard'));
  });
}
