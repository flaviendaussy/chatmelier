import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../auth/domain/user_profile.dart';
import '../data/friends_repository.dart';
import '../../../shared/utils/langue.dart';

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

  /// Mon pseudo, pour que la personne invitée me retrouve une fois inscrite.
  String? _monPseudo;

  @override
  void initState() {
    super.initState();
    final moi = ref.read(currentUserProvider);
    if (moi != null) {
      ref.read(authRepositoryProvider).getProfile(moi.id).then((p) {
        final pseudo = p?.username?.replaceAll('@', '').trim();
        if (mounted && pseudo != null && pseudo.isNotEmpty) setState(() => _monPseudo = pseudo);
      }).catchError((_) {});
    }
  }

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
    final List<UserProfile> results;
    try {
      results = await repo.searchUsers(clean);
    } catch (_) {
      // La recherche a échoué : on le dit, plutôt que « aucun résultat ».
      if (mounted) {
        setState(() => _isSearching = false);
        final isFr = Localizations.localeOf(context).languageCode == 'fr';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isFr
              ? 'Recherche impossible pour le moment. Vérifiez votre connexion et réessayez.'
              : 'Search is unavailable right now. Check your connection and try again.'),
        ));
      }
      return;
    }

    if (mounted) {
      setState(() {
        _matchedUsers = results;
        _isSearching = false;
      });
    }
  }

  /// L'adresse de l'app web, celle des tables et des pages légales.
  static const _adresseDeLApp = 'https://chatmelier.github.io';

  void _shareInviteLink([String? contactName]) {
    // Un numéro ou un e-mail tapé dans la recherche n'est pas un prénom.
    final prenom = contactName?.trim() ?? '';
    final salut = prenom.isEmpty || RegExp(r'[0-9@]').hasMatch(prenom) ? '' : tr('Salut $prenom ! ', 'Hi $prenom! ');
    final pseudo = _monPseudo == null ? '' : tr('\nMon pseudo pour me retrouver : @$_monPseudo', '\nFind me there as @$_monPseudo');
    final inviteMessage = tr(
      '${salut}Rejoins-moi sur Chatmelier, le sommelier qui apprend nos goûts et garde nos caves !\n\n'
          'On pourra comparer nos palais et partager nos bouteilles.$pseudo\n\n'
          'C\'est ici : $_adresseDeLApp',
      '${salut}Join me on Chatmelier, the sommelier that learns our tastes and keeps our cellars!\n\n'
          'We can compare palates and share bottles.$pseudo\n\n'
          "It's here: $_adresseDeLApp",
    );

    Share.share(inviteMessage, subject: tr('Invitation à rejoindre Chatmelier', 'Join me on Chatmelier'));
  }

  Future<void> _sendFriendRequest(UserProfile user) async {
    try {
      await ref.read(friendsRepositoryProvider).sendFriendRequest(user);
      ref.invalidate(pendingOutgoingRequestsProvider);
      if (mounted) {
        setState(() => _sentRequests.add(user.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('📬 Demande d\'ami envoyée à ${user.displayName} !', '📬 Friend request sent to ${user.displayName}!')),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Erreur : $e', 'Error: $e')), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final query = _searchCtrl.text.trim();

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
                        tr('Inviter un proche', 'Invite someone'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('Retrouvez vos proches ou partagez votre lien d\'invitation', 'Find people you know, or share your invitation link'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                hintText: tr('Rechercher par @pseudo, nom, tél ou email...', 'Search by @username, name, phone or email...'),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('Lien d\'invitation direct', 'Invitation link'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(tr('Partagez par SMS, WhatsApp ou Mail', 'Share it by text, WhatsApp or email'), style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
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
                    child: Text(tr('Partager', 'Share'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      tr('🍷 Déjà inscrits sur Chatmelier :', '🍷 Already on Chatmelier:'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD4AF37)),
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
                            ? Chip(
                                label: Text(tr('Ami ✓', 'Friend ✓'), style: const TextStyle(fontSize: 11, color: Colors.green)),
                                visualDensity: VisualDensity.compact,
                              )
                            : isRequestSent
                                ? Chip(
                                    label: Text(tr('Envoyée 📬', 'Sent 📬'), style: const TextStyle(fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                  )
                                : FilledButton.icon(
                                    onPressed: () => _sendFriendRequest(user),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B1E3F),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.person_add, size: 14),
                                    label: Text(tr('Ajouter', 'Add'), style: const TextStyle(fontSize: 11.5)),
                                  ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // 2. Personne ne correspond : on l'invite par lien.
                if (query.isEmpty && !_isSearching)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tr('Tapez un @pseudo, un nom, un numéro ou un e-mail pour retrouver quelqu\'un sur Chatmelier.',
                          'Type a @username, name, phone number or email to find someone on Chatmelier.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                else if (_matchedUsers.isEmpty && !_isSearching)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.person_search, size: 40, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            tr('Personne sur Chatmelier ne correspond à « $query ».', 'No one on Chatmelier matches "$query".'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _shareInviteLink(query),
                            icon: const Icon(Icons.send, size: 16),
                            label: Text(tr('Lui envoyer une invitation', 'Send them an invitation')),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
