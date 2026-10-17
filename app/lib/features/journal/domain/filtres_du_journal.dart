import '../../../shared/utils/langue.dart';
import '../../../shared/utils/pays.dart';
import '../../../shared/utils/sans_accents.dart';
import '../../cellar/domain/wine_world/wine_world.dart';
import 'tasting_entry.dart';

enum FamilleDeFiltre { pays, couleur, appellation, lieu }

/// Une valeur que la feuille des filtres propose : sa clé, comment l'écrire, et combien de
/// dégustations elle compte.
class ChoixDeFiltre {
  final String cle;
  final String libelle;
  final int nombre;
  const ChoixDeFiltre(this.cle, this.libelle, this.nombre);
}

/// Les filtres du journal (V2.5 · F6) : pays, couleur, appellation, lieu, note minimale.
///
/// 13/10, Flavien : « ajoute le drapeau du pays pour chaque vin […] et ajoute des filtres
/// (pays, appellation, couleur, etc...) » ; dans le Journal (décision du 16/10). Les valeurs
/// se lisent comme le journal les écrit : « Spain » et « Espagne » sont un même pays,
/// « Ribera Del Duero » et « Ribera del Duero » une même appellation, et une dégustation
/// sans appellation compte par sa région.
class FiltresDuJournal {
  final Map<FamilleDeFiltre, Set<String>> valeurs;
  final double? noteMin;

  const FiltresDuJournal({this.valeurs = const {}, this.noteMin});

  static const vides = FiltresDuJournal();

  /// Les seuils de note proposés, sur 10.
  static const seuils = [6.0, 7.0, 8.0, 9.0];

  Set<String> de(FamilleDeFiltre f) => valeurs[f] ?? const {};

  int get nombreActifs => valeurs.values.fold(0, (n, s) => n + s.length) + (noteMin != null ? 1 : 0);

  bool get actifs => nombreActifs > 0;

  /// Une dégustation passe si elle répond à chaque famille choisie (à l'une de ses valeurs).
  bool garde(TastingEntry e) {
    for (final MapEntry(key: famille, value: choisies) in valeurs.entries) {
      if (choisies.isNotEmpty && !choisies.contains(cleDe(famille, e))) return false;
    }
    if (noteMin != null && (e.displayRating ?? -1) < noteMin!) return false;
    return true;
  }

  List<TastingEntry> appliquer(Iterable<TastingEntry> entrees) => [for (final e in entrees) if (garde(e)) e];

  FiltresDuJournal basculer(FamilleDeFiltre f, String cle) {
    final choisies = {...de(f)};
    if (!choisies.remove(cle)) choisies.add(cle);
    return FiltresDuJournal(valeurs: {...valeurs, f: choisies}, noteMin: noteMin);
  }

  FiltresDuJournal sans(FamilleDeFiltre f) => FiltresDuJournal(valeurs: {...valeurs}..remove(f), noteMin: noteMin);

  FiltresDuJournal avecNoteMin(double? note) => FiltresDuJournal(valeurs: valeurs, noteMin: note);

  /// Ce que la feuille propose pour [f] : les valeurs des dégustations que les autres filtres
  /// laissent passer (choisir l'Espagne ne propose plus que des appellations espagnoles), avec
  /// leur nombre. Une valeur choisie reste proposée, même à zéro, pour qu'on puisse la retirer.
  List<ChoixDeFiltre> choix(Iterable<TastingEntry> entrees, FamilleDeFiltre f) {
    final comptes = <String, int>{};
    for (final e in sans(f).appliquer(entrees)) {
      final c = cleDe(f, e);
      if (c != null) comptes[c] = (comptes[c] ?? 0) + 1;
    }
    for (final c in de(f)) {
      comptes.putIfAbsent(c, () => 0);
    }
    final libelles = libellesDe(entrees, f);
    final liste = [for (final x in comptes.entries) ChoixDeFiltre(x.key, libelles[x.key] ?? x.key, x.value)];
    if (f == FamilleDeFiltre.couleur) {
      liste.sort((a, b) => _ordreDesCouleurs.indexOf(a.cle).compareTo(_ordreDesCouleurs.indexOf(b.cle)));
    } else {
      // À égalité, l'ordre alphabétique du nom, drapeau ôté (sinon l'Afrique du Sud, ZA,
      // passerait après tout le monde).
      String nom(ChoixDeFiltre c) => sansAccents(c.libelle.replaceAll(_drapeau, '').trim());
      liste.sort((a, b) => a.nombre != b.nombre ? b.nombre.compareTo(a.nombre) : nom(a).compareTo(nom(b)));
    }
    return liste;
  }

