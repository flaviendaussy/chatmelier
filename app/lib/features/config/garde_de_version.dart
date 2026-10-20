import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:url_launcher/url_launcher.dart';

import '../../shared/providers/supabase_provider.dart';
import '../../shared/utils/app_logger.dart';
import '../../shared/utils/langue.dart';
import '../offline/data/coupure_reseau.dart';

/// Ce que la phase de test exige (`app_config.version_minimale_test`, migration 045).
///
/// Une exigence par plateforme (08/10) : Android lit `build` et `lien` (Play Store) ;
/// l'iPhone lit `build_ios` et `lien_ios` (TestFlight). Les deux magasins ne publient pas
/// le même jour : sans `build_ios`, aucun iPhone n'est bloqué — ni renvoyé vers le Play
/// Store, ni bloqué avant que TestFlight ait la version demandée.
class ExigenceDeVersion {
  final int build;
  final String lien;
  final String? message;
  final int? buildIos;
  final String? lienIos;

  /// TestFlight, l'app par laquelle les testeurs iPhone mettent à jour.
  static const lienTestFlight = 'itms-beta://';

  const ExigenceDeVersion({required this.build, required this.lien, this.message, this.buildIos, this.lienIos});

  static ExigenceDeVersion? depuis(Object? valeur) {
    if (valeur is! Map) return null;
    final build = valeur['build'];
    final lien = valeur['lien'];
    if (build is! num || lien is! String) return null;
    final buildIos = valeur['build_ios'];
    final lienIos = valeur['lien_ios'];
    return ExigenceDeVersion(
      build: build.toInt(),
      lien: lien,
      message: valeur['message'] as String?,
      buildIos: buildIos is num ? buildIos.toInt() : null,
      lienIos: lienIos is String && lienIos.isNotEmpty ? lienIos : null,
    );
  }

  /// Le build exigé sur cette plateforme, ou nul : rien n'est exigé.
  int? exigePour({required bool iphone}) => iphone ? buildIos : build;

  String lienPour({required bool iphone}) => iphone ? (lienIos ?? lienTestFlight) : lien;
}

/// Le numéro de build d'une version « 1.4.0+70 » ; nul pour un build de développement.
int? numeroDeBuild(String version) {
  final plus = version.lastIndexOf('+');
  if (plus < 0) return null;
  return int.tryParse(version.substring(plus + 1));
}

/// Faut-il bloquer cette version ? Jamais sans exigence lue, ni pour un build sans numéro
/// (développement) : dans le doute, on laisse passer.
bool doitMettreAJour(String version, ExigenceDeVersion? exigence, {bool iphone = false}) {
  final build = numeroDeBuild(version);
  final exige = exigence?.exigePour(iphone: iphone);
  if (exige == null || build == null) return false;
  return build < exige;
}

/// L'app installée tourne sur un iPhone.
bool get surIphone => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

final exigenceDeVersionProvider = FutureProvider<ExigenceDeVersion?>((ref) async {
  // Le web se sert toujours de la dernière version publiée.
  if (kIsWeb) return null;
  try {
    return await _lireLaVersion(ref, 'version_minimale_test');
  } catch (e) {
    // Hors ligne, ou table absente : on ne bloque personne pour une vérification ratée.
    // Le réseau seul n'est qu'une information (T3) : 59 avertissements en vingt jours, tous
    // des délais dépassés au lancement. Un autre refus du serveur reste un avertissement.
    if (estUneCoupureReseau(e) || (e is PostgrestException && e.code == '504')) {
      AppLogger.info('VERSION', 'Version minimale illisible (réseau) : $e');
    } else {
      AppLogger.warning('VERSION', 'Version minimale illisible: $e');
    }
    return null;
  }
});

/// La version que l'app propose d'installer, sans rien bloquer (`app_config.version_disponible`,
/// migration 072). Même forme que la version exigée : `build` et `lien` pour Android,
/// `build_ios` et `lien_ios` pour l'iPhone, et un `message` facultatif (les nouveautés).
final versionDisponibleProvider = FutureProvider<ExigenceDeVersion?>((ref) async {
  if (kIsWeb) return null;
  try {
    return await _lireLaVersion(ref, 'version_disponible');
  } catch (e) {
    AppLogger.info('VERSION', 'Version disponible illisible : $e');
    return null;
  }
});

Future<ExigenceDeVersion?> _lireLaVersion(Ref ref, String cle) async {
  final ligne = await ref
      .read(supabaseProvider)
      .from('app_config')
      .select('valeur')
      .eq('cle', cle)
      .maybeSingle()
      .timeout(const Duration(seconds: 6));
  return ExigenceDeVersion.depuis(ligne?['valeur']);
}

/// « Une nouvelle version est disponible », sans bloquer (V2.5, 17/10).
///
/// Flavien : « est-ce que tu peux implémenter maintenant le prompt qui prévient qu'une
/// nouvelle version est dispo ? jld semble en utiliser une vieille » — la 74, deux semaines
/// après la 81. Une fois par jour au plus, jusqu'à la mise à jour ; jamais pour un build de
/// développement ; sur l'iPhone, seulement si une version iPhone est annoncée.
class PropositionDeMiseAJour {
  static const cle = 'maj_proposee';

  static String _marque(int build, DateTime jour) => '$build|${jour.year}-${jour.month}-${jour.day}';

