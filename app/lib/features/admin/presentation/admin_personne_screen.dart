import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_personnes_service.dart';
import '../domain/admin_personnes.dart';
import 'admin_onglets.dart';

/// Une personne : ce qu'elle a fait, jour après jour, et ce qu'elle a demandé au
/// sommelier — questions et réponses.
class AdminPersonneScreen extends ConsumerWidget {
  final Personne personne;
  const AdminPersonneScreen({super.key, required this.personne});

  static Future<void> ouvrir(BuildContext context, Personne p) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminPersonneScreen(personne: p)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = personne;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(p.prenom),
          bottom: const TabBar(tabs: [Tab(text: 'Fil'), Tab(text: 'Conversations')]),
        ),
        body: Column(
          children: [
            const BandeauModeTest(),
            _EnTete(personne: p),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _Fil(userId: p.userId),
                  _Conversations(userId: p.userId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnTete extends StatelessWidget {
  final Personne personne;
  const _EnTete({required this.personne});

  @override
  Widget build(BuildContext context) {
    final p = personne;
    final gris = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (p.anonyme) 'Compte anonyme',
              if (p.arriveLe != null) 'arrivé le ${dateCourte(p.arriveLe!)}',
              if (p.plateforme != null) p.plateforme!,
              if (p.version != null) p.version!,
            ].join(' · '),
            style: TextStyle(fontSize: 12, color: gris),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Compteur(icone: Icons.wine_bar, valeur: p.degustations, libelle: 'dégustations'),
              Compteur(icone: Icons.inventory_2_outlined, valeur: p.bouteilles, libelle: 'bouteilles'),
              Compteur(icone: Icons.photo_camera_outlined, valeur: p.scansEtiquette, libelle: 'étiquettes'),
              Compteur(icone: Icons.menu_book_outlined, valeur: p.scansCarte, libelle: 'cartes'),
              Compteur(icone: Icons.chat_bubble_outline, valeur: p.messages, libelle: 'questions'),
              Compteur(icone: Icons.groups_outlined, valeur: p.tables, libelle: 'tables'),
              Compteur(icone: Icons.error_outline, valeur: p.erreurs, libelle: 'erreurs', alerte: p.erreurs > 0),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fil extends ConsumerWidget {
  final String userId;
  const _Fil({required this.userId});

  static const _icones = {
    'degustation': (Icons.wine_bar, Color(0xFF8B1E3F)),
    'bouteille': (Icons.inventory_2_outlined, Color(0xFF6D4C41)),
    'question': (Icons.chat_bubble_outline, Color(0xFF1565C0)),
    'chat_carte': (Icons.forum_outlined, Color(0xFF1565C0)),
    'table': (Icons.groups_outlined, Color(0xFF00897B)),
    'retour': (Icons.campaign_outlined, Color(0xFFD4AF37)),
    'scan_carte': (Icons.menu_book_outlined, Color(0xFF5E35B1)),
    'scan_etiquette': (Icons.photo_camera_outlined, Color(0xFF5E35B1)),
    'usage': (Icons.touch_app_outlined, Color(0xFF546E7A)),
    'erreur': (Icons.error_outline, Color(0xFFC62828)),
    'alerte': (Icons.warning_amber_rounded, Color(0xFFEF6C00)),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(adminFilProvider(userId)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MessageDEchec(erreur: '$e'),
          data: (evenements) {
            if (evenements.isEmpty) {
              return const Center(child: Text('Rien sur cette période.', style: TextStyle(color: Colors.grey)));
            }
            String? jourPrecedent;
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: evenements.length,
              itemBuilder: (context, i) {
                final e = evenements[i];
                final jour = e.quand == null ? '—' : dateLongue(e.quand!);
                final nouveauJour = jour != jourPrecedent;
                jourPrecedent = jour;
                final (icone, couleur) = _icones[e.genre] ?? (Icons.circle_outlined, Colors.grey);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (nouveauJour)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(jour, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ListTile(
                      dense: true,
                      leading: Icon(icone, color: couleur, size: 20),
                      title: Text(e.titre, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        [if (e.quand != null) heure(e.quand!), if ((e.detail ?? '').isNotEmpty) e.detail!].join(' · '),
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
  }
}

class _Conversations extends ConsumerWidget {
  final String userId;
  const _Conversations({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(adminConversationsProvider(userId)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MessageDEchec(erreur: '$e'),
          data: (messages) {
            if (messages.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucune question au sommelier de la cave sur trois mois.\n'
                    'Les questions sur une carte de restaurant sont dans le fil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            // Du plus ancien au plus récent, comme une conversation se lit.
            final ordre = messages.reversed.toList();
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
              itemCount: ordre.length,
              itemBuilder: (context, i) => _Bulle(message: ordre[i]),
            );
          },
        );
  }
}

class _Bulle extends StatelessWidget {
  final MessageDeConversation message;
  const _Bulle({required this.message});

  @override
  Widget build(BuildContext context) {
    final m = message;
    final schema = Theme.of(context).colorScheme;
    return Align(
      alignment: m.deLaPersonne ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: m.deLaPersonne ? const Color(0xFF8B1E3F).withValues(alpha: 0.14) : schema.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.contenu, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              [if (m.quand != null) '${dateCourte(m.quand!)} ${heure(m.quand!)}', if (m.cave != null) m.cave!]
                  .join(' · '),
              style: TextStyle(fontSize: 10.5, color: schema.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
