import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/wine_merchant_service.dart';
import 'wine_merchant_search_dialog.dart';

class BottleProvenancePicker extends ConsumerStatefulWidget {
  final String? initialSourceType;
  final String? initialSourceDetails;
  final void Function(String sourceType, String? sourceDetails) onChanged;

  const BottleProvenancePicker({
    super.key,
    this.initialSourceType,
    this.initialSourceDetails,
    required this.onChanged,
  });

  @override
  ConsumerState<BottleProvenancePicker> createState() => _BottleProvenancePickerState();
}

class _BottleProvenancePickerState extends ConsumerState<BottleProvenancePicker> {
  late String _selectedType;
  late TextEditingController _detailsCtrl;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialSourceType ?? 'estate';
    _detailsCtrl = TextEditingController(text: widget.initialSourceDetails ?? '');
  }

  @override
  void didUpdateWidget(covariant BottleProvenancePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSourceType != null && widget.initialSourceType != _selectedType) {
      _selectedType = widget.initialSourceType!;
    }
    if (widget.initialSourceDetails != null && widget.initialSourceDetails != _detailsCtrl.text) {
      _detailsCtrl.text = widget.initialSourceDetails!;
    }
  }

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged(_selectedType, _detailsCtrl.text.trim().isNotEmpty ? _detailsCtrl.text.trim() : null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final merchantsAsync = ref.watch(wineMerchantsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.place_outlined, size: 18, color: Color(0xFF8B1E3F)),
            const SizedBox(width: 8),
            Text(
              'Provenance & Origine de la Bouteille',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Type selection chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTypeChip('estate', '🏰 Domaine', 'Acheté au domaine'),
              const SizedBox(width: 8),
              _buildTypeChip('merchant', '🏪 Caviste', 'Chez un caviste'),
              const SizedBox(width: 8),
              _buildTypeChip('gift', '🎁 Cadeau', 'Offert par un proche'),
              const SizedBox(width: 8),
              _buildTypeChip('supermarket', '🛒 Grande Surface', 'Enseigne / Épicerie'),
              const SizedBox(width: 8),
              _buildTypeChip('auction', '🔨 Enchères', 'Vente privée / Enchères'),
              const SizedBox(width: 8),
              _buildTypeChip('other', '📦 Autre', 'Stock personnel'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Dynamic contextual input
        if (_selectedType == 'merchant') ...[
          merchantsAsync.when(
            data: (merchants) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: merchants.any((m) => m.name == _detailsCtrl.text)
                              ? _detailsCtrl.text
                              : null,
                          hint: const Text('Choisir un caviste enregistré...', style: TextStyle(fontSize: 13)),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: merchants
                              .map((m) => DropdownMenuItem(
                                    value: m.name,
                                    child: Text(
                                      '${m.name} (${m.city ?? "France"})',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _detailsCtrl.text = val);
                              _notifyChange();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.search, size: 20),
                        tooltip: 'Chercher sur Google Maps',
                        onPressed: () async {
                          final selected = await WineMerchantSearchDialog.show(context);
                          if (selected != null) {
                            setState(() {
                              _detailsCtrl.text = selected.name;
                            });
                            _notifyChange();
                          }
                        },
                      ),
                    ],
                  ),
                  if (_detailsCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '🏪 Caviste sélectionné : ${_detailsCtrl.text}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8B1E3F), fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => TextField(
              controller: _detailsCtrl,
              decoration: InputDecoration(
                hintText: 'Nom du caviste...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    final selected = await WineMerchantSearchDialog.show(context);
                    if (selected != null) {
                      setState(() => _detailsCtrl.text = selected.name);
                      _notifyChange();
                    }
                  },
                ),
              ),
              onChanged: (_) => _notifyChange(),
            ),
          ),
        ] else if (_selectedType == 'gift') ...[
          TextField(
            controller: _detailsCtrl,
            decoration: InputDecoration(
              hintText: 'Offert par qui ? (Ex: Camille, Dimitri, Caro...)',
              prefixIcon: const Icon(Icons.card_giftcard, color: Colors.amber),
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (_) => _notifyChange(),
          ),
        ] else if (_selectedType == 'estate') ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1E3F).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF8B1E3F).withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.castle_outlined, size: 16, color: Color(0xFF8B1E3F)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Acheté directement au domaine viticole / à la propriété.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ] else if (_selectedType == 'supermarket') ...[
          TextField(
            controller: _detailsCtrl,
            decoration: InputDecoration(
              hintText: 'Enseigne ou magasin (Ex: Leclerc, Monoprix, Carrefour...)',
              prefixIcon: const Icon(Icons.shopping_cart_outlined),
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (_) => _notifyChange(),
          ),
        ] else if (_selectedType == 'auction') ...[
          TextField(
            controller: _detailsCtrl,
            decoration: InputDecoration(
              hintText: 'Maison de vente ou site (Ex: iDealwine, Drouot, Sotheby\'s...)',
              prefixIcon: const Icon(Icons.gavel_outlined),
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (_) => _notifyChange(),
          ),
        ] else ...[
          TextField(
            controller: _detailsCtrl,
            decoration: InputDecoration(
              hintText: 'Détails de provenance (optionnel)...',
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (_) => _notifyChange(),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeChip(String type, String label, String tooltip) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.2),
      onSelected: (sel) {
        if (sel) {
          setState(() {
            _selectedType = type;
            if (type == 'estate' && _detailsCtrl.text.isEmpty) {
              _detailsCtrl.text = 'Domaine';
            }
          });
          _notifyChange();
        }
      },
    );
  }
}