  /// Faut-il la proposer ? Une version plus récente est disponible sur cette plateforme, et
  /// on ne l'a pas déjà proposée aujourd'hui.
  static bool aProposer(
    String versionInstallee,
    ExigenceDeVersion? disponible, {
    required bool iphone,
    required DateTime maintenant,
    String? dejaProposee,
  }) {
    if (!doitMettreAJour(versionInstallee, disponible, iphone: iphone)) return false;
    return dejaProposee != _marque(disponible!.exigePour(iphone: iphone)!, maintenant);
  }

  /// La propose si besoin ; vrai si elle s'est affichée.
  static Future<bool> montrerSiBesoin(
    BuildContext context,
    ExigenceDeVersion? disponible, {
    String versionInstallee = versionApp,
    bool? iphone,
    DateTime? maintenant,
  }) async {
    final surUnIphone = iphone ?? surIphone;
    final jour = maintenant ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    if (!aProposer(versionInstallee, disponible,
        iphone: surUnIphone, maintenant: jour, dejaProposee: prefs.getString(cle))) {
      return false;
    }
    if (!context.mounted) return false;
    final build = disponible!.exigePour(iphone: surUnIphone)!;
    await prefs.setString(cle, _marque(build, jour));
    AppLogger.info('VERSION', 'Mise à jour proposée : installée $versionInstallee, disponible build $build');
    if (!context.mounted) return false;
    final accepte = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => FeuilleDeMiseAJour(
        disponible: disponible,
        versionInstallee: versionInstallee,
        iphone: surUnIphone,
      ),
    );
    AppLogger.info('VERSION', accepte == true ? 'Mise à jour : vers le magasin' : 'Mise à jour : plus tard');
    if (accepte == true) {
      await launchUrl(Uri.parse(disponible.lienPour(iphone: surUnIphone)), mode: LaunchMode.externalApplication);
    }
    return true;
  }
}

/// La feuille « Une nouvelle version est disponible ». Rend vrai pour mettre à jour.
class FeuilleDeMiseAJour extends StatelessWidget {
  final ExigenceDeVersion disponible;
  final String versionInstallee;
  final bool iphone;

  const FeuilleDeMiseAJour({super.key, required this.disponible, required this.versionInstallee, required this.iphone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final message = (disponible.message ?? '').trim();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1724) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.system_update, color: Color(0xFF8B1E3F), size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(tr('Une nouvelle version est disponible', 'A new version is available'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              message.isNotEmpty
                  ? message
                  : tr('Chatmelier a changé depuis votre version : la mise à jour apporte les dernières nouveautés et corrections.',
                      'Chatmelier has changed since your version: the update brings the latest features and fixes.'),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              tr('Installée : {installee} · disponible : build {build}', 'Installed: {installee} · available: build {build}',
                  {'installee': versionInstallee, 'build': disponible.exigePour(iphone: iphone)}),
              style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white54 : Colors.black45),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(tr('Plus tard', 'Later')),
                ),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: Icon(iphone ? Icons.flight_takeoff : Icons.shop, size: 18),
                  label: Text(iphone ? tr('Ouvrir TestFlight', 'Open TestFlight') : tr('Mettre à jour', 'Update')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloque l'app si sa version est plus ancienne que celle exigée pendant la phase de test.
class GardeDeVersion extends ConsumerWidget {
  final String versionInstallee;
  final Widget child;

  const GardeDeVersion({super.key, required this.versionInstallee, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exigence = ref.watch(exigenceDeVersionProvider).valueOrNull;
    if (!doitMettreAJour(versionInstallee, exigence, iphone: surIphone)) return child;
    return _MiseAJourObligatoire(exigence: exigence!, versionInstallee: versionInstallee, iphone: surIphone);
  }
}

class _MiseAJourObligatoire extends StatelessWidget {
  final ExigenceDeVersion exigence;
  final String versionInstallee;
  final bool iphone;

  const _MiseAJourObligatoire({required this.exigence, required this.versionInstallee, required this.iphone});

  @override
  Widget build(BuildContext context) {
    final fr = Localizations.localeOf(context).languageCode == 'fr';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.system_update, size: 56, color: Color(0xFF8B1E3F)),
                const SizedBox(height: 16),
                Text(
                  trSi(fr, 'Une mise à jour est nécessaire', 'An update is required'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  exigence.message ??
                      (trSi(fr, 'Pendant la phase de test, tout le monde utilise la même version.', 'During the test phase, everyone uses the same version.')),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  trSi(fr, 'Obligatoire uniquement pendant la phase de test.', 'Required during the test phase only.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                  onPressed: () =>
                      launchUrl(Uri.parse(exigence.lienPour(iphone: iphone)), mode: LaunchMode.externalApplication),
                  icon: Icon(iphone ? Icons.flight_takeoff : Icons.shop),
                  label: Text(iphone ? trSi(fr, 'Ouvrir TestFlight', 'Open TestFlight') : trSi(fr, 'Mettre à jour', 'Update')),
                ),
                const SizedBox(height: 14),
                Text(
                  trSi(fr, 'Installée : {versionInstallee} · requise : build {build}', 'Installed: {versionInstallee} · required: build {build}', {'versionInstallee': versionInstallee, 'build': exigence.exigePour(iphone: iphone)}),
                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
