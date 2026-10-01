import '../../../shared/utils/currency_helper.dart';
import '../../cellar/domain/cellar_gap_engine.dart';
import 'menu_wine.dart';
import '../../../shared/utils/langue.dart';
import '../../../shared/utils/sans_accents.dart';

/// Une bouteille qu'on possède déjà.
class VinDeMaCave {
  final String nom;
  final String? producteur;
  final int? millesime;
  final double? prixAchat;

  /// Devise du prix d'achat (ISO 4217).
  final String deviseAchat;
  final int quantite;

  const VinDeMaCave({
    required this.nom,
    this.producteur,
    this.millesime,
    this.prixAchat,
    this.deviseAchat = 'EUR',
    this.quantite = 1,
  });
}

/// Un vin qu'on a déjà goûté, et ce qu'on en a pensé.
class VinDejaGoute {
  final String nom;
  final String? producteur;
  final int? millesime;
  final double? note; // sur 10
  final DateTime? quand;

  const VinDejaGoute({
    required this.nom,
    this.producteur,
    this.millesime,
    this.note,
    this.quand,
  });
}

/// Ce que la cave et le journal savent, au moment où l'on regarde une carte.
///
/// Rassemblé par l'appelant et passé en valeur : le moteur reste pur, donc testable sans
/// base ni réseau — ce qui compte d'autant plus ici que se tromper revient à affirmer à
/// quelqu'un qu'il a bu un vin qu'il n'a jamais ouvert.
class ContexteDeCave {
  final List<VinDeMaCave> cave;
  final List<VinDejaGoute> journal;
  final CellarGapAnalysis? lacunes;

  const ContexteDeCave({
    this.cave = const [],
    this.journal = const [],
    this.lacunes,
  });

  bool get estVide => cave.isEmpty && journal.isEmpty && lacunes == null;
}

/// La nature du lien entre un vin de la carte et ce qu'on connaît déjà.
enum TypeDeLien {
  /// On l'a bu, et on sait ce qu'on en a pensé.
  dejaGoute,

  /// On en a chez soi. Savoir ce qu'on l'a payé change la lecture de la carte des prix.
  enCave,

  /// Il comblerait un manque de la cave. Un conseil, pas un fait.
  combleUneLacune,
}

/// Ce que la cave a à dire sur un vin de la carte.
class LienAvecMaCave {
  final TypeDeLien type;
  final String libelle;
  final String? detail;

  const LienAvecMaCave({
    required this.type,
    required this.libelle,
    this.detail,
  });

  String get emoji => switch (type) {
        TypeDeLien.dejaGoute => '📓',
        TypeDeLien.enCave => '🏠',
        TypeDeLien.combleUneLacune => '🧩',
      };
}

/// Croise la carte d'un restaurant avec la cave et le journal de son lecteur.
///
/// **C'est la phrase que ni Vivino ni CellarTracker ne peuvent produire** : ils savent ce
/// que le monde pense d'un vin, pas ce que VOUS en avez pensé, ni ce que vous l'avez payé
/// le mois dernier. Le module `menu_scan` ne contenait jusqu'ici aucune référence à la
/// cave ni au journal — les deux moitiés du produit s'ignoraient.
///
/// **Le risque assumé est l'inverse de l'habituel.** Rater un rapprochement ne coûte
/// qu'une occasion manquée ; en inventer un dit à quelqu'un qu'il a bu un vin qu'il n'a
/// jamais ouvert, ou qu'il en a chez lui alors que non. On préfère donc se taire : la
/// correspondance exige le producteur, ou un nom qui se recoupe franchement.
class CellarBridgeEngine {
  /// Un lien par vin, quand il y en a un.
  static List<MenuWine> lier(List<MenuWine> vins, ContexteDeCave contexte, {bool isFr = true}) {
    if (vins.isEmpty || contexte.estVide) return vins;

    final regionsManquantes = _regionsAConseiller(contexte.lacunes);
    var lacunesPosees = 0;

    return [
      for (final v in vins) v.copyWith(pontDeCave: _lienPour(v, contexte, isFr, () {
            // Le conseil est rationné, contrairement aux faits : deux suggestions
            // éclairent, huit deviennent un bruit qu'on cesse de lire.
            if (lacunesPosees >= 2) return null;
            final r = _comblerait(v, regionsManquantes, isFr);
            if (r != null) lacunesPosees++;
            return r;
          })),
    ];
  }

