import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/providers/supabase_provider.dart';
import '../../shared/utils/app_logger.dart';

/// Ce que la phase de test exige (`app_config.version_minimale_test`, migration 045).
class ExigenceDeVersion {
  final int build;
  final String lien;
  final String? message;

  const ExigenceDeVersion({required this.build, required this.lien, this.message});

  static ExigenceDeVersion? depuis(Object? valeur) {
    if (valeur is! Map) return null;
    final build = valeur['build'];
    final lien = valeur['lien'];
    if (build is! num || lien is! String) return null;
    return ExigenceDeVersion(build: build.toInt(), lien: lien, message: valeur['message'] as String?);
  }
}

/// Le numéro de build d'une version « 1.4.0+70 » ; nul pour un build de développement.
int? numeroDeBuild(String version) {
  final plus = version.lastIndexOf('+');
  if (plus < 0) return null;
  return int.tryParse(version.substring(plus + 1));
}

/// Faut-il bloquer cette version ? Jamais sans exigence lue, ni pour un build sans numéro
/// (développement) : dans le doute, on laisse passer.
bool doitMettreAJour(String version, ExigenceDeVersion? exigence) {
  final build = numeroDeBuild(version);
  if (exigence == null || build == null) return false;
  return build < exigence.build;
}

final exigenceDeVersionProvider = FutureProvider<ExigenceDeVersion?>((ref) async {
  // Le web se sert toujours de la dernière version publiée.
  if (kIsWeb) return null;
  try {
    final ligne = await ref
        .read(supabaseProvider)
        .from('app_config')
        .select('valeur')
        .eq('cle', 'version_minimale_test')
        .maybeSingle()
        .timeout(const Duration(seconds: 6));
    return ExigenceDeVersion.depuis(ligne?['valeur']);
  } catch (e) {
    // Hors ligne, ou table absente : on ne bloque personne pour une vérification ratée.
    AppLogger.warning('VERSION', 'Version minimale illisible: $e');
    return null;
  }
});

/// Bloque l'app si sa version est plus ancienne que celle exigée pendant la phase de test.
class GardeDeVersion extends ConsumerWidget {
  final String versionInstallee;
  final Widget child;

  const GardeDeVersion({super.key, required this.versionInstallee, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exigence = ref.watch(exigenceDeVersionProvider).valueOrNull;
    if (!doitMettreAJour(versionInstallee, exigence)) return child;
    return _MiseAJourObligatoire(exigence: exigence!, versionInstallee: versionInstallee);
  }
}

class _MiseAJourObligatoire extends StatelessWidget {
  final ExigenceDeVersion exigence;
  final String versionInstallee;

  const _MiseAJourObligatoire({required this.exigence, required this.versionInstallee});

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
                  fr ? 'Une mise à jour est nécessaire' : 'An update is required',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  exigence.message ??
                      (fr
                          ? 'Pendant la phase de test, tout le monde utilise la même version.'
                          : 'During the test phase, everyone uses the same version.'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  fr
                      ? 'Obligatoire uniquement pendant la phase de test.'
                      : 'Required during the test phase only.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                  onPressed: () => launchUrl(Uri.parse(exigence.lien), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.shop),
                  label: Text(fr ? 'Mettre à jour' : 'Update'),
                ),
                const SizedBox(height: 14),
                Text(
                  fr
                      ? 'Installée : $versionInstallee · requise : build ${exigence.build}'
                      : 'Installed: $versionInstallee · required: build ${exigence.build}',
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
