import 'taste_evidence.dart';
import 'taste_profile.dart';

/// Ce qu'une annulation a pu défaire, et ce qu'elle n'a pas pu.
class ResultatAnnulation {
  final TasteProfile profil;

  /// Cibles rendues à leur état antérieur, exactement.
  final List<String> defaites;

  /// Cibles qu'on n'a pas pu défaire, parce qu'une contribution plus récente les a
  /// modifiées depuis. Les taire donnerait l'illusion d'une suppression complète.
  final List<String> nonDefaites;

  const ResultatAnnulation({
    required this.profil,
    required this.defaites,
    required this.nonDefaites,
  });

  bool get complete => nonDefaites.isEmpty;
}

/// Défait l'effet d'une dégustation sur le profil de goût.
///
/// POURQUOI CE N'EST PAS UNE SIMPLE SOUSTRACTION
///
/// La moyenne exponentielle est **irréversible** : `apres = avant × 0,75 + valeur × 0,25`
/// perd de l'information à chaque pas. Connaître 0,83 ne dit pas d'où l'on venait, et
/// aucun calcul ne le retrouve. La seule façon de revenir en arrière est d'avoir NOTÉ
/// l'état antérieur au moment du changement — ce que fait le registre des preuves.
///
/// Et même ainsi, l'annulation n'est exacte que si **rien n'a modifié la cible depuis**.
/// Sinon on écraserait des observations légitimes et plus récentes par une valeur
/// périmée : défaire deviendrait pire que laisser.
///
/// D'où un résultat qui distingue ce qui a été défait de ce qui ne l'a pas été. Supprimer
/// une dégustation doit vouloir dire quelque chose de vrai, y compris quand la vérité est
/// « je n'ai pas pu tout défaire ».
class TasteUndo {
  static ResultatAnnulation annuler({
    required TasteProfile profil,
    required List<TasteEvidenceEntry> contributions,
    required TasteEvidenceLedger registre,
  }) {
    var p = profil;
    final defaites = <String>[];
    final nonDefaites = <String>[];

    for (final e in contributions) {
      final derniere = registre.derniereSur(e.cible);
      // Rien n'a bougé cette cible depuis ? Alors l'annulation est exacte.
      final estLaDerniere = derniere != null &&
          derniere.quand == e.quand &&
          derniere.tastingId == e.tastingId;

      final partie = e.cible.split(':');
      final type = partie.first;
      final valeur = partie.length > 1 ? partie.sublist(1).join(':') : '';

      switch (type) {
        case 'region':
          // Appartenance à un ensemble : exacte dans tous les cas.
          if (p.favoriteRegions.contains(valeur)) {
            p = p.copyWith(
              favoriteRegions: List<String>.from(p.favoriteRegions)..remove(valeur),
            );
          }
          defaites.add(e.cible);
          break;

        case 'cepage':
          if (p.favoriteGrapes.contains(valeur)) {
            p = p.copyWith(
              favoriteGrapes: List<String>.from(p.favoriteGrapes)..remove(valeur),
            );
          }
          defaites.add(e.cible);
          break;

        case 'axe':
          // `apres` et non `avant` : un axe renseigné pour la première fois venait
          // légitimement de `null`, et c'est le cas le plus exactement annulable qui soit.
          // Tester `avant` refuserait de défaire précisément celui-là.
          if (!estLaDerniere || e.apres == null) {
            // Une valeur plus récente occupe la place, ou l'état antérieur n'a pas été
            // noté : on laisse plutôt que d'écraser.
            nonDefaites.add(e.cible);
            break;
          }
          p = _avecAxe(p, valeur, e.avant);
          // L'observation correspondante disparaît aussi : la confiance doit refléter ce
          // qui reste, pas ce qui a été.
          final obs = Map<String, int>.from(p.axisObservations);
          final n = (obs[valeur] ?? 0) - 1;
          if (n <= 0) {
            obs.remove(valeur);
          } else {
            obs[valeur] = n;
          }
          p = p.copyWith(axisObservations: obs);
          defaites.add(e.cible);
          break;

        default:
          nonDefaites.add(e.cible);
      }
    }

    // Le compteur d'expérience recule d'une dégustation, sans passer sous zéro.
    if (contributions.isNotEmpty && p.questionnairesCompleted > 0) {
      p = p.copyWith(questionnairesCompleted: p.questionnairesCompleted - 1);
    }

    return ResultatAnnulation(
      profil: p,
      defaites: defaites,
      nonDefaites: nonDefaites,
    );
  }

  static TasteProfile _avecAxe(TasteProfile p, String axe, double? v) =>
      switch (axe) {
        'acidity' => p.copyWith(avgAcidityPreference: v),
        'body' => p.copyWith(avgBodyPreference: v),
        'tannin' => p.copyWith(avgTanninPreference: v),
        'oak' => p.copyWith(avgOakPreference: v),
        'ripeFruit' => p.copyWith(avgRipeFruitPreference: v),
        'spice' => p.copyWith(avgSpicePreference: v),
        'freshFruit' => p.copyWith(avgFreshFruitPreference: v),
        'minerality' => p.copyWith(avgMineralityPreference: v),
        _ => p,
      };
}
