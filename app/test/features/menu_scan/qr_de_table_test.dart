import 'package:chatmelier/features/menu_scan/data/menu_table_session_manager.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// « Pas de QR code !! » (Flavien, 30/09). Le QR portait toute la carte : 35 vins, soit
/// 19 500 bits pour une capacité de 18 672, et l'hôte voyait une grande zone vide.
void main() {
  ScannedMenu carte(int n) => ScannedMenu(
        id: 'carte',
        restaurantName: 'The Kitchin',
        scannedAt: DateTime(2026, 9, 30),
        pagePhotoPaths: const [],
        wines: [
          for (var i = 0; i < n; i++)
            MenuWine(
              id: '$i',
              name: 'Cuvée numéro $i du domaine',
              producer: 'Domaine des Coteaux $i',
              vintage: 2015 + i % 8,
              wineType: i.isEven ? 'red' : 'white',
              bottlePrice: 40.0 + i,
              sommelierComment: 'Un commentaire du sommelier assez long pour peser dans la '
                  'charge utile, numéro $i : fruit noir, tanins fondus, belle longueur.',
            ),
        ],
      );

  // Les réglages du widget (`StylizedChatmelierQr`).
  bool tientDansUnQr(String donnees) =>
      QrValidator.validate(
        data: donnees,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ).status ==
      QrValidationStatus.valid;

  test('avec une table au serveur, le QR ne porte que son code, vers la page légère', () {
    final url = MenuTableSessionManager.buildQrUrl(sessionId: 'TABLE-1', menu: carte(35), code: 'kyz3yz');
    expect(url, 'https://chatmelier.github.io/table/?t=KYZ3YZ');
    expect(tientDansUnQr(url), isTrue);
  });

  test('sans serveur, une carte de 35 vins est réduite pour tenir, et reste lisible', () {
    final url = MenuTableSessionManager.buildQrUrl(sessionId: 'TABLE-1', menu: carte(35));
    expect(url.length, lessThanOrEqualTo(MenuTableSessionManager.longueurQrMax));
    expect(tientDansUnQr(url), isTrue);

    final relue = MenuTableSessionManager.decodeMenuPayload(Uri.parse(url).queryParameters['data']);
    expect(relue, isNotNull);
    expect(relue!.wines, isNotEmpty);
  });
}
