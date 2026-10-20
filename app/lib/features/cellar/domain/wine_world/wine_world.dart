import '../../../../shared/utils/sans_accents.dart';
import 'regions_europe.dart';
import 'regions_france.dart';
import 'regions_iberie.dart';
import 'regions_italie.dart';
import 'regions_nouveau_monde.dart';
import 'wine_world_model.dart';

export 'wine_world_model.dart';

/// La base des régions viticoles — une seule, pour tous les usages.
///
/// Elle remplace la dispersion précédente : `AgingReference` décrivait des longévités,
/// `TerroirGISCatalog` des géographies, et les deux parlaient des mêmes régions sans se
/// connaître. Deux tables sur le même sujet divergent toujours — celle qu'on met à jour,
/// et l'autre.
///
/// Le dosage suit deux critères, jamais la simple exhaustivité :
///
///  - **le coût de l'erreur** : se tromper sur un Yquem ou un Barolo déçoit durablement,
///    parce que ce sont des bouteilles qu'on garde et qu'on attend ;
///  - **la fréquence de l'erreur** : se tromper sur un Casillero del Diablo ou un
///    Marlborough Sauvignon se produit des milliers de fois, parce qu'ils sont scannés
///    des milliers de fois.
///
/// Un Pétrus est rarement scanné, un Yellow Tail l'est tous les jours : les deux ont leur
/// place ici, pour des raisons opposées.
class WineWorld {
  static const List<RegionVin> regions = [
    ...regionsFrance,
    ...regionsItalie,
    ...regionsIberie,
    ...regionsEurope,
    ...regionsNouveauMonde,
  ];

  // Le trait d'union compte comme une espace : « Côtes-du-Rhône » et « Côtes du Rhône »
  // sont la même appellation, et seule la seconde graphie était reconnue (30/09).
  static final _horsDesMots = RegExp(r"[^a-z0-9\s']");
  static final _espaces = RegExp(r'\s+');
  static String _norm(String? s) => sansAccents(s ?? '').replaceAll(_horsDesMots, ' ').replaceAll(_espaces, ' ').trim();

  /// La base, normalisée une fois pour toutes (20/10). `region()` et la recherche des
  /// références renormalisaient chaque alias de chaque région à chaque appel : 10 à 15 ms
  /// par vin, plusieurs fois par fenêtre de garde — et la cave triée par maturité en
  /// calculait des milliers.
  static final List<_RegionNormee> _normees = [
    for (final r in regions)
      _RegionNormee(
        r,
        alias: [for (final a in r.alias) _norm(a)],
        cepages: [for (final c in r.cepages) _norm(c)],
        pays: _norm(r.pays),
        cles: [
          for (final ref in r.references)
            for (final cle in [ref.nom, ...ref.alias])
              if (_norm(cle) case final c when c.isNotEmpty) (c, ref),
        ],
      ),
  ];
  static final Map<RegionVin, _RegionNormee> _parRegion = {for (final n in _normees) n.region: n};

  /// Les réponses déjà données : la base ne change pas, les mêmes vins reviennent à
  /// chaque écran. Bornées, pour ne pas grossir sans fin.
  static final Map<String, RegionVin?> _memoRegion = {};
  static final Map<String, ReferenceVin?> _memoReference = {};
  static final Map<String, String?> _memoPays = {};
  static const _memoMax = 4000;

  static V _memoise<V>(Map<String, V> memo, String cle, V Function() calcul) {
    if (memo.containsKey(cle)) return memo[cle] as V;
    final v = calcul();
    if (memo.length >= _memoMax) memo.clear();
    memo[cle] = v;
    return v;
  }

