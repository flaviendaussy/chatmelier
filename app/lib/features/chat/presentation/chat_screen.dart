import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/taste_profiles_dialog.dart';
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
          content: l10n?.chatGreeting ?? 'Bonjour ! Je suis Chatmelier. Posez-moi vos questions sur les accords mets-vins, l\'apogée de vos bouteilles, ou demandez-moi des recommandations basées sur votre cave actuelle.',
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
      final replyText = await service.sendMessage(text, cellarId, languageCode: langCode);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.chatTitle ?? 'Chatmelier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, color: Color(0xFFD4AF37)),
            tooltip: 'Profils de Goût (Flavien & Caro)',
            onPressed: () => TasteProfilesDialog.show(context),
          ),
        ],
      ),
      body: Column(
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
          if (_isLoading)
            const ChatmelierThinkingIndicator(),
          // Suggestion Chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildChip('🍷 Que boire ce soir pour Flavien et Caro ?'),
                _buildChip(l10n?.chatChipTonight ?? '🍾 Que devrais-je boire ce soir ?'),
                _buildChip(l10n?.chatChipSteak ?? '🥩 Quel vin servir avec une viande rouge ?'),
                _buildChip(l10n?.chatChipSeafood ?? '🐟 Quel blanc ouvrir pour un poisson ?'),
                _buildChip(l10n?.chatChipPeak ?? '⏰ Quelles bouteilles sont à leur apogée ?'),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l10n?.chatInputHint ?? 'Demander à Chatmelier...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isLoading ? null : () => _sendMessage(),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
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
