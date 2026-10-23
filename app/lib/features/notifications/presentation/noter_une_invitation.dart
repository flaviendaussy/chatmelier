import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/user_notification.dart';
import '../../journal/data/degustation_rapide.dart';
import '../../journal/data/format_du_questionnaire.dart';
import '../../journal/presentation/journal_screen.dart' show tastingLogProvider;
import '../../journal/presentation/tasting_questionnaire_sheet.dart';
import '../../sommelier/data/cepages_du_vin.dart';
import '../data/invitations_notees.dart';
import 'notification_pre_permission_dialog.dart';

/// Ce que sont devenues les invitations à noter reçues ici : la boîte et « Ce soir » s'en
/// servent pour dire « Noté · 8/10 » au lieu de « Noter ce vin ».
final invitationsNoteesProvider = FutureProvider<Map<String, InvitationNotee>>((ref) => InvitationsNotees.lire());

/// Noter le vin d'une invitation (V2.4 · R4, revu le 22/10) : les questions, directement.
///
/// Avant, « Noter ce vin » ouvrait le formulaire « Noter un vin bu dehors » prérempli :
/// lieu, convives, photo, recherche IA, douze champs à revoir — et le choix de l'inviter
/// en retour. Flavien : « comme Caro l'a déjà scanné, je ne devrais rien pouvoir modifier ».
/// La dégustation est écrite une fois (le vin de l'invitation, l'ami parmi les convives, le
/// lieu), puis le questionnaire la complète.
Future<void> noterUneInvitation(BuildContext context, UserNotification notif) async {
  final conteneur = ProviderScope.containerOf(context, listen: false);
  final vin = notif.data['vin'];
  if (vin is! Map) return;
  final ami = notif.actorName?.trim();
  final lieu = notif.data['lieu']?.toString();
  final millesime = vin['millesime'];
  final annee = millesime is num ? millesime.toInt() : int.tryParse('${millesime ?? ''}');
  final nom = vin['nom']?.toString() ?? tr('Vin dégusté', 'Tasted wine');
  final messager = ScaffoldMessenger.maybeOf(context);

  if (!notif.isRead) {
    try {
      await conteneur.read(friendsRepositoryProvider).markNotificationRead(notif.id);
    } catch (_) {}
    conteneur.invalidate(userNotificationsProvider);
  }

  final deja = (await InvitationsNotees.lire())[notif.id];
  if (deja != null && deja.terminee) {
    messager?.showSnackBar(SnackBar(content: Text(tr('Déjà noté : il est dans votre journal.', 'Already rated: it is in your journal.'))));
    return;
  }

  // La dégustation de l'invitation, écrite une seule fois : un second passage rouvre la
  // même au lieu d'en créer une autre.
  String tastingId;
  if (deja != null) {
    tastingId = deja.tastingId;
  } else {
    try {
      final ecrite = await conteneur.read(degustationRapideProvider).enregistrer(VinBuDehors(
            nom: nom,
            producteur: vin['producteur']?.toString(),
            millesime: annee,
            region: vin['region']?.toString(),
            pays: vin['pays']?.toString(),
            couleur: vin['couleur']?.toString() ?? 'red',
            lieu: lieu,
            convives: [if (ami != null && ami.isNotEmpty) ami],
          ));
      tastingId = ecrite.id;
      await InvitationsNotees.retenir(notif.id, InvitationNotee(tastingId: tastingId));
      conteneur.invalidate(tastingLogProvider);
    } catch (e) {
      AppLogger.warning('INVITATION', 'Dégustation de l\'invitation non écrite : $e');
      messager?.showSnackBar(SnackBar(content: Text(tr('Impossible d\'ouvrir ce vin : réessayez.', 'Could not open this wine: try again.'))));
      return;
    }
  }
  conteneur.invalidate(invitationsNoteesProvider);

  // L'invitation ne dit pas les cépages : on les cherche pendant qu'on répond (080).
  final cepagesAVenir = conteneur.read(cepagesDuVinProvider).chercher(
        nom: nom,
        producteur: vin['producteur']?.toString(),
        millesime: annee,
        region: vin['region']?.toString(),
        pays: vin['pays']?.toString(),
        couleur: vin['couleur']?.toString(),
      );
  // Ouvrir l'invitation ici, c'est souvent qu'elle n'est pas arrivée en notification.
  if (context.mounted) await NotificationPrePermissionDialog.auBonMoment(context);
  final express = await FormatDuQuestionnaire.express();
  if (!context.mounted) return;
  await TastingQuestionnaireSheet.show(
    context,
    dejaAuJournal: true,
    tastingLogId: tastingId,
    wineName: nom,
    vintage: annee,
    producer: vin['producteur']?.toString(),
    region: vin['region']?.toString(),
    wineType: vin['couleur']?.toString(),
    lieu: lieu,
    invitePar: ami,
    initialIsExpress: express,
    demarrerDirectement: true,
    cepagesAVenir: cepagesAVenir,
    onNote: (note, defaut) async {
      await InvitationsNotees.retenir(
          notif.id, InvitationNotee(tastingId: tastingId, note: note, defaut: defaut, terminee: true));
      conteneur.invalidate(invitationsNoteesProvider);
    },
  );
}
