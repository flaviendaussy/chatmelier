import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/services/cellar_location_service.dart';
import '../../../shared/utils/langue.dart';
import '../../auth/data/taste_profile_service.dart';
import '../data/cartes_de_lieux_service.dart';
import '../domain/carte_du_lieu.dart';

/// Ouvre la carte d'un lieu, déposée par quelqu'un d'autre, recalculée pour ce palais
/// (V2.3 · K6). [remplacer] : depuis l'écran de capture, la carte prend sa place.
Future<void> ouvrirLaCarteDuLieu(BuildContext context, WidgetRef ref, CarteProche c, {bool remplacer = false}) async {
  final messager = ScaffoldMessenger.of(context);
  final brute = await ref.read(cartesDeLieuxServiceProvider).ouvrir(c.lieuCle);
  if (brute == null) {
    messager.showSnackBar(SnackBar(
      content: Text(tr('Cette carte n\'est plus disponible : scannez-la, la suivante en profitera.',
          'This menu is no longer available: scan it, the next person will benefit.')),
    ));
    return;
  }
  final profils = await ref.read(tasteProfilesListProvider.future);
  final carte = CarteDuLieu.recue(
    brute.carte,
    nomDuLieu: brute.nom.isEmpty ? c.lieuNom : brute.nom,
    deposeeLe: brute.deposeeLe,
    profil: profils.isNotEmpty ? profils.first : null,
  );
  if (!context.mounted) return;
  if (remplacer) {
    context.pushReplacement('/scan/menu/result', extra: carte);
  } else {
    context.push('/scan/menu/result', extra: carte);
  }
  messager.showSnackBar(SnackBar(
    duration: const Duration(seconds: 6),
    content: Text(c.prixAVerifier()
        ? tr('Carte scannée {age} : les prix ont pu changer, vérifiez-les avant de commander.',
            'Menu scanned {age}: prices may have changed, check them before ordering.', {'age': c.age()})
        : tr('Carte scannée {age} par un autre membre : rescannez-la si elle a changé.',
            'Menu scanned {age} by another member: rescan it if it has changed.', {'age': c.age()})),
  ));
}

/// « La carte du Petit Zinc a été scannée il y a 3 jours : l'ouvrir sans rescanner ? »
class BandeauCarteDuLieu extends StatelessWidget {
  final CarteProche carte;
  final VoidCallback onOuvrir;

  const BandeauCarteDuLieu({super.key, required this.carte, required this.onOuvrir});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distance = carte.distanceM < 30 ? '' : ' · ${carte.distanceM} m';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.history_edu_rounded, color: Colors.teal.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('La carte de « {lieu} » existe déjà', 'The menu of “{lieu}” already exists', {'lieu': carte.lieuNom}),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  [
                    tr('Scannée {age}', 'Scanned {age}', {'age': carte.age()}),
                    tr('{n} vins', '{n} wines', {'n': carte.nbVins}),
                    if (carte.prixAVerifier()) tr('prix à vérifier', 'check prices'),
                  ].join(' · ') +
                      distance,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onOuvrir, child: Text(tr('Ouvrir', 'Open'))),
        ],
      ),
    );
  }
}

/// « Ce soir » : les cartes déjà scannées autour de soi (la position est demandée ici,
/// au geste de la personne, jamais d'office). Rend la carte choisie : c'est l'écran qui
/// l'ouvre, la feuille étant refermée.
class CartesAutourDeMoiSheet extends ConsumerStatefulWidget {
  const CartesAutourDeMoiSheet({super.key});

  static Future<CarteProche?> show(BuildContext context) => showModalBottomSheet<CarteProche>(
        context: context,
        showDragHandle: true,
        builder: (_) => const CartesAutourDeMoiSheet(),
      );

  @override
  ConsumerState<CartesAutourDeMoiSheet> createState() => _CartesAutourDeMoiSheetState();
}

class _CartesAutourDeMoiSheetState extends ConsumerState<CartesAutourDeMoiSheet> {
  List<CarteProche>? _cartes;
  bool _sansPosition = false;

  @override
  void initState() {
    super.initState();
    _chercher();
  }

  Future<void> _chercher() async {
    final service = ref.read(cartesDeLieuxServiceProvider);
    final pos = await CellarLocationService.getCurrentPosition();
    if (pos == null) {
      if (mounted) setState(() => _sansPosition = true);
      return;
    }
    final cartes = await service.proches(pos.latitude, pos.longitude, rayonM: 400);
    if (mounted) setState(() => _cartes = cartes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartes = _cartes;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Les cartes autour de vous', 'Menus around you'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              tr('Scannées par d\'autres membres ces 30 derniers jours : ouvrez-en une sans rescanner.',
                  'Scanned by other members in the last 30 days: open one without rescanning.'),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (_sansPosition)
              Text(tr('Position indisponible : autorisez-la, ou scannez la carte.',
                  'Location unavailable: allow it, or scan the menu.'))
            else if (cartes == null)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (cartes.isEmpty)
              Text(tr('Aucune carte récente ici : scannez-la, la personne suivante en profitera.',
                  'No recent menu here: scan it, the next person will benefit.'))
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in cartes)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(c.ardoise ? Icons.local_bar_outlined : Icons.menu_book_outlined,
                            color: const Color(0xFF8B1E3F)),
                        title: Text(c.lieuNom, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text([
                          '${c.distanceM} m',
                          tr('{n} vins', '{n} wines', {'n': c.nbVins}),
                          c.age(),
                          if (c.prixAVerifier()) tr('prix à vérifier', 'check prices'),
                        ].join(' · ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).pop(c),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
