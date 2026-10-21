import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/providers/premium_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../admob_config.dart';
import '../domain/reglages_de_la_pub.dart';
import '../mesure_des_pubs.dart';

/// Une carte « Annonce » dans une liste qu'on parcourt (modèle économique, 87).
///
/// Le seul format passif retenu par l'étude du 21/10 : aux taux prudents, la vidéo seule
/// ne couvre pas l'IA. Règles : dans les listes qu'on parcourt (le Journal), jamais à table,
/// jamais dans un classement de vins ni une recommandation ; marquée « Annonce » ; rien du
/// tout tant que le bloc natif AdMob n'est pas réglé dans la console, sur le web, en premium,
/// ou si la pub ne se charge pas — la liste reste alors telle quelle.
class AnnonceNative extends ConsumerStatefulWidget {
  /// Où la carte apparaît, pour la mesure (`journal`…).
  final String emplacement;

  const AnnonceNative({super.key, required this.emplacement});

  /// Faut-il glisser une carte après l'entrée [index] (0 = la première) d'une liste ?
  static bool apres(int index) {
    final n = ReglagesDeLaPub.actuels.annonceTousLes;
    return n > 0 && ReglagesDeLaPub.actuels.uniteNative != null && AdMobConfig.isPlatformSupported && (index + 1) % n == 0;
  }

  @override
  ConsumerState<AnnonceNative> createState() => _AnnonceNativeState();
}

class _AnnonceNativeState extends ConsumerState<AnnonceNative> {
  NativeAd? _annonce;
  bool _chargee = false;
  final _idImpression = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    final unite = ReglagesDeLaPub.actuels.uniteNative;
    if (unite == null || !AdMobConfig.isPlatformSupported || ref.read(premiumProvider)) return;
    _annonce = NativeAd(
      adUnitId: unite,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        cornerRadius: 12,
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _chargee = true);
        },
        onAdFailedToLoad: (ad, erreur) {
          AppLogger.debug('ADMOB', 'Annonce native non chargée (${widget.emplacement}) : ${erreur.code}');
          ad.dispose();
          _annonce = null;
        },
        onAdImpression: (_) =>
            MesureDesPubs.impression(format: 'native', emplacement: widget.emplacement, id: _idImpression),
        onPaidEvent: (ad, valeurMicros, precision, devise) => MesureDesPubs.revenu(
          impressionId: _idImpression,
          format: 'native',
          emplacement: widget.emplacement,
          valeurMicros: valeurMicros,
          precision: switch (precision) {
            PrecisionType.precise => 'precise',
            PrecisionType.estimated => 'estimated',
            PrecisionType.publisherProvided => 'publisher_provided',
            _ => 'unknown',
          },
          devise: devise,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _annonce?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final annonce = _annonce;
    if (annonce == null || !_chargee) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      // Les marges de côté sont celles de la liste qui l'accueille.
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              tr('Annonce · elle paie l\'IA de Chatmelier', 'Ad · it pays for Chatmelier\'s AI'),
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          // Le gabarit « small » d'AdMob tient dans une hauteur fixe d'environ 120.
          SizedBox(height: 120, child: AdWidget(ad: annonce)),
        ],
      ),
    );
  }
}
