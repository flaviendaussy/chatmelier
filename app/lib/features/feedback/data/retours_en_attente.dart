import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/utils/app_logger.dart';

/// Un retour « secouer pour commenter » qui n'est pas encore arrivé au serveur.
class RetourEnAttente {
  final String id;
  final String commentaire;
  final bool annotations;

  /// La personne au moment du retour : elle peut se déconnecter avant l'envoi.
  final String? userId;

  /// Le fichier de la capture sur le téléphone, tant qu'elle n'est pas partie.
  final String? captureLocale;

  /// Son chemin dans le bucket privé `feedback` (`<personne>/<id>.png`), cité par le retour.
  final String? captureDistante;
  final bool captureEnvoyee;
  final Map<String, dynamic> contexte;
  final DateTime creeLe;

  const RetourEnAttente({
    required this.id,
    required this.commentaire,
    required this.annotations,
    required this.userId,
    required this.captureLocale,
    required this.captureDistante,
    required this.captureEnvoyee,
    required this.contexte,
    required this.creeLe,
  });

  RetourEnAttente copie({bool? captureEnvoyee, bool sansCapture = false}) => RetourEnAttente(
        id: id,
        commentaire: commentaire,
        annotations: annotations,
        userId: userId,
        captureLocale: sansCapture ? null : captureLocale,
        captureDistante: sansCapture ? null : captureDistante,
        captureEnvoyee: captureEnvoyee ?? this.captureEnvoyee,
        contexte: contexte,
        creeLe: creeLe,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'commentaire': commentaire,
        'annotations': annotations,
        'user_id': userId,
        'capture_locale': captureLocale,
        'capture_distante': captureDistante,
        'capture_envoyee': captureEnvoyee,
        'contexte': contexte,
        'cree_le': creeLe.toIso8601String(),
      };

  static RetourEnAttente? fromJson(Object? j) {
    if (j is! Map) return null;
    final cree = DateTime.tryParse('${j['cree_le']}');
    if (j['id'] is! String || cree == null) return null;
    return RetourEnAttente(
      id: j['id'] as String,
      commentaire: '${j['commentaire'] ?? ''}',
      annotations: j['annotations'] == true,
      userId: j['user_id'] as String?,
      captureLocale: j['capture_locale'] as String?,
      captureDistante: j['capture_distante'] as String?,
      captureEnvoyee: j['capture_envoyee'] == true,
      contexte: j['contexte'] is Map ? Map<String, dynamic>.from(j['contexte'] as Map) : const {},
      creeLe: cree,
    );
  }

  /// La ligne du journal, au format que lisent la console (`admin_retours`) et « Mes
  /// retours » : `Commentaire: … | Capture: … | Annotations: …`.
  String get message => 'Commentaire: ${commentaire.isNotEmpty ? commentaire : "Sans commentaire"} '
      '| Capture: ${captureDistante ?? "aucune"} '
      '| Annotations: ${annotations ? "oui" : "non"}';
}

/// Les retours gardés sur le téléphone jusqu'à leur arrivée au serveur, capture comprise
/// (16/10 : une capture annotée perdue faute de réseau, l'échec écrit dans un `debugPrint`
/// que personne ne voit). Le retour part avec son heure d'origine et son contexte.
class RetoursEnAttente {
  const RetoursEnAttente._();

  static const _cle = 'retours_en_attente_v1';

  /// Au-delà, les plus anciens partent : une file ne doit pas grossir sans fin.
  static const tailleMax = 20;
  static const ageMax = Duration(days: 30);

  static bool _enCours = false;

