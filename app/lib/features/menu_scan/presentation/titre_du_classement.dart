import 'package:flutter/material.dart';
import '../../../shared/utils/langue.dart';

/// Le titre du classement de la table, et ce qu'il classe.
///
/// « Les 3 meilleures bouteilles du restaurant » promettait la qualité ; le classement
/// mesure l'accord avec les goûts des convives, et le premier de la carte peut très bien
/// déplaire à toute la table.
class TitreDuClassement extends StatelessWidget {
  final bool isFr;

  /// Pour un plat plutôt que pour la table.
  final bool pourUnPlat;

  const TitreDuClassement({super.key, required this.isFr, this.pourUnPlat = false});

  @override
  Widget build(BuildContext context) {
    final titre = pourUnPlat
        ? (trSi(isFr, 'LES BOUTEILLES LES PLUS ADAPTÉES À CE PLAT', 'THE BOTTLES THAT SUIT THIS DISH BEST'))
        : (trSi(isFr, 'LES 3 BOUTEILLES LES PLUS ADAPTÉES À LA TABLE', 'THE 3 BOTTLES THAT SUIT YOUR TABLE BEST'));
    final critere = pourUnPlat
        ? (trSi(isFr, 'Pas forcément les plus prestigieuses : celles qui s\'accordent le mieux avec ce plat.', 'Not necessarily the finest: the ones that pair best with this dish.'))
        : (trSi(isFr, 'Pas forcément les meilleures de la carte : celles qui correspondent le mieux aux goûts de chacun.', 'Not necessarily the finest on the list: the ones that best fit everyone\'s taste.'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.wine_bar_rounded, color: Color(0xFFD4AF37), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                titre,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(critere, style: const TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.3)),
      ],
    );
  }
}


/// « 7 vins analysés pour 2 convives », pluriels accordés (« pour 1 convives » avant).
String vinsPourConvives(int vins, int convives, bool fr) {
  final v = vins > 1
      ? trSi(fr, '{n} vins analysés', '{n} wines analysed', {'n': vins})
      : trSi(fr, '{n} vin analysé', '{n} wine analysed', {'n': vins});
  final c = convives > 1
      ? trSi(fr, '{n} convives', '{n} guests', {'n': convives})
      : trSi(fr, '{n} convive', '{n} guest', {'n': convives});
  return trSi(fr, '{vins} pour {convives}', '{vins} for {convives}', {'vins': v, 'convives': c});
}