  /// Combien de dégustations atteignent [seuil], les autres filtres appliqués.
  int nombreAuMoins(Iterable<TastingEntry> entrees, double seuil) =>
      avecNoteMin(null).appliquer(entrees).where((e) => (e.displayRating ?? -1) >= seuil).length;

  /// Les filtres choisis, écrits pour les pastilles qu'on retire d'un geste.
  List<({FamilleDeFiltre? famille, String cle, String libelle})> etiquettes(Iterable<TastingEntry> entrees) {
    final sortie = <({FamilleDeFiltre? famille, String cle, String libelle})>[];
    for (final f in FamilleDeFiltre.values) {
      if (de(f).isEmpty) continue;
      final libelles = libellesDe(entrees, f);
      for (final c in de(f)) {
        sortie.add((famille: f, cle: c, libelle: libelles[c] ?? c));
      }
    }
    if (noteMin case final n?) {
      sortie.add((famille: null, cle: 'note', libelle: libelleDeNote(n)));
    }
    return sortie;
  }

  static String libelleDeNote(double n) => tr('Note ≥ {n}/10', 'Rating ≥ {n}/10', {'n': n % 1 == 0 ? n.toInt() : n});

  /// La clé d'une dégustation dans la famille [f] ; nulle si la dégustation n'en dit rien.
  static String? cleDe(FamilleDeFiltre f, TastingEntry e) => switch (f) {
        FamilleDeFiltre.pays => _clePays(paysDe(e)),
        FamilleDeFiltre.couleur => couleurDe(e.wineType),
        FamilleDeFiltre.appellation => _normale(appellationDe(e)),
        FamilleDeFiltre.lieu => _normale(lieuDe(e)),
      };

  /// Comment écrire la valeur d'une dégustation : le pays dans la langue de l'écran, avec son
  /// drapeau quand on le reconnaît ; l'appellation et le lieu tels qu'écrits.
  static String? libelleDe(FamilleDeFiltre f, TastingEntry e) => switch (f) {
        FamilleDeFiltre.pays => switch (paysDe(e)) {
            null => null,
            final p when Pays.code(p) != null => '${Pays.drapeau(p)} ${Pays.nom(p)}',
            final p => p,
          },
        FamilleDeFiltre.couleur => switch (couleurDe(e.wineType)) { final c? => libelleDeCouleur(c), null => null },
        FamilleDeFiltre.appellation => appellationDe(e),
        FamilleDeFiltre.lieu => lieuDe(e),
      };

