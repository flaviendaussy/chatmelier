import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/data/degustation_rapide.dart';
import 'package:chatmelier/features/journal/domain/tasting_questionnaire_result.dart';
import 'package:chatmelier/features/offline/data/offline_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ce qu'on garde d'un vin bu dehors (V2.3 · E2) : le service commun à « Déguster
/// ailleurs » et à la fin de soirée d'une table. Sans session ni réseau ici : la
/// dégustation doit partir dans la file, s'afficher tout de suite, et apprendre au palais.
class _Palais extends Fake implements TasteProfileService {
  final appris = <String>[];
  final parQuestionnaire = <String>[];

  @override
  Future<TasteProfile> getPrimaryProfile() async => const TasteProfile(id: 'moi', name: 'Moi');

  @override
  Future<TasteProfile> addOrGetProfileByName(String name) async => TasteProfile(id: name.toLowerCase(), name: name);

  @override
  Future<void> recordTastingExperience({
    required String nameOrId,
    required Wine wine,
    required double rating,
    bool hadFault = false,
    String? tastingId,
  }) async =>
      appris.add('$nameOrId:${wine.name}:$rating');

  @override
  Future<void> applyQuestionnaireResult({
    required TastingQuestionnaireResult result,
    String? wineRegion,
    List<String>? wineGrapes,
    String? wineType,
    String? tastingId,
    String? wineName,
  }) async =>
      parQuestionnaire.add('${result.profileId}:${result.mouthfeelTexture}');
}

void main() {
  late OfflineStorageService horsLigne;
  late _Palais palais;
  late DegustationRapide service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    horsLigne = OfflineStorageService(await SharedPreferences.getInstance());
    palais = _Palais();
    // Un client sans session : aucune requête ne part.
    service = DegustationRapide(SupabaseClient('http://localhost:1', 'cle-de-test'), horsLigne, palais);
  });

  test('sans réseau : la file, le cache marqué en attente, et le palais', () async {
    final r = await service.enregistrer(const VinBuDehors(
      nom: 'Morgon',
      producteur: 'Marcel Lapierre',
      millesime: 2022,
      couleur: 'red',
      note: 8,
      lieu: 'The Kitchin',
      convives: ['Caro'],
    ));

    expect(r.enLigne, isFalse);
    final file = horsLigne.getQueue();
    expect(file.single.id, r.id);
    expect(file.single.data['is_external'], isTrue);
    expect(file.single.data['location_name'], 'The Kitchin');

    final cache = horsLigne.getCachedTastings().single;
    expect(cache[OfflineStorageService.pendingSyncKey], isTrue);
    expect((cache['wines'] as Map)['name'], 'Morgon');

    expect(palais.appris, ['moi:Morgon:8.0', 'caro:Morgon:8.0']);
  });

  test('avec une gorgée, le palais apprend par le chemin du questionnaire', () async {
    await service.enregistrer(const VinBuDehors(nom: 'Chablis', couleur: 'white', note: 7, texture: 'crisp_salivating'));
    expect(palais.parQuestionnaire, ['moi:crisp_salivating']);
    expect(palais.appris, isEmpty, reason: 'jamais les deux chemins : le compteur doublerait');
  });

  test('sans note, rien n\'est appris : on n\'invente pas un avis', () async {
    await service.enregistrer(const VinBuDehors(nom: 'Bandol', texture: 'silky'));
    expect(palais.appris, isEmpty);
    expect(palais.parQuestionnaire, isEmpty);
    expect(horsLigne.getCachedTastings(), hasLength(1), reason: 'la dégustation est gardée quand même');
  });
}
