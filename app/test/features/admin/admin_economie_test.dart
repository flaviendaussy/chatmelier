import 'package:chatmelier/features/admin/domain/admin_economie.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'onglet « Économie » de la console (migration 047, S5).
void main() {
  final json = {
    'jours': 30,
    'inclut_tests': false,
    'ecpm_eur_estime': {'rewarded': 8.0, 'app_open': 3.0},
    'cout_ia_eur': 0.0184,
    'appels_ia': 23,
    'appels_groundes': 2,
    'revenu_pub_eur_estime': 0.046,
    'impressions': 6,
    'par_fonctionnalite': [
      {'fonctionnalite': 'scan_enrichment', 'appels': 2, 'cout_eur': 0.0601},
      {'fonctionnalite': 'menu_scan_vision', 'appels': 9, 'cout_eur': 0.0018},
    ],
    'par_emplacement': [
      {'format': 'rewarded', 'emplacement': 'scan_carte', 'impressions': 5, 'revenu_eur': 0.04},
    ],
    'par_plateforme': [
      {'plateforme': 'android', 'cout_eur': 0.015, 'revenu_eur': 0.046},
      {'plateforme': 'web', 'cout_eur': 0.0034, 'revenu_eur': 0},
    ],
    'par_personne': [
      {'user_id': 'u1', 'prenom': 'Caro', 'cout_eur': 0.01, 'appels': 12, 'revenu_eur': 0.024, 'impressions': 3},
    ],
  };

  test('le bilan se lit tel que la fonction serveur le rend', () {
    final b = BilanEconomique.fromJson(json);
    expect(b.jours, 30);
    expect(b.coutIaEur, closeTo(0.0184, 1e-9));
    expect(b.revenuPubEur, closeTo(0.046, 1e-9));
    expect(b.ratio, closeTo(2.5, 1e-9), reason: 'la pub paie 250 % de l\'IA');
    expect(b.parFonctionnalite.first.libelle, 'Enrichissement d\'étiquette');
    expect(b.parFonctionnalite.last.libelle, 'Scan de carte');
    expect(b.parEmplacement.single.emplacement, 'scan_carte');
    expect(b.parPlateforme.map((p) => p.plateforme), ['android', 'web']);
    expect(b.parPersonne.single.prenom, 'Caro');
    expect(b.ecpmEstime['rewarded'], 8.0);
  });

  test('sans coût, pas de ratio infini', () {
    final b = BilanEconomique.fromJson({...json, 'cout_ia_eur': 0});
    expect(b.ratio, isNull);
  });

  test('un bilan vide ou incomplet ne casse rien', () {
    final b = BilanEconomique.fromJson(const {});
    expect(b.appelsIa, 0);
    expect(b.parPersonne, isEmpty);
    expect(b.ratio, isNull);
  });

  test('des montants minuscules se lisent en centimes', () {
    expect(euros(0.0018), '0,180 c€');
    expect(euros(0.046), '4,60 c€');
    expect(euros(3.456), '3,46 €');
  });
}
