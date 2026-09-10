import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/custom_cocktail_service.dart';
import '../domain/cocktail.dart';

class SaveCocktailDialog extends ConsumerStatefulWidget {
  final Cocktail cocktail;
  final String? initialName;

  const SaveCocktailDialog({
    super.key,
    required this.cocktail,
    this.initialName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Cocktail cocktail,
    String? initialName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => SaveCocktailDialog(
        cocktail: cocktail,
        initialName: initialName,
      ),
    );
  }

  @override
  ConsumerState<SaveCocktailDialog> createState() => _SaveCocktailDialogState();
}

class _SaveCocktailDialogState extends ConsumerState<SaveCocktailDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialName ?? widget.cocktail.name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final suggestedName = widget.cocktail.name;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bookmark_add, color: Color(0xFF8B1E3F), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isFr ? 'Enregistrer le cocktail' : 'Save cocktail',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFr
                    ? 'Ajoutez cette création à vos recettes pour la retrouver dans votre catalogue de cocktails.'
                    : 'Add this creation to your recipes to find it in your cocktail catalog.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isFr ? 'Nom de la recette :' : 'Recipe name:',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: isFr ? 'Ex: Mon Negroni Parfumé' : 'e.g. My Fragrant Negroni',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                  suffixIcon: _nameController.text != suggestedName
                      ? IconButton(
                          icon: const Icon(Icons.restore, size: 20),
                          tooltip: isFr ? 'Rétablir le nom suggéré par Chatmelier' : 'Restore name suggested by Chatmelier',
                          onPressed: () {
                            setState(() {
                              _nameController.text = suggestedName;
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return isFr ? 'Veuillez saisir un nom pour ce cocktail' : 'Please enter a name for this cocktail';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Suggestion pill
              if (_nameController.text.trim() != suggestedName.trim())
                InkWell(
                  onTap: () {
                    setState(() {
                      _nameController.text = suggestedName;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFD4AF37)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isFr ? 'Nom suggéré : "$suggestedName"' : 'Suggested name: "$suggestedName"',
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9F9FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '🥃 ${widget.cocktail.baseSpirit.toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          widget.cocktail.localizedGlass(isFr),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.cocktail.ingredients.length} ${isFr ? "ingrédients" : "ingredients"} • ${widget.cocktail.localizedMethod(isFr)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(isFr ? 'Annuler' : 'Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B1E3F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.check, size: 18),
          label: Text(isFr ? 'Enregistrer la recette' : 'Save recipe'),
          onPressed: () => _save(isFr),
        ),
      ],
    );
  }

  void _save(bool isFr) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final chosenName = _nameController.text.trim();
    await ref.read(customCocktailsProvider.notifier).saveCocktail(
          widget.cocktail,
          preferredName: chosenName,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFr
                ? 'Cocktail "$chosenName" enregistré dans votre bar ! 🍸'
                : 'Cocktail "$chosenName" saved to your bar! 🍸',
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }
}
