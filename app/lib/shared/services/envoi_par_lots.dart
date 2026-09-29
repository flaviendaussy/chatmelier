import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';

/// Des événements qui partent au serveur par lots : coûts IA, pubs affichées (S5).
///
/// Trois règles, parce que mesurer ne doit jamais gêner l'usage :
/// - **rien de bloquant** : on range l'événement et on rend la main ; l'envoi se fait
///   plus tard, par lots ;
/// - **rien de perdu** : la file vit dans les préférences, elle survit à la fermeture de
///   l'app et aux coupures de réseau (plafonnée, les plus anciens tombent d'abord) ;
/// - **rien de compté deux fois** : chaque ligne porte l'identifiant créé sur l'appareil,
///   et le serveur ignore un doublon (`on_conflict=event_id`).
///
/// Sans session (invité web qui n'a rien ouvert), la file attend : la table n'accepte
/// que des lignes rattachées à un compte, anonyme compris.
class EnvoiParLots {
  final String table;
  final String cleLocale;
  final int maxEnAttente;
  final int tailleDuLot;
  final SupabaseClient? Function() _client;

  /// Faux dans les tests : ils appellent [envoyer] eux-mêmes, au moment voulu.
  final bool envoiAutomatique;

  EnvoiParLots({
    required this.table,
    required this.cleLocale,
    this.maxEnAttente = 500,
    this.tailleDuLot = 50,
    this.envoiAutomatique = true,
    SupabaseClient? Function()? client,
  }) : _client = client ?? _clientParDefaut;

  /// Le client de l'app, ou rien : `Supabase.instance` lève une assertion tant que
  /// Supabase n'est pas initialisé (tests, tout début du démarrage).
  static SupabaseClient? _clientParDefaut() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  DateTime? _dernierEnvoi;
  bool _envoiEnCours = false;
  static final Set<String> _dejaSignale = {};

  /// Ce qui distingue un essai sur émulateur (profile, debug) du Play Store (release).
  static String get modeDeBuild => kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug');

  static String get plateforme {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'other',
    };
  }

  Future<List<Map<String, dynamic>>> _lire() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final brut = prefs.getString(cleLocale);
      if (brut == null || brut.isEmpty) return [];
      return [for (final e in jsonDecode(brut) as List) Map<String, dynamic>.from(e as Map)];
    } catch (_) {
      return [];
    }
  }

  Future<void> _ecrire(List<Map<String, dynamic>> file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gardee = file.length > maxEnAttente ? file.sublist(file.length - maxEnAttente) : file;
      await prefs.setString(cleLocale, jsonEncode(gardee));
    } catch (_) {}
  }

  /// Nombre d'événements en attente d'envoi.
  Future<int> enAttente() async => (await _lire()).length;

  /// Range une ligne ; l'envoi suit, par lots : dès dix en attente, ou si le dernier
  /// envoi date de plus de 45 s. Pas de minuteur permanent — rien ne tourne pour rien,
  /// et le reste part au démarrage suivant.
  Future<void> ajouter(Map<String, dynamic> ligne) async {
    final file = await _lire()..add(ligne);
    await _ecrire(file);
    final maintenant = DateTime.now();
    if (envoiAutomatique &&
        (file.length >= 10 ||
        _dernierEnvoi == null ||
        maintenant.difference(_dernierEnvoi!) > const Duration(seconds: 45))) {
      unawaited(envoyer());
    }
  }

  /// Envoie ce qui attend, lot par lot. Rend le nombre de lignes acceptées.
  Future<int> envoyer() async {
    if (_envoiEnCours) return 0;
    final client = _client();
    if (client == null || client.auth.currentUser == null) return 0;
    _envoiEnCours = true;
    _dernierEnvoi = DateTime.now();
    var envoyees = 0;
    try {
      while (true) {
        final file = await _lire();
        if (file.isEmpty) break;
        final lot = file.take(tailleDuLot).toList();
        await client.from(table).upsert(lot, onConflict: 'event_id', ignoreDuplicates: true);
        // Relire avant d'écrire : des événements ont pu arriver pendant l'envoi.
        final ids = {for (final l in lot) l['event_id']};
        final reste = (await _lire()).where((l) => !ids.contains(l['event_id'])).toList();
        await _ecrire(reste);
        envoyees += lot.length;
      }
    } catch (e) {
      // Réseau coupé, session expirée, table pas encore créée : la file attend le
      // prochain passage. Un avertissement, pas une erreur — rien n'est perdu.
      // Une fois par session et par table : avant la migration 047, chaque passage
      // échouerait, et les journaux se rempliraient d'un même avertissement.
      if (_dejaSignale.add(table)) {
        AppLogger.warning('MESURE', 'Envoi vers $table différé : $e');
      }
    } finally {
      _envoiEnCours = false;
    }
    return envoyees;
  }
}
