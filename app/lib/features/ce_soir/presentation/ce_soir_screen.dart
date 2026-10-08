import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/langue.dart';
import '../../../shared/widgets/onglets.dart';
import '../../cellar/presentation/cellar_food_pairing_sheet.dart';
import '../../journal/presentation/external_tasting_dialog.dart';
import '../../menu_scan/data/recent_menus_store.dart';
import '../../menu_scan/domain/carte_du_lieu.dart';
import '../../menu_scan/presentation/carte_du_lieu_vue.dart';
import '../../menu_scan/presentation/join_table_sheet.dart';

/// L'onglet « Ce soir » (V2.3 · E1) : ce qu'on fait d'un vin ce soir, au restaurant ou à
/// la maison.
///
/// La table est ce que l'app fait de mieux, et elle était cachée : troisième tuile de
/// l'« Espace Dégustation », en tête d'un onglet consacré au passé (le journal). Elle a
/// maintenant le premier onglet, et le journal redevient un journal.
class CeSoirScreen extends ConsumerWidget {
  const CeSoirScreen({super.key});

  static const _bordeaux = Color(0xFF8B1E3F);
  static const _or = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Les cartes récentes, pas seulement la dernière : celle d'un restaurant scanné avant
    // un autre restait inaccessible (V2.3 · K6).
    final recentes = ref.watch(recentMenusProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Ce soir', 'Tonight')),
        actions: const [BoutonSommelier()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            tr('Au restaurant ou à la maison : choisissons ensemble.', 'Out or at home: let\'s choose together.'),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          _Titre(tr('Au restaurant', 'Eating out')),
          _GrandeAction(
            icone: Icons.document_scanner_outlined,
            titre: tr('Scanner la carte des vins', 'Scan the wine list'),
            sousTitre: tr('Les vins qui vous iront, et ceux de toute la table', 'The wines that suit you, and the whole table'),
            couleur: _bordeaux,
            onTap: () => context.push('/scan/menu'),
          ),
          for (final carte in recentes.take(RecentMenusStore.maximum)) ...[
            const SizedBox(height: 8),
            _Ligne(
              icone: Icons.history_rounded,
              couleur: Colors.teal.shade700,
              titre: tr('Rouvrir « {restaurantName} »', 'Reopen “{restaurantName}”', {'restaurantName': carte.restaurantName}),
              sousTitre: tr('{wines_length} vins · {age} · sans rescanner', '{wines_length} wines · {age} · no rescan needed',
                  {'wines_length': carte.wines.length, 'age': CarteDuLieu.age(carte.scannedAt)}),
              fond: isDark ? const Color(0xFF1F2A2A) : const Color(0xFFE8F4F2),
              onTap: () => context.push('/scan/menu/result', extra: carte),
            ),
          ],
          const SizedBox(height: 8),
          _Ligne(
            icone: Icons.near_me_outlined,
            couleur: Colors.teal.shade700,
            titre: tr('Les cartes autour de moi', 'Menus around me'),
            sousTitre: tr('Déjà scannées par d\'autres membres : sans rescanner',
                'Already scanned by other members: no rescan needed'),
            fond: isDark ? const Color(0xFF1F2A2A) : const Color(0xFFE8F4F2),
            onTap: () async {
              final choisie = await CartesAutourDeMoiSheet.show(context);
              if (choisie != null && context.mounted) await ouvrirLaCarteDuLieu(context, ref, choisie);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Tuile(
                  icone: Icons.groups_rounded,
                  titre: tr('Rejoindre une table', 'Join a table'),
                  sousTitre: tr('Avec son code', 'With its code'),
                  couleur: const Color(0xFF6A4C93),
                  onTap: () => JoinTableSheet.show(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Tuile(
                  icone: Icons.restaurant,
                  titre: tr('Noter un vin bu dehors', 'Rate a wine had out'),
                  sousTitre: tr('Restaurant, amis', 'Restaurant, friends'),
                  couleur: Colors.orange.shade800,
                  onTap: () => ExternalTastingDialog.show(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          _Titre(tr('Au bar', 'At the bar')),
          _Ligne(
            icone: Icons.local_bar_outlined,
            couleur: const Color(0xFF6A4C93),
            titre: tr('Scanner l\'ardoise', 'Scan the board'),
            sousTitre: tr('Les vins au verre, et un parcours qui vous apprend quelque chose',
                'Wines by the glass, and a flight that teaches you something'),
            fond: isDark ? const Color(0xFF241D30) : const Color(0xFFF0EAF7),
            onTap: () => context.push('/scan/menu?mode=ardoise'),
          ),

          const SizedBox(height: 22),
          _Titre(tr('À la maison', 'At home')),
          Row(
            children: [
              Expanded(
                child: _Tuile(
                  icone: Icons.inventory_2_outlined,
                  titre: tr('Ouvrir une bouteille', 'Open a bottle'),
                  sousTitre: tr('De ma cave', 'From my cellar'),
                  couleur: _bordeaux,
                  onTap: () => context.push('/checkout'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Tuile(
                  icone: Icons.dinner_dining_outlined,
                  titre: tr('Quel vin pour mon plat ?', 'Which wine for my dish?'),
                  sousTitre: tr('Dans ma cave', 'From my cellar'),
                  couleur: _or,
                  onTap: () => _accordDeMaCave(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _accordDeMaCave(BuildContext context, WidgetRef ref) {
    final caveId = ref.read(currentCellarIdProvider);
    final bouteilles = ref.read(bottlesProvider(caveId)).valueOrNull ?? [];
    var nom = tr('Ma cave', 'My cellar');
    for (final item in ref.read(userCellarsProvider).valueOrNull ?? const []) {
      final c = item['cellars'];
      if (c is Map && c['id']?.toString() == caveId) {
        final n = c['name']?.toString() ?? '';
        if (n.isNotEmpty && n != 'Ma Cave' && n != 'My Cellar') nom = n;
        break;
      }
    }
    CellarFoodPairingSheet.show(context, bottles: bouteilles, cellarName: nom);
  }
}

class _Titre extends StatelessWidget {
  final String texte;
  const _Titre(this.texte);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          texte.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

/// L'action principale de la soirée : scanner la carte.
class _GrandeAction extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String sousTitre;
  final Color couleur;
  final VoidCallback onTap;

  const _GrandeAction({
    required this.icone,
    required this.titre,
    required this.sousTitre,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: couleur,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(sousTitre, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String titre;
  final String sousTitre;
  final Color fond;
  final VoidCallback onTap;

  const _Ligne({
    required this.icone,
    required this.couleur,
    required this.titre,
    required this.sousTitre,
    required this.fond,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fond,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icone, size: 20, color: couleur),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(sousTitre, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tuile extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String sousTitre;
  final Color couleur;
  final VoidCallback onTap;

  const _Tuile({
    required this.icone,
    required this.titre,
    required this.sousTitre,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: couleur.withValues(alpha: isDark ? 0.14 : 0.07),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: couleur.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: couleur.withValues(alpha: 0.18), shape: BoxShape.circle),
                child: Icon(icone, size: 22, color: couleur),
              ),
              const SizedBox(height: 8),
              Text(
                titre,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.15),
              ),
              const SizedBox(height: 2),
              Text(
                sousTitre,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
