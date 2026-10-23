import 'package:flutter/material.dart';

import '../../../../shared/utils/langue.dart';
import '../../../auth/domain/palais.dart';
import '../../../auth/domain/taste_evidence.dart';

/// « Ce que ce verre a appris à votre palais » : les axes qui ont bougé, de leur valeur
/// d'avant à celle d'après, animés (Flavien, 22/10 : « à chaque vin goûté, on devrait avoir
/// une animation qui nous montre quelle zone a été apprise »).
///
/// Lu dans le registre du palais (`TasteEvidenceLedger`) : ce sont les mêmes traces que
/// « Ce que j'ai appris », pas une seconde comptabilité.
class CeQueCeVerreAAppris extends StatelessWidget {
  /// Les traces d'axes laissées par cette dégustation, pour une personne.
  final List<TasteEvidenceEntry> traces;

  const CeQueCeVerreAAppris({super.key, required this.traces});

  static const _bordeaux = Color(0xFF8B1E3F);
  static const _or = Color(0xFFB8941F);

  /// `axe:<famille>:<axe>` → (famille, axe).
  static (String, String)? _lire(String cible) {
    final p = cible.split(':');
    return p.length == 3 && p[0] == 'axe' ? (p[1], p[2]) : null;
  }

  @override
  Widget build(BuildContext context) {
    final lignes = [
      for (final t in traces)
        if ((_lire(t.cible), t.apres) case ((final famille, final axe)?, final apres?)) (famille, axe, t.avant, apres),
    ];
    if (lignes.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bordeaux.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bordeaux.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Ce que ce verre a appris à votre palais', 'What this glass taught your palate'),
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          for (final (i, (famille, axe, avant, apres)) in lignes.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            _Ligne(famille: famille, axe: axe, avant: avant, apres: apres, delai: i),
          ],
        ],
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final String famille;
  final String axe;
  final double? avant;
  final double apres;

  /// Le rang de la ligne : chacune démarre un peu après la précédente.
  final int delai;

  const _Ligne({required this.famille, required this.axe, required this.avant, required this.apres, required this.delai});

  @override
  Widget build(BuildContext context) {
    final depart = avant ?? apres;
    final ecart = apres - depart;
    final (bas, haut) = AxesDuPalais.bouts(axe);
    final sens = avant == null
        ? tr('appris', 'learned')
        : ecart.abs() < 0.005
            ? tr('confirmé', 'confirmed')
            : ecart > 0
                ? tr('vers « {haut} »', 'towards "{haut}"', {'haut': haut.toLowerCase()})
                : tr('vers « {bas} »', 'towards "{bas}"', {'bas': bas.toLowerCase()});
    final total = 900 + delai * 250;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${AxesDuPalais.nom(axe)} · ${FamillesDeVins.nomCourt(famille).toLowerCase()}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              avant == null
                  ? '${(apres * 10).toStringAsFixed(1)}/10 · $sens'
                  : '${(depart * 10).toStringAsFixed(1)} → ${(apres * 10).toStringAsFixed(1)} · $sens',
              style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: depart, end: apres),
          duration: Duration(milliseconds: total),
          curve: Interval(delai * 250 / total, 1, curve: Curves.easeOutCubic),
          builder: (context, v, _) => _Barre(valeur: v, repere: avant),
        ),
      ],
    );
  }
}

/// Une barre de 0 à 10, la valeur qui avance, l'ancienne marquée d'un trait.
class _Barre extends StatelessWidget {
  final double valeur;
  final double? repere;

  const _Barre({required this.valeur, this.repere});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Container(
              width: c.maxWidth * valeur.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: CeQueCeVerreAAppris._bordeaux,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            if (repere != null)
              Positioned(
                left: (c.maxWidth * repere!.clamp(0.0, 1.0) - 1).clamp(0.0, c.maxWidth - 2),
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: CeQueCeVerreAAppris._or),
              ),
          ],
        ),
      ),
    );
  }
}
