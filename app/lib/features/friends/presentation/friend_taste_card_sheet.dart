import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/phone_dial_code.dart';
import '../../../shared/widgets/owner_avatar.dart';
import '../data/friends_repository.dart';
import '../domain/friend.dart';
import '../../auth/domain/taste_profile.dart';
import '../../auth/domain/wine_taste_radar.dart';
import '../../auth/presentation/widgets/radar_legende.dart';
import '../../auth/presentation/widgets/wine_taste_radar_chart.dart';
import '../../../shared/utils/langue.dart';

class FriendTasteCardSheet extends ConsumerStatefulWidget {
  final Friend friend;

  const FriendTasteCardSheet({super.key, required this.friend});

  static Future<void> show(BuildContext context, Friend friend) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FriendTasteCardSheet(friend: friend),
    );
  }

  @override
  ConsumerState<FriendTasteCardSheet> createState() => _FriendTasteCardSheetState();
}

class _FriendTasteCardSheetState extends ConsumerState<FriendTasteCardSheet> {
  bool _isActionLoading = false;

  Future<void> _showRequestCellarAccessDialog() async {
    String selectedRole = 'viewer';
    final messageCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('🍷 ', style: TextStyle(fontSize: 22)),
              Expanded(
                child: Text(
                  tr('Demander l\'accès à la cave', 'Ask for cellar access'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Vous pouvez demander à {displayName} l\'accès à sa cave à vin. Une notification lui sera envoyée.', 'You can ask {displayName} for access to their wine cellar. They\'ll get a notification.', {'displayName': widget.friend.displayName}),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(tr('Niveau d\'accès souhaité :', 'Access you\'d like:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  value: 'viewer',
                  groupValue: selectedRole,
                  title: Text(tr('👁️ Consultation (Lecture seule)', '👁️ View only'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(tr('Voir les bouteilles, emplacements et apogées.', 'See bottles, where they are, and when they peak.'), style: const TextStyle(fontSize: 11)),
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                  activeColor: const Color(0xFF8B1E3F),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'editor',
                  groupValue: selectedRole,
                  title: Text(tr('✍️ Sommelier délégué (Écriture)', '✍️ Deputy sommelier (write)'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(tr('Ajouter, modifier ou consommer des bouteilles.', 'Add, edit or drink bottles.'), style: const TextStyle(fontSize: 11)),
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                  activeColor: const Color(0xFF8B1E3F),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  decoration: InputDecoration(
                    labelText: tr('Message facultatif', 'Message (optional)'),
                    hintText: tr('Ex: "Pour qu\'on gère nos bouteilles en commun !"', 'E.g. "So we can manage our bottles together!"'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('Annuler', 'Cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isActionLoading = true);
                try {
                  final repo = ref.read(friendsRepositoryProvider);
                  await repo.requestCellarAccess(
                    cellarId: widget.friend.friendCellarId,
                    ownerId: widget.friend.friendUserId,
                    requestedRole: selectedRole,
                    message: messageCtrl.text.trim().isNotEmpty ? messageCtrl.text.trim() : null,
                  );
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(tr('📬 Demande envoyée à {displayName} !', '📬 Request sent to {displayName}!', {'displayName': widget.friend.displayName})),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(tr('Erreur: {e}', 'Error: {e}', {'e': e})), backgroundColor: Colors.redAccent),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isActionLoading = false);
                }
              },
              child: Text(tr('Envoyer la demande', 'Send request'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    messageCtrl.dispose();
  }

  Future<void> _showGrantMyCellarDialog() async {
    final cellars = await ref.read(cellarRepositoryProvider).getUserCellarsWithRole();
    final ownedCellars = cellars.where((c) => c['role'] == 'admin').toList();

    if (!mounted) return;

    if (ownedCellars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Aucune cave propriétaire trouvée.', 'No cellar of yours found.'))),
      );
      return;
    }

    // Default: check the first cellar, others unchecked
    final Map<String, bool> selectedCellars = {};
    final Map<String, String> selectedRoles = {};

    for (int i = 0; i < ownedCellars.length; i++) {
      final c = ownedCellars[i];
      final cMap = c['cellars'] is Map<String, dynamic> ? c['cellars'] as Map<String, dynamic> : c;
      final cId = (cMap['id'] ?? c['cellar_id'] ?? '').toString();
      selectedCellars[cId] = (i == 0); // only first checked by default!
      selectedRoles[cId] = 'editor';
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final anySelected = selectedCellars.values.any((v) => v);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Color(0xFF8B1E3F), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Partager mes caves', 'Share my cellars'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        tr('avec {displayName}', 'with {displayName}', {'displayName': widget.friend.displayName}),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Choisissez quelle(s) cave(s) partager et l\'accès pour chacune :', 'Choose which cellar(s) to share, and the access for each:'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...ownedCellars.map((item) {
                    final cMap = item['cellars'] is Map<String, dynamic>
                        ? item['cellars'] as Map<String, dynamic>
                        : item;
                    final cId = (cMap['id'] ?? item['cellar_id'] ?? '').toString();
                    final cName = cMap['name']?.toString() ?? tr('Cave', 'Cellar');
                    final isChecked = selectedCellars[cId] ?? false;
                    final currentRole = selectedRoles[cId] ?? 'editor';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isChecked
                            ? const Color(0xFF8B1E3F).withValues(alpha: 0.08)
                            : Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isChecked
                              ? const Color(0xFF8B1E3F).withValues(alpha: 0.4)
                              : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isChecked,
                                activeColor: const Color(0xFF8B1E3F),
                                onChanged: (val) {
                                  setDialogState(() {
                                    selectedCellars[cId] = val ?? false;
                                  });
                                },
                              ),
                              const Icon(Icons.wine_bar, size: 20, color: Color(0xFF8B1E3F)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cName,
                                  style: TextStyle(
                                    fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isChecked) ...[
                            const Divider(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    tr('Accès :', 'Access:'),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                  ),
                                  DropdownButton<String>(
                                    value: currentRole,
                                    isDense: true,
                                    underline: const SizedBox(),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'editor',
                                        child: Text(tr('✍️ Sommelier (Écriture)', '✍️ Sommelier (write)'), style: const TextStyle(fontSize: 12.5)),
                                      ),
                                      DropdownMenuItem(
                                        value: 'viewer',
                                        child: Text(tr('👁️ Lecteur (Lecture)', '👁️ Viewer (read)'), style: const TextStyle(fontSize: 12.5)),
                                      ),
                                    ],
                                    onChanged: (newRole) {
                                      if (newRole != null) {
                                        setDialogState(() {
                                          selectedRoles[cId] = newRole;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('Annuler', 'Cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: anySelected
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        setState(() => _isActionLoading = true);
                        try {
                          final repo = ref.read(friendsRepositoryProvider);
                          int grantedCount = 0;

                          for (final item in ownedCellars) {
                            final cMap = item['cellars'] is Map<String, dynamic>
                                ? item['cellars'] as Map<String, dynamic>
                                : item;
                            final cId = (cMap['id'] ?? item['cellar_id'] ?? '').toString();
                            final isChecked = selectedCellars[cId] ?? false;
                            if (isChecked && cId.isNotEmpty) {
                              final role = selectedRoles[cId] ?? 'editor';
                              final cName = cMap['name']?.toString() ?? tr('Ma Cave', 'My cellar');
                              await repo.grantCellarAccessDirectly(
                                cellarId: cId,
                                friendUserId: widget.friend.friendUserId,
                                role: role,
                                cellarName: cName,
                              );
                              grantedCount++;
                            }
                          }

                          ref.invalidate(friendsListProvider);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(tr('🎉 Accès accordé pour {grantedCount} cave(s) à {displayName} !', '🎉 {displayName} now has access to {grantedCount} cellar(s)!', {'grantedCount': grantedCount, 'displayName': widget.friend.displayName})),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(tr('Erreur: {e}', 'Error: {e}', {'e': e})), backgroundColor: Colors.redAccent),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isActionLoading = false);
                        }
                      }
                    : null,
                child: Text(tr('Confirmer le partage', 'Confirm sharing'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final friend = widget.friend;
    // Son vrai palais (migration 067) ; à défaut, ce que son profil déclare.
    final palais = ref.watch(palaisDUnAmiProvider(friend.friendUserId));
    final taste = palais.valueOrNull ?? friend.tasteProfile;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1622) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(90),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Avatar & User Handle & Cellar Access Status
          Row(
            children: [
              OwnerAvatar(userId: friend.friendUserId, displayName: friend.displayName, avatarUrl: friend.avatarUrl, radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            friend.displayName,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wine_bar, size: 12, color: Color(0xFFD4AF37)),
                              const SizedBox(width: 4),
                              Text(tr('Carte des Goûts', 'Taste card'), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      friend.handle,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF8B1E3F), fontSize: 13),
                    ),
                    if (friend.phoneNumber != null || friend.email != null)
                      Text(
                        [
                          if (friend.phoneNumber != null && friend.phoneNumber!.isNotEmpty)
                            '${PhoneDialCodeHelper.parseExisting(friend.phoneNumber).$1.flag} ${friend.phoneNumber}',
                          if (friend.email != null) friend.email
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cellar Access Status Banner
          if (friend.hasCellarAccess)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('Accès cave partagée : {v1}', 'Shared cellar access: {v1}', {'v1': friend.cellarAccessRole == "editor" ? tr('Sommelier / Éditeur ✍️', 'sommelier / editor ✍️') : tr('Consultation 👁️', 'view only 👁️')}),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Scrollable Taste Profile Content
          Expanded(
            child: ListView(
              children: [
                // Son radar (« I want to see the spider here », 04/10) : ce qui est observé,
                // et ce qui n'est encore que deviné.
                if (palais.isLoading)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                else if (palais.valueOrNull != null) ...[
                  Center(
                    child: WineTasteRadarChart(
                      size: 240,
                      datasets: [
                        RadarChartDataset(
                          label: friend.displayName,
                          metrics: WineTasteRadarCalculator.compute(taste),
                          color: const Color(0xFF8B1E3F),
                          confidences: TasteProfile.axisKeys.map(taste.axisConfidence).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const LegendeDuRadar(color: Color(0xFF8B1E3F)),
                  const SizedBox(height: 16),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      tr('{displayName} n\'a pas encore noté assez de vins pour dessiner son palais.',
                          '{displayName} hasn\'t rated enough wines yet to draw their palate.',
                          {'displayName': friend.displayName}),
                      style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                  ),
                // Style & Notes if provided
                if (taste.notes.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1E3F).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🍷 ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            taste.notes,
                            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 1. CÉPAGES FAVORIS
                _buildSectionHeader(tr('🍇 Cépages Favoris', '🍇 Favourite grapes'), isDark),
                const SizedBox(height: 6),
                if (taste.favoriteGrapes.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: taste.favoriteGrapes
                        .map((g) => _buildChip(g, const Color(0xFF8B1E3F), isDark))
                        .toList(),
                  )
                else
                  Text(tr('Aucun cépage spécifique renseigné', 'No particular grape given'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),

                // 2. RÉGIONS & TERROIRS
                _buildSectionHeader(tr('🗺️ Régions & Terroirs Préférés', '🗺️ Favourite regions'), isDark),
                const SizedBox(height: 6),
                if (taste.favoriteRegions.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: taste.favoriteRegions
                        .map((r) => _buildChip(r, const Color(0xFF2E7D32), isDark))
                        .toList(),
                  )
                else
                  Text(tr('Aucune région renseignée', 'No region given'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),

                // 3. TYPES DE VINS
                _buildSectionHeader(tr('🍷 Styles & Couleurs Préférés', '🍷 Favourite styles & colours'), isDark),
                const SizedBox(height: 6),
                if (taste.favoriteTypes.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: taste.favoriteTypes
                        .map((t) => _buildChip(t, const Color(0xFFD4AF37), isDark))
                        .toList(),
                  )
                else
                  Text(tr('Tous types de vins', 'All kinds of wine'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),

                // 4. PROFIL NUMÉRIQUE DU PALAIS
                _buildSectionHeader(tr('⚖️ Profil Palais & Sensibilités', '⚖️ Palate'), isDark),
                const SizedBox(height: 8),
                _buildPalateGauge(
                  label: tr('Acidité', 'Acidity'),
                  value: taste.avgAcidityPreference ?? 0.5,
                  lowLabel: tr('Tendre / Ronde', 'Soft / round'),
                  highLabel: tr('Vive / Minérale', 'Crisp / mineral'),
                  color: Colors.lightGreen,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildPalateGauge(
                  label: tr('Tanins', 'Tannins'),
                  value: taste.avgTanninPreference ?? 0.5,
                  lowLabel: tr('Fondus / Soyeux', 'Silky / supple'),
                  highLabel: tr('Puissants / Structurés', 'Firm / structured'),
                  color: const Color(0xFF8B1E3F),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildPalateGauge(
                  label: tr('Corps & Puissance', 'Body'),
                  value: taste.avgBodyPreference ?? 0.5,
                  lowLabel: tr('Léger & Digest', 'Light & easy'),
                  highLabel: tr('Ample & Corsé', 'Full & powerful'),
                  color: Colors.deepOrange,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 5. AVERSIONS / À ÉVITER
                if (taste.dislikedCharacteristics.isNotEmpty) ...[
                  _buildSectionHeader(tr('🚫 Ce qu\'{displayName} n\'aime pas', '🚫 What {displayName} doesn\'t like', {'displayName': friend.displayName}), isDark),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: taste.dislikedCharacteristics
                        .map((d) => _buildChip('❌ $d', Colors.red.shade700, isDark))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // 6. ARÔMES FAVORIS
                if (taste.aromaPreferences.isNotEmpty) ...[
                  _buildSectionHeader(tr('✨ Arômes les plus plébiscités', '✨ Favourite aromas'), isDark),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: taste.aromaPreferences.keys
                        .take(6)
                        .map((a) => _buildChip(a.replaceAll('_', ' '), Colors.purple, isDark))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),

          // Action Buttons: Cellar Sharing & Chatmelier
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B1E3F),
                    side: const BorderSide(color: Color(0xFF8B1E3F)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.meeting_room_outlined, size: 16),
                  label: Text(
                    friend.hasCellarAccess ? tr('Explorer sa cave', 'Explore their cellar') : tr('Demander l\'accès cave', 'Ask for cellar access'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: _isActionLoading
                      ? null
                      : () {
                          if (friend.hasCellarAccess) {
                            Navigator.pop(context);
                            ref.read(currentCellarIdProvider.notifier).selectCellar(friend.friendCellarId ?? friend.friendUserId);
                            context.go('/');
                          } else {
                            _showRequestCellarAccessDialog();
                          }
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.card_giftcard, size: 16),
                  label: Text(
                    tr('Partager ma cave', 'Share my cellar'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: _isActionLoading ? null : _showGrantMyCellarDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 18),
            label: Text(
              tr('Demander conseil à Chatmelier pour {displayName}', 'Ask Chatmelier what to pour for {displayName}', {'displayName': friend.displayName}),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/chat');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    );
  }

  Widget _buildChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : color.darken(0.1),
        ),
      ),
    );
  }

  Widget _buildPalateGauge({
    required String label,
    required double value,
    required String lowLabel,
    required String highLabel,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
              Text('${(value * 100).round()}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lowLabel, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
              Text(highLabel, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

extension _ColorExtension on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
