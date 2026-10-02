import 'package:chatmelier/features/admin/domain/admin_croissance.dart';
import 'package:chatmelier/shared/services/croissance.dart';
import 'package:flutter_test/flutter_test.dart';

/// D'où vient une installation (V2.3 · K2) : le Play Store garde la fin du lien
/// d'installation, l'app la lit à sa première ouverture, la console en tire le coût du web
/// par installation obtenue.
void main() {
  group('le referrer du Play Store', () {
    test('le lien de la page invité : la source et le code de la table', () {
      final o = Croissance.lireLeReferrer('utm_source=page_invite&utm_campaign=K7M2QX');
      expect(o.source, 'page_invite');
      expect(o.tableCode, 'K7M2QX');
    });

    test('encore encodé, il se lit pareil', () {
      final o = Croissance.lireLeReferrer('utm_source%3Dpage_invite%26utm_campaign%3DK7M2QX');
      expect(o.source, 'page_invite');
      expect(o.tableCode, 'K7M2QX');
    });

    test('une installation depuis une recherche dans le Play Store', () {
      final o = Croissance.lireLeReferrer('utm_source=google-play&utm_medium=organic');
      expect(o.source, 'google-play');
      expect(o.tableCode, isNull);
    });

    test('rien, ou rien d\'exploitable : ni source ni table', () {
      for (final r in [null, '', '   ', 'n\'importe quoi']) {
        final o = Croissance.lireLeReferrer(r);
        expect(o.tableCode, isNull, reason: '$r');
      }
      expect(Croissance.lireLeReferrer(null).source, isNull);
      expect(Croissance.lireLeReferrer('utm_source=google-play&utm_campaign=(not set)').tableCode, isNull);
    });

    test('bornée comme la table de la base : 40 caractères de source au plus, rien d\'exotique', () {
      final o = Croissance.lireLeReferrer('utm_source=${'x' * 60}<script>&utm_campaign=abc123');
      expect(o.source!.length, 40);
      expect(o.source, isNot(contains('<')));
      expect(o.tableCode, 'ABC123');
    });

    test('nos propres liens d\'installation se relisent à l\'identique', () {
      final lien = Uri.parse(Croissance.lienPlayStore(source: 'page_invite', tableCode: 'HNMQQX'));
      final o = Croissance.lireLeReferrer(lien.queryParameters['referrer']);
      expect(o.source, 'page_invite');
      expect(o.tableCode, 'HNMQQX');
    });
  });

  group('la console : du web à l\'app', () {
    test('le coût du web ne se divise que par les installations venues du web', () {
      final c = BilanCroissance.fromJson({
        'jours': 30,
        'par_type': {'invite_web_arrivee': 12, 'clic_installer': 4, 'premiere_ouverture': 9},
        'installations_par_source': {'page_invite': 3, 'google-play': 5, 'inconnue': 1},
        'cout_ia_web_eur': 0.6,
        'cout_web_par_installation_eur': 0.0667,
      });
      expect(c.evenements('invite_web_arrivee'), 12);
      expect(c.installationsWeb, 3);
      expect(c.coutWebParInstallationEur, closeTo(0.2, 1e-9), reason: '0,60 € pour 3, pas pour 9');
    });

    test('sans installation venue du web, pas de coût par installation', () {
      final c = BilanCroissance.fromJson({
        'installations_par_source': {'google-play': 2},
        'cout_ia_web_eur': 0.3,
      });
      expect(c.installationsWeb, 0);
      expect(c.coutWebParInstallationEur, isNull);
      expect(BilanCroissance.fromJson(const {}).coutWebParInstallationEur, isNull);
    });
  });
}
