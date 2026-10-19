import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/langue.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../auth/domain/palais.dart';
import '../../auth/domain/taste_profile.dart';
import '../../auth/presentation/taste_profiles_dialog.dart';
import '../../auth/presentation/widgets/wine_taste_radar_chart.dart';
import '../../journal/domain/filtres_du_journal.dart';
import '../../sommelier/domain/guest_matcher_engine.dart';
import '../../sommelier/domain/profil_du_vin.dart';
import '../domain/explication_du_score.dart';
import '../domain/menu_wine.dart';

/// La fiche d'un vin de la carte (V2.5 · F1) : pourquoi il vous va ou non, son profil face
/// au vôtre, ses détails.
///
/// 13/10, Flavien : « je devrais pouvoir cliquer sur chaque vin pour savoir pourquoi un vin
/// est taillé pour moi ou pas, voir son spider vs le mien, voir ses détails, etc ». Le
/// pourcentage s'explique par son propre calcul (`ExplicationDuScore`), avec le palais
/// d'aujourd'hui.
class FicheDuVinDeLaCarte extends ConsumerStatefulWidget {
  final MenuWine vin;

  /// Le vin est-il retenu pour le comparatif de la carte ?
  final bool selectionne;
  final ValueChanged<bool>? onComparer;

  const FicheDuVinDeLaCarte({super.key, required this.vin, this.selectionne = false, this.onComparer});

  static Future<void> montrer(
    BuildContext context, {
    required MenuWine vin,
    bool selectionne = false,
    ValueChanged<bool>? onComparer,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FicheDuVinDeLaCarte(vin: vin, selectionne: selectionne, onComparer: onComparer),
      );

  @override
  ConsumerState<FicheDuVinDeLaCarte> createState() => _FicheDuVinDeLaCarteState();
}

class _FicheDuVinDeLaCarteState extends ConsumerState<FicheDuVinDeLaCarte> {
  static const _bordeaux = Color(0xFF8B1E3F);
  static const _or = Color(0xFFD4AF37);

  late bool _selectionne = widget.selectionne;

