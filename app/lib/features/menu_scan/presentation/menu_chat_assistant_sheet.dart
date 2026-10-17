import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../journal/domain/habitudes_du_palais.dart';
import '../../journal/presentation/journal_screen.dart';
import '../data/menu_scan_service.dart';
import '../domain/menu_wine.dart';
import '../../../shared/utils/langue.dart';

class MenuChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  /// L'accueil et les erreurs ne font pas partie de l'échange : ni gardés, ni renvoyés.
  final bool horsEchange;

  const MenuChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.horsEchange = false,
  });

  Map<String, dynamic> toJson() => {'t': text, 'u': isUser, 'h': time.toIso8601String()};

  static MenuChatMessage? fromJson(Object? j) {
    if (j is! Map || j['t'] is! String) return null;
    return MenuChatMessage(
      text: j['t'] as String,
      isUser: j['u'] == true,
      time: DateTime.tryParse('${j['h']}') ?? DateTime.now(),
    );
  }
}

/// La conversation de chaque carte, gardée sur le téléphone (V2.5 · F4). « Ça devrait spin
/// une nouvelle instance du Chatmelier dédiée à cet item, avec son propre historique »
/// (Flavien, 13/10) : la feuille refermée, l'échange se perdait.
///
/// Peu de chose : les douze derniers messages de cinq cartes au plus. Les préférences
/// sont réécrites en entier à chaque écriture (E7) : elles ne doivent pas grossir.
class ConversationsDeCarte {
  static const messagesGardes = 12;
  static const cartesGardees = 5;
  static const _index = 'menu_chat_index';
  static String _cle(String menuId) => 'menu_chat_$menuId';

  static Future<List<MenuChatMessage>> lire(String menuId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final brut = prefs.getString(_cle(menuId));
      if (brut == null) return const [];
      return (jsonDecode(brut) as List).map(MenuChatMessage.fromJson).whereType<MenuChatMessage>().toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> ecrire(String menuId, List<MenuChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final echange = [for (final m in messages) if (!m.horsEchange) m];
      final gardes = echange.length > messagesGardes ? echange.sublist(echange.length - messagesGardes) : echange;
      await prefs.setString(_cle(menuId), jsonEncode([for (final m in gardes) m.toJson()]));
      final index = [menuId, for (final id in prefs.getStringList(_index) ?? const <String>[]) if (id != menuId) id];
      for (final ancienne in index.skip(cartesGardees)) {
        await prefs.remove(_cle(ancienne));
      }
      await prefs.setStringList(_index, index.take(cartesGardees).toList());
    } catch (_) {}
  }

