import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/wine_merchant_service.dart';
import '../domain/wine_merchant.dart';

class WineMerchantSearchDialog extends ConsumerStatefulWidget {
  const WineMerchantSearchDialog({super.key});

  static Future<WineMerchant?> show(BuildContext context) {
    return showModalBottomSheet<WineMerchant>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WineMerchantSearchDialog(),
    );
  }

  @override
  ConsumerState<WineMerchantSearchDialog> createState() => _WineMerchantSearchDialogState();
}

class _WineMerchantSearchDialogState extends ConsumerState<WineMerchantSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<WineMerchant> _results = [];
  bool _isLoading = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialMerchants();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMerchants() async {
    final service = ref.read(wineMerchantServiceProvider);
    final list = await service.getMerchants();
    if (mounted) {
      setState(() => _results = list);
    }
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean == _lastQuery) return;
    _lastQuery = clean;

    if (clean.isEmpty) {
      await _loadInitialMerchants();
      return;
    }

    setState(() => _isLoading = true);
    final service = ref.read(wineMerchantServiceProvider);
    final results = await service.searchOnlineMerchants(clean);

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmAndSaveMerchant(WineMerchant candidate) async {
    final notesCtrl = TextEditingController(text: candidate.notes ?? '');
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          final isDark = theme.brightness == Brightness.dark;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront, color: Color(0xFFD4AF37), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Confirmer le Caviste', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Confirmation Map / Pin Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1A24) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pin_drop, color: Color(0xFF8B1E3F), size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                candidate.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          candidate.fullAddressDisplay,
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        if (candidate.latitude != null && candidate.longitude != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.map_outlined, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'GPS : ${candidate.latitude!.toStringAsFixed(4)}, ${candidate.longitude!.toStringAsFixed(4)} (Google Maps Grounded)',
                                style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Notes ou contact (optionnel) :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ex: Conseillé par Pierre, spécialité Champagne...',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F), foregroundColor: Colors.white),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Confirmer & Enregistrer'),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          );
        },
      );

      if (confirmed == true && mounted) {
        final finalMerchant = candidate.copyWith(notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null);
        final service = ref.read(wineMerchantServiceProvider);
        await service.saveMerchant(finalMerchant);
        ref.invalidate(wineMerchantsProvider);
        if (mounted) {
          Navigator.of(context).pop(finalMerchant);
        }
      }
    } finally {
      notesCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront, color: Color(0xFF8B1E3F), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rechercher ou Ajouter un Caviste',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Recherche Google Maps & Carnet de Cavistes',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onSubmitted: _performSearch,
              onChanged: (val) {
                if (val.length >= 3) {
                  _performSearch(val);
                } else if (val.isEmpty) {
                  _performSearch('');
                }
              },
              decoration: InputDecoration(
                hintText: 'Nom du caviste, ville ou adresse (ex: Lavinia, Paris)...',
                hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8B1E3F)),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => _performSearch(_searchCtrl.text),
                      ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1A24) : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          const Divider(height: 1),

          // Results list
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('Aucun caviste trouvé', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text(
                            'Saisissez le nom d\'une boutique ou d\'une ville pour chercher sur Google Maps.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          if (_searchCtrl.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF8B1E3F),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: Text('Créer "${_searchCtrl.text.trim()}"', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                final manual = WineMerchant.create(
                                  name: _searchCtrl.text.trim(),
                                  address: 'Adresse personnalisée',
                                );
                                _confirmAndSaveMerchant(manual);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.isFavorite
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                                : const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.isFavorite ? Icons.star : Icons.storefront,
                            color: item.isFavorite ? const Color(0xFFD4AF37) : const Color(0xFF8B1E3F),
                            size: 20,
                          ),
                        ),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          item.fullAddressDisplay,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                        ),
                        trailing: const Icon(Icons.check_circle_outline, color: Color(0xFF8B1E3F), size: 20),
                        onTap: () => _confirmAndSaveMerchant(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
