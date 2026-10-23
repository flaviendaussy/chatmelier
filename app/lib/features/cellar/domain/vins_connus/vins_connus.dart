import '../../../../shared/utils/sans_accents.dart';
import '../wine_world/wine_world.dart' show WineWorld;
import 'vins_connus_bordeaux_sud_ouest.dart';
import 'vins_connus_bourgogne_est.dart';
import 'vins_connus_champagne_loire_alsace.dart';
import 'vins_connus_europe.dart';
import 'vins_connus_iberie.dart';
import 'vins_connus_italie.dart';
import 'vins_connus_nouveau_monde.dart';
import 'vins_connus_rhone_sud.dart';
import 'vins_connus_modele.dart';

export 'vins_connus_modele.dart';

/// Un vin reconnu dans la base, et les cépages qu'on lui prête.
class VinTrouve {
  final VinConnu vin;

  /// L'appellation sous laquelle la base range ce vin.
  final AppellationConnue appellation;

  /// L'appellation que la fiche du vin donne elle-même, quand la base la connaît : une
  /// maison rangée sous « Bourgogne » fait aussi du Beaujolais.
  final AppellationConnue? appellationDeLaFiche;

  const VinTrouve(this.vin, this.appellation, {this.appellationDeLaFiche});

  /// Les cépages de la cuvée ; sinon ceux de l'appellation de la fiche, puis ceux de la
  /// base, pour la couleur du vin.
  List<String> get cepages {
    if (vin.cepages.isNotEmpty) return vin.cepages;
    final fiche = appellationDeLaFiche;
    if (fiche != null && !fiche.generique) {
      final c = fiche.cepagesPour(vin.couleur);
      if (c.isNotEmpty) return c;
    }
    return appellation.cepagesPour(vin.couleur);
  }

  /// Vrai quand les cépages sont ceux de la cuvée elle-même, pas une moyenne.
  bool get cepagesDeLaCuvee => vin.cepages.isNotEmpty;
}

/// La base des vins connus : les appellations, et dans chacune les vins qu'on y croise.
class VinsConnus {
  VinsConnus._();

  static const List<AppellationConnue> appellations = [
    ...appellationsBordeauxSudOuest,
    ...appellationsBourgogneEst,
    ...appellationsRhoneSud,
    ...appellationsChampagneLoireAlsace,
    ...appellationsItalie,
    ...appellationsIberie,
    ...appellationsEurope,
    ...appellationsNouveauMonde,
  ];

  /// Combien de vins la base connaît.
  static int get nombreDeVins => appellations.fold(0, (n, a) => n + a.vins.length);

  // Les mots de liaison varient d'une étiquette à l'autre (« Moët & Chandon », « Moët et
  // Chandon ») : ils ne comptent pas. « St » et « Ste » valent « Saint » et « Sainte ».
  static const _liaisons = {'et', 'and', 'und'};
  static const _abreviations = {'st': 'saint', 'ste': 'sainte', 'mt': 'mount'};
  static final _horsDesMots = RegExp(r'[^a-z0-9]+');

  /// Un nom en mots : minuscules, sans accents ni ponctuation, les apostrophes et traits
  /// d'union comme des espaces (« Cos d'Estournel » → « cos d estournel »).
  static String normaliser(String? texte) {
    if (texte == null || texte.isEmpty) return '';
    return _memoise(_memoNormal, texte, () => _normaliser(texte));
  }

  static final Map<String, String> _memoNormal = {};

  static String _normaliser(String texte) {
    return sansAccents(texte)
        .replaceAll(_horsDesMots, ' ')
        .split(' ')
        .where((m) => m.isNotEmpty && !_liaisons.contains(m))
        .map((m) => _abreviations[m] ?? m)
        .join(' ');
  }