  /// La région qui correspond, du plus spécifique au plus général.
  ///
  /// L'ordre de déclaration vaut priorité : les fichiers listent les appellations
  /// nommées avant les mentions larges, faute de quoi un Morgon serait capturé par
  /// « Bourgogne » et un Koonunga Hill par « Barossa ».
  static RegionVin? region({
    String? pays,
    String? region,
    String? appellation,
    List<String> cepages = const [],
  }) {
    final app = _norm(appellation);
    final reg = _norm(region);
    final pay = _norm(pays);
    final ceps = cepages.map(_norm).toList();
    return _memoise(_memoRegion, '$app|$reg|$pay|${ceps.join('|')}', () => _region(app, reg, pay, ceps));
  }

  static RegionVin? _region(String app, String reg, String pay, List<String> ceps) {
    // 1. L'appellation, qui est le signal le plus précis.
    for (final n in _normees) {
      if (app.isEmpty) break;
      if (n.alias.any(app.contains)) return n.region;
    }
    // 2. La région déclarée.
    for (final n in _normees) {
      if (reg.isEmpty) break;
      if (n.alias.any(reg.contains)) return n.region;
    }
    // 3. Le cépage, qui trahit souvent l'origine à défaut de mieux.
    for (final n in _normees) {
      if (ceps.isEmpty) break;
      if (n.cepages.any(ceps.contains)) {
        if (pay.isEmpty || n.pays.contains(pay) || pay.contains(n.pays)) {
          return n.region;
        }
      }
    }
    return null;
  }

  /// Le nom du vin désigne-t-il une appellation de la base, dans son propre pays ?
  ///
  /// Une fiche sans appellation la porte souvent dans son nom : « Châteauneuf-du-Pape »,
  /// région « Vallée du Rhône ». Le pays garde du contresens : un « Chablis » californien
  /// n'est pas un chablis.
  static bool appellationDansLeNom(String? nom, {String? pays}) {
    final r = region(appellation: nom);
    return r != null && memePays(r.pays, pays);
  }

  /// L'appellation telle que le nom l'écrit, et elle seule : « Côte-Rôtie » dans
  /// « Côte-Rôtie Fructus Voluptas », « Bandol » dans « Bandol Pour Lulu » (17/10 : la cuvée
  /// passait pour un terroir). Mot à mot, dans le pays du vin ; un cépage qui sert d'alias
  /// (« Albariño ») n'est pas une appellation. Nulle si le nom n'en porte aucune.
  static String? appellationLueDans(String? nom, {String? pays}) {
    final r = region(appellation: nom);
    if (nom == null || r == null || !memePays(r.pays, pays)) return null;
    final mots = _mots.allMatches(nom).toList();
    final normes = [for (final m in mots) _norm(m.group(0))];
    final n = _parRegion[r]!;
    final cepages = n.cepages.toSet();
    String? lue;
    for (final cible in n.alias) {
      if (cible.isEmpty || cepages.contains(cible)) continue;
      final morceaux = cible.split(' ');
      for (var i = 0; i + morceaux.length <= normes.length; i++) {
        var pareil = true;
        for (var j = 0; j < morceaux.length && pareil; j++) {
          pareil = normes[i + j] == morceaux[j];
        }
        if (!pareil) continue;
        final texte = nom.substring(mots[i].start, mots[i + morceaux.length - 1].end);
        if (lue == null || texte.length > lue.length) lue = texte;
      }
    }
    return lue;
  }

  /// Le pays d'une appellation ou d'une région nommée, quand le nom ne laisse aucun doute :
  /// « Morgon » est en France, « Ribera del Duero » en Espagne (V2.5 · F6 : le journal de
  /// Flavien n'avait de pays pour aucun vin bu dehors, donc aucun drapeau).
  ///
  /// Mot à mot, et non par morceaux : « Castilla » contient « asti », et `region` en faisait
  /// un vin italien. Sans les cépages qui servent d'alias (un albariño pousse aussi au
  /// Portugal et en Uruguay), ni les mots partagés par plusieurs pays (un crémant peut être
  /// luxembourgeois, la Central Valley est au Chili et en Californie). Nul si deux pays se
  /// disputent le nom.
  static String? paysDe({String? appellation, String? region}) =>
      _memoise(_memoPays, '${_norm(appellation)}|${_norm(region)}', () => _paysDe(appellation, region));

