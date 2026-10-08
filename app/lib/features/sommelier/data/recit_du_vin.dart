import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/fonctions_ia.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../../cellar/domain/wine.dart';

/// Le récit d'un vin, écrit à la demande par le sommelier (V2.4 · R8) : trois actes et les
/// pages sur lesquelles il s'appuie.
class RecitDuVin {
  final String titre;
  final String terroir;
  final String histoire;
  final String verre;
  final List<({String titre, String url})> sources;

  const RecitDuVin({
    required this.titre,
    required this.terroir,
    required this.histoire,
    required this.verre,
    this.sources = const [],
  });

  /// Ce que la voix lit.
  String get texte => [terroir, histoire, verre].where((t) => t.trim().isNotEmpty).join('\n\n');

  bool get estVide => texte.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'titre': titre,
        'terroir': terroir,
        'histoire': histoire,
        'verre': verre,
        'sources': [for (final s in sources) {'titre': s.titre, 'url': s.url}],
      };

  /// Le récit rendu par le serveur ([resultat], [sources]) ou gardé sur le téléphone.
  static RecitDuVin? lire(Object? resultat, [Object? sources]) {
    if (resultat is! Map) return null;
    String champ(String cle) => resultat[cle] is String ? (resultat[cle] as String).trim() : '';
    final brutes = sources ?? resultat['sources'];
    final recit = RecitDuVin(
      titre: champ('titre'),
      terroir: champ('terroir'),
      histoire: champ('histoire'),
      verre: champ('verre'),
      sources: [
        if (brutes is List)
          for (final s in brutes)
            if (s is Map && s['url'] is String && (s['url'] as String).startsWith('https://'))
              (titre: (s['titre'] is String && (s['titre'] as String).isNotEmpty) ? s['titre'] as String : s['url'] as String,
                  url: s['url'] as String),
      ],
    );
    return recit.estVide ? null : recit;
  }
}

/// Écrit le récit d'un vin à la demande (« don't pre-generate anything here, generate on
/// request », 04/10), une fois : il reste ensuite sur le téléphone.
class ServiceDuRecit {
  final FonctionsIa? _iaInjecte;

  ServiceDuRecit({FonctionsIa? ia}) : _iaInjecte = ia;

  FonctionsIa? get _ia {
    if (_iaInjecte != null) return _iaInjecte;
    try {
      return FonctionsIa(Supabase.instance.client);
    } catch (_) {
      return null;
    }
  }

  static String cleDe(Wine w) => 'recit_v1:${w.id}:${Langue.code}';

  Future<RecitDuVin?> ecrire(Wine vin, {bool forcer = false}) async {
    final cle = cleDe(vin);
    if (!forcer) {
      try {
        final deja = (await SharedPreferences.getInstance()).getString(cle);
        if (deja != null) {
          final r = RecitDuVin.lire(jsonDecode(deja));
          if (r != null) return r;
        }
      } catch (_) {}
    }
    final ia = _ia;
    if (ia == null) return null;
    final r = await ia.appeler(
      'taches-ia',
      {
        'tache': 'recit_source',
        'langue': Langue.code,
        'nom': vin.name,
        'producteur': vin.producer,
        if (vin.vintage != null) 'millesime': vin.vintage,
        'appellation': vin.appellation ?? '',
        'region': vin.region,
        'pays': vin.country,
        'cepages': [for (final g in vin.grapes) g.name],
        'type': vin.type,
      },
      delai: const Duration(seconds: 60),
    );
    if (!r.ok) return null;
    final recit = RecitDuVin.lire(r.donnees!['resultat'], r.donnees!['sources']);
    if (recit == null) return null;
    try {
      await (await SharedPreferences.getInstance()).setString(cle, jsonEncode(recit.toJson()));
    } catch (_) {}
    return recit;
  }
}

/// La voix naturelle du récit (Gemini TTS), quand la console l'a allumée ; sinon nulle, et
/// l'app lit avec la voix du téléphone.
class VoixDuRecit {
  final FonctionsIa? _iaInjecte;

  VoixDuRecit({FonctionsIa? ia}) : _iaInjecte = ia;

  /// Une voix refusée par le serveur (éteinte, quota) ne se redemande pas de la session.
  static bool _indisponible = false;

  @visibleForTesting
  static void reinitialiser() => _indisponible = false;

  FonctionsIa? get _ia {
    if (_iaInjecte != null) return _iaInjecte;
    try {
      return FonctionsIa(Supabase.instance.client);
    } catch (_) {
      return null;
    }
  }

  /// Le fichier WAV du récit, lu une fois puis gardé dans le cache de l'app.
  Future<String?> fichier(RecitDuVin recit, String cle) async {
    if (kIsWeb || _indisponible) return null;
    final ia = _ia;
    if (ia == null) return null;
    try {
      final dossier = await getTemporaryDirectory();
      final f = File('${dossier.path}/recit_${cle.hashCode.toUnsigned(32).toRadixString(16)}_${recit.texte.length}.wav');
      if (await f.exists() && await f.length() > 44) return f.path;
      final r = await ia.appeler(
        'taches-ia',
        {'tache': 'voix', 'langue': Langue.code, 'texte': recit.texte},
        delai: const Duration(seconds: 90),
      );
      if (!r.ok) {
        // 403 (éteinte) ou 429 (quota du jour) : la voix du téléphone, sans redemander.
        if (r.statut == 403 || r.statut == 429) _indisponible = true;
        return null;
      }
      final res = r.donnees!['resultat'];
      final audio = res is Map ? res['audio'] : null;
      if (audio is! String || audio.isEmpty) return null;
      await f.writeAsBytes(base64Decode(audio), flush: true);
      return f.path;
    } catch (e) {
      AppLogger.warning('RECIT', 'Voix naturelle indisponible : $e');
      return null;
    }
  }
}
