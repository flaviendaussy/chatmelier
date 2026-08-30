import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/bottle.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/widgets/wine_type_badge.dart';
import '../../../shared/widgets/maturity_colorbar.dart';
import 'delete_bottle_dialog.dart';
import 'sommelier_table_mode_sheet.dart';

class BottleContextSheet extends ConsumerWidget {
  final BuildContext parentContext;
  final Bottle bottle;
  final String cellarId;

  const BottleContextSheet({
    super.key,
    required this.parentContext,
    required this.bottle,
    required this.cellarId,
  });

  static Future<void> show(
    BuildContext context, {
    required Bottle bottle,
    required String cellarId,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BottleContextSheet(
        parentContext: context,
        bottle: bottle,
        cellarId: cellarId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFr = Localizations.localeOf(context).languageCode != 'en';
    final wine = bottle.wine;
    final wineName = wine?.name ?? (isFr ? 'Vin' : 'Wine');
    final vintage = wine?.vintage != null ? '${wine!.vintage}' : (isFr ? 'NM' : 'NV');
    final isViewOnly = ref.watch(currentCellarRoleProvider) == 'viewer';

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Wine Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF8B1E3F).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$wineName ($vintage)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (wine != null) ...[
                                WineTypeBadge(type: wine.type),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  wine?.producer ?? 'Producteur non renseigné',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Stock : ${bottle.quantity}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (bottle.rack != null && bottle.rack!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Casier ${bottle.rack}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (wine != null)
                                MaturityColorbar(wine: wine, width: 70, height: 6),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bottle.provenanceDisplay,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.brightness == Brightness.dark ? const Color(0xFFD4AF37) : const Color(0xFF8B1E3F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // Action List
              // 1. Sortir / Boire
              if (!isViewOnly)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F), size: 20),
                  ),
                  title: const Text('Sortir / Boire cette bouteille', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(bottle.quantity > 1 ? 'Déguster 1 ou plusieurs bouteilles (${bottle.quantity} dispo)' : 'Enregistrer la dégustation dans le journal'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    Navigator.of(context).pop();
                    parentContext.push('/checkout?bottleId=${bottle.id}');
                  },
                ),

              // 1.b Mode Sommelier à Table (Minuteur & Notes)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.room_service_outlined, color: Color(0xFFD4AF37), size: 20),
                ),
                title: const Text('Mode Sommelier à Table', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                subtitle: const Text('Minuteur de carafage & fiche express de dégustation'),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFFD4AF37)),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                  SommelierTableModeSheet.show(parentContext, bottle: bottle);
                },
              ),

              // 2. Ajouter des bouteilles (+1, +2, +6...)
              if (!isViewOnly)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.green, size: 20),
                  ),
                  title: const Text('Ajouter des bouteilles au stock', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('+1, +2, carton de 6, caisse de 12...'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAddQuantityDialog(parentContext, ref);
                  },
                ),

              // 3. Déplacer de cave
              if (!isViewOnly)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.drive_file_move_outline, color: Colors.blue, size: 20),
                  ),
                  title: const Text('Déplacer vers une autre cave', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Transférer tout ou partie du stock (ex: vers Vosges, Londres...)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showMoveCellarDialog(parentContext, ref);
                  },
                ),

              // 4. Demander à Chatmelier
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: Colors.amber, size: 20),
                ),
                title: const Text('Demander conseil à Chatmelier', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Accords mets-vins, apogée, température de service...'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  parentContext.push('/chat');
                },
              ),

              // 5. Voir la fiche complète
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.purple, size: 20),
                ),
                title: const Text('Voir la fiche détaillée', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Terroir, carte, notes de dégustation, historique de prix'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  parentContext.push('/cellar/bottle/${bottle.id}');
                },
              ),

              // 6. Supprimer définitivement
              if (!isViewOnly) ...[
                const Divider(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  ),
                  title: const Text(
                    'Supprimer définitivement',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  subtitle: const Text('Effacer toute trace (erreur, casse, doublon)'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
                  onTap: () {
                    Navigator.of(context).pop();
                    DeleteBottleDialog.show(
                      parentContext,
                      bottle: bottle,
                      cellarId: cellarId,
                    );
                  },
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddQuantityDialog(BuildContext context, WidgetRef ref) {
    int qtyToAdd = 1;
    final repo = ref.read(cellarRepositoryProvider);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Ajouter au stock'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Combien de bouteilles de "${bottle.wine?.name ?? "ce vin"}" souhaitez-vous ajouter ?',
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    onPressed: qtyToAdd > 1 ? () => setDlgState(() => qtyToAdd--) : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '+$qtyToAdd',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: () => setDlgState(() => qtyToAdd++),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('+1'),
                    onPressed: () => setDlgState(() => qtyToAdd = 1),
                  ),
                  ActionChip(
                    label: const Text('+3'),
                    onPressed: () => setDlgState(() => qtyToAdd = 3),
                  ),
                  ActionChip(
                    label: const Text('+6 (Carton)'),
                    onPressed: () => setDlgState(() => qtyToAdd = 6),
                  ),
                  ActionChip(
                    label: const Text('+12 (Caisse)'),
                    onPressed: () => setDlgState(() => qtyToAdd = 12),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                await repo.addBottleQuantity(
                  bottleId: bottle.id,
                  cellarId: cellarId,
                  quantityToAdd: qtyToAdd,
                );
                notifyCellarChanged(ref, cellarId);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('🍾 +$qtyToAdd bouteille(s) ajoutée(s) au stock !'),
                    backgroundColor: Colors.green.shade800,
                  ),
                );
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveCellarDialog(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(cellarRepositoryProvider);
    final userCellars = await repo.getUserCellarsWithRole();
    final otherCellars = userCellars.where((c) {
      final cMap = c['cellars'];
      final id = cMap is Map ? cMap['id']?.toString() : c['cellar_id']?.toString();
      return id != null && id != cellarId;
    }).toList();

    if (!context.mounted) return;

    if (otherCellars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous n\'avez pas d\'autre cave configurée. Créez-en une nouvelle depuis le sélecteur de cave !'),
        ),
      );
      return;
    }

    String? targetCellarId;
    final first = otherCellars.first;
    final cMap = first['cellars'];
    targetCellarId = cMap is Map ? cMap['id']?.toString() : first['cellar_id']?.toString();
    int qtyToMove = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.drive_file_move, color: Colors.blue),
              SizedBox(width: 8),
              Text('Déplacer vers une cave'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vin : ${bottle.wine?.name ?? "Vin"} (${bottle.quantity} en stock)'),
              const SizedBox(height: 16),
              const Text('Sélectionner la cave de destination :', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: targetCellarId,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: otherCellars.map((c) {
                  final map = c['cellars'];
                  final id = map is Map ? map['id']?.toString() : c['cellar_id']?.toString();
                  final name = map is Map ? map['name']?.toString() : 'Cave';
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(name ?? 'Cave'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => targetCellarId = val);
                },
              ),
              if (bottle.quantity > 1) ...[
                const SizedBox(height: 16),
                Text('Quantité à déplacer : $qtyToMove / ${bottle.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.remove),
                      onPressed: qtyToMove > 1 ? () => setDlgState(() => qtyToMove--) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$qtyToMove', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      onPressed: qtyToMove < bottle.quantity ? () => setDlgState(() => qtyToMove++) : null,
                    ),
                    TextButton(
                      onPressed: () => setDlgState(() => qtyToMove = bottle.quantity),
                      child: const Text('Tout'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: targetCellarId == null
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.of(context).pop();
                      await repo.moveBottleToCellar(
                        bottleId: bottle.id,
                        sourceCellarId: cellarId,
                        targetCellarId: targetCellarId!,
                        quantityToMove: qtyToMove,
                      );
                      notifyCellarChanged(ref, cellarId);
                      notifyCellarChanged(ref, targetCellarId);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('🚚 $qtyToMove bouteille(s) déplacée(s) avec succès !'),
                          backgroundColor: Colors.blue.shade800,
                        ),
                      );
                    },
              child: const Text('Déplacer'),
            ),
          ],
        ),
      ),
    );
  }
}
