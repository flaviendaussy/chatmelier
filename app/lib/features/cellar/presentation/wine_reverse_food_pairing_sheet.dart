import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../domain/wine.dart';
import '../domain/wine_reverse_pairing_engine.dart';

class WineReverseFoodPairingSheet extends StatefulWidget {
  final Wine wine;

  const WineReverseFoodPairingSheet({super.key, required this.wine});

  static Future<void> show(BuildContext context, Wine wine) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WineReverseFoodPairingSheet(wine: wine),
    );
  }

  @override
  State<WineReverseFoodPairingSheet> createState() => _WineReverseFoodPairingSheetState();
}

class _WineReverseFoodPairingSheetState extends State<WineReverseFoodPairingSheet> {
  late List<ReverseFoodPairing> _pairings;
  int _selectedPairingIndex = 0;

  String get _langCode => Localizations.maybeLocaleOf(context)?.languageCode ?? 'fr';

  String _t(String en, String es, String ca, String la, String fr) {
    switch (_langCode) {
      case 'en': return en;
      case 'es': return es;
      case 'ca': return ca;
      case 'la': return la;
      default: return fr;
    }
  }

  @override
  void initState() {
    super.initState();
    _pairings = WineReversePairingEngine.getPairingsForWine(widget.wine);
  }

  void _askSommelierForRecipe(ReverseFoodPairing pairing) {
    final wineName = '${widget.wine.producer} ${widget.wine.name} ${widget.wine.vintage ?? ""}';
    final grapesStr = widget.wine.grapes.map((g) => g.name).join(", ");
    final prompt = switch (_langCode) {
      'en' => 'Chatmelier, please provide the complete gourmet recipe and chef secrets to cook "${pairing.dishName}" to elevate my bottle of $wineName (${widget.wine.region}, $grapesStr). Explain cooking temperatures and molecular pairings.',
      'es' => 'Chatmelier, dame la receta gastronómica completa y los secretos de chef para cocinar "${pairing.dishName}" para ensalzar mi botella de $wineName (${widget.wine.region}, $grapesStr). Explica cocciones y maridajes moleculares.',
      'ca' => 'Chatmelier, dóna\'m la recepta gastronòmica completa i els secrets de xef per cuinar "${pairing.dishName}" per sublimar la meva ampolla de $wineName (${widget.wine.region}, $grapesStr). Explica coccions i maridatges moleculars.',
      'la' => 'Chatmelier, da mihi integram formulam culinariam et secreta coquendi pro "${pairing.dishName}" ad illustrandam lagenam meam de $wineName (${widget.wine.region}, $grapesStr).',
      _ => 'Chatmelier, donne-moi la recette gastronomique complète et les secrets de chef pour cuisiner "${pairing.dishName}" afin de sublimer ma bouteille de $wineName (${widget.wine.region}, $grapesStr). Explique les cuissons et accords moléculaires.',
    };

    Navigator.pop(context);
    context.go('/chat', extra: prompt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentPairing = _pairings.isNotEmpty ? _pairings[_selectedPairingIndex] : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF19171C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('👨‍🍳', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('What to cook with this wine?', '¿Qué cocinar con este vino?', 'Què cuinar amb aquest vi?', 'Quid coquendum cum hoc vino?', 'Que cuisiner avec ce vin ?'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${widget.wine.producer} ${widget.wine.name}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

              const Divider(height: 1),

              // Content List
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Horizontal Tab Selector for Suggested Dishes
                    Text(
                      _t('IDEAL RECIPES & MASTER PAIRINGS', 'RECETAS IDEALES EN MARIDAJE MAYOR', 'RECEPTES IDEALS EN MARIDATGE MAJOR', 'PRAECEPTA COQUINARIA OPTIMA', 'RECETTES IDÉALES EN ACCORD MAJEUR'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 54,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _pairings.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (ctx, idx) {
                          final p = _pairings[idx];
                          final isSelected = idx == _selectedPairingIndex;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedPairingIndex = idx);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF722F37)
                                    : (isDark ? const Color(0xFF262022) : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFD4AF37)
                                      : (isDark ? Colors.white12 : Colors.grey.shade300),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(p.categoryIcon, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    p.dishName.length > 25 ? '${p.dishName.substring(0, 22)}...' : p.dishName,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Active Dish Focus Card
                    if (currentPairing != null) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF221E26) : const Color(0xFFFAF8F5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header affinity
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    currentPairing.localizedAffinityLevel(_langCode),
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${currentPairing.affinityPct}% ${_t("Affinity", "Afinidad", "Afinitat", "Affinitas", "Affinité")}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD4AF37),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Dish Title
                            Text(
                              currentPairing.dishName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Key Ingredients
                            Text(
                              _t('KEY INGREDIENTS & RESONANCES', 'INGREDIENTES CLAVE Y RESONANCIAS', 'INGREDIENTS CLAU I RESONÀNCIES', 'ELEMENTA PRAECIPUA & RESONANTIAE', 'INGRÉDIENTS CLÉS & RÉSONANCES'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white60 : Colors.black54,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: currentPairing.keyIngredients.map((ing) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2C2733) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    ing,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 16),

                            // Chef Cooking Advice
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF722F37).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF722F37).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _t("Chef's Cooking Secret:", "Secreto de Cocina del Chef:", "Secret de Cuina del Xef:", "Secretum Coquinandi Magistri:", "Secret de Cuisson du Chef :"),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Color(0xFF8B1E3F),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          currentPairing.cookingAdvice,
                                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Molecular Explanation
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('🔬', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _t("Why the pairing works (Science & Molecules):", "¿Por qué funciona el maridaje? (Ciencia y Moléculas):", "Per què funciona el maridatge? (Ciència i Molècules):", "Cur concordantia valet (Scientia & Moleculae):", "Pourquoi l'accord fonctionne (Science & Molécules) :"),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Color(0xFFD4AF37),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          currentPairing.molecularRationale,
                                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // CTA Button: Ask Chatmelier for full recipe
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF722F37),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          icon: const Text('👨‍🍳', style: TextStyle(fontSize: 18)),
                          label: Text(
                            _t('Ask Chatmelier for the full recipe', 'Pedir la receta completa a Chatmelier', 'Demanar la recepta completa a Chatmelier', 'Roga integram formulam a Chatmelier', 'Demander la recette complète à Chatmelier'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () => _askSommelierForRecipe(currentPairing),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
