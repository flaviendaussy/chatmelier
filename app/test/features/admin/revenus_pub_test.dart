import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/admin/domain/revenus_pub.dart';

void main() {
  test('le revenu réel, l\'eCPM face à l\'estimé, et la livre sans taux à part', () {
    final r = RevenusPub.fromJson({
      'paiements': 3,
      'impressions': 4,
      'revenu_eur': 0.018,
      'par_devise': [
        {'devise': 'EUR', 'total': 0.018, 'paiements': 2, 'converti': true},
        {'devise': 'GBP', 'total': 0.003, 'paiements': 1, 'converti': false},
      ],
      'par_format': [
        {'format': 'rewarded', 'impressions': 3, 'paiements': 2, 'revenu_eur': 0.018, 'ecpm_reel_eur': 9.0, 'ecpm_estime_eur': 8},
        {'format': 'app_open', 'impressions': 1, 'paiements': 1, 'revenu_eur': null, 'ecpm_reel_eur': null, 'ecpm_estime_eur': 5},
      ],
      'par_jour': [],
      'precision': {'precise': 2, 'estimated': 1},
    });
    expect(r.revenuEur, 0.018);
    expect(r.nonConvertis.single.devise, 'GBP');
    expect(r.parFormat.first.ecpmReelEur, 9.0);
    expect(r.parFormat.first.ecpmEstimeEur, 8.0);
    expect(r.parFormat.last.ecpmReelEur, isNull);
    expect(r.ratioSur(0.036), closeTo(0.5, 1e-9));
    expect(r.ratioSur(0), isNull);
  });

  test('rien reçu : zéro paiement, aucun total inventé', () {
    final r = RevenusPub.fromJson({'paiements': 0, 'impressions': 12, 'revenu_eur': null});
    expect(r.paiements, 0);
    expect(r.revenuEur, isNull);
    expect(r.ratioSur(1.0), isNull);
  });
}
