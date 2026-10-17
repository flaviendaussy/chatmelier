import 'package:flutter/material.dart';

import '../../../shared/utils/langue.dart';
import '../../../shared/widgets/wine_type_badge.dart';
import '../domain/filtres_du_journal.dart';
import '../domain/tasting_entry.dart';

/// La feuille des filtres du journal (V2.5 · F6) : pays, couleur, note, appellation, lieu.
///
/// Chaque geste s'applique aussitôt au journal, derrière : ce qu'on voit en refermant est ce
/// qu'on a choisi. Chaque valeur dit combien de dégustations elle compte, compte tenu des
/// autres choix.
class FeuilleDesFiltres extends StatefulWidget {
  /// Les dégustations que la recherche et les pastilles de l'écran laissent passer.
  final List<TastingEntry> entrees;
  final FiltresDuJournal filtres;
  final ValueChanged<FiltresDuJournal> onChanged;

  const FeuilleDesFiltres({super.key, required this.entrees, required this.filtres, required this.onChanged});

  static Future<void> montrer(
    BuildContext context, {
    required List<TastingEntry> entrees,
    required FiltresDuJournal filtres,
    required ValueChanged<FiltresDuJournal> onChanged,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FeuilleDesFiltres(entrees: entrees, filtres: filtres, onChanged: onChanged),
      );

  /// La teinte d'une couleur de vin, celle des pastilles de la cave.
  static Color teinte(String couleur) => WineTypeBadge.getColor(switch (couleur) {
        'mute' => 'fortified',
        'spiritueux' => 'spirit',
        'autre' => '',
        _ => couleur,
      });

  @override
  State<FeuilleDesFiltres> createState() => _FeuilleDesFiltresState();
}

class _FeuilleDesFiltresState extends State<FeuilleDesFiltres> {
  static const _bordeaux = Color(0xFF8B1E3F);

  /// Au-delà, une famille se replie derrière « Voir les N autres ».
  static const _repliAu = 8;

  late FiltresDuJournal _filtres = widget.filtres;
  final Set<FamilleDeFiltre> _depliees = {};

  void _changer(FiltresDuJournal f) {
    setState(() => _filtres = f);
    widget.onChanged(f);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resultat = _filtres.appliquer(widget.entrees).length;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(tr('Filtrer le journal', 'Filter the journal'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: _filtres.actifs ? () => _changer(FiltresDuJournal.vides) : null,
                    child: Text(tr('Tout effacer', 'Clear all')),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _famille(FamilleDeFiltre.pays, tr('Pays', 'Country'), isDark),
                    _famille(FamilleDeFiltre.couleur, tr('Couleur', 'Colour'), isDark),
                    _note(isDark),
                    _famille(FamilleDeFiltre.appellation, tr('Appellation ou région', 'Appellation or region'), isDark),
                    _famille(FamilleDeFiltre.lieu, tr('Lieu', 'Place'), isDark),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _bordeaux,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(switch (resultat) {
                  0 => tr('Aucune dégustation', 'No tasting'),
                  1 => tr('Voir 1 dégustation', 'Show 1 tasting'),
                  _ => tr('Voir les {n} dégustations', 'Show {n} tastings', {'n': resultat}),
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titre(String texte, bool isDark) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
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

  Widget _famille(FamilleDeFiltre f, String titre, bool isDark) {
    final choix = _filtres.choix(widget.entrees, f);
    if (choix.isEmpty) return const SizedBox.shrink();
    final depliee = _depliees.contains(f) || choix.length <= _repliAu + 2;
    final montres = depliee ? choix : choix.take(_repliAu).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titre(titre, isDark),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final c in montres)
              FilterChip(
                key: ValueKey('filtre-${f.name}-${c.cle}'),
                avatar: f == FamilleDeFiltre.couleur
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: FeuilleDesFiltres.teinte(c.cle), shape: BoxShape.circle),
                      )
                    : null,
                label: _libelleEtNombre(c.libelle, c.nombre, isDark),
                selected: _filtres.de(f).contains(c.cle),
                selectedColor: _bordeaux.withValues(alpha: 0.18),
                checkmarkColor: _bordeaux,
                showCheckmark: f != FamilleDeFiltre.couleur,
                onSelected: (_) => _changer(_filtres.basculer(f, c.cle)),
              ),
          ],
        ),
        if (!depliee)
          TextButton(
            onPressed: () => setState(() => _depliees.add(f)),
            child: Text(tr('Voir les {n} autres', 'Show {n} more', {'n': choix.length - montres.length})),
          ),
      ],
    );
  }

  Widget _note(bool isDark) {
    final notees = widget.entrees.any((e) => e.displayRating != null);
    if (!notees) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titre(tr('Note minimale', 'Minimum rating'), isDark),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: Text(tr('Toutes', 'Any')),
              selected: _filtres.noteMin == null,
              selectedColor: _bordeaux.withValues(alpha: 0.18),
              onSelected: (_) => _changer(_filtres.avecNoteMin(null)),
            ),
            for (final s in FiltresDuJournal.seuils)
              ChoiceChip(
                key: ValueKey('filtre-note-${s.toInt()}'),
                avatar: const Icon(Icons.star, size: 14, color: Color(0xFFD4AF37)),
                label: _libelleEtNombre('≥ ${s.toInt()}', _filtres.nombreAuMoins(widget.entrees, s), isDark),
                selected: _filtres.noteMin == s,
                selectedColor: _bordeaux.withValues(alpha: 0.18),
                onSelected: (sel) => _changer(_filtres.avecNoteMin(sel ? s : null)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _libelleEtNombre(String libelle, int nombre, bool isDark) => Text.rich(
        TextSpan(children: [
          TextSpan(text: libelle),
          TextSpan(
            text: '  $nombre',
            style: TextStyle(
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ]),
      );
}
