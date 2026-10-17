import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/scan/data/scan_service.dart';
import 'package:chatmelier/features/scan/domain/completion_par_le_web.dart';
import 'package:chatmelier/features/scan/domain/scan_result.dart';
import 'package:chatmelier/shared/services/fonctions_ia.dart';
import 'package:chatmelier/shared/utils/app_logger.dart';

/// 16/10 au soir, Flavien : « pourquoi est-ce qu'on ne trouve pas ce vin ? quand je vais sur
/// Google, je le trouve !! ». « La Rosa Mayor » 2019 : l'étiquette lue, mais ni région, ni
/// appellation, ni cépages.
void main() {
  const lu = ScanResult(
    name: 'La Rosa Mayor',
    producer: 'La Rosa Mayor',
    vintage: 2019,
    wineType: 'red',
    country: 'Spain',
    region: '',
    alcoholPct: 14,
  );

  const surLeWeb = ScanResult(
    name: 'La Rosa Mayor',
    producer: 'Bodega Ejemplo',
    vintage: 2020,
    wineType: 'red',
    country: 'Espagne',
    region: 'Castilla y León',
    appellation: 'Ribera del Duero',
    alcoholPct: 13.5,
    grapes: [Grape(name: 'Tempranillo', pct: 100)],
    tastingNotes: 'Cerise noire, réglisse, tanins fermes.',
    peakDrinkingStart: 2023,
    peakDrinkingEnd: 2029,
  );

  test('une étiquette qui ne dit ni d\'où vient le vin ni ce qu\'il est appelle une recherche', () {
    expect(CompletionParLeWeb.aCompleter(lu), isTrue);
    expect(CompletionParLeWeb.aCompleter(surLeWeb), isFalse);
    // « Gran Reserva » seul ne désigne aucun vin : rien à chercher.
    expect(CompletionParLeWeb.aCompleter(const ScanResult(name: 'Gran Reserva', wineType: 'red', country: '', region: '')), isFalse);
  });

  test('on cherche ce que l\'étiquette dit, sans répétition', () {
    expect(
      CompletionParLeWeb.requete(nom: 'La Rosa Mayor', producteur: 'La Rosa Mayor', millesime: 2019, pays: 'Spain', region: ''),
      'La Rosa Mayor 2019, Spain',
    );
    // Un nom court ne suffit pas : « Menudo » est aussi un plat et un groupe.
    expect(CompletionParLeWeb.requete(nom: 'Menudo', producteur: 'Menudo', millesime: 2021, type: 'red'), 'Menudo 2021, red wine');
  });

  test('le web remplit les vides, et ne touche ni au millésime, ni au degré, ni à ce qui est lu', () {
    final f = CompletionParLeWeb.fusionner(lu, surLeWeb, sources: ['vinosdeespana.com']);
    expect((f.name, f.producer, f.vintage, f.country, f.alcoholPct), ('La Rosa Mayor', 'Bodega Ejemplo', 2019, 'Spain', 14.0));
    expect((f.region, f.appellation), ('Castilla y León', 'Ribera del Duero'));
    expect(f.grapes.single.name, 'Tempranillo');
    expect((f.peakDrinkingStart, f.peakDrinkingEnd), (2023, 2029));
    expect(f.sourcesVerified, ['vinosdeespana.com']);
    expect(CompletionParLeWeb.champsCompletes(lu, f), containsAll(['appellation', 'region', 'cepages', 'notes', 'garde']));
  });

  test('un domaine recopié du nom n\'est pas une lecture : le web le remplace', () {
    // L'étiquette de « La Rosa Mayor » ne montre pas Bodegas Valtravieso, au dos.
    final f = CompletionParLeWeb.fusionner(lu, surLeWeb.copyWith(producer: 'Bodegas Valtravieso'));
    expect(f.producer, 'Bodegas Valtravieso');
    // Sans domaine sur le web, le nom recopié reste plutôt que rien.
    expect(CompletionParLeWeb.fusionner(lu, const ScanResult(name: 'La Rosa Mayor', wineType: 'red', country: '', region: 'Ribera del Duero')).producer,
        'La Rosa Mayor');
    // Un vrai domaine lu sur l'étiquette ne bouge pas.
    final lue = lu.copyWith(producer: 'Valtravieso');
    expect(CompletionParLeWeb.fusionner(lue, surLeWeb).producer, 'Valtravieso');
  });

  test('une description devinée cède la place au web ; une description sourcée reste', () {
    final devinee = lu.copyWith(grapes: const [Grape(name: 'Garnacha')], tastingNotes: 'Un rouge espagnol typique.');
    expect(CompletionParLeWeb.fusionner(devinee, surLeWeb).grapes.single.name, 'Tempranillo');
    final catalogue = devinee.copyWith(fromCache: true);
    expect(CompletionParLeWeb.fusionner(catalogue, surLeWeb).grapes.single.name, 'Garnacha');
  });

  test('un autre vin trouvé à la place n\'est pas celui-ci', () {
    const autre = ScanResult(name: 'Viña Pomal', producer: 'Bodegas Bilbaínas', wineType: 'red', country: 'Spain', region: 'Rioja');
    expect(CompletionParLeWeb.memeVin(lu, autre), isFalse);
    expect(CompletionParLeWeb.memeVin(lu, surLeWeb), isTrue);
  });

  group('la recherche, de bout en bout', () {
    setUp(AppLogger.clear);
    final client = SupabaseClient('http://localhost:1', 'cle-de-test');
    ScanService service(Map<String, dynamic> reponse, {List<Map<String, dynamic>>? appels}) => ScanService(client,
        ia: FonctionsIa.pourEssai((f, c) async {
          appels?.add({'fonction': f, ...c});
          return reponse;
        }));

    test('trouvé : la fiche complétée, ses sources par leur nom, et une ligne au journal', () async {
      final appels = <Map<String, dynamic>>[];
      final trouve = await service({
        'resultat': {...surLeWeb.toJson(), 'reconnu': true},
        'sources': [
          {'titre': 'vinosdeespana.com', 'url': 'https://vertexaisearch.cloud.google.com/grounding-api-redirect/abc'},
        ],
      }, appels: appels)
          .chercherSurLeWeb(lu, requete: 'La Rosa Mayor 2019, Spain');
      expect(appels.single, containsPair('tache', 'vin_depuis_texte'));
      expect(appels.single, containsPair('texte', 'La Rosa Mayor 2019, Spain'));
      expect(trouve!.fiche.appellation, 'Ribera del Duero');
      expect(trouve.sources, ['vinosdeespana.com']);
      expect(AppLogger.logs.last.message, allOf(contains('Trouvé sur le web'), contains('La Rosa Mayor 2019, Spain')));
    });

    test('introuvable : rien d\'inventé, et la raison au journal', () async {
      final trouve = await service({
        'resultat': {'reconnu': false, 'name': 'La Rosa Mayor'},
      }).chercherSurLeWeb(lu, requete: 'La Rosa Mayor 2019, Spain');
      expect(trouve, isNull);
      expect(AppLogger.logs.last.message, contains('Introuvable sur le web'));
    });

    test('le web répond pour un autre vin : laissé de côté', () async {
      final trouve = await service({
        'resultat': {'reconnu': true, 'name': 'Viña Pomal', 'producer': 'Bodegas Bilbaínas', 'wine_type': 'red', 'region': 'Rioja'},
      }).chercherSurLeWeb(lu, requete: 'La Rosa Mayor 2019, Spain');
      expect(trouve, isNull);
      expect(AppLogger.logs.last.message, contains('un autre vin'));
    });
  });
}
