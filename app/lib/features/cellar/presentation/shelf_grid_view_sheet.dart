import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/bottle.dart';
import '../domain/cellar_furniture.dart';
import 'furniture_editor_dialog.dart';

class ShelfGridViewSheet extends ConsumerStatefulWidget {
  final String cellarId;
  final String? initialFurnitureId;
  final String? highlightedSlot; // e.g. 'A7'
  final Bottle? bottleToPlace; // If non-null, user is selecting a slot for this bottle

  const ShelfGridViewSheet({
    super.key,
    required this.cellarId,
    this.initialFurnitureId,
    this.highlightedSlot,
    this.bottleToPlace,
  });

  static Future<String?> show(
    BuildContext context, {
    required String cellarId,
    String? initialFurnitureId,
    String? highlightedSlot,
    Bottle? bottleToPlace,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ShelfGridViewSheet(
        cellarId: cellarId,
        initialFurnitureId: initialFurnitureId,
        highlightedSlot: highlightedSlot,
        bottleToPlace: bottleToPlace,
      ),
    );
  }

  @override
  ConsumerState<ShelfGridViewSheet> createState() => _ShelfGridViewSheetState();
}

class _ShelfGridViewSheetState extends ConsumerState<ShelfGridViewSheet> with SingleTickerProviderStateMixin {
  String? _selectedFurnitureId;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedFurnitureId = widget.initialFurnitureId;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getWineCapColor(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('red') || t.contains('rouge')) return const Color(0xFF8B1E3F);
    if (t.contains('white') || t.contains('blanc')) return const Color(0xFFE2C968);
    if (t.contains('ros')) return const Color(0xFFE88E9B);
    if (t.contains('spark') || t.contains('efferv') || t.contains('champ')) return const Color(0xFFD4AF37);
    if (t.contains('spirit') || t.contains('whisky') || t.contains('rhum') || t.contains('cognac')) {
      return const Color(0xFFC07028);
    }
    return const Color(0xFF7A4B92);
  }

  Future<void> _handleSlotTap({
    required CellarFurniture furniture,
    required String slotCode,
    required Bottle? occupantBottle,
    required List<Bottle> allBottles,
  }) async {
    final repo = ref.read(cellarRepositoryProvider);

    // MODE 1: Bottle placement mode
    if (widget.bottleToPlace != null) {
      final target = widget.bottleToPlace!;

      if (furniture.isCupboard) {
        // Loose cupboard storage: bottles can coexist freely on the same shelf without collisions or swaps
        try {
          await repo.assignBottleToSlot(
            bottleId: target.id,
            furnitureId: furniture.id,
            slot: slotCode,
          );
          notifyCellarChanged(ref, widget.cellarId);
          if (mounted) {
            Navigator.of(context).pop(slotCode);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Bouteille rangée dans ${furniture.name} (${CellarFurniture.describeSlotCode(slotCode)})'),
                backgroundColor: const Color(0xFF2E7D32),
              ),
            );
          }
        } catch (e) {
          AppLogger.error('SHELF', 'Cupboard assign failed', e);
        }
        return;
      }

      if (occupantBottle != null && occupantBottle.id != target.id) {
        // Clash detected! Propose Swap
        final doSwap = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.swap_horiz, color: Color(0xFFD4AF37), size: 28),
                const SizedBox(width: 8),
                Text('Emplacement $slotCode occupé'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cet emplacement contient déjà :',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getWineCapColor(occupantBottle.wine?.type),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              occupantBottle.wine?.name ?? 'Bouteille en cave',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (occupantBottle.wine?.producer != null)
                              Text(
                                occupantBottle.wine!.producer!,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  target.furnitureSlot != null
                      ? 'Souhaitez-vous échanger les places entre ces deux bouteilles ?'
                      : 'Souhaitez-vous placer "${target.wine?.name ?? 'cette bouteille'}" ici et déplacer l\'autre ?',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Échanger les places (Swap)'),
              ),
            ],
          ),
        );

        if (doSwap == true) {
          try {
            await repo.assignBottleToSlot(
              bottleId: target.id,
              furnitureId: furniture.id,
              slot: slotCode,
              previousFurnitureId: target.furnitureId,
              previousSlot: target.furnitureSlot,
              existingOccupantBottleId: occupantBottle.id,
              allowSwap: true,
            );
            notifyCellarChanged(ref, widget.cellarId);
            if (mounted) {
              Navigator.of(context).pop(slotCode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🔄 Bouteilles échangées : $slotCode'),
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              );
            }
          } catch (e) {
            AppLogger.error('SHELF', 'Swap failed', e);
          }
        }
        return;
      }

      // Slot is empty -> Assign directly!
      try {
        await repo.assignBottleToSlot(
          bottleId: target.id,
          furnitureId: furniture.id,
          slot: slotCode,
        );
        notifyCellarChanged(ref, widget.cellarId);
        if (mounted) {
          Navigator.of(context).pop(slotCode);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Bouteille assignée en $slotCode (${furniture.name})'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        }
      } catch (e) {
        AppLogger.error('SHELF', 'Slot assign failed', e);
      }
      return;
    }

    // MODE 2: Explore / view mode
    if (occupantBottle != null) {
      _showOccupantDetails(occupantBottle, slotCode);
    } else {
      // Empty slot -> Offer to place a bottle from cellar
      _showPickBottleForSlotSheet(furniture: furniture, slotCode: slotCode, allBottles: allBottles);
    }
  }

  void _showOccupantDetails(Bottle occupantBottle, String slotCode) {
    final repo = ref.read(cellarRepositoryProvider);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Emplacement ${CellarFurniture.describeSlotCode(slotCode)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9A7B1C)),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getWineCapColor(occupantBottle.wine?.type).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      occupantBottle.sizeBadgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getWineCapColor(occupantBottle.wine?.type),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                occupantBottle.wine?.name ?? 'Vin en cave',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (occupantBottle.wine?.producer != null)
                Text(
                  occupantBottle.wine!.producer!,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: const Text('Libérer la place'),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await repo.assignBottleToSlot(
                          bottleId: occupantBottle.id,
                          furnitureId: null,
                          slot: null,
                        );
                        notifyCellarChanged(ref, widget.cellarId);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Voir la fiche'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.push('/bottle/${occupantBottle.id}');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCupboardView(
    BuildContext context,
    CellarFurniture furniture,
    List<Bottle> allBottles,
    bool isDark,
    ThemeData theme,
  ) {
    final cupboardBottles = allBottles.where((b) => b.furnitureId == furniture.id).toList();

    final Map<int, List<Bottle>> bottlesByShelf = {};
    for (int r = 0; r < furniture.rows; r++) {
      bottlesByShelf[r] = [];
    }
    for (final b in cupboardBottles) {
      int r = 0;
      if (b.furnitureSlot != null && b.furnitureSlot!.isNotEmpty) {
        final match = RegExp(r'R(\d+)', caseSensitive: false).firstMatch(b.furnitureSlot!);
        if (match != null) {
          r = (int.tryParse(match.group(1)!) ?? 1) - 1;
        } else {
          final numMatch = RegExp(r'\d+').firstMatch(b.furnitureSlot!);
          if (numMatch != null) {
            r = (int.tryParse(numMatch.group(0)!) ?? 1) - 1;
          }
        }
      }
      if (r < 0) r = 0;
      if (r >= furniture.rows) r = furniture.rows - 1;
      bottlesByShelf[r]!.add(b);
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C22) : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1E3F).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.kitchen_outlined, color: Color(0xFF8B1E3F), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${furniture.name} • ${furniture.rows} niveau${furniture.rows > 1 ? "x" : ""}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Rangement libre : déposez vos bouteilles sans contrainte d\'emplacement précis.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(furniture.rows, (r) {
            final shelfSlotCode = 'Étagère ${r + 1}';
            final shelfBottles = bottlesByShelf[r] ?? [];
            final isHighlighted = widget.highlightedSlot != null &&
                (widget.highlightedSlot!.trim().toLowerCase() == shelfSlotCode.toLowerCase() ||
                    widget.highlightedSlot!.toUpperCase() == CellarFurniture.slotCode(0, r) ||
                    widget.highlightedSlot!.toUpperCase().contains('R${r + 1}') ||
                    RegExp(r'\d+').firstMatch(widget.highlightedSlot!)?.group(0) == '${r + 1}');

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2830) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHighlighted
                      ? const Color(0xFFD4AF37)
                      : theme.dividerColor.withValues(alpha: 0.4),
                  width: isHighlighted ? 2.2 : 1,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.table_rows_outlined, size: 16, color: Color(0xFFD4AF37)),
                        const SizedBox(width: 6),
                        Text(
                          'Étagère / Niveau ${r + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${shelfBottles.length} bouteille${shelfBottles.length > 1 ? "s" : ""}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9A7B1C)),
                          ),
                        ),
                        const Spacer(),
                        if (widget.bottleToPlace != null)
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              backgroundColor: const Color(0xFF8B1E3F),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Déposer ici', style: TextStyle(fontSize: 12)),
                            onPressed: () => _handleSlotTap(
                              furniture: furniture,
                              slotCode: shelfSlotCode,
                              occupantBottle: null,
                              allBottles: allBottles,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    height: 4,
                    width: double.infinity,
                    color: const Color(0xFFB08968),
                  ),
                  if (shelfBottles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Étagère vide',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: shelfBottles.map((b) {
                          final isTarget = widget.highlightedSlot != null && b.furnitureSlot == widget.highlightedSlot;
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              _showOccupantDetails(b, b.furnitureSlot ?? shelfSlotCode);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: isTarget
                                    ? const Color(0xFFD4AF37).withValues(alpha: 0.25)
                                    : (isDark ? Colors.white10 : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isTarget
                                      ? const Color(0xFFD4AF37)
                                      : _getWineCapColor(b.wine?.type).withValues(alpha: 0.4),
                                  width: isTarget ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getWineCapColor(b.wine?.type),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 140),
                                    child: Text(
                                      b.wine?.name ?? 'Bouteille',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isTarget ? FontWeight.bold : FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (b.wine?.vintage != null) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '${b.wine!.vintage}',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showPickBottleForSlotSheet({
    required CellarFurniture furniture,
    required String slotCode,
    required List<Bottle> allBottles,
  }) {
    final unassigned = allBottles.where((b) => b.furnitureSlot == null || b.furnitureSlot!.isEmpty).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Ranger une bouteille en $slotCode',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: unassigned.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Toutes vos bouteilles ont déjà un emplacement attitré.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: unassigned.length,
                      itemBuilder: (_, i) {
                        final b = unassigned[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getWineCapColor(b.wine?.type),
                            radius: 14,
                            child: const Icon(Icons.wine_bar, size: 14, color: Colors.white),
                          ),
                          title: Text(b.wine?.name ?? 'Bouteille', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(b.wine?.producer ?? ''),
                          trailing: Text(b.sizeBadgeLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            final repo = ref.read(cellarRepositoryProvider);
                            await repo.assignBottleToSlot(
                              bottleId: b.id,
                              furnitureId: furniture.id,
                              slot: slotCode,
                            );
                            notifyCellarChanged(ref, widget.cellarId);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final furnitureAsync = ref.watch(cellarFurnitureProvider(widget.cellarId));
    final bottlesAsync = ref.watch(bottlesProvider(widget.cellarId));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => furnitureAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (furnitures) {
          if (furnitures.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shelves, size: 64, color: Color(0xFFD4AF37)),
                    const SizedBox(height: 16),
                    Text('Aucun meuble de cave déclaré', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Déclarez vos casiers, étagères ou meubles pour modéliser précisément votre cave.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un premier meuble'),
                      onPressed: () async {
                        final created = await FurnitureEditorDialog.show(context, cellarId: widget.cellarId);
                        if (created != null && mounted) {
                          setState(() => _selectedFurnitureId = created.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          // Active furniture
          final currentFurniture = furnitures.firstWhere(
            (f) => f.id == _selectedFurnitureId,
            orElse: () => furnitures.first,
          );

          final allBottles = bottlesAsync.value ?? [];
          // Build occupancy map for current furniture: slotCode -> Bottle
          final Map<String, Bottle> slotOccupants = {};
          for (final b in allBottles) {
            if (b.furnitureId == currentFurniture.id && b.furnitureSlot != null && b.furnitureSlot!.isNotEmpty) {
              slotOccupants[b.furnitureSlot!.toUpperCase()] = b;
            }
          }

          return Column(
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header: Title & Furniture Switcher
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shelves, color: Color(0xFF8B1E3F), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentFurniture.id,
                          isExpanded: true,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          items: furnitures.map((f) {
                            final label = f.isCupboard
                                ? '${f.name} (${f.rows} niveau${f.rows > 1 ? "x" : ""})'
                                : '${f.name} (${f.columns}x${f.rows})';
                            return DropdownMenuItem(
                              value: f.id,
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) setState(() => _selectedFurnitureId = id);
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Modifier ce meuble',
                      onPressed: () => FurnitureEditorDialog.show(
                        context,
                        initialFurniture: currentFurniture,
                        cellarId: widget.cellarId,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 22),
                      tooltip: 'Nouveau meuble',
                      onPressed: () async {
                        final created = await FurnitureEditorDialog.show(context, cellarId: widget.cellarId);
                        if (created != null && mounted) {
                          setState(() => _selectedFurnitureId = created.id);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Highlight Banner if active
              if (widget.highlightedSlot != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Emplacement : ${widget.highlightedSlot} (${currentFurniture.name})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Placement hint banner if user is placing a bottle
              if (widget.bottleToPlace != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app, color: Color(0xFF8B1E3F), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Touchez un casier pour y ranger "${widget.bottleToPlace!.wine?.name ?? 'la bouteille'}"',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 12),

              // 2D Block Matrix or Cupboard View
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: currentFurniture.isCupboard
                        ? _buildCupboardView(context, currentFurniture, allBottles, isDark, theme)
                        : Container(
                            constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F5F0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Column Headers (A, B, C...)
                          Row(
                            children: [
                              const SizedBox(width: 28), // Row label spacing
                              ...List.generate(currentFurniture.columns, (c) {
                                return Expanded(
                                  child: Text(
                                    String.fromCharCode(65 + c),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Grid of Slots
                          ...List.generate(currentFurniture.rows, (r) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  // Row Header (1, 2, 3...)
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${r + 1}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  // Slots in row
                                  ...List.generate(currentFurniture.columns, (c) {
                                    final isActive = currentFurniture.isSlotActive(c, r);
                                    final slotCode = CellarFurniture.slotCode(c, r);
                                    final occupant = slotOccupants[slotCode];
                                    final isHighlighted = widget.highlightedSlot?.toUpperCase() == slotCode;

                                    if (!isActive) {
                                      // Void slot (e.g. Inactive corner in triangle or staggered)
                                      return Expanded(
                                        child: Container(
                                          height: 48,
                                          margin: const EdgeInsets.symmetric(horizontal: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                      );
                                    }

                                    Widget cellContent;
                                    if (occupant != null) {
                                      final capColor = _getWineCapColor(occupant.wine?.type);
                                      cellContent = Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: capColor,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: capColor.withValues(alpha: 0.4),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.circle, size: 6, color: Colors.white70),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            slotCode,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      cellContent = Text(
                                        slotCode,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade400,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    }

                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () => _handleSlotTap(
                                          furniture: currentFurniture,
                                          slotCode: slotCode,
                                          occupantBottle: occupant,
                                          allBottles: allBottles,
                                        ),
                                        child: AnimatedBuilder(
                                          animation: _pulseAnimation,
                                          builder: (context, child) {
                                            final scale = isHighlighted ? _pulseAnimation.value : 1.0;
                                            return Transform.scale(
                                              scale: scale,
                                              child: Container(
                                                height: 48,
                                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                                decoration: BoxDecoration(
                                                  color: occupant != null
                                                      ? (isDark ? const Color(0xFF2E2428) : const Color(0xFFF9F1F3))
                                                      : (isDark ? Colors.white10 : Colors.white),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isHighlighted
                                                        ? const Color(0xFFD4AF37)
                                                        : (occupant != null
                                                            ? const Color(0xFF8B1E3F).withValues(alpha: 0.6)
                                                            : theme.dividerColor.withValues(alpha: 0.3)),
                                                    width: isHighlighted ? 2.5 : 1,
                                                  ),
                                                  boxShadow: isHighlighted
                                                      ? [
                                                          BoxShadow(
                                                            color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                                                            blurRadius: 8,
                                                            spreadRadius: 1,
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                                child: Center(child: child),
                                              ),
                                            );
                                          },
                                          child: cellContent,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendDot(const Color(0xFF8B1E3F), 'Rouge'),
                    const SizedBox(width: 12),
                    _buildLegendDot(const Color(0xFFE2C968), 'Blanc'),
                    const SizedBox(width: 12),
                    _buildLegendDot(const Color(0xFFE88E9B), 'Rosé'),
                    const SizedBox(width: 12),
                    _buildLegendDot(const Color(0xFFD4AF37), 'Champagne'),
                    const SizedBox(width: 12),
                    _buildLegendDot(const Color(0xFFC07028), 'Spiritueux'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
