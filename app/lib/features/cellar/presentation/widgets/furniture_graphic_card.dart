import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/cellar_provider.dart';
import '../../domain/bottle.dart';
import '../../domain/cellar_furniture.dart';
import '../shelf_grid_view_sheet.dart';

/// A visual and written representation of a bottle's location in cellar furniture.
/// Supports both rigid grid racks (with slot codes like A7) and loose cupboards
/// (where bottles are stored in bulk without rigid coordinates).
class FurnitureGraphicCard extends ConsumerWidget {
  final Bottle bottle;
  final VoidCallback? onEditRequested;
  final VoidCallback? onUnassignRequested;

  const FurnitureGraphicCard({
    super.key,
    required this.bottle,
    this.onEditRequested,
    this.onUnassignRequested,
  });

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFr = Localizations.localeOf(context).languageCode != 'en';

    final furnituresAsync = ref.watch(cellarFurnitureProvider(bottle.cellarId));
    final bottlesAsync = ref.watch(bottlesProvider(bottle.cellarId));

    final furnitures = furnituresAsync.value ?? [];
    final allBottles = bottlesAsync.value ?? [];

    final furniture = furnitures.where((f) => f.id == bottle.furnitureId).firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C22) : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Written details header
          _buildWrittenDetails(context, furniture, isFr),
          const SizedBox(height: 14),

          // 2. Embedded furniture graphic
          if (furniture != null) ...[
            if (furniture.isCupboard)
              _buildCupboardGraphic(context, furniture, allBottles, isFr)
            else
              _buildRackGridGraphic(context, furniture, allBottles)
          ] else if (bottle.rack != null || bottle.shelf != null || bottle.position != null || bottle.furnitureSlot != null) ...[
            _buildManualCoordinatesGraphic(context, isFr),
          ],

          const SizedBox(height: 14),

          // 3. Action Buttons
          Row(
            children: [
              if (furniture != null) ...[
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.fullscreen, size: 18),
                    label: Text(isFr ? 'Vue rayonnage' : 'Shelf view'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                      foregroundColor: const Color(0xFF8B1E3F),
                    ),
                    onPressed: () async {
                      await ShelfGridViewSheet.show(
                        context,
                        cellarId: bottle.cellarId,
                        initialFurnitureId: furniture.id,
                        highlightedSlot: bottle.furnitureSlot,
                      );
                      onEditRequested?.call();
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                  label: Text(isFr ? 'Déplacer' : 'Move'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                  ),
                  onPressed: onEditRequested ??
                      () async {
                        await ShelfGridViewSheet.show(
                          context,
                          cellarId: bottle.cellarId,
                          bottleToPlace: bottle,
                          initialFurnitureId: furniture?.id,
                        );
                      },
                ),
              ),
              if (onUnassignRequested != null) ...[
                const SizedBox(width: 8),
                IconButton.outlined(
                  icon: const Icon(Icons.location_off_outlined, size: 18, color: Colors.redAccent),
                  tooltip: isFr ? 'Retirer du meuble' : 'Remove from furniture',
                  onPressed: onUnassignRequested,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWrittenDetails(BuildContext context, CellarFurniture? furniture, bool isFr) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String furnitureName = furniture?.name ?? (bottle.rack != null ? (isFr ? 'Casier ${bottle.rack}' : 'Rack ${bottle.rack}') : (isFr ? 'Emplacement en cave' : 'Cellar location'));
    final String shapeTypeLabel = furniture != null ? furniture.getShapeTypeName(isFr) : (isFr ? 'Emplacement manuel' : 'Manual location');

    String detailedLocationText = '';
    if (furniture != null) {
      if (furniture.isCupboard) {
        if (bottle.furnitureSlot != null && bottle.furnitureSlot!.isNotEmpty) {
          final slot = bottle.furnitureSlot!;
          final lower = slot.trim().toLowerCase();
          if (lower.startsWith('etagere') || lower.startsWith('étagère') || lower.startsWith('niveau') || lower.startsWith('shelf')) {
            detailedLocationText = slot.trim();
          } else {
            final parsed = CellarFurniture.parseSlotCode(slot);
            if (parsed != null) {
              detailedLocationText = isFr ? 'Étagère ${parsed.row + 1}' : 'Shelf ${parsed.row + 1}';
            } else {
              final numMatch = RegExp(r'\d+').firstMatch(slot);
              if (numMatch != null) {
                detailedLocationText = isFr ? 'Étagère ${numMatch.group(0)}' : 'Shelf ${numMatch.group(0)}';
              } else {
                detailedLocationText = isFr ? 'Rangement libre dans le meuble' : 'Free storage in furniture';
              }
            }
          }
        } else {
          detailedLocationText = isFr ? 'Rangement libre dans le meuble' : 'Free storage in furniture';
        }
      } else {
        if (bottle.furnitureSlot != null && bottle.furnitureSlot!.isNotEmpty) {
          detailedLocationText = CellarFurniture.describeSlotCode(bottle.furnitureSlot!, isFr);
        } else {
          detailedLocationText = isFr ? 'Dans le casier' : 'In the rack';
        }
      }
    } else {
      final parts = <String>[];
      if (bottle.furnitureSlot != null && bottle.furnitureSlot!.isNotEmpty) {
        parts.add(CellarFurniture.describeSlotCode(bottle.furnitureSlot!, isFr));
      }
      if (bottle.rack != null && bottle.rack!.isNotEmpty) parts.add(isFr ? 'Casier : ${bottle.rack}' : 'Rack: ${bottle.rack}');
      if (bottle.shelf != null && bottle.shelf!.isNotEmpty) parts.add(isFr ? 'Tablette : ${bottle.shelf}' : 'Shelf: ${bottle.shelf}');
      if (bottle.position != null && bottle.position!.isNotEmpty) parts.add(isFr ? 'Position : ${bottle.position}' : 'Position: ${bottle.position}');
      detailedLocationText = parts.isNotEmpty ? parts.join('  •  ') : (isFr ? 'Emplacement défini' : 'Location defined');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                furniture?.isCupboard == true ? Icons.kitchen_outlined : Icons.shelves,
                color: const Color(0xFFB58A14),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    furnitureName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    shapeTypeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF8A6D14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF8B1E3F)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detailedLocationText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Visual graphic for a Cupboard / Placard (bulk/loose storage without fixed coordinates)
  Widget _buildCupboardGraphic(BuildContext context, CellarFurniture furniture, List<Bottle> allBottles, bool isFr) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter bottles in this cupboard
    final cupboardBottles = allBottles.where((b) => b.furnitureId == furniture.id).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282522) : const Color(0xFFECE5D8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8C7355), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cupboard top header bar
          Row(
            children: [
              const Icon(Icons.kitchen_outlined, size: 16, color: Color(0xFF8C7355)),
              const SizedBox(width: 6),
              Text(
                '${furniture.name} (${isFr ? "Rangement libre en vrac" : "Free bulk storage"})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF8C7355)),
              ),
              const Spacer(),
              Text(
                '${cupboardBottles.length} btl${cupboardBottles.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8C7355)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Shelves
          ...List.generate(furniture.rows, (rowIndex) {
            final shelfNum = rowIndex + 1;
            int? targetShelfIndex;
            if (bottle.furnitureSlot != null && bottle.furnitureSlot!.isNotEmpty) {
              final parsed = CellarFurniture.parseSlotCode(bottle.furnitureSlot!);
              if (parsed != null) {
                targetShelfIndex = parsed.row;
              } else {
                final match = RegExp(r'\d+').firstMatch(bottle.furnitureSlot!);
                if (match != null) {
                  targetShelfIndex = (int.tryParse(match.group(0)!) ?? 1) - 1;
                }
              }
            }
            final isTargetShelf = (targetShelfIndex != null && targetShelfIndex == rowIndex) ||
                (furniture.rows == 1) ||
                ((bottle.furnitureSlot == null || bottle.furnitureSlot == 'Placard') && rowIndex == 0);

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF8C7355), width: 4),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isFr ? 'Étagère $shelfNum' : 'Shelf $shelfNum',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // If this is the target shelf, show the target bottle prominently!
                        if (isTargetShelf)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wine_bar, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  bottle.wine?.name ?? (isFr ? 'Cette bouteille' : 'This bottle'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                        // Other bottles on this shelf or cupboard
                        ...cupboardBottles
                            .where((b) => b.id != bottle.id)
                            .take(5)
                            .map(
                              (ob) => Container(
                                width: 14,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: _getWineCapColor(ob.wine?.type),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                      ],
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

  /// Visual graphic for a grid Rack (rectangle, triangle, staggered, custom)
  Widget _buildRackGridGraphic(BuildContext context, CellarFurniture furniture, List<Bottle> allBottles) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final targetSlot = bottle.furnitureSlot?.toUpperCase();

    // Map occupants in this furniture
    final Map<String, Bottle> occupants = {};
    for (final b in allBottles) {
      if (b.furnitureId == furniture.id && b.furnitureSlot != null) {
        occupants[b.furnitureSlot!.toUpperCase()] = b;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141316) : const Color(0xFFF1EFEA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          // Column Headers (A, B, C...)
          Row(
            children: [
              const SizedBox(width: 22),
              ...List.generate(furniture.columns, (c) {
                return Expanded(
                  child: Text(
                    String.fromCharCode(65 + c),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 4),

          // Matrix
          ...List.generate(furniture.rows, (r) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${r + 1}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  ...List.generate(furniture.columns, (c) {
                    final isActive = furniture.isSlotActive(c, r);
                    final slotCode = CellarFurniture.slotCode(c, r);
                    final isTarget = targetSlot == slotCode;
                    final occupant = occupants[slotCode];

                    if (!isActive) {
                      return const Expanded(child: SizedBox(height: 24));
                    }

                    Color cellBg;
                    Border? cellBorder;
                    Widget? cellChild;

                    if (isTarget) {
                      cellBg = const Color(0xFFD4AF37);
                      cellBorder = Border.all(color: const Color(0xFF8B1E3F), width: 2);
                      cellChild = const Icon(Icons.wine_bar, size: 14, color: Colors.white);
                    } else if (occupant != null) {
                      cellBg = _getWineCapColor(occupant.wine?.type).withValues(alpha: 0.4);
                      cellChild = Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getWineCapColor(occupant.wine?.type),
                        ),
                      );
                    } else {
                      cellBg = isDark ? Colors.white10 : Colors.white;
                    }

                    return Expanded(
                      child: Container(
                        height: 26,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: cellBg,
                          borderRadius: BorderRadius.circular(4),
                          border: cellBorder ?? Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          boxShadow: isTarget
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(child: cellChild),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Visual representation when only manual text fields (rack, shelf, position) exist
  Widget _buildManualCoordinatesGraphic(BuildContext context, bool isFr) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222026) : const Color(0xFFF3EFE6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.grid_on, size: 24, color: Color(0xFF8B1E3F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFr ? 'Repères manuels enregistrés' : 'Saved manual coordinates',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  [
                    if (bottle.furnitureSlot != null && bottle.furnitureSlot!.isNotEmpty)
                      CellarFurniture.describeSlotCode(bottle.furnitureSlot!, isFr),
                    if (bottle.rack != null && bottle.rack!.isNotEmpty) (isFr ? 'Casier : ${bottle.rack}' : 'Rack: ${bottle.rack}'),
                    if (bottle.shelf != null && bottle.shelf!.isNotEmpty) (isFr ? 'Tablette : ${bottle.shelf}' : 'Shelf: ${bottle.shelf}'),
                    if (bottle.position != null && bottle.position!.isNotEmpty) (isFr ? 'Position : ${bottle.position}' : 'Position: ${bottle.position}'),
                  ].join(' • '),
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
