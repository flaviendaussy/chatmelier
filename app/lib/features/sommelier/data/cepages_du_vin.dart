import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../cellar/domain/vins_connus/vins_connus.dart';
import '../../../shared/services/fonctions_ia.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/sans_accents.dart';

/// Les cépages d'un vin qu'on ne connaît pas, cherchés par le serveur (`taches-ia`, tâche
/// `cepages`, migration 080) : le cache commun, puis le catalogue, puis le web — et ce qui
/// est trouvé sert au suivant.
///
/// Flavien, 23/10 : « go check the grapes when you don't know them and when you can find
/// them on internet! And then cache them in the database for the next user ». Le 22/10, un
/// « Ungrafted Cinsault » bu au Vagabond arrivait sans cépages, et le palais l'apprenait
/// comme un cabernet de la Maipo.
///
/// Rien ne bloque : la recherche part pendant qu'on répond au questionnaire, qui l'attend un
/// instant à la fin ; sans réponse, il apprend comme avant (le cépage du nom, sinon ceux de
/// la région).
class CepagesDuVin {
  final FonctionsIa Function() _ia;

  CepagesDuVin(this._ia);

  static const _cleLocale = 'chatmelier_cepages_trouves_v1';

  /// Les recherches en cours, pour ne pas lancer deux fois la même (deux verres du même vin).
  static final Map<String, Future<List<String>>> _enCours = {};

  /// « domaine|vin », comme le serveur : en minuscules, sans accents ni ponctuation.
  static String cle(String? producteur, String nom) {
    String net(String t) => sansAccents(t).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    return '${net(producteur ?? '')}|${net(nom)}';
  }

  Future<List<String>> chercher({
    required String nom,
    String? producteur,
    int? millesime,
    String? region,
    String? pays,
    String? couleur,
  }) {
    final n = nom.trim();
    if (n.isEmpty) return Future.value(const []);
    // Une cuvée de la base des vins connus (23/10) a ses cépages sur le téléphone : ni
    // réseau, ni quota. Un vin seulement rangé dans son appellation se cherche encore.
    final connu = VinsConnus.trouver(nom: n, producteur: producteur, region: region, pays: pays, type: couleur);
    if (connu != null && connu.cepagesDeLaCuvee) return Future.value(connu.cepages);
    final k = cle(producteur, n);
    // Un bloc, pas une flèche : `remove` rendrait la recherche elle-même, que whenComplete
    // attendrait — elle s'attendrait sans fin.
    return _enCours[k] ??= _chercher(k, n, producteur, millesime, region, pays, couleur).whenComplete(() {
      _enCours.remove(k);
    });
  }

  Future<List<String>> _chercher(
      String k, String nom, String? producteur, int? millesime, String? region, String? pays, String? couleur) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final gardes = jsonDecode(prefs.getString(_cleLocale) ?? '{}');
      if (gardes is Map && gardes[k] is List && (gardes[k] as List).isNotEmpty) {
        return [for (final c in gardes[k] as List) c.toString()];
      }
    } catch (_) {}
    try {
      final r = await _ia().appeler('taches-ia', {
        'tache': 'cepages',
        'nom': nom,
        if ((producteur ?? '').trim().isNotEmpty) 'producteur': producteur!.trim(),
        if (millesime != null) 'millesime': millesime,
        if ((region ?? '').trim().isNotEmpty) 'region': region!.trim(),
        if ((pays ?? '').trim().isNotEmpty) 'pays': pays!.trim(),
        if ((couleur ?? '').trim().isNotEmpty) 'couleur': couleur!.trim(),
      }, delai: const Duration(seconds: 30));
      if (!r.ok) return const [];
      final resultat = r.donnees!['resultat'];
      final cepages = [
        if (resultat is Map && resultat['cepages'] is List)
          for (final g in resultat['cepages'] as List)
            if (g is Map && (g['name'] ?? '').toString().trim().isNotEmpty) g['name'].toString().trim(),
      ];
      AppLogger.info('CEPAGES', '« $nom » : ${cepages.isEmpty ? 'cépages introuvables' : cepages.join(', ')}'
          ' (${resultat is Map ? resultat['methode'] : '?'})');
      if (cepages.isNotEmpty && prefs != null) {
        try {
          final gardes = jsonDecode(prefs.getString(_cleLocale) ?? '{}');
          final m = gardes is Map ? Map<String, dynamic>.from(gardes) : <String, dynamic>{};
          m[k] = cepages;
          // Deux cents vins suffisent : le serveur garde le reste.
          while (m.length > 200) {
            m.remove(m.keys.first);
          }
          await prefs.setString(_cleLocale, jsonEncode(m));
        } catch (_) {}
      }
      return cepages;
    } catch (e) {
      AppLogger.warning('CEPAGES', 'Cépages de « $nom » non cherchés : $e');
      return const [];
    }
  }
}

final cepagesDuVinProvider = Provider<CepagesDuVin>((ref) => CepagesDuVin(() => FonctionsIa(ref.read(supabaseProvider))));