  static Future<void> effacer(String menuId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cle(menuId));
      await prefs.setStringList(_index, [for (final id in prefs.getStringList(_index) ?? const <String>[]) if (id != menuId) id]);
    } catch (_) {}
  }
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

  static const _suggestions = [
    Phrase('🐟 Quel vin avec du poisson / fruits de mer ?', '🐟 Which wine with fish / seafood?'),
    Phrase('🥩 Quel vin rouge pour une viande rouge savoureuse ?', '🥩 Which red wine for savory red meat?'),
    Phrase('💎 Le meilleur rapport qualité / prix de la carte ?', '💎 Best value for money on this list?'),
    Phrase('🍷 Un vin rouge souple et très peu tannique ?', '🍷 A smooth red wine with low tannins?'),
    Phrase('🧀 Quel accord parfait avec un plateau de fromages ?', '🧀 Best pairing for a cheese board?'),
  ];

  
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final isFr = Localizations.localeOf(context).languageCode == 'fr';
      _messages.add(MenuChatMessage(
        text: trSi(isFr, 'Bonjour ! Je suis votre Sommelier personnel chez "{restaurantName}". J\'ai analysé les {wines_length} références de cette carte des vins. Que mangez-vous ce soir, ou quelles sont vos envies pour vous guider ?', 'Hello! I\'m your personal Sommelier at "{restaurantName}". I have analyzed the {wines_length} wines on this list. What are you dining on tonight, or what are you in the mood for?', {'restaurantName': widget.menu.restaurantName, 'wines_length': widget.menu.wines.length}),
        isUser: false,
        time: DateTime.now(),
        horsEchange: true,
      ));
      _reprendre();
    }
  }

  /// L'échange déjà commencé sur cette carte, à la suite de l'accueil.
  Future<void> _reprendre() async {
    final anciens = await ConversationsDeCarte.lire(widget.menu.id);
    if (!mounted || anciens.isEmpty) return;
    setState(() => _messages.insertAll(1, anciens));
    _scrollToBottom();
  }

  Future<void> _effacer() async {
    await ConversationsDeCarte.effacer(widget.menu.id);
    if (!mounted) return;
    // L'accueil reste, seul.
    setState(() => _messages.removeRange(1, _messages.length));
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
      if (!mounted) return;
      final languageCode = Localizations.localeOf(context).languageCode;
      // Ce qu'elle boit d'habitude : sans journal joignable, le sommelier répond quand même.
      var habitudes = '';
      try {
        final journal = await ref.read(tastingLogProvider.future).timeout(const Duration(seconds: 3));
        habitudes = HabitudesDuPalais.resumer(journal, fr: languageCode == 'fr');
      } catch (_) {}
      if (!mounted) return;
      // Ce qui a déjà été dit sur cette carte, sans la question en cours : elle part à part.
      final echange = [for (final m in _messages) if (!m.horsEchange) m];
      final historique = [
        for (final m in echange.take(echange.length - 1)) (role: m.isUser ? 'user' : 'assistant', texte: m.text),
      ];
      final answer = await scanService.askMenuSommelier(
        menu: widget.menu,
        userQuestion: clean,
        userProfile: activeProfile,
        languageCode: languageCode,
        habitudes: habitudes,
        historique: historique,
      );

      if (mounted) {
        setState(() {
          _messages.add(MenuChatMessage(text: answer, isUser: false, time: DateTime.now()));
          _isLoading = false;
        });
        _scrollToBottom();
        await ConversationsDeCarte.ecrire(widget.menu.id, _messages);
      }
    } catch (e) {
      if (mounted) {
        final isFr = Localizations.localeOf(context).languageCode == 'fr';
        setState(() {
          _messages.add(MenuChatMessage(
            text: trSi(isFr, 'Désolé, une erreur est survenue : {e}', 'Sorry, an error occurred: {e}', {'e': e}),
            isUser: false,
            time: DateTime.now(),
            horsEchange: true,
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
    final quickPrompts = [for (final p in _suggestions) p.dans(isFr)];

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
                        trSi(isFr, 'Conseil Sommelier sur cette carte', 'Sommelier Advice on this Wine List'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        trSi(isFr, '{restaurantName} • {wines_length} vins analysés', '{restaurantName} • {wines_length} wines analyzed', {'restaurantName': widget.menu.restaurantName, 'wines_length': widget.menu.wines.length}),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (_messages.any((m) => !m.horsEchange))
                  IconButton(
                    tooltip: tr('Effacer la conversation', 'Clear conversation'),
                    onPressed: _effacer,
                    icon: const Icon(Icons.delete_sweep_outlined),
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
                    // Le sommelier écrit en Markdown (gras pour les vins et les prix) : en texte
                    // brut, les « ** » s'affichaient tels quels (01/10). Même rendu que le chat.
                    child: msg.isUser
                        ? Text(
                            msg.text,
                            style: const TextStyle(fontSize: 13.5, color: Colors.white, height: 1.4),
                          )
                        : MarkdownBody(
                            data: msg.text,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.4,
                              ),
                              strong: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFE2C480) : const Color(0xFF8B1E3F),
                                height: 1.4,
                              ),
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
                  Text(trSi(isFr, 'Le sommelier réfléchit...', 'Sommelier reflecting...'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                      hintText: trSi(isFr, 'Ex: Quel vin pour du canard rôti ?', 'E.g.: Which wine for roasted duck?'),
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
