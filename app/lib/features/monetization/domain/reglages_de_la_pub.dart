import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/utils/app_logger.dart';

/// Ce que l'IA offre chaque jour, et ce qu'une vidéo débloque (modèle économique, 21/10).
///
/// Étude du 21/10 : chaque personne active coûtait plus d'IA qu'elle ne rapportait de pub.
/// La règle devient « la pub paie l'IA ; tout le reste est gratuit et sans pub » : quelques
/// questions offertes par jour, puis une courte vidéo choisie pour en ouvrir d'autres ; au
/// restaurant, une vidéo pour la soirée. Tout se règle depuis la console
/// (`app_config.politique_pub`, migration 077) ; sans ce réglage, ces valeurs par défaut.
class ReglagesDeLaPub {
  /// Interrupteur général des vidéos de déblocage : faux, tout est ouvert (dans les quotas
  /// du serveur), comme avant la 87.
  final bool videos;

  /// Questions au sommelier offertes par jour, et combien une vidéo en ajoute.
  final int chatOfferts;
  final int chatParVideo;

  /// Questions sur une carte sans soirée ouverte (carte rouverte, carte du lieu).
  final int questionsCarteOffertes;

  /// Une vidéo au restaurant ouvre la soirée : questions sur la carte sans compter.
  final int soireeHeures;

  /// Cotes d'un vin par jour (chacune est une recherche Google payante).
  final int coteOffertes;

  /// Une carte « Annonce » toutes les N entrées d'une liste ; 0 : aucune.
  final int annonceTousLes;

  /// Les blocs « natif avancé » d'AdMob ; sans eux, pas de carte « Annonce ».
  final String? uniteNativeAndroid;
  final String? uniteNativeIos;

  const ReglagesDeLaPub({
    this.videos = true,
    this.chatOfferts = 5,
    this.chatParVideo = 8,
    this.questionsCarteOffertes = 3,
    this.soireeHeures = 4,
    this.coteOffertes = 3,
    this.annonceTousLes = 12,
    this.uniteNativeAndroid,
    this.uniteNativeIos,
  });

  static final _unite = RegExp(r'^ca-app-pub-[0-9]{10,20}/[0-9]{6,12}$');

  /// Une valeur illisible ne casse rien : elle garde sa valeur par défaut.
  factory ReglagesDeLaPub.depuis(Object? brut) {
    const d = ReglagesDeLaPub();
    if (brut is! Map) return d;
    int entier(String cle, int defaut) {
      final v = brut[cle];
      return v is num && v >= 0 && v <= 1000 ? v.toInt() : defaut;
    }

    String? unite(String cle) {
      final v = brut[cle];
      return v is String && _unite.hasMatch(v) ? v : null;
    }

    return ReglagesDeLaPub(
      videos: brut['videos'] is bool ? brut['videos'] as bool : d.videos,
      chatOfferts: entier('chat_offerts', d.chatOfferts),
      chatParVideo: entier('chat_par_video', d.chatParVideo).clamp(1, 1000),
      questionsCarteOffertes: entier('questions_carte_offertes', d.questionsCarteOffertes),
      soireeHeures: entier('soiree_heures', d.soireeHeures).clamp(1, 24),
      coteOffertes: entier('cote_offertes', d.coteOffertes),
      annonceTousLes: entier('annonce_tous_les', d.annonceTousLes),
      uniteNativeAndroid: unite('unite_native_android'),
      uniteNativeIos: unite('unite_native_ios'),
    );
  }

  /// Le bloc natif de cette plateforme, s'il est réglé.
  String? get uniteNative {
    if (kIsWeb) return null;
    try {
      return Platform.isIOS ? uniteNativeIos : (Platform.isAndroid ? uniteNativeAndroid : null);
    } catch (_) {
      return null;
    }
  }

  // ─── Les réglages en cours ─────────────────────────────────────────────────────────
  static ReglagesDeLaPub _actuels = const ReglagesDeLaPub();
  static ReglagesDeLaPub get actuels => _actuels;
  static const _cle = 'politique_pub_v1';

  @visibleForTesting
  static set actuels(ReglagesDeLaPub r) => _actuels = r;

  /// Au lancement : la dernière copie connue tout de suite (hors ligne compris), puis celle
  /// du serveur.
  static Future<void> charger(SupabaseClient client) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final copie = prefs.getString(_cle);
      if (copie != null) _actuels = ReglagesDeLaPub.depuis(jsonDecode(copie));
      final ligne = await client
          .from('app_config')
          .select('valeur')
          .eq('cle', 'politique_pub')
          .maybeSingle()
          .timeout(const Duration(seconds: 6));
      final valeur = ligne?['valeur'];
      if (valeur is Map) {
        _actuels = ReglagesDeLaPub.depuis(valeur);
        await prefs.setString(_cle, jsonEncode(valeur));
      }
    } catch (e) {
      // Hors ligne, ou migration 077 pas encore appliquée : les valeurs par défaut suffisent.
      AppLogger.info('PUB', 'Politique de la pub non lue : $e');
    }
  }
}
