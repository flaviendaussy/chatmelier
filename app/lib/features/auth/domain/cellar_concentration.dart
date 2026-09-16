import '../../cellar/domain/bottle.dart';

/// Une valeur sur-représentée dans une cave.
class ConcentrationSignal {
  /// 'appellation', 'region', 'cepage', 'type', 'classification' ou 'age'.
  final String dimension;
  final String valeur;
  final int bouteilles;

  /// Part de la cave, de 0 à 1.
  final double part;

  const ConcentrationSignal({
    required this.dimension,
    required this.valeur,
    required this.bouteilles,
    required this.part,
  });

  String get cible => '$dimension:$valeur';

  String get effet =>
      '$bouteilles bouteilles, ${(part * 100).round()} % de votre cave.';

  @override
  String toString() => '$cible ($bouteilles btl, ${(part * 100).round()} %)';
}

/// Ce que la composition d'une cave révèle, indépendamment de toute dégustation.
///
/// Une cave n'est pas un échantillon aléatoire : c'est une suite de choix. Accumuler
/// quinze Syrah, ou se fournir surtout en Saint-Joseph, en dit autant qu'une note — et
/// souvent plus tôt, puisqu'on achète avant de déguster.
///
/// LE POINT DÉLICAT : « beaucoup » est RELATIF. Cinq Syrah dans une cave de dix
/// bouteilles est une préférence marquée ; cinq dans une cave de deux cents est du
/// bruit. On raisonne donc en **part de la cave**, jamais en compte absolu — et on exige
/// en plus un minimum de bouteilles, parce qu'une part de 50 % sur une cave de deux
/// bouteilles ne veut rien dire non plus.
class CellarConcentration {
  /// Mêmes exclusions que partout ailleurs : un cadeau n'est pas un choix.
  static const Set<String> _originesExclues = {'gift', 'supermarket'};

  /// En deçà, les parts n'ont pas de sens statistique.
  static const int tailleMinimaleCave = 8;

  /// Part à partir de laquelle une valeur est sur-représentée.
  static const double partMinimale = 0.25;

  /// Et un plancher en bouteilles, pour que la part ne suffise pas à elle seule.
  static const int bouteillesMinimales = 3;

  /// Tous les signaux de concentration d'une cave, du plus marqué au moins marqué.
  static List<ConcentrationSignal> detecter(List<Bottle> bottles) {
    final retenues = bottles
        .where((b) => b.isInCellar && b.quantity > 0)
        .where((b) => !_originesExclues.contains(b.sourceType))
        .toList();

    final total = retenues.fold<int>(0, (s, b) => s + b.quantity);
    if (total < tailleMinimaleCave) return const [];

    final dimensions = <String, Map<String, int>>{
      'appellation': {},
      'region': {},
      'cepage': {},
      'type': {},
      'classification': {},
      'age': {},
    };

    for (final b in retenues) {
      final w = b.wine;
      if (w == null) continue;
      void compter(String dim, String? valeur) {
        final v = valeur?.trim() ?? '';
        if (v.isEmpty || v.toLowerCase() == 'autre') return;
        dimensions[dim]![v] = (dimensions[dim]![v] ?? 0) + b.quantity;
      }

      compter('appellation', w.appellation);
      compter('region', w.region);
      compter('type', w.type);
      compter('classification', w.classification);
      compter('age', _bandeDAge(w.vintage));
      for (final g in w.grapes) {
        compter('cepage', g.name);
      }
    }

    final signaux = <ConcentrationSignal>[];
    dimensions.forEach((dim, comptes) {
      comptes.forEach((valeur, n) {
        final part = n / total;
        if (n >= bouteillesMinimales && part >= partMinimale) {
          signaux.add(ConcentrationSignal(
            dimension: dim,
            valeur: valeur,
            bouteilles: n,
            part: part,
          ));
        }
      });
    });

    signaux.sort((a, b) => b.part.compareTo(a.part));
    return signaux;
  }

  /// Le millésime ramené à une bande d'âge lisible.
  ///
  /// Une cave pleine de millésimes récents et une cave de vieilles bouteilles décrivent
  /// deux façons de boire — l'une cherche le fruit, l'autre la garde. Le millésime brut
  /// ne dirait rien : c'est la bande qui porte le sens.
  static String? _bandeDAge(int? millesime) {
    if (millesime == null || millesime < 1900) return null;
    final age = DateTime.now().year - millesime;
    if (age < 0) return null;
    if (age <= 2) return 'Jeune (0-2 ans)';
    if (age <= 5) return 'Récent (3-5 ans)';
    if (age <= 10) return 'Mûr (6-10 ans)';
    if (age <= 20) return 'De garde (11-20 ans)';
    return 'Ancien (20 ans et plus)';
  }
}
