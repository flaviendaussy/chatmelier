import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/phone_dial_code.dart';
import '../../../shared/widgets/owner_avatar.dart';
import '../data/friends_repository.dart';
import '../domain/friend.dart';

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

  void _showRequestCellarAccessDialog() {
    String selectedRole = 'viewer';
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('🍷 ', style: TextStyle(fontSize: 22)),
              Expanded(
                child: Text(
                  'Demander l\'accès à la cave',
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
                  'Vous pouvez demander à ${widget.friend.displayName} l\'accès à sa cave à vin. Une notification lui sera envoyée.',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text('Niveau d\'accès souhaité :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  value: 'viewer',
                  groupValue: selectedRole,
                  title: const Text('👁️ Consultation (Lecture seule)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Voir les bouteilles, emplacements et apogées.', style: TextStyle(fontSize: 11)),
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                  activeColor: const Color(0xFF8B1E3F),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'editor',
                  groupValue: selectedRole,
                  title: const Text('✍️ Sommelier délégué (Écriture)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Ajouter, modifier ou consommer des bouteilles.', style: TextStyle(fontSize: 11)),
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                  activeColor: const Color(0xFF8B1E3F),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  decoration: InputDecoration(
                    labelText: 'Message facultatif',
                    hintText: 'Ex: "Pour qu\'on gère nos bouteilles en commun !"',
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
              child: const Text('Annuler'),
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
                  // Default or fetch friend cellar ID
                  final cellarId = widget.friend.friendCellarId ?? widget.friend.friendUserId;
                  await repo.requestCellarAccess(
                    cellarId: cellarId,
                    ownerId: widget.friend.friendUserId,
                    requestedRole: selectedRole,
                    message: messageCtrl.text.trim().isNotEmpty ? messageCtrl.text.trim() : null,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📬 Demande envoyée à ${widget.friend.displayName} !'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isActionLoading = false);
                }
              },
              child: const Text('Envoyer la demande', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showGrantMyCellarDialog() {
    String selectedRole = 'viewer';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('🎁 ', style: TextStyle(fontSize: 22)),
              Expanded(
                child: Text(
                  'Donner accès à ma cave',
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
                  'Invitez ${widget.friend.displayName} à consulter ou gérer votre cave. Il/elle recevra une notification et un accès immédiat.',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text('Rôle attribué :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  value: 'viewer',
                  groupValue: selectedRole,
                  title: const Text('👁️ Lecteur (Consultation seule)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Peut voir vos bouteilles sans les modifier.', style: TextStyle(fontSize: 11)),
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                  activeColor: const Color(0xFF8B1E3F),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'editor',
                  groupValue: selectedRole,
                  title: const Text('✍️ Sommelier délégué (Éditeur)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Peut ajouter, modifier et consommer vos flacons.', style: TextStyle(fontSize: 11)),
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                  activeColor: const Color(0xFF8B1E3F),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                setState(() => _isActionLoading = true);
                try {
                  final supabase = ref.read(supabaseProvider);
                  final user = supabase.auth.currentUser;
                  if (user == null) return;

                  // Find current user's primary cellar
                  final cellarRes = await supabase.from('cellars').select('id, name').eq('owner_id', user.id).limit(1).maybeSingle();
                  final cellarId = cellarRes?['id']?.toString() ?? user.id;
                  final cellarName = cellarRes?['name']?.toString() ?? 'Ma Cave';

                  final repo = ref.read(friendsRepositoryProvider);
                  await repo.grantCellarAccessDirectly(
                    cellarId: cellarId,
                    friendUserId: widget.friend.friendUserId,
                    role: selectedRole,
                    cellarName: cellarName,
                  );

                  ref.invalidate(friendsListProvider);
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('🎉 Accès accordé à ${widget.friend.displayName} !'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isActionLoading = false);
                }
              },
              child: const Text('Accorder l\'accès', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final friend = widget.friend;
    final taste = friend.tasteProfile;

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
              OwnerAvatar(userId: friend.friendUserId, radius: 28),
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wine_bar, size: 12, color: Color(0xFFD4AF37)),
                              SizedBox(width: 4),
                              Text('Carte des Goûts', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
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
                      'Accès cave partagée : ${friend.cellarAccessRole == "editor" ? "Sommelier / Éditeur ✍️" : "Consultation 👁️"}',
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
                _buildSectionHeader('🍇 Cépages Favoris', isDark),
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
                  const Text('Aucun cépage spécifique renseigné', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),

                // 2. RÉGIONS & TERROIRS
                _buildSectionHeader('🗺️ Régions & Terroirs Préférés', isDark),
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
                  const Text('Aucune région renseignée', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),

                // 3. TYPES DE VINS
                _buildSectionHeader('🍷 Styles & Couleurs Préférés', isDark),
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
                  const Text('Tous types de vins', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),

                // 4. PROFIL NUMÉRIQUE DU PALAIS
                _buildSectionHeader('⚖️ Profil Palais & Sensibilités', isDark),
                const SizedBox(height: 8),
                _buildPalateGauge(
                  label: 'Acidité',
                  value: taste.avgAcidityPreference ?? 0.5,
                  lowLabel: 'Tendre / Ronde',
                  highLabel: 'Vive / Minérale',
                  color: Colors.lightGreen,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildPalateGauge(
                  label: 'Tanins',
                  value: taste.avgTanninPreference ?? 0.5,
                  lowLabel: 'Fondus / Soyeux',
                  highLabel: 'Puissants / Structurés',
                  color: const Color(0xFF8B1E3F),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildPalateGauge(
                  label: 'Corps & Puissance',
                  value: taste.avgBodyPreference ?? 0.5,
                  lowLabel: 'Léger & Digest',
                  highLabel: 'Ample & Corsé',
                  color: Colors.deepOrange,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 5. AVERSIONS / À ÉVITER
                if (taste.dislikedCharacteristics.isNotEmpty) ...[
                  _buildSectionHeader('🚫 Ce qu\'${friend.displayName} n\'aime pas', isDark),
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
                  _buildSectionHeader('✨ Arômes les plus plébiscités', isDark),
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
                    friend.hasCellarAccess ? 'Explorer sa cave' : 'Demander l\'accès cave',
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
                  label: const Text(
                    'Partager ma cave',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
              'Demander conseil à Chatmelier pour ${friend.displayName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/chat');
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
