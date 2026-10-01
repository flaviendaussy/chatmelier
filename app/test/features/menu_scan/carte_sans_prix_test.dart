import 'package:chatmelier/features/menu_scan/data/menu_scan_service.dart';
import 'package:chatmelier/features/menu_scan/domain/menu_wine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Une carte sans aucun prix : salon d'aéroport, avion, formule tout compris (01/10).
///
/// Flavien a scanné une carte de cinq vins sans prix. Le sommelier a répondu en anglais…
/// en recopiant « (Prix non indiqué) », écrit en français dans le contexte qu'on lui
/// envoyait, et chaque fiche portait « Prix non indiqué ».
void main() {
  ScannedMenu carte(List<MenuWine> vins) =>
      ScannedMenu(id: 'c', restaurantName: 'Lounge', scannedAt: DateTime(2026, 10, 1), pagePhotoPaths: const [], wines: vins);

  const primitivo = MenuWine(id: '1', name: 'Primitivo', producer: 'Giovanello', vintage: 2021, wineType: 'Red');
  const shiraz = MenuWine(id: '2', name: 'Shiraz', producer: 'Barossa Estate', vintage: 2020, wineType: 'Red');
  const sancerre = MenuWine(id: '3', name: 'Sancerre', producer: 'Vacheron', vintage: 2022, wineType: 'White', bottlePrice: 45);

  test('une carte sans aucun prix se reconnaît, une carte en partie chiffrée non', () {
    expect(carte([primitivo, shiraz]).sansPrix, isTrue);
    expect(carte([primitivo, sancerre]).sansPrix, isFalse);
    expect(carte(const []).sansPrix, isFalse);
    expect(primitivo.aUnPrix, isFalse);
    expect(primitivo.prixAffiche(false), isEmpty, reason: 'rien plutôt que « Price not listed » sous chaque vin');
  });

  test('le sommelier lit la carte dans la langue de la conversation, et sait qu\'elle est sans prix', () {
    final en = MenuScanService.carteLueParLeSommelier(carte([primitivo, shiraz]), 'en');
    expect(en, contains('no prices at all'));
    expect(en, isNot(contains('Prix')));
    expect(en, contains('Profile:'));
    expect(en, contains('"Primitivo" (2021), Giovanello [Red, ].'));

    final fr = MenuScanService.carteLueParLeSommelier(carte([sancerre, primitivo]), 'fr');
    expect(fr, isNot(contains('sans aucun prix')), reason: 'une carte en partie chiffrée n\'est pas une carte de salon');
    expect(fr, contains('/ bt'));
    expect(fr, isNot(contains('non indiqué')));
  });
}
