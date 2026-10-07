import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_console_service.dart';
import '../data/admin_personnes_service.dart';
import '../domain/admin_economie.dart';
import '../domain/admin_personnes.dart';
import 'admin_console_onglets.dart';
import 'admin_graphes.dart';
import 'admin_personne_screen.dart';

// =============================================================================
// Petits outils partagés par les écrans de la console
// =============================================================================
const _mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
const _joursSemaine = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];

String dateCourte(DateTime d) => '${d.day} ${_mois[d.month - 1]}';
String dateLongue(DateTime d) => '${_joursSemaine[d.weekday - 1]} ${d.day} ${_mois[d.month - 1]}';
String heure(DateTime d) => '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

String ilYA(DateTime? d) {
  if (d == null) return 'jamais';
  final e = DateTime.now().difference(d);
  if (e.inMinutes < 1) return 'à l\'instant';
  if (e.inMinutes < 60) return 'il y a ${e.inMinutes} min';
  if (e.inHours < 24) return 'il y a ${e.inHours} h';
  if (e.inDays < 30) return 'il y a ${e.inDays} j';
  return 'le ${dateCourte(d)}';
}

/// Rappelle, en haut de chaque écran, ce que la console montre et jusqu'à quand.
class BandeauModeTest extends ConsumerWidget {
  const BandeauModeTest({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nominatif = ref.watch(adminNominatifProvider).valueOrNull;
    if (nominatif == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: nominatif ? const Color(0xFFFFE0B2) : const Color(0xFFE0E0E0),
      child: Row(
        children: [
          Icon(nominatif ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nominatif
                  ? 'Mode test — données nominatives, à opacifier avant la production.'
                  : 'Données opacifiées : prénoms remplacés, conversations masquées.',
              style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class Compteur extends StatelessWidget {
  final IconData icone;
  final int valeur;
  final String libelle;
  final bool alerte;

  const Compteur({super.key, required this.icone, required this.valeur, required this.libelle, this.alerte = false});

  @override
  Widget build(BuildContext context) {
    final couleur = alerte ? const Color(0xFFC62828) : Theme.of(context).colorScheme.onSurfaceVariant;
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icone, size: 16, color: couleur),
      label: Text('$valeur $libelle', style: TextStyle(fontSize: 12, color: alerte ? couleur : null)),
    );
  }
}

class MessageDEchec extends StatelessWidget {
  final String erreur;

  /// La migration qui crée les fonctions de l'onglet.
  final String migration;
  const MessageDEchec({super.key, required this.erreur, this.migration = '044'});

  @override
  Widget build(BuildContext context) {
    final texte = erreur.contains('reserve_admin')
        ? 'Réservé au compte administrateur.'
        : erreur.contains('detail_masque')
            ? 'Masqué : la console est en mode opacifié.'
            : erreur.contains('PGRST202') || erreur.contains('Could not find the function')
                ? 'Fonction absente : la migration $migration n\'est pas encore appliquée.'
                : 'Chargement impossible. Vérifiez la connexion, puis actualisez.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(texte, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}

// =============================================================================
// Personnes
// =============================================================================
class OngletPersonnes extends ConsumerStatefulWidget {
  const OngletPersonnes({super.key});

  @override
  ConsumerState<OngletPersonnes> createState() => _OngletPersonnesState();
}

enum _Tri { activite, arrivee, gestes, erreurs }

class _OngletPersonnesState extends ConsumerState<OngletPersonnes> {
  String _recherche = '';
  _Tri _tri = _Tri.activite;
  bool _masquerInactifs = false;

  @override
  Widget build(BuildContext context) {
    return ref.watch(adminPersonnesProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MessageDEchec(erreur: '$e'),
          data: (toutes) {
            final q = _recherche.trim().toLowerCase();
            final liste = [
              for (final p in toutes)
                if ((q.isEmpty || p.prenom.toLowerCase().contains(q)) && (!_masquerInactifs || p.gestes > 0)) p,
            ]..sort((a, b) => switch (_tri) {
                  _Tri.activite =>
                    (b.derniereActivite ?? DateTime(2000)).compareTo(a.derniereActivite ?? DateTime(2000)),
                  _Tri.arrivee => (b.arriveLe ?? DateTime(2000)).compareTo(a.arriveLe ?? DateTime(2000)),
                  _Tri.gestes => b.gestes.compareTo(a.gestes),
                  _Tri.erreurs => b.erreurs.compareTo(a.erreurs),
                });
            final anonymes = toutes.where((p) => p.anonyme).length;

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminPersonnesProvider),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Chercher un prénom',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => _recherche = v),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        for (final (t, l) in const [
                          (_Tri.activite, 'Activité récente'),
                          (_Tri.arrivee, 'Arrivée'),
                          (_Tri.gestes, 'Les plus actifs'),
                          (_Tri.erreurs, 'Erreurs'),
                        ]) ...[
                          ChoiceChip(label: Text(l), selected: _tri == t, onSelected: (_) => setState(() => _tri = t)),
                          const SizedBox(width: 6),
                        ],
                        FilterChip(
                          label: const Text('Actifs seulement'),
                          selected: _masquerInactifs,
                          onSelected: (v) => setState(() => _masquerInactifs = v),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                    child: Text(
                      '${toutes.length} comptes, dont $anonymes anonymes · ${liste.length} affichés',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                  for (final p in liste) _LignePersonne(personne: p),
                ],
              ),
            );
          },
        );
  }
}

class _LignePersonne extends StatelessWidget {
  final Personne personne;
  const _LignePersonne({required this.personne});

  @override
  Widget build(BuildContext context) {
    final p = personne;
    final gris = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListTile(
      onTap: () => AdminPersonneScreen.ouvrir(context, p),
      leading: CircleAvatar(
        backgroundColor: p.anonyme ? Colors.grey.shade300 : const Color(0xFF8B1E3F).withValues(alpha: 0.15),
        child: Text(p.prenom.isEmpty ? '?' : p.prenom[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      title: Row(
        children: [
          Flexible(child: Text(p.prenom, overflow: TextOverflow.ellipsis)),
          if (p.anonyme) ...[
            const SizedBox(width: 6),
            Text('anonyme', style: TextStyle(fontSize: 11, color: gris)),
          ],
          if (p.erreurs > 0) ...[
            const SizedBox(width: 6),
            const Icon(Icons.error_outline, size: 14, color: Color(0xFFC62828)),
          ],
        ],
      ),
      subtitle: Text(
        [
          ilYA(p.derniereActivite),
          if (p.plateforme != null) p.plateforme!,
          if (p.version != null) p.version!,
          if (p.gestes > 0)
            [
              if (p.degustations > 0) '${p.degustations} dég.',
              if (p.bouteilles > 0) '${p.bouteilles} bout.',
              if (p.scansCarte > 0) '${p.scansCarte} cartes',
              if (p.scansEtiquette > 0) '${p.scansEtiquette} étiq.',
              if (p.messages > 0) '${p.messages} questions',
              if (p.tables > 0) '${p.tables} tables',
            ].join(', '),
        ].join(' · '),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

// =============================================================================
// Fonctionnalités : qui utilise quoi
// =============================================================================
class OngletFonctionnalites extends ConsumerWidget {
  const OngletFonctionnalites({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(adminUsagesProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MessageDEchec(erreur: '$e'),
          data: (lignes) {
            final bilans = BilanDeFonctionnalite.depuis(lignes);
            if (bilans.isEmpty) {
              return const Center(child: Text('Aucun usage sur cette période.', style: TextStyle(color: Colors.grey)));
            }
            final max = bilans.first.usages;
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminUsagesProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  for (final b in bilans) ...[
                    Row(
                      children: [
                        Expanded(child: Text(b.nom, style: const TextStyle(fontWeight: FontWeight.w600))),
                        Text('${b.usages} · ${b.personnes} pers.', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : b.usages / max,
                        minHeight: 8,
                        color: const Color(0xFF8B1E3F),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.parPersonne.map((e) => '${e.key} (${e.value})').join(', '),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            );
          },
        );
  }
}

// =============================================================================
// Erreurs : WARNING et ERROR, groupés
// =============================================================================
class OngletErreurs extends ConsumerWidget {
  const OngletErreurs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(adminErreursProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MessageDEchec(erreur: '$e'),
          data: (erreurs) {
            if (erreurs.isEmpty) {
              return const Center(
                  child: Text('Aucune erreur sur cette période. 🎉', style: TextStyle(color: Colors.grey)));
            }
            final nbErreurs = erreurs.where((e) => e.estErreur).fold(0, (a, e) => a + e.n);
            final nbAlertes = erreurs.where((e) => !e.estErreur).fold(0, (a, e) => a + e.n);
            final parJour = ref.watch(adminErreursParJourProvider).valueOrNull ?? const [];
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminErreursProvider);
                ref.invalidate(adminErreursParJourProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: BarresDErreurs(jours: parJour),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text('$nbErreurs erreurs, $nbAlertes avertissements · touchez-en une pour ses occurrences',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  for (final e in erreurs)
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => FeuilleDOccurrences.ouvrir(context, e),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: e.estErreur ? const Color(0xFFC62828) : const Color(0xFFEF6C00),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(e.estErreur ? 'ERREUR' : 'ALERTE',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(e.tag, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                  const Spacer(),
                                  Text('×${e.n}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(e.forme, style: const TextStyle(fontSize: 12.5)),
                              const SizedBox(height: 6),
                              Text(
                                [
                                  if (e.qui.isNotEmpty) e.qui,
                                  if (e.derniere != null) 'dernière : ${dateCourte(e.derniere!)} ${heure(e.derniere!)}',
                                  if (e.versions.isNotEmpty) e.versions,
                                ].join(' · '),
                                style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
  }
}

// =============================================================================
// Économie : ce que coûte l'IA, ce que rapporte la pub (migration 047, S5)
// =============================================================================
class OngletEconomie extends ConsumerWidget {
  const OngletEconomie({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inclureTests = ref.watch(adminInclureTestsProvider);
    final gris = Theme.of(context).colorScheme.onSurfaceVariant;
    return ref.watch(adminEconomieProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MessageDEchec(erreur: '$e', migration: '047'),
          data: (b) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminEconomieProvider);
              ref.invalidate(adminCroissanceProvider);
              ref.invalidate(adminEconomieDetailProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compter les essais sur émulateur', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Builds profile et debug : pubs de test, sans revenu réel.',
                      style: TextStyle(fontSize: 12)),
                  value: inclureTests,
                  onChanged: (v) => ref.read(adminInclureTestsProvider.notifier).state = v,
                ),
                _Ratio(bilan: b),
                const SizedBox(height: 8),
                Text(
                  'Revenu ESTIMÉ : impressions × eCPM de app_config.ecpm_eur_estime '
                  '(${b.ecpmEstime.entries.map((e) => '${e.key} ${e.value.toStringAsFixed(1)} €').join(', ')}). '
                  'À remplacer par les eCPM réels de la console AdMob.',
                  style: TextStyle(fontSize: 11.5, color: gris, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                // Le détail de la V2.4 (migration 060) : sans elle, la section se tait.
                ...ref.watch(adminEconomieDetailProvider).maybeWhen(
                      data: (d) => [
                        CourbeCoutEtRevenu(jours: d.parJour),
                        CourbeCoutDesScans(jours: d.parJour),
                        JaugeDeRecherche(utilisees: d.recherchesDuMois, franchise: d.franchiseMensuelle),
                        CoutsParModele(modeles: d.parModele),
                      ],
                      orElse: () => const <Widget>[],
                    ),
                _Titre('Coût par fonctionnalité', '${b.appelsIa} appels, dont ${b.appelsGroundes} avec recherche'),
                if (b.parFonctionnalite.isEmpty) _Vide(gris),
                for (final l in b.parFonctionnalite)
                  _Barre(
                    libelle: l.libelle,
                    droite: '${euros(l.coutEur)} · ${l.appels} appels',
                    part: b.coutIaEur == 0 ? 0 : l.coutEur / b.coutIaEur,
                    couleur: const Color(0xFF8B1E3F),
                  ),
                const SizedBox(height: 16),
                _Titre('Pubs par emplacement', '${b.impressions} impressions'),
                if (b.parEmplacement.isEmpty) _Vide(gris),
                for (final l in b.parEmplacement)
                  _Barre(
                    libelle: '${l.emplacement} (${l.format})',
                    droite: '${l.impressions} · ${euros(l.revenuEur)}',
                    part: b.impressions == 0 ? 0 : l.impressions / b.impressions,
                    couleur: const Color(0xFF2E7D32),
                  ),
                const SizedBox(height: 16),
                const _Titre('App et web', 'le web n\'a pas de pub : il se lit comme un coût d\'acquisition'),
                for (final l in b.parPlateforme)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.plateforme),
                    trailing: Text('coût ${euros(l.coutEur)} · pub ${euros(l.revenuEur)}'),
                  ),
                const SizedBox(height: 16),
                const _DuWebALApp(),
                const SizedBox(height: 16),
                const _Titre('Par personne', 'du plus coûteux au moins coûteux'),
                if (b.parPersonne.isEmpty) _Vide(gris),
                for (final l in b.parPersonne)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.prenom),
                    subtitle: Text('${l.appels} appels IA · ${l.impressions} pubs'),
                    trailing: Text('${euros(l.coutEur)} / ${euros(l.revenuEur)}',
                        style: TextStyle(
                            color: l.revenuEur >= l.coutEur ? const Color(0xFF2E7D32) : const Color(0xFFC62828))),
                  ),
              ],
            ),
          ),
        );
  }
}

/// Du web à l'app (V2.3 · J6, K2) : ce que la page invité amène jusqu'à l'app installée,
/// et ce que l'IA du web coûte par installation obtenue — le chiffre qui dira s'il faut
/// garder le web ouvert.
class _DuWebALApp extends ConsumerWidget {
  const _DuWebALApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gris = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget ligne(String titre, String valeur, {String? detail}) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(titre),
          subtitle: detail == null ? null : Text(detail, style: const TextStyle(fontSize: 12)),
          trailing: Text(valeur, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
    return ref.watch(adminCroissanceProvider).when(
          loading: () => const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('Du web à l\'app : illisible ($e). Migration 053 appliquée ?',
              style: TextStyle(fontSize: 12, color: gris)),
          data: (c) {
            final parInstallation = c.coutWebParInstallationEur;
            final sources = c.installationsParSource.entries.map((e) => '${e.key} ${e.value}').join(' · ');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Titre('Du web à l\'app', 'ce que la page invité amène jusqu\'à l\'app installée'),
                ligne('Invités arrivés sur le web', '${c.evenements('invite_web_arrivee')}'),
                ligne('Notes de fin de soirée sur le web', '${c.evenements('invite_web_note')}'),
                ligne('Clics « Installer l\'app »', '${c.evenements('clic_installer')}'),
                ligne('Installations venues du web', '${c.installationsWeb}',
                    detail: sources.isEmpty ? null : 'toutes les premières ouvertures : $sources'),
                ligne('Coût de l\'IA sur le web', euros(c.coutIaWebEur)),
                ligne('Coût web par installation obtenue', parInstallation == null ? '—' : euros(parInstallation)),
                Text(
                  'Une installation n\'a de source qu\'à partir de la 1.6.0+73 (Install Referrer). '
                  '« google-play » : une recherche dans le Play Store, sans lien du web.',
                  style: TextStyle(fontSize: 11.5, color: gris, fontStyle: FontStyle.italic),
                ),
              ],
            );
          },
        );
  }
}

class _Ratio extends StatelessWidget {
  final BilanEconomique bilan;
  const _Ratio({required this.bilan});

  @override
  Widget build(BuildContext context) {
    final r = bilan.ratio;
    final couleur = r == null ? Colors.grey : (r >= 1 ? const Color(0xFF2E7D32) : const Color(0xFFC62828));
    Widget case_(String titre, String valeur) => Expanded(
          child: Column(
            children: [
              Text(valeur, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(titre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5)),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(children: [
              case_('coût IA', euros(bilan.coutIaEur)),
              case_('revenu pub estimé', euros(bilan.revenuPubEur)),
            ]),
            const Divider(height: 20),
            Text(
              r == null ? 'Aucun coût IA sur la période' : 'La pub paie ${(r * 100).toStringAsFixed(0)} % de l\'IA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: couleur),
            ),
          ],
        ),
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  final String titre;
  final String sousTitre;
  const _Titre(this.titre, this.sousTitre);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(sousTitre, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
}

class _Barre extends StatelessWidget {
  final String libelle;
  final String droite;
  final double part;
  final Color couleur;
  const _Barre({required this.libelle, required this.droite, required this.part, required this.couleur});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(libelle, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(droite, style: const TextStyle(fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: part.clamp(0.0, 1.0),
                minHeight: 7,
                color: couleur,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      );
}

class _Vide extends StatelessWidget {
  final Color gris;
  const _Vide(this.gris);

  @override
  Widget build(BuildContext context) => Text('Rien sur cette période.', style: TextStyle(fontSize: 12.5, color: gris));
}
