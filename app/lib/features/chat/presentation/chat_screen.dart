import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/responsive_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../auth/presentation/taste_profiles_dialog.dart';
import '../data/chat_service.dart';
import '../domain/chat_message.dart';
import 'chat_bubble.dart';
import 'chatmelier_thinking_indicator.dart';
import '../../offline/presentation/chatmelier_offline_antenna_widget.dart';
import '../../offline/presentation/sync_provider.dart';
import '../../offline/data/connectivity_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (_messages.isEmpty) {
        final l10n = AppLocalizations.of(context);
        _messages.add(ChatMessage(
          id: 'welcome',
          role: 'assistant',
          content: l10n?.chatGreeting ??
              'Bonjour ! Je suis Chatmelier. Posez-moi vos questions sur les accords mets-vins, l\'apogée de vos bouteilles, ou demandez-moi des recommandations basées sur votre cave actuelle.',
          createdAt: DateTime.now(),
        ));
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    String? cellarId = ref.read(currentCellarIdProvider);
    if (cellarId == null) {
      try {
        final cellars = await ref.read(userCellarsProvider.future);
        if (cellars.isNotEmpty) {
          final first = cellars.first;
          final cMap = first['cellars'];
          cellarId = (cMap is Map ? cMap['id']?.toString() : null) ?? first['cellar_id']?.toString();
          if (cellarId != null && mounted) {
            ref.read(currentCellarIdProvider.notifier).state = cellarId;
          }
        }
      } catch (_) {}
    }
    if (cellarId == null) return;
    try {
      final service = ref.read(chatServiceProvider);
      final history = await service.getChatHistory(cellarId);
      if (history.isNotEmpty && mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(history);
        });
        _scrollToBottom();
      }
    } catch (_) {
      // Keep welcome message if no history or error
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty || _isLoading) return;

    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ChatmelierOfflineAntennaWidget(
              title: 'Chatmelier est hors-ligne',
              message: 'L\'IA Chatmelier requiert une connexion internet pour vous conseiller et analyser votre cave. Vos bouteilles et statistiques restent consultables hors-ligne.',
              onRetry: () async {
                final online = await ref.read(connectivityServiceProvider).checkConnection();
                if (online && mounted && ctx.mounted) {
                  Navigator.pop(ctx);
                  _sendMessage(presetText ?? text);
                }
              },
            ),
          ),
        ),
      );
      return;
    }

    if (presetText == null) _textController.clear();

    final userMsg = ChatMessage(
      id: DateTime.now().toIso8601String(),
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    var cellarId = ref.read(currentCellarIdProvider);
    if (cellarId == null) {
      final cellars = ref.read(userCellarsProvider).value;
      if (cellars != null && cellars.isNotEmpty) {
        final first = cellars.first;
        final cMap = first['cellars'];
        cellarId = (cMap is Map ? cMap['id']?.toString() : null) ?? first['cellar_id']?.toString();
        if (cellarId != null) {
          ref.read(currentCellarIdProvider.notifier).state = cellarId;
        }
      }
    }
    final service = ref.read(chatServiceProvider);
    final langCode = Localizations.localeOf(context).languageCode;

    try {
      final replyText =
          await service.sendMessage(text, cellarId, languageCode: langCode);
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            id: DateTime.now().toIso8601String(),
            role: 'assistant',
            content: replyText,
            createdAt: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final isFr = langCode == 'fr';
        setState(() {
          _messages.add(ChatMessage(
            id: DateTime.now().toIso8601String(),
            role: 'assistant',
            content: isFr
                ? 'Désolé, une erreur est survenue lors de la communication avec Chatmelier : $e'
                : 'Sorry, I encountered an issue connecting to the cellar knowledge base: $e',
            createdAt: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLargeScreen = Responsive.isTabletOrDesktop(context);
    final profiles = ref.watch(tasteProfilesListProvider).value ?? [];
    final names = profiles.map((p) => p.name).where((n) => n.trim().isNotEmpty && n != 'Moi').toList();
    final profileTooltip = names.isNotEmpty
        ? 'Profils de Goût (${names.take(2).join(' & ')})'
        : 'Profils de Goût & Invités';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.chatTitle ?? 'Chatmelier IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, color: Color(0xFFD4AF37)),
            tooltip: profileTooltip,
            onPressed: () => TasteProfilesDialog.show(context),
          ),
        ],
      ),
      body: isLargeScreen ? _buildLargeScreenLayout() : _buildMobileLayout(),
    );
  }

  /// 📱 Mobile Layout: Single-column chat stream with bottom input and chips
  Widget _buildMobileLayout() {
    final l10n = AppLocalizations.of(context);
    final profiles = ref.watch(tasteProfilesListProvider).value ?? [];
    final names = profiles.map((p) => p.name).where((n) => n.trim().isNotEmpty && n != 'Moi').toList();
    final duoChipText = names.length >= 2
        ? '🍷 Que boire ce soir pour ${names[0]} et ${names[1]} ?'
        : (names.length == 1
            ? '🍷 Que boire ce soir pour ${names[0]} et moi ?'
            : '🍷 Quel vin ouvrir ce soir ?');

    final isOnline = ref.watch(isOnlineProvider);

    return Column(
      children: [
        if (!isOnline)
          Container(
            color: Colors.amber.shade900.withValues(alpha: 0.9),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Mode Hors-Ligne : Chatmelier recherche du réseau...',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
                InkWell(
                  onTap: () => ref.read(connectivityServiceProvider).checkConnection(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text('Tester', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return ChatBubble(
                isUser: msg.isUser,
                text: msg.content,
              );
            },
          ),
        ),
        if (_isLoading) const ChatmelierThinkingIndicator(),
        // Suggestion Chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildChip(duoChipText),
              _buildChip(
                  l10n?.chatChipTonight ?? '🍾 Que devrais-je boire ce soir ?'),
              _buildChip(l10n?.chatChipSteak ??
                  '🥩 Quel vin servir avec une viande rouge ?'),
              _buildChip(l10n?.chatChipSeafood ??
                  '🐟 Quel blanc ouvrir pour un poisson ?'),
              _buildChip(l10n?.chatChipPeak ??
                  '⏰ Quelles bouteilles sont à leur apogée ?'),
            ],
          ),
        ),
        const Divider(height: 1),
        _buildInputBar(),
      ],
    );
  }

  /// 💻 Tablet & Desktop Layout: 2-Column Split Workspace
  Widget _buildLargeScreenLayout() {
    final isOnline = ref.watch(isOnlineProvider);

    return Row(
      children: [
        // Main Column: Chat Conversation Stream
        Expanded(
          flex: 6,
          child: Column(
            children: [
              if (!isOnline)
                Container(
                  color: Colors.amber.shade900.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Mode Hors-Ligne : Chatmelier recherche du réseau...',
                          style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      InkWell(
                        onTap: () => ref.read(connectivityServiceProvider).checkConnection(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text('Tester', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return ChatBubble(
                      isUser: msg.isUser,
                      text: msg.content,
                    );
                  },
                ),
              ),
              if (_isLoading) const ChatmelierThinkingIndicator(),
              const Divider(height: 1),
              _buildInputBar(),
            ],
          ),
        ),

        // Vertical Separator
        const VerticalDivider(width: 1, thickness: 1),

        // Right Contextual Panel: Inspirations & Live Cellar Inspector
        SizedBox(
          width: 340,
          child: _buildContextSidebar(),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      l10n?.chatInputHint ?? 'Demander un conseil à Chatmelier...',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E3F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
              ),
              onPressed: _isLoading ? null : () => _sendMessage(),
              icon: const Icon(Icons.send, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextSidebar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cellarId = ref.watch(currentCellarIdProvider);
    final bottlesAsync = ref.watch(bottlesProvider(cellarId));
    final profiles = ref.watch(tasteProfilesListProvider).value ?? [];
    final names = profiles.map((p) => p.name).where((n) => n.trim().isNotEmpty && n != 'Moi').toList();

    return Container(
      color: isDark ? const Color(0xFF16151B) : const Color(0xFFFAF7F5),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Suggestions Rapides
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 18),
              const SizedBox(width: 8),
              Text(
                'INSPIRATIONS SOMMELIER',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSidebarPromptCard(
            title: names.length >= 2
                ? 'Soirée ${names[0]} & ${names[1]} 🍷'
                : (names.length == 1 ? 'Soirée ${names[0]} & moi 🍷' : 'Inspiration du Soir 🍷'),
            subtitle: 'Conseil sur-mesure pour vos profils de goût',
            prompt: names.length >= 2
                ? 'Que me conseilles-tu d\'ouvrir ce soir parmi mes bouteilles qui plaira à la fois à ${names[0]} et à ${names[1]} ?'
                : (names.length == 1
                    ? 'Que me conseilles-tu d\'ouvrir ce soir parmi mes bouteilles qui plaira à la fois à ${names[0]} et à moi ?'
                    : 'Que me conseilles-tu d\'ouvrir ce soir parmi mes bouteilles pour passer un excellent moment ?'),
          ),
          _buildSidebarPromptCard(
            title: 'Apogées prioritaires ⏰',
            subtitle: 'Les vins à boire sans tarder',
            prompt: 'Quelles sont les bouteilles de ma cave actuellement à leur apogée ou à boire rapidement ?',
          ),
          _buildSidebarPromptCard(
            title: 'Accord Viande Rouge 🥩',
            subtitle: 'Sélection de rouges tanniques ou soyeux',
            prompt: 'Quel vin de ma cave serait idéal pour accompagner une belle pièce de bœuf ou des grillades ?',
          ),
          _buildSidebarPromptCard(
            title: 'Accord Poisson / Crustacés 🐟',
            subtitle: 'Sélection de blancs minéraux ou ronds',
            prompt: 'Quel vin blanc de ma cave ouvrir pour accompagner un poisson ou des fruits de mer ?',
          ),
          _buildSidebarPromptCard(
            title: 'Plateau de Fromages 🧀',
            subtitle: 'Accords blancs & rouges affinés',
            prompt: 'Quels vins de ma cave suggères-tu pour un accord parfait avec un plateau de fromages variés ?',
          ),

          const SizedBox(height: 18),
          Divider(color: theme.dividerColor.withValues(alpha: 0.2)),
          const SizedBox(height: 12),

          // Section 2: Ma Cave en Direct (Interrogation Rapide)
          Row(
            children: [
              const Icon(Icons.wine_bar, color: Color(0xFF8B1E3F), size: 18),
              const SizedBox(width: 8),
              Text(
                'MA CAVE EN DIRECT',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          bottlesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (bottles) {
              if (bottles.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Aucune bouteille enregistrée dans cette cave.',
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              }

              return Column(
                children: bottles.take(10).map((b) {
                  final wine = b.wine;
                  final name = wine?.name ?? 'Vin';
                  final vintage = wine?.vintage?.toString() ?? '';
                  final region = wine?.region ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      title: Text(
                        '$name $vintage'.trim(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        region,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: const Icon(Icons.chat_bubble_outline,
                          size: 16, color: Color(0xFF8B1E3F)),
                      onTap: () {
                        _sendMessage(
                          'Que penses-tu de mon $name $vintage ($region) ? Donne-moi son apogée estimée, son profil gustatif et les meilleurs accords mets-vins.',
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarPromptCard({
    required String title,
    required String subtitle,
    required String prompt,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
              fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        onTap: _isLoading ? null : () => _sendMessage(prompt),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: _isLoading ? null : () => _sendMessage(label),
      ),
    );
  }
}
