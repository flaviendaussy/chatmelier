import 'package:flutter_test/flutter_test.dart';

import 'package:chatmelier/features/cellar/domain/wine_world/wine_world.dart';

/// Invariants structurels de la base de régions.
///
/// POURQUOI DES INVARIANTS ET PAS DES EXEMPLES
///
/// Le défaut « En Sol » — une cuvée élevée en amphores à qui l'on attribuait l'élevage
/// en foudre de son domaine — avait trois propriétés qui le rendaient indétectable :
///
///  1. **silencieux** : aucune erreur, aucun nul, juste une valeur fausse ;
///  2. **plausible** : « foudre 20 mois » pour un Bandol, personne ne tique ;
///  3. **invisible aux tests** : dix tests écrits sur cette base passaient pendant que
///     le défaut y était.
///
/// Un test par exemple ne couvre que les cas auxquels on a pensé. Ces vérifications-ci
/// parcourent la base ENTIÈRE et échouent dès qu'une entrée viole une propriété — y
/// compris sur des régions qui n'existent pas encore.
void main() {
  final toutes = <(RegionVin, ReferenceVin)>[
    for (final r in WineWorld.regions)
      for (final ref in r.references) (r, ref),
  ];

  group('🔁 Accessibilité — toute entrée doit pouvoir être renvoyée', () {
    test('chaque référence est retrouvée par son propre nom', () {
      // Une entrée qu'aucune recherche ne peut atteindre est une donnée morte qui donne
      // une fausse impression de couverture.
      final introuvables = <String>[];
      for (final (_, ref) in toutes) {
        if (WineWorld.reference(nom: ref.nom) == null) introuvables.add(ref.nom);
      }
      expect(introuvables, isEmpty,
          reason: 'Références inatteignables : ${introuvables.join(", ")}');
    });

    test('chaque alias retrouve bien sa référence', () {
      final mauvais = <String>[];
      for (final (_, ref) in toutes) {
        for (final a in ref.alias) {
          final trouve = WineWorld.reference(nom: a);
          if (trouve == null) {
            mauvais.add('« $a » ne trouve rien (attendu ${ref.nom})');
          }
        }
      }
      expect(mauvais, isEmpty, reason: mauvais.join('\n'));
    });

    test('chaque région est retrouvée par ses propres alias', () {
      final mauvais = <String>[];
      for (final r in WineWorld.regions) {
        for (final a in r.alias) {
          if (WineWorld.region(appellation: a) == null) {
            mauvais.add('« $a » (${r.id})');
          }
        }
      }
      expect(mauvais, isEmpty,
          reason: 'Alias de région sans effet : ${mauvais.join(", ")}');
    });
  });

  group('📈 Monotonie — en savoir plus ne doit jamais dégrader la réponse', () {
    test('ajouter le producteur ne change pas une réponse trouvée par le nom', () {
      // C'EST L'INVARIANT QUI AURAIT ATTRAPÉ « EN SOL ». Chercher « En Sol » seul
      // donnait la bonne cuvée ; ajouter « Domaine de La Tour du Bon » la remplaçait par
      // le domaine, donc par un élevage faux. Fournir une information supplémentaire
      // avait rendu la réponse PIRE.
      final degradees = <String>[];
      for (final (_, ref) in toutes) {
        final seul = WineWorld.reference(nom: ref.nom);
        if (seul == null) continue;
        for (final (_, autre) in toutes) {
          if (identical(autre, ref)) continue;
          final avecProducteur =
              WineWorld.reference(nom: ref.nom, producteur: autre.nom);
          if (avecProducteur?.nom != seul.nom) {
            degradees.add('« ${ref.nom} » + producteur « ${autre.nom} » '
                '→ ${avecProducteur?.nom}');
          }
        }
      }
      expect(degradees.take(5), isEmpty,
          reason: '${degradees.length} dégradation(s) :\n'
              '${degradees.take(5).join("\n")}');
    });

    test('préciser l\'appellation ne fait pas perdre une région déjà trouvée', () {
      final degradees = <String>[];
      for (final r in WineWorld.regions) {
        if (r.alias.isEmpty) continue;
        final parAlias = WineWorld.region(appellation: r.alias.first);
        if (parAlias == null) continue;
        final avecPays = WineWorld.region(
            appellation: r.alias.first, pays: r.pays);
        if (avecPays?.id != parAlias.id) {
          degradees.add('${r.id} : $parAlias → ${avecPays?.id} en ajoutant le pays');
        }
      }
      expect(degradees, isEmpty, reason: degradees.join('\n'));
    });
  });

  group('⚠️ Ambiguïté — deux entrées ne doivent pas se disputer un libellé', () {
    test('aucun libellé de référence n\'est porté par deux domaines', () {
      final parCle = <String, List<String>>{};
      for (final (_, ref) in toutes) {
        for (final cle in [ref.nom, ...ref.alias]) {
          final c = cle.toLowerCase().trim();
          parCle.putIfAbsent(c, () => []).add(ref.nom);
        }
      }
      final conflits = parCle.entries
          .where((e) => e.value.toSet().length > 1)
          .map((e) => '« ${e.key} » → ${e.value.join(" / ")}')
          .toList();
      expect(conflits, isEmpty,
          reason: 'Libellés ambigus, la recherche en choisira un au hasard :\n'
              '${conflits.join("\n")}');
    });

    test('aucune région ne masque totalement une autre', () {
      // Une région dont TOUS les alias sont capturés par une région déclarée avant elle
      // est inatteignable. C'est ce qui faisait recevoir au Morgon les vingt ans du
      // Bourgogne rouge.
      final masquees = <String>[];
      for (var i = 0; i < WineWorld.regions.length; i++) {
        final r = WineWorld.regions[i];
        if (r.alias.isEmpty) continue;
        final atteignable = r.alias.any(
            (a) => WineWorld.region(appellation: a)?.id == r.id);
        if (!atteignable) masquees.add(r.id);
      }
      expect(masquees, isEmpty,
          reason: 'Régions masquées par une règle déclarée avant : ${masquees.join(", ")}');
    });
  });

  group('🧪 Cohérence des valeurs', () {
    test('toute fenêtre de garde est ordonnée', () {
      final incoherentes = <String>[];
      void verifier(String ou, AgingProfile p) {
        if (!(p.debut <= p.picDebut &&
            p.picDebut <= p.picFin &&
            p.picFin <= p.fin)) {
          incoherentes.add('$ou : ${p.debut}/${p.picDebut}/${p.picFin}/${p.fin}');
        }
      }

      for (final r in WineWorld.regions) {
        r.longevites.forEach((k, p) => verifier('${r.id}[$k]', p));
        for (final ref in r.references) {
          if (ref.longevite != null) verifier(ref.nom, ref.longevite!);
        }
      }
      expect(incoherentes, isEmpty, reason: incoherentes.join('\n'));
    });

    test('aucune longévité absurde', () {
      final absurdes = <String>[];
      for (final r in WineWorld.regions) {
        r.longevites.forEach((k, p) {
          if (p.fin < 1 || p.fin > 120) absurdes.add('${r.id}[$k] : ${p.fin} ans');
        });
      }
      expect(absurdes, isEmpty, reason: absurdes.join('\n'));
    });

    test('toute région déclare au moins une longévité', () {
      final vides = WineWorld.regions
          .where((r) => r.longevites.isEmpty)
          .map((r) => r.id)
          .toList();
      expect(vides, isEmpty, reason: 'Régions sans longévité : ${vides.join(", ")}');
    });

    test('un élevage en bouteille ne concerne que des effervescents', () {
      // Sinon c'est qu'on a confondu l'élevage sur lattes avec un élevage de chai.
      final suspects = <String>[];
      for (final r in WineWorld.regions) {
        r.elevages.forEach((couleur, e) {
          if (e.contenant == ContenantElevage.bouteille &&
              couleur != 'sparkling' &&
              couleur != '*') {
            suspects.add('${r.id}[$couleur]');
          }
        });
      }
      expect(suspects, isEmpty, reason: suspects.join(', '));
    });
  });

  group('🎯 Les entrées où l\'erreur coûte le plus', () {
    test('les grands vins à longévité surchargée sont vérifiés', () {
      // Une fenêtre qui s'écarte de sa catégorie est une affirmation forte : sur un
      // grand vin, elle doit venir d'une source, pas d'un souvenir.
      final nonVerifies = <String>[];
      for (final (_, ref) in toutes) {
        if (ref.longevite == null) continue;
        if (ref.raison == RaisonDePresence.grandVolume) continue;
        if (ref.longevite!.fin >= 40 && ref.certitude != Certitude.verifiee) {
          nonVerifies.add('${ref.nom} (${ref.longevite!.fin} ans)');
        }
      }
      expect(nonVerifies, isEmpty,
          reason: 'Longévités de plus de quarante ans affirmées sans vérification :\n'
              '${nonVerifies.join("\n")}');
    });
  });
}