  static String? _paysDe(String? appellation, String? region) {
    for (final texte in [appellation, region]) {
      final mots = ' ${_norm(texte)} ';
      if (mots.trim().isEmpty) continue;
      final trouves = <String>{};
      for (final n in _normees) {
        final cepages = n.cepages.toSet();
        for (final cible in n.alias) {
          if (cible.isEmpty || cepages.contains(cible) || _aliasPartages.contains(cible)) continue;
          if (mots.contains(' $cible ')) {
            trouves.add(n.region.pays);
            break;
          }
        }
      }
      if (trouves.length == 1) return trouves.single;
      if (trouves.length > 1) return null;
    }
    return null;
  }

  static const _aliasPartages = {'cremant', 'vin mousseux', 'central valley'};
  static final _mots = RegExp(r"[\p{L}\p{N}']+", unicode: true);

  /// Deux noms du même pays, en français, en anglais ou en espagnol. Un pays inconnu
  /// ou absent ne contredit rien.
  static bool memePays(String? a, String? b) {
    final x = _norm(a);
    final y = _norm(b);
    if (x.isEmpty || y.isEmpty) return true;
    return (_pays[x] ?? x) == (_pays[y] ?? y);
  }

  static const Map<String, String> _pays = {
    'francia': 'france', 'frankreich': 'france',
    'spain': 'espagne', 'espana': 'espagne',
    'italy': 'italie', 'italia': 'italie',
    'germany': 'allemagne', 'alemania': 'allemagne', 'deutschland': 'allemagne',
    'austria': 'autriche', 'osterreich': 'autriche',
    'england': 'angleterre', 'uk': 'angleterre', 'united kingdom': 'angleterre',
    'royaume uni': 'angleterre', 'inglaterra': 'angleterre', 'reino unido': 'angleterre',
    'greece': 'grece', 'grecia': 'grece',
    'hungary': 'hongrie', 'hungria': 'hongrie',
    'usa': 'etats unis', 'us': 'etats unis', 'united states': 'etats unis',
    'estados unidos': 'etats unis', 'eeuu': 'etats unis',
    'argentina': 'argentine',
    'chile': 'chili',
    'australia': 'australie',
    'new zealand': 'nouvelle zelande', 'nueva zelanda': 'nouvelle zelande',
    'south africa': 'afrique du sud', 'sudafrica': 'afrique du sud',
  };

  /// La référence nommée qui correspond à ce vin, s'il y en a une.
  ///
  /// C'est le niveau qui règle les cas où un domaine s'écarte de sa catégorie :
  /// « Bandol rosé » donne quatorze ans, Terrebrune en tient vingt.
  static ReferenceVin? reference({String? nom, String? producteur}) {
    // Le NOM du vin est cherché en premier, et il l'emporte sur le producteur.
    //
    // La spécificité n'est pas la longueur du libellé : « Domaine de La Tour du Bon »
    // fait vingt-cinq caractères et « En Sol » six, mais c'est la cuvée qui décrit le
    // vin. Cette cuvée est élevée en amphores quand le domaine élève en foudre — la
    // faire perdre au profit du nom de domaine donnait une réponse fausse.
    final parLeNom = _chercherDans(_norm(nom));
    if (parLeNom != null) return parLeNom;
    return _chercherDans(_norm(producteur));
  }

  static ReferenceVin? _chercherDans(String texte) {
    if (texte.isEmpty) return null;
    return _memoise(_memoReference, texte, () => _chercher(texte));
  }

