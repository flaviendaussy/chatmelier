import 'package:chatmelier/features/monetization/domain/politique_pub.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Moins de pub au mauvais moment (V2.3 · G2).
void main() {
  test('les 30 premiers scans d\'étiquette se font sans vidéo, puis la vidéo revient', () {
    expect(PolitiquePub.doitMontrer(emplacement: 'scan_etiquette', premium: false, scansEtiquetteDejaFaits: 0), isFalse);
    expect(PolitiquePub.doitMontrer(emplacement: 'scan_etiquette', premium: false, scansEtiquetteDejaFaits: 29), isFalse);
    expect(PolitiquePub.doitMontrer(emplacement: 'scan_etiquette', premium: false, scansEtiquetteDejaFaits: 30), isTrue);
  });

  test('jamais de vidéo pendant un import Excel', () {
    expect(PolitiquePub.doitMontrer(emplacement: 'import_excel', premium: false), isFalse);
  });

  test('la vidéo reste sur le scan de carte, jamais pour un compte premium', () {
    expect(PolitiquePub.doitMontrer(emplacement: 'scan_carte', premium: false), isTrue);
    expect(PolitiquePub.doitMontrer(emplacement: 'scan_carte', premium: true), isFalse);
    expect(PolitiquePub.doitMontrer(emplacement: 'scan_etiquette', premium: true, scansEtiquetteDejaFaits: 100), isFalse);
  });

  test('le compteur est propre à chaque compte', () async {
    SharedPreferences.setMockInitialValues({});
    await PolitiquePub.compterUnScanEtiquette('alice');
    await PolitiquePub.compterUnScanEtiquette('alice');
    await PolitiquePub.compterUnScanEtiquette('bruno');
    expect(await PolitiquePub.scansEtiquette('alice'), 2);
    expect(await PolitiquePub.scansEtiquette('bruno'), 1);
  });
}
