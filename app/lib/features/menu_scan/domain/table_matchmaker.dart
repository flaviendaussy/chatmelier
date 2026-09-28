import '../../sommelier/domain/guest_matcher_engine.dart';
import 'menu_table_matcher_engine.dart';
import 'menu_wine.dart';

/// L'avis d'un convive sur un vin, au matchmaker de table.
enum AvisDeTable {
  adore,
  ok,
  plutotPas,
  non;

  /// Ce que vaut l'avis sur l'échelle des scores du consensus (10 à 100).
  double get score => switch (this) {
        AvisDeTable.adore => 95,
        AvisDeTable.ok => 75,
        AvisDeTable.plutotPas => 45,
        AvisDeTable.non => 15,
      };

  String libelle(bool fr) => switch (this) {
        AvisDeTable.adore => fr ? 'J\'adore' : 'Love it',
        AvisDeTable.ok => fr ? 'Ça me va' : 'Fine by me',
        AvisDeTable.plutotPas => fr ? 'Plutôt pas' : 'Rather not',
        AvisDeTable.non => fr ? 'Non' : 'No',
      };

  static AvisDeTable? depuis(Object? brut) {
    for (final a in AvisDeTable.values) {
      if (a.name == brut) return a;
    }
    return null;
  }
}

/// Le matchmaker de table : chacun se prononce sur des vins de TOUTES les couleurs.
///
/// Contrairement au matchmaker seul, il n'élimine rien (retour du 28/09) : la table peut
/// finir sur un blanc que les autres préfèrent, et il faut alors savoir quel blanc
/// l'amateur de rouge supportera le mieux. Sa couleur préférée ne ferme donc aucune porte ;
/// elle déclenche seulement une explication, au moment où un vin d'une autre couleur
/// arrive.
class TableMatchmaker {
  /// Un avis pèse plus que ce que le moteur devine : c'est la personne qui parle.
  static const poidsDeLAvis = 0.7;

  /// Le score d'un convive pour un vin, une fois son avis donné.
  static double avecAvis(double calcule, AvisDeTable? avis) =>
      avis == null ? calcule : (1 - poidsDeLAvis) * calcule + poidsDeLAvis * avis.score;

  /// Les vins soumis à la table.
  ///
  /// Les mieux placés pour la table, mais au moins un de chaque couleur présente sur la
  /// carte : sans cela, une table d'amateurs de rouge ne verrait jamais le blanc qui
  /// l'aurait peut-être réconciliée avec le convive qui ne supporte pas les tanins.
  static List<MenuWine> candidats(
    List<MenuWine> carte,
    List<GuestProfile> convives, {
    int nombre = 8,
  }) {
    if (carte.isEmpty) return const [];
    final classes = convives.isEmpty
        ? List<MenuWine>.from(carte)
        : MenuTableMatcherEngine.classerLaCarte(menuWines: carte, guests: convives)
            .map((r) => r.menuWine)
            .toList();

    String couleur(MenuWine w) => w.isSparkling
        ? 'bulles'
        : w.isRose
            ? 'rose'
            : w.isWhite
                ? 'blanc'
                : w.isRed
                    ? 'rouge'
                    : 'autre';

    final retenus = <MenuWine>[];
    // Le meilleur de chaque couleur d'abord…
    for (final c in ['rouge', 'blanc', 'rose', 'bulles']) {
      final meilleur = classes.where((w) => couleur(w) == c).firstOrNull;
      if (meilleur != null) retenus.add(meilleur);
    }
    // … puis les mieux classés, jusqu'au nombre voulu.
    for (final w in classes) {
      if (retenus.length >= nombre) break;
      if (!retenus.contains(w)) retenus.add(w);
    }
    // Présentés dans l'ordre du classement, pas couleur par couleur.
    retenus.sort((a, b) => classes.indexOf(a).compareTo(classes.indexOf(b)));
    return retenus.take(nombre).toList();
  }

  /// Ce vin est-il d'une couleur que ce convive n'a pas dite préférer ?
  static bool horsDeSesCouleurs(MenuWine vin, GuestProfile convive) =>
      convive.favoriteTypes.isNotEmpty &&
      !convive.favoriteTypes.any((t) => MenuTableMatcherEngine.correspondALaCouleur(vin, t));

  /// L'explication montrée quand un vin d'une autre couleur arrive.
  static String pourquoiCeVin(MenuWine vin, GuestProfile convive, bool fr) {
    final prefere = convive.favoriteTypes.first.toLowerCase();
    final sa = fr ? _couleurFr(vin) : _couleurEn(vin);
    return fr
        ? 'Vous préférez le $prefere, c\'est noté. Mais la table penchera peut-être pour un $sa : '
            'dites-nous lequel vous gênerait le moins.'
        : 'You prefer $prefere — noted. But the table may lean towards a $sa: tell us which one '
            'you would mind least.';
  }

  static String _couleurFr(MenuWine w) => w.isSparkling
      ? 'effervescent'
      : w.isRose
          ? 'rosé'
          : w.isWhite
              ? 'blanc'
              : w.isRed
                  ? 'rouge'
                  : 'vin d\'une autre couleur';

  static String _couleurEn(MenuWine w) => w.isSparkling
      ? 'sparkling wine'
      : w.isRose
          ? 'rosé'
          : w.isWhite
              ? 'white'
              : w.isRed
                  ? 'red'
                  : 'wine of another colour';
}