  static LienAvecMaCave? _lienPour(
    MenuWine vin,
    ContexteDeCave contexte,
    bool fr,
    LienAvecMaCave? Function() lacune,
  ) {
    // 1. « Vous l'avez goûté » passe avant tout : c'est le seul fait qui porte un jugement
    //    déjà formé, et il tranche une hésitation mieux que n'importe quel conseil.
    for (final g in contexte.journal) {
      if (!_memeVin(vin.name, vin.producer, g.nom, g.producteur)) continue;
      final note = g.note;
      return LienAvecMaCave(
        type: TypeDeLien.dejaGoute,
        libelle: trSi(fr, 'Vous connaissez ce vin', 'You know this wine'),
        detail: note == null
            ? _quand(g.quand, fr)
            : (trSi(fr, 'Vous l\'aviez noté {v1}/10{v2}', 'You rated it {v1}/10{v2}', {'v1': _note(note), 'v2': _quandSuffixe(g.quand, fr)})),
      );
    }

    // 2. « Vous en avez chez vous », avec le prix payé quand on le connaît.
    for (final c in contexte.cave) {
      if (!_memeVin(vin.name, vin.producer, c.nom, c.producteur)) continue;
      final achat = c.prixAchat;
      final carte = vin.bottlePrice;
      // Un écart ne se calcule que dans une même devise : une bouteille payée en euros
      // et une carte en livres donneraient un chiffre faux. Carte sans devise connue :
      // on la suppose dans celle de la cave, comme avant.
      final memeDevise = vin.devise == null || vin.devise == c.deviseAchat;
      String? detail;
      if (achat != null && achat > 0 && carte != null && carte > 0 && memeDevise) {
        final ecart = carte - achat;
        final paye = _prix(achat, c.deviseAchat);
        detail = ecart > 0
            ? (trSi(fr, 'Vous en avez en cave, payée {paye} — soit {v1} de moins qu\'ici', 'You have it in your cellar, bought for {paye} — {v1} less than here', {'paye': paye, 'v1': _prix(ecart, c.deviseAchat)}))
            : (trSi(fr, 'Vous en avez en cave, payée {paye}', 'You have it in your cellar, bought for {paye}', {'paye': paye}));
      } else if (achat != null && achat > 0 && carte != null && carte > 0) {
        final paye = _prix(achat, c.deviseAchat);
        detail = trSi(fr, 'Vous en avez en cave, payée {paye}', 'You have it in your cellar, bought for {paye}', {'paye': paye});
      } else {
        detail = c.quantite > 1
            ? (trSi(fr, 'Vous en avez {quantite} en cave', 'You have {quantite} in your cellar', {'quantite': c.quantite}))
            : (trSi(fr, 'Vous en avez une en cave', 'You have one in your cellar'));
      }
      return LienAvecMaCave(
        type: TypeDeLien.enCave,
        libelle: trSi(fr, 'Déjà dans votre cave', 'Already in your cellar'),
        detail: detail,
      );
    }

    // 3. Le conseil, en dernier.
    return lacune();
  }