  /// La base, normalisée une fois pour toutes.
  static final List<_AppellationIndexee> _index = [
    for (final a in appellations)
      _AppellationIndexee(
        a,
        noms: {
          for (final n in [a.nom, ...a.alias])
            if (normaliser(n) case final c when c.isNotEmpty) c,
        }.toList(),
        vins: [
          for (final v in a.vins)
            _VinIndexe(
              v,
              cles: {
                for (final n in [v.nom, ...v.alias])
                  if (normaliser(n) case final c when c.isNotEmpty) ...[c, if (_sansChateau(c) case final s?) s],
              }.toList(),
              de: v.de == null ? null : normaliser(v.de),
            ),
        ],
      ),
  ];

  /// « Château Cos Labory » s'écrit souvent « Cos Labory » : le nom sans « Château » ni
  /// « Domaine » vaut aussi, quand il reste assez long pour ne désigner que lui. Pas
  /// « Latour » ni « Margaux » (une appellation), ni ce qui commence par « de » : « Château
  /// de France » serait lu dans chaque « Vin de France ».
  static String? _sansChateau(String cle) {
    for (final prefixe in const ['chateau ', 'domaine ']) {
      if (!cle.startsWith(prefixe)) continue;
      final reste = cle.substring(prefixe.length);
      final premier = reste.split(' ').first;
      if (reste.length >= 9 && !const {'de', 'du', 'des', 'd'}.contains(premier)) return reste;
    }
    return null;
  }

  /// `WineWorld.memePays` renormalise ses deux noms à chaque appel : gardé ici, une fois
  /// par paire de pays.
  static final Map<String, bool> _memoPays = {};
  static bool _memePays(String a, String? b) => _memoPays['$a|$b'] ??= WineWorld.memePays(a, b);

  static final Map<String, AppellationConnue?> _memoAppellation = {};
  static final Map<String, VinTrouve?> _memoVin = {};
  static const _memoMax = 4000;

  static V _memoise<V>(Map<String, V> memo, String cle, V Function() calcul) {
    if (memo.containsKey(cle)) return memo[cle] as V;
    final v = calcul();
    if (memo.length >= _memoMax) memo.clear();
    memo[cle] = v;
    return v;
  }

  /// L'appellation que nomme la fiche : le champ appellation d'abord, puis le nom du vin,
  /// puis la région. Le nom le plus long l'emporte (« Lussac-Saint-Émilion » avant
  /// « Saint-Émilion », « Petit Chablis » avant « Chablis »), dans le pays du vin.
  static AppellationConnue? appellation({String? appellation, String? nom, String? region, String? pays}) {
    final cle = '${normaliser(appellation)}|${normaliser(nom)}|${normaliser(region)}|${normaliser(pays)}';
    return _memoise(_memoAppellation, cle, () {
      for (final champ in [appellation, nom, region]) {
        final trouvee = _appellationDans(normaliser(champ), pays);
        if (trouvee != null) return trouvee;
      }
      return null;
    });
  }

  /// Le mot qui range un nom dans l'index : son plus long, le plus rare (« margaux » plutôt
  /// que « château »). Un nom ne se lit dans une fiche que si tous ses mots y sont : il
  /// suffit d'en ranger un.
  static String _motCle(String nom) {
    var meilleur = '';
    for (final m in nom.split(' ')) {
      if (m.length > meilleur.length) meilleur = m;
    }
    return meilleur;
  }

  /// Les noms d'appellation et les noms de vins, rangés par [_motCle] : une fiche ne
  /// regarde que ceux dont le mot-clé est un de ses mots. Parcourir toute la base pour
  /// chaque bouteille coûtait dix millisecondes par vin — trois secondes pour une cave de
  /// trois cents bouteilles sur un téléphone.
  static final Map<String, List<(int, _AppellationIndexee, String)>> _appellationsParMot = () {
    final m = <String, List<(int, _AppellationIndexee, String)>>{};
    for (var i = 0; i < _index.length; i++) {
      for (final n in _index[i].noms) {
        (m[_motCle(n)] ??= []).add((i, _index[i], n));
      }
    }
    return m;
  }();

