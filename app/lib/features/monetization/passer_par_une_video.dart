import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/utils/app_logger.dart';
import '../../shared/utils/langue.dart';
import 'admob_config.dart';
import 'admob_service.dart';
import 'domain/credits_ia.dart';
import 'domain/reglages_de_la_pub.dart';
import 'proposer_une_video.dart';

/// Le passage d'un geste d'IA (modèle économique, 21/10) : dans ce qui est offert chaque
/// jour, il passe ; au-delà, une courte vidéo choisie l'ouvre.
///
/// Jamais au détriment de la personne : sans pub possible (web, premium, vidéos coupées
/// depuis la console) ou sans vidéo prête (réseau du restaurant, pas d'annonce), le geste
/// passe — le quota du serveur reste le garde-fou. Une vidéo refusée ou coupée avant la fin :
/// le geste ne part pas, et rien n'est payé.
class PasserParUneVideo {
  static const _emplacements = {
    GesteIa.chat: 'chat',
    GesteIa.questionCarte: 'question_carte',
    GesteIa.cote: 'cote',
  };

  static Future<bool> autoriser(
    BuildContext context, {
    required GesteIa geste,
    required bool premium,
    String? uid,
    DateTime? maintenant,
  }) async {
    final reglages = ReglagesDeLaPub.actuels;
    if (!reglages.videos || premium || !AdMobConfig.isPlatformSupported) return true;
    final t = maintenant ?? DateTime.now();
    final credits = await CreditsIa.lire(uid, maintenant: t);
    if (credits.autorise(geste, reglages, t)) return true;

    final pub = AdMobService();
    final emplacement = _emplacements[geste]!;
    if (!pub.isReady) {
      pub.assurerUnePubPrete();
      AppLogger.info('ADMOB', 'Vidéo indisponible : $emplacement');
      return true;
    }
    if (!context.mounted) return false;
    final (titre, explication) = _textes(geste, reglages);
    final regarder = await ProposerUneVideo.demander(context, titre: titre, explication: explication);
    if (!regarder) return false;

    final issue = Completer<bool>();
    final montree = await pub.showRewardedAd(
      emplacement: emplacement,
      onRewardEarned: () {
        if (!issue.isCompleted) issue.complete(true);
      },
      onAdDismissed: () {
        if (!issue.isCompleted) issue.complete(false);
      },
      // Une vidéo qui ne s'affiche pas n'est pas la faute de la personne.
      onAdFailedToShow: () {
        if (!issue.isCompleted) issue.complete(true);
      },
    );
    if (!montree) return true;
    final recompense = await issue.future;
    if (recompense) {
      final apres = await CreditsIa.lire(uid);
      apres.crediter(geste, reglages, DateTime.now());
      await apres.ecrire(uid);
    }
    return recompense;
  }

  static (String, String) _textes(GesteIa geste, ReglagesDeLaPub r) => switch (geste) {
        GesteIa.chat => (
            tr('Encore des questions ?', 'More questions?'),
            tr('Vos {n} questions offertes du jour sont posées. Une courte vidéo en ouvre {m} de plus.',
                'You\'ve used today\'s {n} free questions. A short video opens {m} more.',
                {'n': r.chatOfferts, 'm': r.chatParVideo}),
          ),
        GesteIa.questionCarte => (
            tr('Une vidéo pour la soirée', 'One video for the evening'),
            tr('Une courte vidéo, et vos questions sur la carte sont libres pendant {h} heures.',
                'One short video, and your questions about the list are free for {h} hours.',
                {'h': r.soireeHeures}),
          ),
        GesteIa.cote => (
            tr('Chercher la cote', 'Look up the market price'),
            tr('Chaque cote est une recherche sur le web. Vos {n} recherches offertes du jour sont faites : une courte vidéo paie la suivante.',
                'Each market price is a web search. Today\'s {n} free searches are used: a short video pays for the next one.',
                {'n': r.coteOffertes}),
          ),
      };
}
