import 'package:chatmelier/features/cellar/domain/terroir_geo_data.dart';
import 'package:chatmelier/features/cellar/domain/terroir_geo_data_en.dart';
import 'package:chatmelier/shared/utils/langue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les fiches de terroir en anglais : aucun texte ne doit retomber en français.
void main() {
  tearDown(() => Langue.estFr = true);

  bool francais(String t) => RegExp(r"[éèêàùçôîœ]|\b(le|la|les|des|du|une|et|sur|avec|mètres)\b", caseSensitive: false)
      .hasMatch(t.replaceAll(RegExp(r"Vosne-Romanée|Pouilly-Fumé|Côte|Médoc|Pessac-Léognan|Émilion|Estèphe|Rhône|Tâche|Bâtard|Vosne|Chambolle|Châteauneuf|Pouilly|Barossa|Mourvèdre|Sémillon|Torrontés|Bédan|Léoville|Bèze|Qualificada|Denominació|Denominación|Geográfica|Calificada|Origen|Wódka|Bénédictine|Fécamp|Côtes|d'Alsace|Chevalier|Petit|Grande|Petite|Crus?|Pays d'Auge|Grands|Premiers|Classés|classement|Montagne de Reims|des Blancs|Valle de Uco|Paraje|piñas|Variedad|Menzioni|Geografiche|Aggiuntive|Rhum|terres blanches|crasse de fer|caillottes|restanques|boulbènes|rancio|vesou|sorì|cheys|patamares|socalcos|Llicorella|Priorat|Cariñena|Peluda|Mazuelo|Tintorera|Galestro|Alberese|Sant'Agata|La Tâche|Richebourg|Romanée-Conti|Pic Saint-Loup|Terrasses du Larzac|Muscat d'Alsace|Figeac|Pavie|Le Pin"), ''));

  test('chaque texte de fiche a sa traduction', () {
    final manquants = <String>[];
    for (final p in TerroirGeoResolver.toutes) {
      for (final t in [p.soilType, p.climate, p.exposure, p.elevation, p.keyGrapes, p.classification, p.sommelierNotes, p.name]) {
        if (francais(t) && !terroirEnAnglais.containsKey(t)) manquants.add(t);
      }
    }
    expect(manquants, isEmpty);
  });

  test('en anglais, la fiche de Bandol est en anglais', () {
    Langue.estFr = false;
    final bandol = TerroirGeoResolver.toutes.firstWhere((p) => p.id == 'provence_bandol');
    expect(bandol.solAffiche, contains('sandstone'));
    expect(bandol.notesAffichees, startsWith("Mourvèdre's sacred ground"));
    expect(bandol.altitudeAffichee, isNot(contains('mètres')));
    Langue.estFr = true;
    expect(bandol.solAffiche, contains('grès'));
  });

  test('ce que le sommelier corrigerait ne revient pas', () {
    final tout = TerroirGeoResolver.toutes.map((p) => '${p.classification} ${p.sommelierNotes}').join('\n');
    expect(tout, isNot(contains('Ausone, Cheval Blanc')), reason: 'classement de Saint-Émilion 2022');
    expect(tout, isNot(contains('Monopoles (Romanée-Conti, La Tâche, Richebourg)')), reason: 'Richebourg n\'est pas un monopole');
    expect(tout, isNot(contains('La plus ancienne région délimitée')), reason: 'Tokaj est délimité depuis 1737');
  });
}
