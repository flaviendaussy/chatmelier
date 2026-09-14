import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/taste_profile_service.dart';
import '../data/menu_scan_service.dart';
import '../domain/menu_wine.dart';

class MenuChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  const MenuChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class MenuChatAssistantSheet extends ConsumerStatefulWidget {
  final ScannedMenu menu;

  const MenuChatAssistantSheet({super.key, required this.menu});

  static Future<void> show(BuildContext context, ScannedMenu menu) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MenuChatAssistantSheet(menu: menu),
    );
  }

  @override
  ConsumerState<MenuChatAssistantSheet> createState() => _MenuChatAssistantSheetState();
}

class _MenuChatAssistantSheetState extends ConsumerState<MenuChatAssistantSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MenuChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPromptsFr = [
    '🐟 Quel vin avec du poisson / fruits de mer ?',
    '🥩 Quel vin rouge pour une viande rouge savoureuse ?',
    '💎 Le meilleur rapport qualité / prix sous 45 € ?',
    '🍷 Un vin rouge souple et très peu tannique ?',
    '🧀 Quel accord parfait avec un plateau de fromages ?',
  ];

  final List<String> _quickPromptsEn = [
    '🐟 Which wine with fish / seafood?',
    '🥩 Which red wine for savory red meat?',
    '💎 Best value for money under €45?',
    '🍷 A smooth red wine with low tannins?',
    '🧀 Best pairing for a cheese board?',
  ];

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final isFr = Localizations.localeOf(context).languageCode == 'fr';
      _messages.add(MenuChatMessage(
        text: isFr
            ? 'Bonjour ! Je suis votre Sommelier personnel chez "${widget.menu.restaurantName}". J\'ai analysé les ${widget.menu.wines.length} références de cette carte des vins. Que mangez-vous ce soir, ou quelles sont vos envies pour vous guider ?'
            : 'Hello! I\'m your personal Sommelier at "${widget.menu.restaurantName}". I have analyzed the ${widget.menu.wines.length} wines on this list. What are you dining on tonight, or what are you in the mood for?',
        isUser: false,
        time: DateTime.now(),
      ));
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String query) async {
    final clean = query.trim();
    if (clean.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add(MenuChatMessage(text: clean, isUser: true, time: DateTime.now()));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final profiles = await ref.read(tasteProfilesListProvider.future);
      final activeProfile = profiles.isNotEmpty ? profiles.first : null;

      final scanService = ref.read(menuScanServiceProvider);
      final answer = await scanService.askMenuSommelier(
        menu: widget.menu,
        userQuestion: clean,
        userProfile: activeProfile,
      );

      if (mounted) {
        setState(() {
          _messages.add(MenuChatMessage(text: answer, isUser: false, time: DateTime.now()));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final isFr = Localizations.localeOf(context).languageCode == 'fr';
        setState(() {
          _messages.add(MenuChatMessage(
            text: isFr ? 'Désolé, une erreur est survenue : $e' : 'Sorry, an error occurred: $e',
            isUser: false,
            time: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
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

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final quickPrompts = isFr ? _quickPromptsFr : _quickPromptsEn;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1622) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF8B1E3F), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFr ? 'Conseil Sommelier sur cette carte' : 'Sommelier Advice on this Wine List',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isFr
                            ? '${widget.menu.restaurantName} • ${widget.menu.wines.length} vins analysés'
                            : '${widget.menu.restaurantName} • ${widget.menu.wines.length} wines analyzed',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Quick Suggestion Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = quickPrompts[index];
                return ActionChip(
                  label: Text(prompt, style: const TextStyle(fontSize: 12)),
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  onPressed: () => _sendMessage(prompt),
                );
              },
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? const Color(0xFF8B1E3F)
                          : (isDark ? const Color(0xFF26202E) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: msg.isUser ? const Radius.circular(2) : const Radius.circular(16),
                        bottomLeft: !msg.isUser ? const Radius.circular(2) : const Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: msg.isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B1E3F)),
                  ),
                  const SizedBox(width: 10),
                  Text(isFr ? 'Le sommelier réfléchit...' : 'Sommelier reflecting...', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: isFr ? 'Ex: Quel vin pour du canard rôti ?' : 'E.g.: Which wine for roasted duck?',
                      hintStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E3F),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _sendMessage(_inputController.text),
                  icon: const Icon(Icons.arrow_upward, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
