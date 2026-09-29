import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/utils/app_logger.dart';

/// Le palais recopié côté serveur (migration 050, P6).
///
/// Le palais — profils de goût, registre des preuves, instantanés mensuels — vit dans le
/// téléphone. Jusqu'au 29/09 il n'en sortait pas : « ajoutez votre adresse pour retrouver
/// votre soirée ailleurs » gardait le compte, pas le palais, et vider son cache le
/// détruisait. Désormais chaque sauvegarde en envoie une copie (regroupée, quelques
/// secondes après), et un appareil vierge la rapatrie.
///
/// Règle de prudence : on ne remplace jamais un palais local qui a de vraies observations
/// par celui du serveur — sauf reprise explicite d'une soirée (code de reprise).
class PalaisDistant {
  /// Les trois mémoires du téléphone, dans l'ordre des colonnes de `palais_utilisateur`.
  static const Map<String, String> colonnes = {
    'chatmelier_taste_profiles_v2': 'profils',
    'chatmelier_taste_evidence_v1': 'preuves',
    'chatmelier_taste_history_v1': 'historique',
  };

  /// Le compte à qui appartient le palais local. Sur un téléphone partagé, le palais de
  /// l'un ne doit jamais partir dans le compte de l'autre.
  static const String cleProprietaire = 'chatmelier_palais_proprietaire';

  /// Allumé par `main.dart` seulement : dans les tests, pas d'envoi ni de minuterie.
  static bool actif = false;

  /// Un événement à chaque palais rapatrié : les écrans qui l'affichent se rechargent.
  static final StreamController<int> _rapatriements = StreamController<int>.broadcast();
  static Stream<int> get rapatriements => _rapatriements.stream;
  static int _n = 0;

  static const Duration delaiDeRegroupement = Duration(seconds: 3);
  static Timer? _minuterie;

  /// Vrai si le serveur n'a pas (encore) la table : migration 050 non appliquée. Le
  /// service se tait alors pour la session, au lieu d'écrire un avertissement à chaque
  /// dégustation.
  static bool _tableAbsente = false;

  static bool _estTableAbsente(Object e) {
    final t = e.toString();
    return t.contains('palais_utilisateur') &&
        (t.contains('does not exist') || t.contains('Could not find') || t.contains('PGRST205') || t.contains('42P01'));
  }

  static SupabaseClient? _client() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Après une sauvegarde locale : un envoi, regroupé avec les sauvegardes voisines
  /// (une dégustation écrit profil, preuves et historique en quelques millisecondes).
  static void planifierEnvoi() {
    if (!actif) return;
    _minuterie?.cancel();
    _minuterie = Timer(delaiDeRegroupement, () => unawaited(envoyer()));
  }

  /// Envoie tout de suite ce que le téléphone sait. Faux sans session ou en cas d'échec :
  /// la prochaine sauvegarde réessaiera.
  static Future<bool> envoyer() async {
    final client = _client();
    final moi = client?.auth.currentUser;
    if (client == null || moi == null || _tableAbsente) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final proprietaire = prefs.getString(cleProprietaire);
      if (proprietaire != null && proprietaire != moi.id) {
        // Le palais local est celui d'un autre compte : on ne l'envoie pas ici.
        return false;
      }
      final ligne = <String, dynamic>{
        'user_id': moi.id,
        'maj_le': DateTime.now().toUtc().toIso8601String(),
        for (final e in colonnes.entries) e.value: _lire(prefs.getString(e.key)),
      };
      await client.from('palais_utilisateur').upsert(ligne);
      await prefs.setString(cleProprietaire, moi.id);
      return true;
    } catch (e) {
      if (_estTableAbsente(e)) {
        _tableAbsente = true;
        AppLogger.info('PALAIS', 'Palais côté serveur indisponible (migration 050 absente)');
      } else {
        AppLogger.warning('PALAIS', 'Copie du palais impossible : $e');
      }
      return false;
    }
  }

  /// Rapatrie le palais du serveur.
  ///
  /// Sans [forcer], seulement si le palais local est vierge (appareil neuf, cache vidé)
  /// ou s'il appartient à un autre compte ; avec [forcer] (reprise d'une soirée), toujours.
  static Future<bool> recuperer({bool forcer = false}) async {
    final client = _client();
    final moi = client?.auth.currentUser;
    if (client == null || moi == null || _tableAbsente) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final proprietaire = prefs.getString(cleProprietaire);
      final dUnAutre = proprietaire != null && proprietaire != moi.id;
      final remplacer = forcer || dUnAutre;
      if (!remplacer && !vierge(prefs.getString(colonnes.keys.first))) return false;

      final ligne = await client.from('palais_utilisateur').select().eq('user_id', moi.id).maybeSingle();
      if (ligne == null) {
        if (!dUnAutre) return false;
        // Le palais de l'autre compte est à l'abri sur son compte (il l'a envoyé, sinon
        // il n'en serait pas propriétaire) : celui-ci repart d'une page blanche.
        for (final cle in colonnes.keys) {
          await prefs.remove(cle);
        }
        await prefs.setString(cleProprietaire, moi.id);
        _annoncer();
        return true;
      }
      if (!remplacer && vierge(jsonEncode(ligne['profils']))) return false; // rien de mieux là-haut
      for (final e in colonnes.entries) {
        final valeur = ligne[e.value];
        if (valeur is List && valeur.isNotEmpty) {
          await prefs.setString(e.key, jsonEncode(valeur));
        } else if (remplacer) {
          await prefs.remove(e.key);
        }
      }
      await prefs.setString(cleProprietaire, moi.id);
      AppLogger.info('PALAIS', forcer ? 'Palais repris d\'une soirée' : 'Palais rapatrié sur cet appareil');
      _annoncer();
      return true;
    } catch (e) {
      if (_estTableAbsente(e)) {
        _tableAbsente = true;
      } else {
        AppLogger.warning('PALAIS', 'Rapatriement du palais impossible : $e');
      }
      return false;
    }
  }

  static void _annoncer() => _rapatriements.add(++_n);

  static dynamic _lire(String? brut) {
    if (brut == null || brut.isEmpty) return const [];
    try {
      return jsonDecode(brut);
    } catch (_) {
      return const [];
    }
  }

  /// Un palais (JSON des profils) est vierge s'il n'a encore rien appris : aucun
  /// questionnaire, aucune observation, sur aucun profil.
  static bool vierge(String? jsonProfils) {
    if (jsonProfils == null || jsonProfils.isEmpty) return true;
    final dynamic liste;
    try {
      liste = jsonDecode(jsonProfils);
    } catch (_) {
      return true;
    }
    if (liste is! List || liste.isEmpty) return true;
    for (final p in liste) {
      if (p is! Map) continue;
      if (((p['questionnaires_completed'] as num?) ?? 0) > 0) return false;
      final obs = p['axis_observations'];
      if (obs is Map && obs.values.any((v) => v is num && v > 0)) return false;
    }
    return true;
  }
}