  static final Map<String, List<(int, _AppellationIndexee, _VinIndexe, String)>> _vinsParMot = () {
    final m = <String, List<(int, _AppellationIndexee, _VinIndexe, String)>>{};
    var rang = 0;
    for (final a in _index) {
      for (final v in a.vins) {
        for (final c in v.cles) {
          (m[_motCle(c)] ??= []).add((rang, a, v, c));
        }
        rang++;
      }
    }
    return m;
  }();

  static AppellationConnue? _appellationDans(String texte, String? pays) {
    if (texte.isEmpty) return null;
    final t = ' $texte ';
    AppellationConnue? meilleure;
    var longueur = 0;
    var rang = 0;
    for (final mot in texte.split(' ').toSet()) {
      for (final (i, a, n) in _appellationsParMot[mot] ?? const <(int, _AppellationIndexee, String)>[]) {
        // À longueur égale, l'ordre de la base : la première déclarée l'emporte.
        final mieux = n.length > longueur || (n.length == longueur && i < rang);
        if (!mieux || !t.contains(' $n ') || !_memePays(a.appellation.pays, pays)) continue;
        meilleure = a.appellation;
        longueur = n.length;
        rang = i;
      }
    }
    return meilleure;
  }

  /// Le vin de la base que décrit cette fiche, ou rien.
  ///
  /// Le nom (ou un alias) doit se lire, mot à mot, dans « domaine + nom + cuvée » ; le
  /// domaine aussi quand la base l'exige. La couleur départage deux vins du même domaine
  /// (le rouge et le rosé de Tempier) et en écarte un d'une autre couleur ; à couleur
  /// égale, le nom le plus long est le plus précis (« Pavillon Rouge du Château Margaux »
  /// avant « Château Margaux »). Une appellation précise sur la fiche, qui n'est pas celle
  /// du vin, l'écarte aussi : « Château Latour-Martillac », Pessac-Léognan, n'est pas
  /// Château Latour.
  static VinTrouve? trouver({
    String? nom,
    String? producteur,
    String? cuvee,
    String? appellation,
    String? region,
    String? pays,
    String? type,
  }) {
    final couleur = couleurDe(type);
    if (couleur == _pasUnVin) return null;
    final texte = normaliser('${producteur ?? ''} ${nom ?? ''} ${cuvee ?? ''}');
    if (texte.isEmpty) return null;
    final cle = '$texte|${normaliser(appellation)}|${normaliser(region)}|${normaliser(pays)}|$couleur';
    return _memoise(_memoVin, cle, () {
      final t = ' $texte ';
      // Le nom du vin l'emporte sur le domaine : « Gran Reserva 904 » de « La Rioja Alta
      // S.A. » est le 904, pas l'assemblage moyen de la maison.
      final duNom = ' ${normaliser('${nom ?? ''} ${cuvee ?? ''}')} ';
      final deLaFiche = VinsConnus.appellation(appellation: appellation, nom: nom, region: region, pays: pays);
      final duChamp = _appellationDans(normaliser(appellation), pays);
      _VinIndexe? meilleur;
      AppellationConnue? sonAppellation;
      var meilleurScore = 0;
      var meilleurRang = 0;
      for (final mot in texte.split(' ').toSet()) {
        for (final (rang, a, v, c) in _vinsParMot[mot] ?? const <(int, _AppellationIndexee, _VinIndexe, String)>[]) {
          if (!t.contains(' $c ')) continue;
          final accord = _accord(v.vin.couleur, couleur);
          if (accord == 0) continue;
          if (v.de != null && v.de!.isNotEmpty && !t.contains(' ${v.de} ')) continue;
          if (!_memePays(a.appellation.pays, pays)) continue;
          // Une appellation précise sur la fiche, qui n'est pas celle-ci : pas ce vin-là.
          final contredite = duChamp != null &&
              !duChamp.generique &&
              !a.appellation.generique &&
              !identical(duChamp, a.appellation);
          if (contredite) continue;
          final score = accord * 1000 + (duNom.contains(' $c ') ? 500 : 0) + c.length + (v.de?.length ?? 0);
          // À score égal, l'ordre de la base : le rouge de Tempier avant son rosé quand la
          // fiche ne dit pas la couleur.
          if (score > meilleurScore || (score == meilleurScore && rang < meilleurRang)) {
            meilleurScore = score;
            meilleurRang = rang;
            meilleur = v;
            sonAppellation = a.appellation;
          }
        }
      }
      if (meilleur == null) return null;
      return VinTrouve(meilleur.vin, sonAppellation!, appellationDeLaFiche: deLaFiche);
    });
  }

