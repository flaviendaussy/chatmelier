import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/utils/langue.dart';
import '../../../auth/domain/palais.dart';
import '../../domain/question_pour_vous.dart';

/// Le « pour vous » d'une dégustation (V2.6 · P6) : trop, juste ou pas assez, sur les trois
/// axes les plus utiles (`QuestionPourVous.ordre`). Les autres se précisent si l'on veut.
class PourVous extends StatefulWidget {
  final String famille;

  /// Les axes, du plus utile au moins utile (`QuestionPourVous.ordre`).
  final List<String> ordre;

  /// Axe → `trop`, `juste` ou `pas_assez`.
  final Map<String, String> jugements;
  final void Function(String axe, String sens) onJuger;

  const PourVous({
    super.key,
    required this.famille,
    required this.ordre,
    required this.jugements,
    required this.onJuger,
  });

  @override
  State<PourVous> createState() => _PourVousState();
}

class _PourVousState extends State<PourVous> {
  List<String> get _dEmblee => widget.ordre.take(QuestionPourVous.dEmblee).toList();
  List<String> get _autres => widget.ordre.skip(QuestionPourVous.dEmblee).toList();

  // Ouvert d'emblée quand un axe de plus a déjà une réponse (une dictée).
  late bool _plusLoin = widget.jugements.keys.any(_autres.contains);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, axe) in _dEmblee.indexed) ...[
          if (i > 0) const SizedBox(height: 14),
          _Question(axe: axe, jugement: widget.jugements[axe], onJuger: widget.onJuger, principale: true),
        ],
        if (_autres.isNotEmpty && !_plusLoin)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
              onPressed: () => setState(() => _plusLoin = true),
              icon: const Icon(Icons.tune, size: 16),
              label: Text(tr('Aller plus loin', 'Go further'), style: const TextStyle(fontSize: 12.5)),
            ),
          )
        else
          for (final axe in _autres) ...[
            const SizedBox(height: 14),
            _Question(axe: axe, jugement: widget.jugements[axe], onJuger: widget.onJuger, principale: true),
          ],
      ],
    );
  }
}

class _Question extends StatelessWidget {
  final String axe;
  final String? jugement;
  final void Function(String axe, String sens) onJuger;
  final bool principale;

  const _Question({required this.axe, required this.jugement, required this.onJuger, this.principale = false});

  static const _bordeaux = Color(0xFF8B1E3F);

  @override
  Widget build(BuildContext context) {
    final (pasAssez, juste, trop) = AxesDuPalais.jugements(axe);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AxesDuPalais.question(axe),
          style: principale
              ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
              : const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final (sens, libelle) in [('pas_assez', pasAssez), ('juste', juste), ('trop', trop)])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _Choix(
                    libelle: libelle,
                    choisi: jugement == sens,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onJuger(axe, sens);
                    },
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Choix extends StatelessWidget {
  final String libelle;
  final bool choisi;
  final VoidCallback onTap;

  const _Choix({required this.libelle, required this.choisi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const bordeaux = _Question._bordeaux;
    return Semantics(
      button: true,
      selected: choisi,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: choisi ? bordeaux : bordeaux.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: choisi ? bordeaux : bordeaux.withValues(alpha: 0.25)),
          ),
          child: Text(
            libelle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: choisi ? FontWeight.bold : FontWeight.w500,
              color: choisi ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }
}