  /// Pour chaque clé, l'écriture la plus fréquente dans le journal.
  static Map<String, String> libellesDe(Iterable<TastingEntry> entrees, FamilleDeFiltre f) {
    final ecritures = <String, Map<String, int>>{};
    for (final e in entrees) {
      final c = cleDe(f, e);
      final l = libelleDe(f, e);
      if (c == null || l == null) continue;
      final parEcriture = ecritures.putIfAbsent(c, () => {});
      parEcriture[l] = (parEcriture[l] ?? 0) + 1;
    }
    return {
      for (final x in ecritures.entries)
        x.key: (x.value.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key,
    };
  }

  /// Le pays de la dégustation : celui qu'elle porte, ou celui que son appellation (à
  /// défaut, sa région) désigne sans ambiguïté. Les vins bus dehors n'en portent souvent
  /// aucun : « Morgon », « Bourgogne Côte d'Or » restaient sans drapeau.
  static String? paysDe(TastingEntry e) {
    final ecrit = (e.country ?? '').trim();
    if (ecrit.isNotEmpty) return ecrit;
    return WineWorld.paysDe(appellation: e.appellation, region: e.region);
  }

  static String? _clePays(String? brut) {
    final t = (brut ?? '').trim();
    if (t.isEmpty) return null;
    return Pays.code(t) ?? _normale(t);
  }

  static String? _normale(String? brut) {
    final t = sansAccents((brut ?? '').trim()).replaceAll(RegExp(r'\s+'), ' ');
    return t.isEmpty ? null : t;
  }

  static final _drapeau = RegExp(r'[\u{1F1E6}-\u{1F1FF}]', unicode: true);

  static const _ordreDesCouleurs = [
    'rouge', 'blanc', 'rose', 'bulles', 'moelleux', 'mute', 'orange', 'spiritueux', 'autre',
  ];

  static const _spiritueux = {
    'spirit', 'spiritueux', 'whisky', 'whiskey', 'bourbon', 'scotch', 'rum', 'rhum', 'gin', 'vodka',
    'tequila', 'mezcal', 'cognac', 'armagnac', 'calvados', 'pisco', 'grappa', 'eau-de-vie', 'eau de vie',
    'aguardente', 'pastis', 'absinthe', 'liqueur', 'rosolio', 'aperitif', 'bitter',
  };

  /// La couleur, telle qu'on la filtre : rouge, blanc, rose, bulles, moelleux, mute (vins
  /// mutés : porto, xérès, banyuls), orange, spiritueux, autre. Le journal écrit le type en
  /// anglais (« red »), en français (« Rouge ») ou dans la langue de l'étiquette (« tinto »).
  static String? couleurDe(String? type) {
    final t = sansAccents((type ?? '').trim());
    if (t.isEmpty) return null;
    if (_spiritueux.contains(t)) return 'spiritueux';
    if (RegExp(r'spark|bulle|champ|effervesc|cremant|cava|prosecco|petillant|espumos|spumante|frizzante|sekt')
        .hasMatch(t)) {
      return 'bulles';
    }
    if (RegExp(r'rose|rosado|rosato').hasMatch(t)) return 'rose';
    if (RegExp(r'dessert|moelleux|liquoreux|sweet|dulce|dolce|passito|vendanges tardives').hasMatch(t)) {
      return 'moelleux';
    }
    if (RegExp(r'fortif|mute|porto|\bport\b|xeres|sherry|jerez|madere|madeira|marsala|banyuls|generoso|vin doux naturel')
        .hasMatch(t)) {
      return 'mute';
    }
    if (t.contains('orange')) return 'orange';
    if (RegExp(r'white|blanc|blanco|bianco|branco').hasMatch(t)) return 'blanc';
    if (RegExp(r'red|rouge|tinto|rosso').hasMatch(t)) return 'rouge';
    return 'autre';
  }

  static String libelleDeCouleur(String couleur) => switch (couleur) {
        'rouge' => tr('Rouge', 'Red'),
        'blanc' => tr('Blanc', 'White'),
        'rose' => tr('Rosé', 'Rosé'),
        'bulles' => tr('Bulles', 'Sparkling'),
        'moelleux' => tr('Moelleux', 'Sweet'),
        'mute' => tr('Muté', 'Fortified'),
        'orange' => tr('Orange', 'Orange'),
        'spiritueux' => tr('Spiritueux', 'Spirits'),
        _ => tr('Autre', 'Other'),
      };

  /// L'appellation, ou la région à défaut, telle qu'écrite.
  static String? appellationDe(TastingEntry e) {
    final a = (e.appellation ?? '').trim();
    if (a.isNotEmpty) return a;
    final r = (e.region ?? '').trim();
    return r.isEmpty ? null : r;
  }

  static String? lieuDe(TastingEntry e) {
    final l = (e.locationName ?? '').trim();
    return l.isEmpty ? null : l;
  }
}
