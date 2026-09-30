import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/ai_cost_tracker_service.dart';
import '../utils/app_logger.dart';
import '../utils/langue.dart';

/// Ce que rend une fonction IA du serveur.
class ReponseIa {
  final Map<String, dynamic>? donnees;

  /// `null` si tout va bien ; sinon `limite_du_jour`, `session_requise`, `serveur` ou `reseau`.
  final String? erreur;
  final int? statut;
  final int? limite;
  final bool anonyme;

  const ReponseIa._({this.donnees, this.erreur, this.statut, this.limite, this.anonyme = false});

  bool get ok => erreur == null && donnees != null;
  bool get limiteAtteinte => erreur == 'limite_du_jour';

  /// La phrase à montrer quand le quota du jour est atteint.
  String messageDeLimite({bool web = kIsWeb}) => LimiteIaAtteinte(limite: limite, anonyme: anonyme).message(web: web);
}

/// Le quota du jour d'une fonction IA est atteint (V2.3 · B2).
class LimiteIaAtteinte implements Exception {
  final int? limite;
  final bool anonyme;

  const LimiteIaAtteinte({this.limite, this.anonyme = false});

  /// Pour une session anonyme sur le web, c'est une invitation, pas un mur (J5) : ce qui
  /// est en cours reste là.
  String message({bool web = kIsWeb}) {
    if (anonyme && web) {
      return tr(
          'Votre palais commence à se dessiner : installez l\'app pour le garder, et scanner d\'autres cartes. '
              'La table en cours et ses accords restent disponibles.',
          'Your palate is taking shape: install the app to keep it, and to scan more wine lists. '
              'The current table and its pairings stay available.');
    }
    final n = limite == null ? '' : ' ($limite)';
    return tr('Vous avez atteint la limite du jour pour cette fonction$n. Elle se renouvelle demain.',
        'You\'ve reached today\'s limit for this feature$n. It resets tomorrow.');
  }

  @override
  String toString() => message();
}

typedef InvoquerFonction = Future<dynamic> Function(String fonction, Map<String, dynamic> corps);

/// Appel d'une fonction IA du serveur (V2.3 · B2, C3).
///
/// Depuis la V2.3, toute l'IA passe par le serveur : plus aucune clé dans l'app. Ce service
/// garantit une session (anonyme au besoin), rejoue une fois l'appel si le serveur en exige
/// une, rend lisible un quota atteint, et enregistre les coûts renvoyés (`couts`).
class FonctionsIa {
  final InvoquerFonction _invoquer;
  final Future<User?> Function()? _assurerUneSession;
  final String? Function() _utilisateur;
  final AiCostTrackerService? _suivi;

  FonctionsIa(
    SupabaseClient client, {
    Future<User?> Function()? assurerUneSession,
    AiCostTrackerService? suivi,
  })  : _invoquer = ((f, c) async => (await client.functions.invoke(f, body: c)).data),
        // Par défaut, une session anonyme : depuis la V2.3, le serveur peut en exiger une
        // (app_config.ia_session_obligatoire), et l'app en ouvre déjà au premier geste.
        _assurerUneSession = assurerUneSession ??
            (() async => client.auth.currentUser ?? (await client.auth.signInAnonymously()).user),
        _utilisateur = (() => client.auth.currentUser?.id),
        _suivi = suivi;

  @visibleForTesting
  FonctionsIa.pourEssai(
    this._invoquer, {
    Future<User?> Function()? assurerUneSession,
    String? Function()? utilisateur,
    AiCostTrackerService? suivi,
  })  : _assurerUneSession = assurerUneSession,
        _utilisateur = utilisateur ?? (() => null),
        _suivi = suivi;

  Future<ReponseIa> appeler(
    String fonction,
    Map<String, dynamic> corps, {
    Duration delai = const Duration(seconds: 90),
    bool enregistrerLesCouts = true,
  }) async {
    var dejaRejoue = false;
    while (true) {
      try {
        final brut = await _invoquer(fonction, corps).timeout(delai);
        final donnees = brut is Map ? Map<String, dynamic>.from(brut) : <String, dynamic>{'valeur': brut};
        if (enregistrerLesCouts) {
          unawaited(Future.wait((_suivi ?? AiCostTrackerService()).enregistrerCoutsServeur(donnees, _utilisateur())));
        }
        return ReponseIa._(donnees: donnees);
      } on FunctionException catch (e) {
        final details = e.details is Map ? Map<String, dynamic>.from(e.details as Map) : const <String, dynamic>{};
        if (e.status == 401 && !dejaRejoue && _assurerUneSession != null) {
          dejaRejoue = true;
          final moi = await _assurerUneSession();
          if (moi != null) continue;
        }
        if (e.status == 429 && details['error'] == 'limite_du_jour') {
          AppLogger.info('IA', '$fonction : limite du jour atteinte');
          return ReponseIa._(
            erreur: 'limite_du_jour',
            statut: 429,
            limite: (details['limite'] as num?)?.toInt(),
            anonyme: details['anonyme'] == true,
          );
        }
        AppLogger.warning('IA', '$fonction : HTTP ${e.status} ${details['error'] ?? ''}');
        return ReponseIa._(erreur: e.status == 401 ? 'session_requise' : 'serveur', statut: e.status);
      } catch (e) {
        AppLogger.warning('IA', '$fonction injoignable : $e');
        return const ReponseIa._(erreur: 'reseau');
      }
    }
  }
}