  static Future<List<RetourEnAttente>> lire() async {
    try {
      final brut = (await SharedPreferences.getInstance()).getString(_cle);
      if (brut == null) return [];
      final liste = jsonDecode(brut);
      if (liste is! List) return [];
      final limite = DateTime.now().subtract(ageMax);
      return [
        for (final j in liste)
          if (RetourEnAttente.fromJson(j) case final r? when r.creeLe.isAfter(limite)) r,
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _ecrire(List<RetourEnAttente> retours) async {
    final gardes = retours.length > tailleMax ? retours.sublist(retours.length - tailleMax) : retours;
    await (await SharedPreferences.getInstance()).setString(_cle, jsonEncode([for (final r in gardes) r.toJson()]));
  }

  static Future<void> _remplacer(RetourEnAttente r) async {
    final tous = await lire();
    await _ecrire([for (final x in tous) x.id == r.id ? r : x]);
  }

  static Future<void> _retirer(String id) async {
    final tous = await lire();
    await _ecrire([for (final x in tous) if (x.id != id) x]);
  }

  /// Garde le retour sur le téléphone, puis tente de l'envoyer. Vrai : il est parti.
  static Future<bool> deposer({
    required String commentaire,
    required bool annotations,
    Uint8List? capture,
    Map<String, dynamic> contexte = const {},
    @visibleForTesting SupabaseClient? client,

    /// Faux : le retour est gardé, et il part en arrière-plan — l'écran n'attend pas le
    /// réseau (Flavien, 22/10 : « les commentaires doivent être fire and forget, ils ne
    /// doivent jamais mettre de temps à s'envoyer »). Le résultat est alors toujours faux.
    bool attendreLEnvoi = true,
  }) async {
    final supabase = client ?? Supabase.instance.client;
    final id = const Uuid().v4();
    final userId = supabase.auth.currentUser?.id;
    String? locale;
    String? distante;
    if (capture != null && userId != null) {
      distante = '$userId/$id.png';
      if (!kIsWeb) {
        try {
          final dossier = Directory('${(await getApplicationSupportDirectory()).path}/retours');
          await dossier.create(recursive: true);
          final fichier = File('${dossier.path}/$id.png');
          await fichier.writeAsBytes(capture, flush: true);
          locale = fichier.path;
        } catch (e) {
          AppLogger.warning('FEEDBACK', 'Capture du retour non gardée sur le téléphone : $e');
        }
      }
    }
    final retour = RetourEnAttente(
      id: id,
      commentaire: commentaire,
      annotations: annotations,
      userId: userId,
      captureLocale: locale,
      captureDistante: distante,
      captureEnvoyee: false,
      contexte: contexte,
      creeLe: DateTime.now(),
    );
    await _ecrire([...await lire(), retour]);
    final envoi = envoyer(client: supabase, enMemoire: capture == null ? null : {id: capture});
    if (!attendreLEnvoi) {
      unawaited(envoi.then((_) {}, onError: (Object e) => AppLogger.warning('FEEDBACK', 'Retour pas encore parti : $e')));
      return false;
    }
    final partis = await envoi;
    return partis.contains(id);
  }

  /// Envoie ce qui attend : la capture d'abord (le retour la cite), puis le retour. Appelé
  /// après chaque dépôt, au lancement et au retour de l'app au premier plan.
  static Future<Set<String>> envoyer({SupabaseClient? client, Map<String, Uint8List>? enMemoire}) async {
    if (_enCours) return {};
    _enCours = true;
    final partis = <String>{};
    try {
      final SupabaseClient supabase;
      try {
        supabase = client ?? Supabase.instance.client;
      } catch (_) {
        return partis;
      }
      for (final attente in await lire()) {
        var retour = attente;
        String? causeCapture;
        if (retour.captureDistante != null && !retour.captureEnvoyee) {
          Uint8List? octets = enMemoire?[retour.id];
          if (octets == null && retour.captureLocale != null) {
            final f = File(retour.captureLocale!);
            if (await f.exists()) octets = await f.readAsBytes();
          }
          if (octets == null) {
            causeCapture = 'capture introuvable sur le téléphone';
            retour = retour.copie(sansCapture: true);
          } else {
            try {
              await supabase.storage
                  .from('feedback')
                  .uploadBinary(retour.captureDistante!, octets,
                      fileOptions: const FileOptions(contentType: 'image/png', upsert: true))
                  .timeout(const Duration(seconds: 20));
              retour = retour.copie(captureEnvoyee: true);
              await _remplacer(retour);
            } catch (e) {
              AppLogger.warning('FEEDBACK', 'Capture du retour en attente de réseau : $e');
              if (!kIsWeb) continue; // elle repartira avec son retour
              // Sur le web, rien ne garde la capture : le retour part sans elle, et le dit.
              causeCapture = 'capture non envoyée (web) : $e';
              retour = retour.copie(sansCapture: true);
            }
          }
        }
        final maintenant = DateTime.now();
        try {
          await supabase.from('app_diagnostic_logs').insert({
            'user_id': retour.userId,
            'device_id': kIsWeb ? 'Web Browser' : defaultTargetPlatform.name,
            'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
            'app_version': versionApp,
            'tag': 'USER_FEEDBACK',
            'level': 'info',
            'message': retour.message,
            'created_at': retour.creeLe.toIso8601String(),
            'metadata': {
              'utc_offset_min': retour.creeLe.timeZoneOffset.inMinutes,
              'contexte': retour.contexte,
              if (maintenant.difference(retour.creeLe) > const Duration(minutes: 1))
                'envoye_le': maintenant.toIso8601String(),
              if (causeCapture != null) 'capture': causeCapture,
            },
          }).timeout(const Duration(seconds: 10));
          await _retirer(retour.id);
          if (attente.captureLocale != null) {
            try {
              await File(attente.captureLocale!).delete();
            } catch (_) {}
          }
          partis.add(retour.id);
        } catch (e) {
          AppLogger.warning('FEEDBACK', 'Retour en attente de réseau : $e');
        }
      }
    } finally {
      _enCours = false;
    }
    return partis;
  }
}