  /// Les cépages d'une fiche qui n'en donne pas : ceux du vin s'il est connu, sinon ceux
  /// de son appellation pour sa couleur. Vide quand la base ne sait rien.
  static List<String> cepagesPour({
    String? nom,
    String? producteur,
    String? cuvee,
    String? appellation,
    String? region,
    String? pays,
    String? type,
  }) {
    final vin = trouver(
        nom: nom, producteur: producteur, cuvee: cuvee, appellation: appellation, region: region, pays: pays, type: type);
    if (vin != null) return vin.cepages;
    final couleur = couleurDe(type);
    if (couleur == _pasUnVin) return const [];
    final a = VinsConnus.appellation(appellation: appellation, nom: nom, region: region, pays: pays);
    return a?.cepagesPour(couleur) ?? const [];
  }

  static const _pasUnVin = 'autre';

  /// La couleur de la base pour un type de fiche ; nulle si la fiche n'en dit rien.
  static String? couleurDe(String? type) {
    final t = normaliser(type);
    if (t.isEmpty) return null;
    if (const ['spirit', 'gin', 'whisky', 'whiskey', 'vodka', 'liqueur', 'rhum', 'rum', 'biere', 'beer', 'cidre', 'sake']
        .any(t.contains)) {
      return _pasUnVin;
    }
    if (t.contains('fortif') || t.contains('mute') || t.contains('porto') || t.contains('sherry')) return 'fortified';
    if (t.contains('orange')) return 'orange';
    if (t.contains('champ') || t.contains('sparkl') || t.contains('effervesc') || t.contains('bulle') || t.contains('mousseu')) {
      return 'sparkling';
    }
    if (t.contains('moelleux') || t.contains('liquoreux') || t.contains('sweet') || t.contains('dessert') || t.contains('doux')) {
      return 'sweet';
    }
    if (t.contains('ros')) return 'rose';
    if (t.contains('blanc') || t.contains('white') || t.contains('bianco') || t.contains('blanco')) return 'white';
    if (t.contains('rouge') || t.contains('red') || t.contains('rosso') || t.contains('tinto')) return 'red';
    return null;
  }

  /// 2 : même couleur ; 1 : compatible (un sauternes saisi « blanc », un champagne rosé
  /// saisi « rosé », un porto saisi « rouge ») ; 0 : contraire.
  static int _accord(String duVin, String? deLaFiche) {
    if (deLaFiche == null) return 1;
    if (duVin == deLaFiche) return 2;
    String teinte(String c) => switch (c) {
          'red' => 'r',
          'rose' => 'p',
          'white' || 'orange' => 'w',
          _ => '*',
        };
    final a = teinte(duVin);
    final b = teinte(deLaFiche);
    return a == b || a == '*' || b == '*' ? 1 : 0;
  }
}

class _AppellationIndexee {
  final AppellationConnue appellation;
  final List<String> noms;
  final List<_VinIndexe> vins;

  _AppellationIndexee(this.appellation, {required this.noms, required this.vins});
}

class _VinIndexe {
  final VinConnu vin;
  final List<String> cles;
  final String? de;

  _VinIndexe(this.vin, {required this.cles, required this.de});
}
