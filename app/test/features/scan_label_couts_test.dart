import 'package:chatmelier/features/auth/data/ai_cost_tracker_service.dart';
import 'package:chatmelier/features/scan/data/scan_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ce que `scan-label` a payé devient des événements de coût (P1, P4) : sans cela, les
/// scans d'étiquette passés par le serveur échappaient à la mesure.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Map<String, dynamic> cout(String fonction, {bool recherche = false}) => {
        'fonction': fonction,
        'modele': 'gemini-3.8-flash',
        'usageMetadata': {'promptTokenCount': 1200, 'candidatesTokenCount': 300},
        'recherche': recherche,
      };

  test('un vin inconnu, décrit avec recherche : deux appels, le second groundé', () async {
    await Future.wait(ScanService.enregistrerLesCouts({
      'name': 'Bandol Rouge',
      'couts': [cout('scan_vision'), cout('scan_enrichment', recherche: true)],
    }, 'u1'));
    final evts = (await AiCostTrackerService().getStats()).recentEvents;
    expect(evts.map((e) => e.feature).toSet(), {'scan_vision', 'scan_enrichment'});
    expect(evts.singleWhere((e) => e.feature == 'scan_enrichment').isSearchGrounded, isTrue);
    expect(evts.singleWhere((e) => e.feature == 'scan_vision').isSearchGrounded, isFalse);
  });

  test('un vin trouvé au catalogue ne coûte que la lecture', () async {
    await Future.wait(ScanService.enregistrerLesCouts({
      'from_cache': true,
      'couts': [cout('scan_vision')],
    }, 'u1'));
    final evts = (await AiCostTrackerService().getStats()).recentEvents;
    expect(evts, hasLength(1));
    expect(evts.single.feature, 'scan_vision');
  });

  test('une ancienne réponse sans « couts » ne casse rien', () {
    expect(ScanService.enregistrerLesCouts({'name': 'x'}, null), isEmpty);
    expect(ScanService.enregistrerLesCouts({'couts': 'nimporte'}, null), isEmpty);
  });
}
