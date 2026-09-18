import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/cellar/domain/elevage_backfill.dart';
import 'package:chatmelier/features/cellar/domain/wine.dart';
import 'package:chatmelier/features/cellar/domain/wine_world/wine_world.dart';
import 'package:chatmelier/features/cellar/domain/wine_world/wine_world_model.dart';

/// Ce que le backfill écrit doit passer les contraintes de la base.
///
/// La migration 034 vient d'être appliquée : ce code va écrire pour la première fois dans
/// des colonnes qui n'existaient pas hier, et il le fait dans un `try/catch` silencieux.
/// Une valeur hors contrainte ne ferait donc pas de bruit — le backfill échouerait à
/// chaque chargement de cave, sans que rien ne le dise.
void main() {
  /// Les valeurs admises par `CHECK (elevage_type IN (...))` de la migration 034.
  const typesAdmis = {
    'inox', 'beton', 'barrique', 'foudre', 'amphore', 'oeuf', 'bouteille',
  };

  group('🔒 Le backfill respecte le schéma', () {
    test('tout type produit par la table des régions est admis en base', () {
      // Le contrat lie deux fichiers qui ne se connaissent pas : l'énumération Dart et la
      // contrainte SQL. Rien d'autre ne les empêche de diverger.
      for (final c in ContenantElevage.values) {
        expect(typesAdmis, contains(c.name),
            reason: '« ${c.name} » existe en Dart et serait refusé par la base');
      }
    });

    test('aucune durée ne sort des bornes 0–600 mois', () {
      for (final r in WineWorld.regions) {
        for (final e in r.elevages.values) {
          expect(e.mois, inInclusiveRange(0, 600),
              reason: '${r.nom} : ${e.mois} mois serait rejeté');
        }
        for (final ref in r.references) {
          final e = ref.elevage;
          if (e == null) continue;
          expect(e.mois, inInclusiveRange(0, 600),
              reason: '${ref.nom} : ${e.mois} mois serait rejeté');
        }
      }
    });

    test('la charge utile ne contient que les colonnes créées par 034', () {
      const c = CorrectionElevage(
          wineId: 'w', type: 'barrique', mois: 18, impose: true);
      expect(c.payload.keys,
          unorderedEquals(['elevage_type', 'elevage_months']));
    });

    test('un vin déjà renseigné n\'est pas réécrit', () {
      // Sinon le backfill repartirait à chaque chargement de cave, pour rien.
      final dejaFait = Wine(
        id: 'w', name: 'Margaux', region: 'Margaux', country: 'France',
        type: 'red', vintage: 2015, elevageType: 'barrique', elevageMois: 18,
      );
      expect(ElevageBackfill.aCompleter([dejaFait]), isEmpty);
    });
  });
}
