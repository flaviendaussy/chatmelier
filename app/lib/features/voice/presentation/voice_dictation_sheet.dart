import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/voice_command_parser.dart';
import '../../chat/data/chat_service.dart';
import '../../../shared/providers/cellar_provider.dart';

class VoiceDictationSheet extends ConsumerStatefulWidget {
  const VoiceDictationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const VoiceDictationSheet(),
    );
  }

  @override
  ConsumerState<VoiceDictationSheet> createState() => _VoiceDictationSheetState();
}

class _VoiceDictationSheetState extends ConsumerState<VoiceDictationSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  bool _isListening = true;
  bool _isProcessing = false;
  String _statusText = 'Parlez naturellement : "Sortir 1 bouteille de Margaux", "Ajouter un Chablis 2020"...';
  String? _resultMessage;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Simulate natural voice recognition prompt or ready state
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _processVoiceCommand(String rawCommand) async {
    if (rawCommand.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _isListening = false;
      _statusText = 'Analyse de votre commande en cours...';
    });

    final parsed = VoiceCommandParser.parse(rawCommand);
    final repo = ref.read(cellarRepositoryProvider);
    String? activeCellarId = ref.read(currentCellarIdProvider);

    if (activeCellarId == null || activeCellarId.isEmpty) {
      final cellars = await repo.getUserCellarsWithRole();
      if (cellars.isNotEmpty) {
        final first = cellars.first;
        final cMap = first['cellars'];
        if (cMap is Map) {
          activeCellarId = cMap['id']?.toString();
        } else {
          activeCellarId = first['cellar_id']?.toString();
        }
        if (activeCellarId != null) {
          ref.read(currentCellarIdProvider.notifier).state = activeCellarId;
        }
      }
    }

    try {
      // 1. COMMANDE DE SORTIE / DÉGUSTATION (CHECKOUT)
      if (parsed.actionType == VoiceActionType.checkout) {
        final bottles = await repo.getBottles(activeCellarId ?? '');
        if (bottles.isEmpty) {
          setState(() {
            _resultMessage = '⚠️ Aucune bouteille trouvée dans la cave active.';
            _isProcessing = false;
          });
          return;
        }

        // Match bottle by words in command
        final targetName = (parsed.wineName ?? '').toLowerCase();
        final targetVintage = parsed.vintage?.toString() ?? '';

        final match = bottles.firstWhere(
          (b) {
            final name = b.wine?.name.toLowerCase() ?? '';
            final prod = (b.wine?.producer ?? '').toLowerCase();
            final vintage = b.wine?.vintage?.toString() ?? '';
            return (targetName.isNotEmpty && (name.contains(targetName) || targetName.contains(name))) ||
                (prod.isNotEmpty && targetName.contains(prod)) ||
                (targetVintage.isNotEmpty && vintage == targetVintage);
          },
          orElse: () => bottles.first,
        );

        await repo.consumeBottle(
          match.id,
          cellarId: match.cellarId,
          rating: null,
          notes: null,
        );

        notifyCellarChanged(ref, activeCellarId);
        setState(() {
          final wineName = match.wine?.name ?? 'Bouteille';
          final wineVintage = match.wine?.vintage?.toString() ?? 'NM';
          _resultMessage = '🍾 Bouteille sortie avec succès : $wineName ($wineVintage). Stock mis à jour !';
          _isProcessing = false;
        });
        HapticFeedback.heavyImpact();
        return;
      }

      // 2. COMMANDE D'AJOUT RAPIDE
      if (parsed.actionType == VoiceActionType.add) {
        final cleanName = parsed.wineName ?? 'Vin Déclaré Vocalement';
        final vintage = parsed.vintage;
        final qty = parsed.quantity;
        final wineType = parsed.wineType ?? 'red';

        await repo.addBottle(
          cellarId: activeCellarId ?? '',
          wineName: cleanName,
          vintage: vintage,
          producer: null,
          wineType: wineType,
          quantity: qty,
          shelf: parsed.location,
        );

        notifyCellarChanged(ref, activeCellarId);
        setState(() {
          _resultMessage = '✨ $qty bouteille(s) ajoutée(s) : $cleanName ${vintage != null ? "($vintage)" : ""}${parsed.location != null ? " en ${parsed.location}" : ""}.';
          _isProcessing = false;
        });
        HapticFeedback.heavyImpact();
        return;
      }

      // 3. QUESTION SOMMELIER / ACCORD METS & VINS
      final chatService = ref.read(chatServiceProvider);
      final reply = await chatService.sendMessage(parsed.query ?? rawCommand, activeCellarId);
      setState(() {
        _resultMessage = '🍷 Chatmelier :\n$reply';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Erreur lors du traitement de la commande : $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1722) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mic, color: Color(0xFF8B1E3F), size: 26),
                  const SizedBox(width: 8),
                  Text(
                    'Dictée Vocale Mains Libres',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Waveform Animation / Mic Animation
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final scale = _isListening ? 1.0 + (_waveController.value * 0.25) : 1.0;
              return Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B1E3F).withValues(alpha: _isListening ? 0.15 * scale : 0.08),
                ),
                child: Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? const Color(0xFF8B1E3F) : Colors.grey.shade600,
                    ),
                    child: Icon(
                      _isListening ? Icons.graphic_eq : Icons.mic_none,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Status message
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Result box if any
          if (_resultMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
              ),
              child: Text(
                _resultMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Quick Voice Test / Text Fallback Input
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Ou écrivez ici : "Sortir 1 Margaux 2015"...',
              filled: true,
              fillColor: isDark ? const Color(0xFF262030) : const Color(0xFFF7F4F0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, color: Color(0xFF8B1E3F)),
                onPressed: _isProcessing ? null : () => _processVoiceCommand(_textController.text),
              ),
            ),
            onSubmitted: _processVoiceCommand,
          ),
          const SizedBox(height: 12),

          // Quick Command Suggestions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _VoiceChip(
                  label: '🍷 Sortir 1 bouteille',
                  onTap: () {
                    _textController.text = 'Sortir 1 bouteille de vin pour le repas';
                    _processVoiceCommand(_textController.text);
                  },
                ),
                const SizedBox(width: 8),
                _VoiceChip(
                  label: '➕ Ajouter Chablis 2020',
                  onTap: () {
                    _textController.text = 'Ajouter 1 bouteille de Chablis Grand Cru 2020';
                    _processVoiceCommand(_textController.text);
                  },
                ),
                const SizedBox(width: 8),
                _VoiceChip(
                  label: '🥩 Accord côte de bœuf',
                  onTap: () {
                    _textController.text = 'Quel vin rouge ouvrir pour une côte de bœuf ce soir ?';
                    _processVoiceCommand(_textController.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _VoiceChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
