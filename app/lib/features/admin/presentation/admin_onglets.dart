import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_personnes_service.dart';
import '../domain/admin_personnes.dart';
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
          Icon(nominatif ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 16, color: Colors.black87),
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
  const MessageDEchec({super.key, required this.erreur});

  @override
  Widget build(BuildContext context) {
    final texte = erreur.contains('reserve_admin')
        ? 'Réservé au compte administrateur.'
        : erreur.contains('detail_masque')
            ? 'Masqué : la console est en mode opacifié.'
            : erreur.contains('PGRST202') || erreur.contains('Could not find the function')
                ? 'Fonction absente : la migration 044 n\'est pas encore appliquée.'
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
                _Tri.activite => (b.derniereActivite ?? DateTime(2000)).compareTo(a.derniereActivite ?? DateTime(2000)),
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
              return const Center(child: Text('Aucune erreur sur cette période. 🎉', style: TextStyle(color: Colors.grey)));
            }
            final nbErreurs = erreurs.where((e) => e.estErreur).fold(0, (a, e) => a + e.n);
            final nbAlertes = erreurs.where((e) => !e.estErreur).fold(0, (a, e) => a + e.n);
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminErreursProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text('$nbErreurs erreurs, $nbAlertes avertissements',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  for (final e in erreurs)
                    Card(
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
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                ],
              ),
            );
          },
        );
  }
}
