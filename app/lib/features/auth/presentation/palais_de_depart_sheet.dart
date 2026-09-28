import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/utils/app_logger.dart';
import '../../menu_scan/presentation/palais_express.dart';
import '../data/taste_profile_service.dart';

/// Le palais de départ, proposé une fois à la première ouverture (retour du 28/09).
///
/// Les mêmes six curseurs qu'à table. Ce que la personne déclare devient un A PRIORI :
/// aucune observation n'est comptée, la confiance affichée reste nulle, et la première
/// vraie dégustation pèse davantage que la déclaration (voir
/// `WineTasteRadarCalculator.compute`). Refusable : « Plus tard ».
class PalaisDeDepartSheet extends ConsumerWidget {
  const PalaisDeDepartSheet({super.key});

  static const cleDejaPropose = 'chatmelier_palais_de_depart_propose';

  /// Propose la feuille si le palais est encore vierge et qu'elle n'a jamais été proposée.
  static Future<void> proposerSiBesoin(BuildContext context, WidgetRef ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(cleDejaPropose) ?? false) return;
      final palais = await ref.read(tasteProfileServiceProvider).getPrimaryProfile();
      // Proposée une fois, quoi qu'on réponde — et jamais à un palais qui a déjà vécu.
      await prefs.setBool(cleDejaPropose, true);
      if (palais.questionnairesCompleted > 0 || palais.palaisDeDepart.isNotEmpty || palais.isWellProvided) return;
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PalaisDeDepartSheet(),
      );
    } catch (e) {
      AppLogger.warning('PROFILE', 'Palais de départ non proposé: $e');
    }
  }

  static const _aversionsDuProfil = {'tanin': 'Trop tannique', 'boisé': 'Trop boisé', 'acide': 'Trop acide'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = Localizations.localeOf(context).languageCode == 'fr';
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1728),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fr ? 'Dessinez votre palais de départ' : 'Sketch your starting palate',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              fr
                  ? 'Trente secondes, facultatif. Chatmelier s\'en sert comme point de départ, sans y croire '
                      'aveuglément : vos vraies dégustations le corrigeront très vite.'
                  : 'Thirty seconds, optional. Chatmelier uses it as a starting point, not as gospel: your real '
                      'tastings will correct it quickly.',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            PalaisExpress(
              isFr: fr,
              libelleValider: fr ? 'Enregistrer mon palais de départ' : 'Save my starting palate',
              libelleRefus: fr ? 'Plus tard' : 'Later',
              onJusteMonPrenom: () => Navigator.of(context).pop(),
              onValider: (p) async {
                await ref.read(tasteProfileServiceProvider).enregistrerPalaisDeDepart(
                  axes: {
                    'tannin': p.tanins,
                    'body': p.corps,
                    'acidity': p.acidite,
                    'oak': p.boise,
                    'ripeFruit': p.fruit,
                    'freshFruit': p.fruit,
                    'minerality': p.mineralite,
                  },
                  couleurs: p.couleurs.toList(),
                  aversions: [for (final a in p.aversions) _aversionsDuProfil[a] ?? a],
                );
                AppLogger.info('USAGE', 'palais_de_depart');
                ref.invalidate(tasteProfilesListProvider);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
