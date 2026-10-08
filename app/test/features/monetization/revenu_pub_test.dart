import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/monetization/mesure_des_pubs.dart';

void main() {
  Map<String, dynamic>? ligne(double micros, String devise, [String precision = 'precise']) =>
      MesureDesPubs.ligneDeRevenu(
        impressionId: 'imp-1',
        format: 'rewarded',
        emplacement: 'scan_carte',
        valeurMicros: micros,
        precision: precision,
        devise: devise,
        maintenant: DateTime.utc(2026, 10, 8, 18),
      );

  test('un paiement : en micro-unités entières, rattaché à son impression', () {
    final l = ligne(6123.6, 'eur')!;
    expect(l['valeur_micros'], 6124);
    expect(l['devise'], 'EUR');
    expect(l['impression_id'], 'imp-1');
    expect(l['precision_type'], 'precise');
    expect(l['ad_format'], 'rewarded');
    expect(l['occurred_at'], '2026-10-08T18:00:00.000Z');
  });

  test('un montant ou une devise illisibles ne partent pas', () {
    expect(ligne(-1, 'EUR'), isNull);
    expect(ligne(double.nan, 'EUR'), isNull);
    expect(ligne(5e8, 'EUR'), isNull);
    expect(ligne(5000, ''), isNull);
    expect(ligne(5000, 'euro'), isNull);
  });
}