  static ReferenceVin? _chercher(String texte) {
    ReferenceVin? meilleure;
    var meilleureLongueur = 0;
    for (final n in _normees) {
      for (final (c, ref) in n.cles) {
        // Un libellé court — « DRC », « KWV », « Ott » — doit rester atteignable : le
        // rejeter sur sa seule longueur en faisait des entrées MORTES, présentes dans
        // la base mais qu'aucune recherche ne pouvait renvoyer.
        //
        // Ce qui protège des fragments n'est pas la longueur mais la frontière de
        // mot : « ott » dans « Domaines Ott » oui, dans « Lotte » non. Au-delà de
        // quatre caractères la sous-chaîne suffit, les collisions y étant improbables
        // et les étiquettes rarement écrites à l'identique.
        final trouve = c.length >= 5
            ? texte.contains(c)
            : _contientMotEntier(texte, c);
        if (!trouve) continue;
        // À champ égal, le libellé le plus long reste le plus précis :
        // « Penfolds Grange » avant « Penfolds ».
        if (c.length > meilleureLongueur) {
          meilleureLongueur = c.length;
          meilleure = ref;
        }
      }
    }
    return meilleure;
  }

  /// L'élevage de ce vin : celui du domaine s'il est connu, sinon celui de sa région.
  ///
  /// Beaucoup d'appellations IMPOSENT une durée minimale — Barolo dix-huit mois sous
  /// bois, Brunello vingt-quatre, Rioja Crianza douze. Là où l'enrichissement ne dit
  /// rien, le cahier des charges, lui, est connu : c'est une source déterministe et
  /// gratuite, et `Elevage.impose` distingue le fait de l'estimation.
  static Elevage? elevage({
    String? pays,
    String? region,
    String? appellation,
    String? nom,
    String? producteur,
    String? type,
    List<String> cepages = const [],
  }) {
    final duDomaine = reference(nom: nom, producteur: producteur)?.elevage;
    if (duDomaine != null) return duDomaine;

    final r = WineWorld.region(
      pays: pays, region: region, appellation: appellation, cepages: cepages);
    return r?.elevagePour(_couleur(type));
  }

  /// `motif` apparaît-il comme une suite de mots entiers dans `texte` ?
  static bool _contientMotEntier(String texte, String motif) {
    final mots = texte.split(' ').where((m) => m.isNotEmpty).toList();
    final cibles = motif.split(' ').where((m) => m.isNotEmpty).toList();
    if (cibles.isEmpty || cibles.length > mots.length) return false;
    for (var i = 0; i <= mots.length - cibles.length; i++) {
      var ok = true;
      for (var j = 0; j < cibles.length; j++) {
        if (mots[i + j] != cibles[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  static String _couleur(String? type) {
    final t = _norm(type);
    if (t.contains('fortifi') || t.contains('mute')) return 'fortified';
    if (t.contains('moelleux') ||
        t.contains('liquoreux') ||
        t.contains('sweet') ||
        t.contains('dessert')) {
      return 'sweet';
    }
    if (t.contains('bulle') || t.contains('sparkl') || t.contains('effervesc')) {
      return 'sparkling';
    }
    if (t.contains('ros')) return 'rose';
    if (t.contains('blanc') || t.contains('white')) return 'white';
    return 'red';
  }

  /// Combien de régions et de références, par pays. Sert au test de couverture.
  static Map<String, ({int regions, int references})> couverture() {
    final m = <String, ({int regions, int references})>{};
    for (final r in regions) {
      final actuel = m[r.pays] ?? (regions: 0, references: 0);
      m[r.pays] = (
        regions: actuel.regions + 1,
        references: actuel.references + r.references.length,
      );
    }
    return m;
  }
}

/// Une région de la base et ses noms déjà normalisés.
class _RegionNormee {
  final RegionVin region;
  final List<String> alias;
  final List<String> cepages;
  final String pays;

  /// Les noms et alias de ses références, normalisés et non vides, dans l'ordre de la base.
  final List<(String, ReferenceVin)> cles;

  const _RegionNormee(this.region, {required this.alias, required this.cepages, required this.pays, required this.cles});
}
