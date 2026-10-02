import '../../../shared/utils/langue.dart';
import '../../journal/domain/tasting_questionnaire_result.dart';
import '../../sommelier/domain/guest_matcher_engine.dart';
import 'menu_wine.dart';

/// Un verre du comptoir, et ce que chacun en a pensé.
class VerreDuComptoir {
  final MenuWine vin;

  /// Prénom → note sur 10, donnée d'un geste.
  final Map<String, double> notes;

  const VerreDuComptoir(this.vin, this.notes);

  double? get moyenne => notes.isEmpty ? null : notes.values.reduce((a, b) => a + b) / notes.length;

  /// L'écart entre la meilleure et la moins bonne note.
  double get ecart {
    if (notes.length < 2) return 0;
    final v = notes.values;
    return v.reduce((a, b) => a > b ? a : b) - v.reduce((a, b) => a < b ? a : b);
  }

  /// « 😍 Paul, 😊 Léa » : chacun avec son visage, du plus content au moins content.
  String get visages {
    final parNote = notes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return parNote.map((e) => '${visage(e.value)} ${e.key}').join(', ');
  }

  static String visage(double note) =>
      TastingQuestionnaireResult.emojiLabels[TastingQuestionnaireResult.emojiIndexForRating(note)];
}

/// Le comptoir à plusieurs (V2.3 · J4) : autour d'une ardoise, chacun note chaque verre
/// d'un geste sur son téléphone ; à la fin, qui a aimé quoi.
///
/// Les notes voyagent dans le profil de chaque convive (`GuestProfile.verres`), par la
/// même table que le consensus : aucune donnée nouvelle au serveur.
class BilanDuComptoir {
  final List<VerreDuComptoir> verres;

  const BilanDuComptoir(this.verres);

  /// Les verres de l'ardoise, dans son ordre, avec les notes de ceux qui boivent.
  factory BilanDuComptoir.dresser(List<MenuWine> ardoise, List<GuestProfile> convives) => BilanDuComptoir([
        for (final w in ardoise)
          VerreDuComptoir(w, {
            for (final c in convives)
              if (!c.neBoitPas && c.verres[w.cacheKey] != null) c.name: c.verres[w.cacheKey]!,
          }),
      ]);

  List<VerreDuComptoir> get goutes => [for (final v in verres) if (v.notes.isNotEmpty) v];

  /// Le préféré du comptoir : la meilleure moyenne parmi les verres que deux personnes au
  /// moins ont notés ; à moyenne égale, le plus goûté.
  VerreDuComptoir? get prefere {
    VerreDuComptoir? meilleur;
    for (final v in goutes) {
      if (v.notes.length < 2) continue;
      if (meilleur == null ||
          v.moyenne! > meilleur.moyenne! ||
          (v.moyenne == meilleur.moyenne && v.notes.length > meilleur.notes.length)) {
        meilleur = v;
      }
    }
    return meilleur;
  }

  /// Le verre qui divise : le plus grand écart, s'il sépare franchement deux personnes
  /// (au moins quatre points : un 😍 contre un 😕).
  VerreDuComptoir? get quiDivise {
    VerreDuComptoir? pire;
    for (final v in goutes) {
      if (v.ecart >= 4 && (pire == null || v.ecart > pire.ecart)) pire = v;
    }
    return pire;
  }

  /// Le préféré de chacun : prénom → son verre le mieux noté (à égalité, le premier de
  /// l'ardoise).
  Map<String, VerreDuComptoir> get prefereDeChacun {
    final r = <String, VerreDuComptoir>{};
    for (final v in goutes) {
      for (final e in v.notes.entries) {
        final actuel = r[e.key];
        if (actuel == null || e.value > actuel.notes[e.key]!) r[e.key] = v;
      }
    }
    return r;
  }

  /// Le bilan en phrases, dans la langue de l'écran ; vide tant que personne n'a noté.
  List<String> get phrases {
    final p = prefere;
    final d = quiDivise;
    final chacun = prefereDeChacun;
    return [
      if (p != null)
        tr('Le préféré du comptoir : {vin} ({visages}).', 'The bar\'s favourite: {vin} ({visages}).',
            {'vin': _nom(p.vin), 'visages': p.visages}),
      if (d != null && d != p)
        tr('Celui qui divise : {vin} ({visages}).', 'The one that divides: {vin} ({visages}).',
            {'vin': _nom(d.vin), 'visages': d.visages}),
      if (chacun.length >= 2)
        tr('Le préféré de chacun : {liste}.', 'Everyone\'s favourite: {liste}.',
            {'liste': chacun.entries.map((e) => '${e.key}, ${_nom(e.value.vin)}').join(' · ')}),
    ];
  }

  static String _nom(MenuWine w) => '${w.name}${w.vintage != null ? ' ${w.vintage}' : ''}';
}
