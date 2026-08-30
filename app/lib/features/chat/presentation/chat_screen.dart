import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/responsive_layout.dart';
import '../../../shared/widgets/drinking_window_badge.dart';
import '../../../shared/widgets/wine_type_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/taste_profiles_dialog.dart';
import '../../cellar/domain/bottle.dart';
import '../data/chat_service.dart';
import '../domain/chat_message.dart';
import 'chat_bubble.dart';
import 'chatmelier_thinking_indicator.dart';

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
    final cellarId = ref.read(currentCellarIdProvider);
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

    final cellarId = ref.read(currentCellarIdProvider);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLargeScreen = Responsive.isTabletOrDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.chatTitle ?? 'Chatmelier IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, color: Color(0xFFD4AF37)),
            tooltip: 'Profils de Goût (Flavien & Caro)',
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

    return Column(
      children: [
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
              _buildChip('🍷 Que boire ce soir pour Flavien et Caro ?'),
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
    return Row(
      children: [
        // Main Column: Chat Conversation Stream
        Expanded(
          flex: 6,
          child: Column(
            children: [
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
            title: 'Soirée Flavien & Caro 🍷',
            subtitle: 'Conseil sur-mesure pour les 2 profils de goût',
            prompt: 'Que me conseilles-tu d\'ouvrir ce soir parmi mes bouteilles qui plaira à la fois à Flavien et à Caro ?',
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