  static LienAvecMaCave? _comblerait(MenuWine vin, Set<String> regions, bool fr) {
    if (regions.isEmpty) return null;
    final candidats = <String>[
      vin.appellation ?? '',
      vin.region ?? '',
    ].map(_norm).where((s) => s.isNotEmpty);

    for (final c in candidats) {
      for (final r in regions) {
        if (c.contains(r) || r.contains(c)) {
          return LienAvecMaCave(
            type: TypeDeLien.combleUneLacune,
            libelle: trSi(fr, 'Comblerait un manque', 'Would fill a gap'),
            detail: trSi(fr, 'Votre cave est légère sur ce registre — l\'occasion de l\'essayer avant d\'en acheter.', 'Your cellar is light in this style — a chance to try it before buying any.'),
          );
        }
      }
    }
    return null;
  }

  static Set<String> _regionsAConseiller(CellarGapAnalysis? a) {
    if (a == null) return const {};
    return {
      for (final g in a.gaps)
        if (g.status != 'balanced')
          for (final app in g.recommendedAppellations)
            if (_norm(app).isNotEmpty) _norm(app),
    };
  }

  /// Deux désignations parlent-elles du même vin ?
  ///
  /// Strict par construction. Deux voies seulement :
  ///   · le producteur correspond — c'est le signal le plus sûr, un domaine ne se
  ///     confond pas ;
  ///   · à défaut de producteur des deux côtés, les noms partagent au moins deux mots
  ///     significatifs. Un seul ne suffit pas : « Bandol Rouge » et « Bandol Rosé »
  ///     partagent « bandol » et ne sont pas le même vin.
  ///
  /// Le millésime n'entre pas dans la comparaison : avoir goûté le 2019 dit quelque chose
  /// d'utile sur le 2020, et l'exiger ferait rater presque tous les rapprochements.
  static bool _memeVin(
      String nomCarte, String? prodCarte, String nomConnu, String? prodConnu) {
    final pc = _norm(prodCarte);
    final pk = _norm(prodConnu);
    if (pc.isNotEmpty && pk.isNotEmpty) {
      if (pc == pk || pc.contains(pk) || pk.contains(pc)) return true;
      // Producteurs différents : c'est un autre vin, même si les noms se ressemblent.
      return false;
    }

    final a = _motsSignificatifs(nomCarte);
    final b = _motsSignificatifs(nomConnu);
    if (a.isEmpty || b.isEmpty) return false;
    final communs = a.intersection(b);
    return communs.length >= 2;
  }

  /// Les mots qui identifient, débarrassés de ceux qui ne disent rien.
  static Set<String> _motsSignificatifs(String s) {
    const vides = {
      'le', 'la', 'les', 'de', 'du', 'des', 'et', 'aux', 'au', 'vin', 'cuvee',
      'domaine', 'chateau', 'clos', 'rouge', 'blanc', 'rose', 'vieilles',
      'vignes', 'grand', 'petit', 'the', 'of', 'wine',
    };
    return _norm(s)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((m) => m.length > 2 && !vides.contains(m))
        .toSet();
  }

  static String _norm(String? s) => sansAccents(s ?? '').trim();

  static String _note(double n) =>
      n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(1);

  static String _prix(double v, String devise) => CurrencyHelper.formatPrice(v, currency: devise);

  static String? _quand(DateTime? d, bool fr) =>
      d == null ? null : '${trSi(fr, 'Goûté', 'Tasted')} ${_moisAnnee(d, fr)}';

  static String _quandSuffixe(DateTime? d, bool fr) =>
      d == null ? '' : ', ${_moisAnnee(d, fr)}';

  static String _moisAnnee(DateTime d, bool fr) {
    const mois = [
      Phrase('janvier', 'January'), Phrase('février', 'February'), Phrase('mars', 'March'),
      Phrase('avril', 'April'), Phrase('mai', 'May'), Phrase('juin', 'June'),
      Phrase('juillet', 'July'), Phrase('août', 'August'), Phrase('septembre', 'September'),
      Phrase('octobre', 'October'), Phrase('novembre', 'November'), Phrase('décembre', 'December'),
    ];
    return trSi(fr, 'en {mois} {year}', 'in {mois} {year}', {'mois': mois[d.month - 1].dans(fr), 'year': d.year});
  }
}
