import 'dart:convert';
import 'dart:typed_data';

import 'package:chatmelier/features/scan/data/scan_service.dart';
import 'package:chatmelier/features/scan/domain/scan_result.dart';
import 'package:chatmelier/features/sommelier/data/cepages_du_vin.dart';
import 'package:chatmelier/shared/services/fonctions_ia.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le scan d'une étiquette en deux temps (23/10) : le vin lu d'abord, la description
/// ensuite. Et les cépages d'un vin inconnu, cherchés une fois pour tous (080).
Uint8List _photo(int n) {
  final i = img.Image(width: 64, height: 96);
  img.fill(i, color: img.ColorRgb8(120, n, 40));
  return Uint8List.fromList(img.encodeJpg(i));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('l\'étiquette en deux temps', () {
    test('le vin lu arrive d\'abord, la fiche complète ensuite, sans quota de plus', () async {
      final appels = <Map<String, dynamic>>[];
      final service = ScanService(
        SupabaseClient('http://localhost:1', 'cle-de-test'),
        ia: FonctionsIa.pourEssai((f, corps) async {
          appels.add(corps);
          if (corps['etape'] == 'lecture') {
            return {'name': 'Ungrafted Cinsault', 'producer': 'De Martino', 'vintage': 2025, 'wine_type': 'red',
              'country': 'Chile', 'complete': false, 'suite': 'suite-signee', 'etapes': {'description': 'à suivre'}};
          }
          return {'name': 'Ungrafted Cinsault', 'grapes': [{'name': 'Cinsault', 'pct': 100}],
            'tasting_notes': 'Fruits rouges, tanins souples.', 'complete': true};
        }),
      );
      ScanResult? lu;
      final complet = await service.analyzeBottleImage(imageBytes: _photo(1), onLecture: (r) => lu = r);

      expect(appels.map((c) => c['etape']), ['lecture', 'description']);
      expect(appels.last['suite'], 'suite-signee', reason: 'la description se demande avec la suite signée');
      expect(appels.last.containsKey('imageBase64'), isFalse, reason: 'la photo ne repart pas une seconde fois');
      expect(lu!.name, 'Ungrafted Cinsault');
      expect(lu!.grapes, isEmpty, reason: 'la lecture n\'a pas encore les cépages');
      expect(complet.producer, 'De Martino', reason: 'la lecture reste dans la fiche complète');
      expect(complet.grapes.single.name, 'Cinsault');
      expect(complet.tastingNotes, isNotNull);
    });

    test('une fonction serveur d\'avant la 88 rend tout d\'un coup : un seul appel, rien d\'annoncé', () async {
      var n = 0;
      final service = ScanService(
        SupabaseClient('http://localhost:1', 'cle-de-test'),
        ia: FonctionsIa.pourEssai((f, corps) async {
          n++;
          return {'name': 'Morgon', 'grapes': [{'name': 'Gamay', 'pct': 100}], 'tasting_notes': 'Cerise.'};
        }),
      );
      ScanResult? lu;
      final r = await service.analyzeBottleImage(imageBytes: _photo(2), onLecture: (x) => lu = x);
      expect(n, 1);
      expect(lu, isNull);
      expect(r.grapes.single.name, 'Gamay');
    });

    test('la description manquée : le vin lu reste, et la même photo la redemandera', () async {
      var descriptions = 0;
      final service = ScanService(
        SupabaseClient('http://localhost:1', 'cle-de-test'),
        ia: FonctionsIa.pourEssai((f, corps) async {
          if (corps['etape'] == 'lecture') {
            return {'name': 'Rosy', 'producer': 'Pio Cesare', 'wine_type': 'rose', 'complete': false, 'suite': 's'};
          }
          descriptions++;
          throw const FunctionException(status: 502, details: {'error': 'Aucun modèle n\'a répondu'});
        }),
      );
      final photo = _photo(3);
      final r = await service.analyzeBottleImage(imageBytes: photo, onLecture: (_) {});
      expect(r.name, 'Rosy');
      await service.analyzeBottleImage(imageBytes: photo, onLecture: (_) {});
      expect(descriptions, 2, reason: 'un résultat sans description n\'est pas gardé en cache');
    });
  });

  group('les cépages d\'un vin inconnu', () {
    test('cherchés une fois : deux verres du même vin, une seule recherche ; gardés sur le téléphone', () async {
      var n = 0;
      final service = CepagesDuVin(() => FonctionsIa.pourEssai((f, corps) async {
            n++;
            expect(f, 'taches-ia');
            expect(corps['tache'], 'cepages');
            expect(corps['producteur'], 'Viña Imaginaria');
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return {'resultat': {'cepages': [{'name': 'Cinsault', 'pct': 100}], 'methode': 'recherche', 'source': 'https://x'}};
          }));
      final deux = await Future.wait([
        service.chercher(nom: 'Secano Cinsault', producteur: 'Viña Imaginaria'),
        service.chercher(nom: 'Secano  Cinsault', producteur: 'VIÑA IMAGINARIA'),
      ]);
      expect(deux, [['Cinsault'], ['Cinsault']]);
      expect(n, 1);
      expect(await service.chercher(nom: 'Secano Cinsault', producteur: 'Viña Imaginaria'), ['Cinsault']);
      expect(n, 1, reason: 'le téléphone les garde');
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('chatmelier_cepages_trouves_v1')!), {'vina imaginaria|secano cinsault': ['Cinsault']});
    });

    test('une cuvée de la base des vins connus : ses cépages sans réseau ni quota', () async {
      var n = 0;
      final service = CepagesDuVin(() => FonctionsIa.pourEssai((f, corps) async {
            n++;
            return {'resultat': {'cepages': [], 'methode': 'inconnu'}};
          }));
      expect(await service.chercher(nom: 'Ungrafted Cinsault', producteur: 'De Martino', pays: 'Chile', couleur: 'red'), ['Cinsault']);
      expect(await service.chercher(nom: 'Gran Reserva 904', producteur: 'La Rioja Alta', couleur: 'red'), ['Tempranillo', 'Graciano']);
      expect(n, 0);
    });

    test('pas trouvés, ou pas de réseau : aucun cépage inventé', () async {
      final introuvable = CepagesDuVin(() => FonctionsIa.pourEssai((f, c) async => {'resultat': {'cepages': [], 'methode': 'inconnu'}}));
      expect(await introuvable.chercher(nom: 'Vin Introuvable'), isEmpty);
      final horsLigne = CepagesDuVin(() => FonctionsIa.pourEssai((f, c) async => throw Exception('réseau')));
      expect(await horsLigne.chercher(nom: 'Bio Tinto', producteur: 'Terrenus'), isEmpty);
    });
  });
}
