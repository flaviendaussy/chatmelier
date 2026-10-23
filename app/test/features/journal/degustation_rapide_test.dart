import 'package:chatmelier/features/auth/data/taste_profile_service.dart';
import 'package:chatmelier/features/auth/domain/taste_profile.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/journal/data/degustation_rapide.dart';
import 'package:chatmelier/features/journal/domain/questionnaire_de_degustation.dart';
import 'package:chatmelier/features/offline/domain/offline_action.dart';
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
    Wine? vin,
    DateTime? le,
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

  group('la note arrive après la ligne (22/10 : vingt et une dégustations « Non noté »)', () {
    TastingQuestionnaireResult resultat(double note, {Set<String> aromes = const {}}) => TastingQuestionnaireResult(
          emojiImpression: TastingQuestionnaireResult.emojiIndexForRating(note),
          noteOutOf10: note,
          perceivedAromas: aromes,
          aromaIntensity: 0.5,
          length: 0.5,
          wouldBuyAgain: 'maybe',
          idealMoment: '',
          whatLikedMost: const {},
          whatDislikedMost: const {},
          profileId: 'moi',
          profileName: 'Moi',
        );

    test('le complément : la note, les arômes à la suite des notes déjà écrites', () {
      final c = complementDuJournal(resultat: resultat(8.5, aromes: {'agrumes'}), notesDeja: 'Au verre, au comptoir');
      expect(c['rating'], 8.5);
      expect(c['rating_scale'], 10);
      expect(c.containsKey('fault'), isFalse);
      expect(c['tasting_notes'], startsWith('Au verre, au comptoir\n'));
    });

    test('une bouteille défectueuse : le défaut, et pas de note (le Bio Tinto oxydé)', () {
      final c = complementDuJournal(resultat: resultat(1.0), defaut: 'oxidation');
      expect(c['fault'], 'oxidation');
      expect(c['rating'], isNull);
    });

    test('la ligne attend encore le réseau : la note entre dans la même action', () async {
      final r = await service.enregistrer(const VinBuDehors(nom: 'Ungrafted - Muscat', couleur: 'white', lieu: 'Vagabond'));
      await service.completer(r.id, complementDuJournal(resultat: resultat(9.5)));
      final file = horsLigne.getQueue();
      expect(file, hasLength(1), reason: 'une mise à jour partie avant la ligne ne trouverait rien');
      expect(file.single.data['rating'], 9.5);
      expect(file.single.data['location_name'], 'Vagabond');
      expect(horsLigne.getCachedTastings().single['rating'], 9.5, reason: 'le journal affiche la note tout de suite');
    });

    test('la ligne est partie mais le réseau manque pour la note : une action de mise à jour', () async {
      await horsLigne.addCachedTasting({'id': 'deja-en-ligne', 'rating': null});
      await service.completer('deja-en-ligne', complementDuJournal(resultat: resultat(7.0)));
      final action = horsLigne.getQueue().single;
      expect(action.type, OfflineActionType.updateTasting);
      expect(action.data['tasting_id'], 'deja-en-ligne');
      expect(action.data['rating'], 7.0);
      expect(horsLigne.getCachedTastings().single['rating'], 7.0);
    });
  });
}
