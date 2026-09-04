import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../auth/domain/user_profile.dart';
import '../data/friends_repository.dart';

class ContactInviteSheet extends ConsumerStatefulWidget {
  final Set<String> existingFriendIds;

  const ContactInviteSheet({
    super.key,
    required this.existingFriendIds,
  });

  static Future<void> show(BuildContext context, Set<String> existingFriendIds) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContactInviteSheet(existingFriendIds: existingFriendIds),
    );
  }

  @override
  ConsumerState<ContactInviteSheet> createState() => _ContactInviteSheetState();
}

class _ContactInviteSheetState extends ConsumerState<ContactInviteSheet> {
  final _searchCtrl = TextEditingController();
  List<UserProfile> _matchedUsers = [];
  bool _isSearching = false;
  final Set<String> _sentRequests = {};

  // Recommended contact templates or simulated address book highlights
  final List<Map<String, String>> _sampleContacts = [
    {'name': 'Alexandre Martin', 'phone': '+33 6 12 34 56 78', 'note': 'Ami amateur de Bordeaux'},
    {'name': 'Sophie Dupont', 'phone': '+33 6 98 76 54 32', 'note': 'Sommelière passionnée'},
    {'name': 'Thomas Leroy', 'phone': '+33 7 45 67 89 01', 'note': 'Club d\'œnologie'},
    {'name': 'Camille Bernard', 'phone': '+33 6 55 44 33 22', 'note': 'Soirées dégustations'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchContact(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        _matchedUsers = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final repo = ref.read(authRepositoryProvider);
    final results = await repo.searchUsers(clean);

    if (mounted) {
      setState(() {
        _matchedUsers = results;
        _isSearching = false;
      });
    }
  }

  void _shareInviteLink([String? contactName]) {
    final currentUser = ref.read(currentUserProvider);
    final myCode = currentUser?.email?.split('@').first ?? 'ami';
    final nameSalutation = (contactName != null && contactName.isNotEmpty) ? 'Salut $contactName ! ' : '';
    
    final inviteMessage = '${nameSalutation}Rejoins-moi sur Chatmelier, l\'application sommelier et gestionnaire de cave à vin !\n\n'
        'Tu pourras voir ma cave, explorer mes bouteilles et partager nos dégustations.\n'
        'Télécharge l\'app ici : https://flaviendaussy.github.io/#/invite?ref=$myCode';

    Share.share(inviteMessage, subject: 'Invitation à rejoindre Chatmelier');
  }

  Future<void> _sendFriendRequest(UserProfile user) async {
    try {
      await ref.read(friendsRepositoryProvider).sendFriendRequest(user);
      ref.invalidate(pendingOutgoingRequestsProvider);
      if (mounted) {
        setState(() => _sentRequests.add(user.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📬 Demande d\'ami envoyée à ${user.displayName} !'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final query = _searchCtrl.text.trim().toLowerCase();
    final filteredContacts = query.isEmpty
        ? _sampleContacts
        : _sampleContacts.where((c) =>
            (c['name'] ?? '').toLowerCase().contains(query) ||
            (c['phone'] ?? '').contains(query)).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.contacts, color: Color(0xFF8B1E3F), size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inviter depuis mes contacts',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Retrouvez vos proches ou partagez votre lien d\'invitation',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher un contact (nom ou téléphone)...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _searchContact('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (val) => _searchContact(val),
            ),
          ),

          // Quick Share Global Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1E3F).withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B1E3F).withAlpha(40)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.share_outlined, color: Color(0xFF8B1E3F), size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lien d\'invitation direct', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Partagez par SMS, WhatsApp ou Mail', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => _shareInviteLink(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1E3F),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Partager', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Body: List of Results or Suggested Contacts
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                // 1. Registered Chatmelier Users matching query
                if (_matchedUsers.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '🍷 Déjà inscrits sur Chatmelier :',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD4AF37)),
                    ),
                  ),
                  ..._matchedUsers.map((user) {
                    final isAlreadyFriend = widget.existingFriendIds.contains(user.id);
                    final isRequestSent = _sentRequests.contains(user.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF8B1E3F),
                          child: Text(
                            (user.displayName.isNotEmpty ? user.displayName[0] : '?').toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        subtitle: Text(user.handle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: isAlreadyFriend
                            ? const Chip(
                                label: Text('Ami ✓', style: TextStyle(fontSize: 11, color: Colors.green)),
                                visualDensity: VisualDensity.compact,
                              )
                            : isRequestSent
                                ? const Chip(
                                    label: Text('Envoyée 📬', style: TextStyle(fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                  )
                                : FilledButton.icon(
                                    onPressed: () => _sendFriendRequest(user),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B1E3F),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.person_add, size: 14),
                                    label: const Text('Ajouter', style: TextStyle(fontSize: 11.5)),
                                  ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // 2. Device Contacts to invite
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    query.isEmpty ? '📱 Vos contacts à inviter :' : '📱 Contacts correspondants :',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                  ),
                ),

                if (filteredContacts.isEmpty && _matchedUsers.isEmpty && !_isSearching)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.person_search, size: 40, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text('Aucun contact trouvé pour "$query"', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _shareInviteLink(query),
                            icon: const Icon(Icons.send, size: 16),
                            label: Text('Envoyer une invitation à "$query"'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredContacts.map((contact) {
                    final name = contact['name'] ?? '';
                    final phone = contact['phone'] ?? '';
                    final note = contact['note'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          child: Icon(Icons.person, color: isDark ? Colors.white70 : Colors.black54),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        subtitle: Text(
                          '$phone ${note.isNotEmpty ? "• $note" : ""}',
                          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                        trailing: OutlinedButton.icon(
                          onPressed: () => _shareInviteLink(name),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF8B1E3F)),
                            foregroundColor: const Color(0xFF8B1E3F),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.send, size: 14),
                          label: const Text('Inviter', style: TextStyle(fontSize: 11.5)),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
