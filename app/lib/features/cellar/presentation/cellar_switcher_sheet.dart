import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/cellar_provider.dart';
import 'create_cellar_dialog.dart';
import 'edit_cellar_dialog.dart';
import '../domain/cellar.dart';

class CellarSwitcherSheet extends ConsumerWidget {
  const CellarSwitcherSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CellarSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cellarsAsync = ref.watch(userCellarsProvider);
    final currentCellarId = ref.watch(currentCellarIdProvider);
    final theme = Theme.of(context);
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFr ? 'Mes Caves à Vin' : 'My Wine Cellars',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isFr
                ? 'Basculez facilement entre vos différentes caves ou celles partagées avec vous.'
                : 'Easily switch between your wine cellars or those shared with you.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),

          // Cellars List
          cellarsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${isFr ? "Erreur" : "Error"} : $err'),
            ),
            data: (rawCellars) {
              // Deduplicate cellars by ID (prefer admin/owner role if present)
              final Map<String, Map<String, dynamic>> uniqueMap = {};
              for (final c in rawCellars) {
                final cMap = c['cellars'] is Map<String, dynamic> ? c['cellars'] as Map<String, dynamic> : c;
                final id = (cMap['id'] ?? c['cellar_id'] ?? '').toString();
                if (id.isEmpty) continue;
                if (!uniqueMap.containsKey(id) || c['role'] == 'admin') {
                  uniqueMap[id] = c;
                }
              }
              final cellars = uniqueMap.values.toList();

              if (cellars.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(isFr ? 'Aucune cave trouvée.' : 'No cellars found.'),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cellars.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = cellars[index];
                  final cellarMap = item['cellars'] is Map<String, dynamic>
                      ? item['cellars'] as Map<String, dynamic>
                      : item;
                  final cellar = Cellar.fromJson(cellarMap);
                  final cellarId = cellar.id.isNotEmpty ? cellar.id : (item['cellar_id'] ?? '').toString();
                  final name = cellar.displayName;
                  final locationName = cellar.locationName;
                  final role = item['role'] as String? ?? 'editor';
                  final isSelected = cellarId == currentCellarId;

                  String roleLabel;
                  Color roleColor;
                  IconData roleIcon;

                  if (role == 'admin') {
                    roleLabel = isFr ? 'Propriétaire' : 'Owner';
                    roleColor = const Color(0xFF8B1E3F);
                    roleIcon = Icons.stars;
                  } else if (role == 'editor') {
                    roleLabel = isFr ? 'Lecture & Écriture' : 'Read & Write';
                    roleColor = const Color(0xFF2E7D32);
                    roleIcon = Icons.edit_note;
                  } else {
                    roleLabel = isFr ? 'Lecture seule' : 'Read-only';
                    roleColor = const Color(0xFF6B7280);
                    roleIcon = Icons.visibility;
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ref.read(currentCellarIdProvider.notifier).state = cellarId;
                      ref.invalidate(bottlesProvider(cellarId));
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B1E3F).withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF8B1E3F).withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.wine_bar,
                              color: isSelected
                                  ? const Color(0xFF8B1E3F)
                                  : theme.iconTheme.color,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: roleColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: roleColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(roleIcon, size: 12, color: roleColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            roleLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: roleColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (locationName != null && locationName.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_city_outlined,
                                            size: 12,
                                            color: theme.textTheme.bodySmall?.color,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            locationName,
                                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    if (cellar.hasWifi)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.wifi, size: 12, color: Color(0xFF1976D2)),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Wi-Fi : "${cellar.wifiSsid!}"',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF1976D2), fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    if (cellar.hasGpsLocation)
                                      const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.pin_drop, size: 12, color: Color(0xFF2E7D32)),
                                          SizedBox(width: 2),
                                          Text(
                                            'GPS',
                                            style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            tooltip: isFr ? 'Options de la cave' : 'Cellar options',
                            onSelected: (action) {
                              if (action == 'share') {
                                Navigator.of(context).pop();
                                context.push(
                                  '/sharing/$cellarId?name=${Uri.encodeComponent(name)}',
                                );
                              } else if (action == 'edit') {
                                EditCellarDialog.show(context, cellar);
                              } else if (action == 'delete') {
                                _showDeleteCellarDialog(
                                  context,
                                  ref,
                                  cellarId: cellarId,
                                  cellarName: name,
                                  isSelected: isSelected,
                                );
                              } else if (action == 'leave') {
                                _showLeaveCellarDialog(
                                  context,
                                  ref,
                                  cellarId: cellarId,
                                  cellarName: name,
                                  isSelected: isSelected,
                                );
                              }
                            },
                            itemBuilder: (ctx) => [
                              if (role == 'admin') ...[
                                PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.share_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Text(isFr ? 'Partages & Accès' : 'Sharing & Access'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.settings_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Text(isFr ? 'Gérer / Paramètres' : 'Manage / Settings'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_forever_outlined, size: 18, color: Colors.redAccent),
                                      const SizedBox(width: 8),
                                      Text(
                                        isFr ? 'Supprimer la cave' : 'Delete cellar',
                                        style: const TextStyle(color: Colors.redAccent),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                PopupMenuItem(
                                  value: 'leave',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.logout, size: 18, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      Text(
                                        isFr ? 'Retirer de mes caves' : 'Remove from my cellars',
                                        style: const TextStyle(color: Colors.orange),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF8B1E3F),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Add New Cellar Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (ctx) => const CreateCellarDialog(),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(isFr ? 'Créer une nouvelle cave' : 'Create a new cellar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteCellarDialog(
    BuildContext context,
    WidgetRef ref, {
    required String cellarId,
    required String cellarName,
    required bool isSelected,
  }) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(child: Text(isFr ? 'Supprimer "$cellarName" ?' : 'Delete "$cellarName"?')),
          ],
        ),
        content: Text(
          isFr
              ? 'Attention : Vous êtes le propriétaire de cette cave. La cave et toutes ses bouteilles seront définitivement supprimées pour vous et pour tous les utilisateurs avec qui elle est partagée. Cette action est irréversible.'
              : 'Warning: You are the owner of this cellar. This cellar and all its bottles will be permanently deleted for you and for all members it is shared with. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isFr ? 'Annuler' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Close sheet

              await ref.read(cellarRepositoryProvider).deleteCellar(cellarId);

              if (isSelected) {
                ref.read(currentCellarIdProvider.notifier).state = null;
              }
              ref.invalidate(userCellarsProvider);
              ref.invalidate(bottlesProvider(null));

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFr
                          ? 'Cave "$cellarName" supprimée définitivement'
                          : 'Cellar "$cellarName" permanently deleted',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(isFr ? 'Supprimer définitivement' : 'Delete permanently'),
          ),
        ],
      ),
    );
  }

  void _showLeaveCellarDialog(
    BuildContext context,
    WidgetRef ref, {
    required String cellarId,
    required String cellarName,
    required bool isSelected,
  }) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(isFr ? 'Retirer "$cellarName" ?' : 'Remove "$cellarName"?')),
          ],
        ),
        content: Text(
          isFr
              ? 'Cette cave partagée ne sera plus visible dans votre application.\n\n'
                  'Les bouteilles et données restent intactes pour le propriétaire et ses autres membres.'
              : 'This shared cellar will no longer be visible in your application.\n\n'
                  'Bottles and cellar data remain intact for the owner and other members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isFr ? 'Annuler' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Close sheet

              await ref.read(cellarRepositoryProvider).leaveCellar(cellarId);

              if (isSelected) {
                ref.read(currentCellarIdProvider.notifier).state = null;
              }
              ref.invalidate(userCellarsProvider);
              ref.invalidate(bottlesProvider(null));

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFr
                          ? 'Cave "$cellarName" retirée de votre vue'
                          : 'Cellar "$cellarName" removed from your view',
                    ),
                    backgroundColor: Colors.orange.shade800,
                  ),
                );
              }
            },
            child: Text(isFr ? 'Retirer de ma vue' : 'Remove from my view'),
          ),
        ],
      ),
    );
  }
}