  MenuWine get _vin => widget.vin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profils = ref.watch(tasteProfilesListProvider);
    final palais = switch (profils) {
      AsyncData(:final value) when value.isNotEmpty =>
        value.firstWhere((p) => p.isPrimary, orElse: () => value.first),
      _ => null,
    };

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1724) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _entete(theme, isDark),
                    const SizedBox(height: 18),
                    _pourVous(theme, isDark, palais, enCours: profils.isLoading),
                    const SizedBox(height: 20),
                    _profil(theme, isDark, palais),
                    const SizedBox(height: 20),
                    _details(theme, isDark),
                  ],
                ),
              ),
            ),
            if (widget.onComparer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _bordeaux,
                    side: const BorderSide(color: _bordeaux),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  icon: Icon(_selectionne ? Icons.check_box : Icons.check_box_outline_blank, size: 20),
                  label: Text(_selectionne
                      ? tr('Retenu pour le comparatif', 'Kept for comparison')
                      : tr('Ajouter au comparatif', 'Add to comparison')),
                  onPressed: () {
                    setState(() => _selectionne = !_selectionne);
                    widget.onComparer!(_selectionne);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _titre(String texte, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          texte.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      );

  Widget _entete(ThemeData theme, bool isDark) {
    final v = _vin;
    final domaine = v.producer.trim();
    final origine = [
      if (v.countryWithFlag.isNotEmpty) v.countryWithFlag,
      if ((v.appellation ?? '').trim().isNotEmpty) v.appellation!.trim()
      else if ((v.region ?? '').trim().isNotEmpty) v.region!.trim(),
    ].join(' • ');
    final prix = [
      if ((v.bottlePrice ?? 0) > 0) '${v.formaterPrix(v.bottlePrice!)} / ${v.uniteDuPrix()}',
      for (final g in v.glassPrices) '${v.formaterPrix(g.price)} (${g.format})',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 8),
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(color: v.colorIndicator, shape: BoxShape.circle),
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: v.name),
                  if (v.vintage != null)
                    TextSpan(
                      text: ' ${v.vintage}',
                      style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                ]),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
              ),
            ),
          ],
        ),
        if (domaine.isNotEmpty && !v.name.toLowerCase().contains(domaine.toLowerCase()))
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 19),
            child: Text(domaine,
                style: TextStyle(
                    color: isDark ? const Color(0xFFE8A0B4) : _bordeaux, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        if (origine.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 19),
            child: Text(origine,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54)),
          ),
        if (prix.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 19),
            child: Text(prix.join('   ·   '),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _bordeaux)),
          ),
        if (v.flag case final drapeau?)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 19),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: drapeau.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: drapeau.color.withValues(alpha: 0.35)),
              ),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '${drapeau.iconEmoji} '),
                  TextSpan(
                      text: drapeau.libelle(Langue.estFr),
                      style: TextStyle(fontWeight: FontWeight.bold, color: drapeau.color)),
                  if (drapeau.raisonAffichee(Langue.estFr) case final raison?)
                    TextSpan(text: ' — $raison', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                ]),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ),
      ],
    );
  }

  /// Pourquoi il vous va, ou non : le calcul du pourcentage, raison par raison.
  Widget _pourVous(ThemeData theme, bool isDark, TasteProfile? palais, {required bool enCours}) {
    final e = ExplicationDuScore.expliquer(_vin, palais);
    final gris = isDark ? Colors.white60 : Colors.black54;
    if (e == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titre(tr('Pour vous', 'For you'), isDark),
          if (enCours)
            const LinearProgressIndicator(minHeight: 2)
          else ...[
            Text(
              tr('Je ne connais pas encore assez vos goûts pour dire si ce vin vous ira.',
                  'I don\'t know your taste well enough yet to tell whether this wine suits you.'),
              style: const TextStyle(fontSize: 13.5, height: 1.35),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: _bordeaux, padding: EdgeInsets.zero),
              onPressed: () => TasteProfilesDialog.show(context),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text(tr('Compléter mon palais', 'Complete my palate')),
            ),
          ],
        ],
      );
    }
    // Le palais de la famille du vin (V2.6) : connaître ses rouges ne dit rien de ses blancs.
    final famille = TasteProfile.familleDe(_vin.wineType);
    final confiance = palais == null
        ? 1.0
        : (famille == null ? palais.overallConfidence : palais.palaisPour(famille).connaissance);
    final devine = confiance < GuestProfile.seuilAxeObserve;
    final avant = _vin.userMatchScore;
    final vert = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final rouge = isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titre(tr('Pour vous', 'For you'), isDark),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${devine ? '≈' : ''}${e.score.round()} %',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _bordeaux,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(ExplicationDuScore.verdict(e.score),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        if (devine)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tr('Votre palais est encore deviné (connu à {pct} %) : ce pourcentage se précisera à chaque vin noté.',
                  'Your palate is still a guess ({pct}% known): this percentage will sharpen with every wine you rate.',
                  {'pct': (confiance * 100).round()}),
              style: TextStyle(fontSize: 12, color: gris, height: 1.3),
            ),
          ),
        const SizedBox(height: 10),
        for (final r in e.raisons)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  r.points >= 2
                      ? Icons.arrow_upward_rounded
                      : (r.points <= -2 ? Icons.arrow_downward_rounded : Icons.remove_rounded),
                  size: 17,
                  color: r.points >= 2 ? vert : (r.points <= -2 ? rouge : gris),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(r.phrase, style: const TextStyle(fontSize: 13.5, height: 1.3))),
                const SizedBox(width: 8),
                Text(
                  '${r.points > 0 ? '+' : '−'}${_points(r.points.abs())}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: gris,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            [
              tr('Chaque vin part de 70 % ; ces raisons l\'en rapprochent ou l\'en éloignent.',
                  'Every wine starts at 70%; these reasons move it up or down.'),
              if (e.borne && e.brut > ExplicationDuScore.plafond)
                tr('La somme dépasse 99 % : le pourcentage s\'arrête là.', 'The total goes past 99%: the percentage stops there.'),
              if (e.borne && e.brut < ExplicationDuScore.plancher)
                tr('La somme descend sous 35 % : le pourcentage s\'arrête là.',
                    'The total drops below 35%: the percentage stops there.'),
              if (avant != null && (avant - e.score).abs() >= 1)
                tr('Au moment du scan, il était à {avant} % : votre palais a changé depuis.',
                    'When the list was scanned, it was at {avant}%: your palate has changed since.',
                    {'avant': avant.round()}),
            ].join(' '),
            style: TextStyle(fontSize: 11.5, color: gris, height: 1.35),
          ),
        ),
      ],
    );
  }

  static String _points(double p) => p % 1 == 0 ? '${p.toInt()}' : p.toStringAsFixed(1).replaceAll('.', Langue.estFr ? ',' : '.');

  /// Son profil face au vôtre, sur les axes du palais de sa famille (V2.6) : ceux que l'on
  /// connaît du vin. Un muté, un spiritueux n'ont pas de palais en face : leur seul profil.
  Widget _profil(ThemeData theme, bool isDark, TasteProfile? palais) {
    final gris = isDark ? Colors.white60 : Colors.black54;
    final profil = ProfilDuVin.deLaCarte(_vin);
    final famille = profil.famille;
    final axes = famille == null
        ? const <String>[]
        : [for (final a in AxesDuPalais.duRadar(famille)) if (profil.valeur(a) != null) a];
    final face = famille != null && axes.length >= 3;
    final vous = face && palais != null ? palais.palaisPour(famille) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titre(vous != null ? tr('Son profil face au vôtre', 'Its profile against yours') : tr('Son profil', 'Its profile'),
            isDark),
        Center(
          child: SizedBox(
            height: 270,
            child: WineTasteRadarChart(
              size: 260,
              customAxisLabels: face ? [for (final a in axes) AxesDuPalais.nom(a)] : null,
              datasets: [
                if (face)
                  RadarChartDataset(
                      label: tr('Ce vin', 'This wine'), customValues: [for (final a in axes) profil.sur10(a)!], color: _bordeaux)
                else
                  _vin.toRadarDataset(color: _bordeaux),
                if (vous != null)
                  RadarChartDataset(
                    label: tr('Vous', 'You'),
                    customValues: [for (final a in axes) vous.valeur(a)],
                    color: _or,
                    confidences: [for (final a in axes) vous.confianceDe(a)],
                  ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pastille(_bordeaux, tr('Ce vin', 'This wine')),
            if (vous != null) ...[const SizedBox(width: 18), _pastille(_or, tr('Vous', 'You'))],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          vous != null
              ? tr('Le profil du vin est une estimation, d\'après ce qu\'on sait de lui ; le vôtre vient de vos dégustations, en pointillés là où je devine encore.',
                  'The wine\'s profile is an estimate from what is known about it; yours comes from your tastings, dotted where I\'m still guessing.')
              : tr('Une estimation, d\'après ce qu\'on sait de ce vin.', 'An estimate, from what is known about this wine.'),
          style: TextStyle(fontSize: 11.5, color: gris, height: 1.35),
        ),
      ],
    );
  }

  Widget _pastille(Color couleur, String libelle) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(libelle, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _details(ThemeData theme, bool isDark) {
    final v = _vin;
    final couleur = FiltresDuJournal.couleurDe(v.wineType);
    final lignes = <(String, String)>[
      if (couleur != null) (tr('Couleur', 'Colour'), FiltresDuJournal.libelleDeCouleur(couleur)),
      if (v.grapes.isNotEmpty) (tr('Cépages', 'Grapes'), v.grapes.join(', ')),
      if ((v.appellation ?? '').trim().isNotEmpty) (tr('Appellation', 'Appellation'), v.appellation!.trim()),
      if ((v.region ?? '').trim().isNotEmpty) (tr('Région', 'Region'), v.region!.trim()),
      if (v.countryWithFlag.isNotEmpty) (tr('Pays', 'Country'), v.countryWithFlag),
      if (v.foodPairings.isNotEmpty) (tr('Accords', 'Pairings'), v.foodPairings.join(', ')),
    ];
    final gris = isDark ? Colors.white60 : Colors.black54;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titre(tr('Détails', 'Details'), isDark),
        for (final (libelle, valeur) in lignes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 104, child: Text(libelle, style: TextStyle(color: gris, fontSize: 13))),
                Expanded(child: Text(valeur, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
              ],
            ),
          ),
        if (v.pontDeCave case final lien?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${lien.emoji} ${lien.libelle}${lien.detail != null ? ' — ${lien.detail}' : ''}',
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        if ((v.sommelierComment ?? '').trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '« ${v.sommelierComment!.trim()} »',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: gris, height: 1.35),
            ),
          ),
      ],
    );
  }
}
