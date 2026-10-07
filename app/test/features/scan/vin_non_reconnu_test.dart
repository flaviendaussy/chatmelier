import 'package:chatmelier/features/scan/data/scan_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Zéro hallucination (V2.4 · R1). Le 07/10, « S de Siroua », un vin marocain, est devenu un
/// Côtes du Rhône : un vin non reconnu doit le rester, sans pays ni couleur inventés.
void main() {
  test('le serveur peut dire « non reconnu »', () {
    expect(ScanService.nonReconnu({'reconnu': false, 'name': 'S de Siroua'}), isTrue);
    expect(ScanService.nonReconnu({'reconnu': true, 'name': 'Chablis'}), isFalse);
    expect(ScanService.nonReconnu({'name': 'Chablis'}), isFalse, reason: 'ancienne fonction : réponse acceptée');
  });
}
