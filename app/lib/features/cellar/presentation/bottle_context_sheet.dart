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
import '../../../shared/utils/langue.dart';

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
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final wine = bottle.wine;
    final wineName = wine?.name ?? (trSi(isFr, 'Vin', 'Wine'));
    final vintage = wine?.vintage != null ? '${wine!.vintage}' : (trSi(isFr, 'NM', 'NV'));
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
                                  wine?.producer ?? (trSi(isFr, 'Producteur non renseigné', 'Unknown Producer')),
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
                                  trSi(isFr, 'Stock : {quantity}', 'Stock: {quantity}', {'quantity': bottle.quantity}),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (bottle.rack != null && bottle.rack!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  trSi(isFr, 'Casier {rack}', 'Rack {rack}', {'rack': bottle.rack}),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (wine != null && !wine.isSpirit && !wine.tracksFillLevel && !bottle.tracksFillLevel)
                                MaturityColorbar(wine: wine, width: 70, height: 6),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bottle.getProvenanceDisplay(isFr),
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
                  title: Text(trSi(isFr, 'Sortir / Boire cette bouteille', 'Checkout / Drink this bottle'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(bottle.quantity > 1
                      ? (trSi(isFr, 'Déguster 1 ou plusieurs bouteilles ({quantity} dispo)', 'Taste 1 or more bottles ({quantity} available)', {'quantity': bottle.quantity}))
                      : (trSi(isFr, 'Enregistrer la dégustation dans le journal', 'Log tasting in journal'))),
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
                title: Text(trSi(isFr, 'Mode Sommelier à Table', 'Table Sommelier Mode'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                subtitle: Text(trSi(isFr, 'Minuteur de carafage & fiche express de dégustation', 'Decanting timer & express tasting card')),
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
                  title: Text(trSi(isFr, 'Ajouter des bouteilles au stock', 'Add bottles to stock'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(trSi(isFr, '+1, +2, carton de 6, caisse de 12...', '+1, +2, case of 6, crate of 12...')),
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
                  title: Text(trSi(isFr, 'Déplacer vers une autre cave', 'Move to another cellar'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(trSi(isFr, 'Transférer tout ou partie du stock (ex: vers Vosges, Londres...)', 'Transfer all or part of the stock to another cellar')),
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
                title: Text(trSi(isFr, 'Demander conseil à Chatmelier', 'Ask Chatmelier for advice'), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(trSi(isFr, 'Accords mets-vins, apogée, température de service...', 'Food & wine pairing, peak, serving temperature...')),
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
                title: Text(trSi(isFr, 'Voir la fiche détaillée', 'View detailed card'), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(trSi(isFr, 'Terroir, carte, notes de dégustation, historique de prix', 'Terroir, map, tasting notes, price history')),
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
                  title: Text(
                    trSi(isFr, 'Supprimer définitivement', 'Permanently delete'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  subtitle: Text(trSi(isFr, 'Effacer toute trace (erreur, casse, doublon)', 'Erase record (error, broken, duplicate)')),
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
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.add_circle_outline, color: Colors.green),
              const SizedBox(width: 8),
              Text(trSi(isFr, 'Ajouter au stock', 'Add to stock')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trSi(isFr, 'Combien de bouteilles de "{v1}" souhaitez-vous ajouter ?', 'How many bottles of "{v2}" would you like to add?', {'v1': bottle.wine?.name ?? "ce vin", 'v2': bottle.wine?.name ?? "this wine"}),
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
                    label: Text(trSi(isFr, '+6 (Carton)', '+6 (Case)')),
                    onPressed: () => setDlgState(() => qtyToAdd = 6),
                  ),
                  ActionChip(
                    label: Text(trSi(isFr, '+12 (Caisse)', '+12 (Crate)')),
                    onPressed: () => setDlgState(() => qtyToAdd = 12),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(trSi(isFr, 'Annuler', 'Cancel')),
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
                    content: Text(trSi(isFr, '🍾 +{qtyToAdd} bouteille(s) ajoutée(s) au stock !', '🍾 +{qtyToAdd} bottle(s) added to stock!', {'qtyToAdd': qtyToAdd})),
                    backgroundColor: Colors.green.shade800,
                  ),
                );
              },
              child: Text(trSi(isFr, 'Ajouter', 'Add')),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveCellarDialog(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(cellarRepositoryProvider);
    final userCellars = await repo.getUserCellarsWithRole();
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final otherCellars = userCellars.where((c) {
      final cMap = c['cellars'];
      final id = cMap is Map ? cMap['id']?.toString() : c['cellar_id']?.toString();
      return id != null && id != cellarId;
    }).toList();

    if (!context.mounted) return;

    if (otherCellars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(trSi(isFr, 'Vous n\'avez pas d\'autre cave configurée. Créez-en une nouvelle depuis le sélecteur de cave !', 'You have no other cellar configured. Create a new one from the cellar switcher!')),
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
          title: Row(
            children: [
              const Icon(Icons.drive_file_move, color: Colors.blue),
              const SizedBox(width: 8),
              Text(trSi(isFr, 'Déplacer vers une cave', 'Move to cellar')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trSi(isFr, 'Vin : {v1} ({quantity} en stock)', 'Wine: {v2} ({quantity} in stock)', {'v1': bottle.wine?.name ?? "Vin", 'quantity': bottle.quantity, 'v2': bottle.wine?.name ?? "Wine"})),
              const SizedBox(height: 16),
              Text(
                trSi(isFr, 'Sélectionner la cave de destination :', 'Select destination cellar:'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: targetCellarId,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: otherCellars.map((c) {
                  final map = c['cellars'];
                  final id = map is Map ? map['id']?.toString() : c['cellar_id']?.toString();
                  final name = map is Map ? map['name']?.toString() : (trSi(isFr, 'Cave', 'Cellar'));
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(name ?? (trSi(isFr, 'Cave', 'Cellar'))),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => targetCellarId = val);
                },
              ),
              if (bottle.quantity > 1) ...[
                const SizedBox(height: 16),
                Text(
                  trSi(isFr, 'Quantité à déplacer : {qtyToMove} / {quantity}', 'Quantity to move: {qtyToMove} / {quantity}', {'qtyToMove': qtyToMove, 'quantity': bottle.quantity}),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
                      child: Text(trSi(isFr, 'Tout', 'All')),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(trSi(isFr, 'Annuler', 'Cancel')),
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
                          content: Text(trSi(isFr, '🚚 {qtyToMove} bouteille(s) déplacée(s) avec succès !', '🚚 {qtyToMove} bottle(s) moved successfully!', {'qtyToMove': qtyToMove})),
                          backgroundColor: Colors.blue.shade800,
                        ),
                      );
                    },
              child: Text(trSi(isFr, 'Déplacer', 'Move')),
            ),
          ],
        ),
      ),
    );
  }
}
