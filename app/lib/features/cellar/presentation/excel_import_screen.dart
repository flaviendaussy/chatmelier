import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/providers/premium_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/widgets/wine_type_badge.dart';
import '../../monetization/admob_service.dart';
import '../data/excel_import_service.dart';

class ExcelImportScreen extends ConsumerStatefulWidget {
  final String cellarId;

  const ExcelImportScreen({super.key, required this.cellarId});

  @override
  ConsumerState<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends ConsumerState<ExcelImportScreen> {
  String? _selectedFileName;
  List<ImportedWineCandidate> _candidates = [];

  bool _isAnalyzing = false;
  double _analyzeProgress = 0.0;
  String _analyzeStatus = '';

  bool _isImporting = false;
  int _importedCount = 0;

  static const int _freeBatchSize = 15;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv', 'tsv', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fichier vide ou illisible.'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      setState(() {
        _selectedFileName = file.name;
        _candidates.clear();
        _isAnalyzing = true;
        _analyzeProgress = 0.1;
        _analyzeStatus = 'Lecture et extraction du fichier...';
      });

      // 1. Extract text lines
      final rows = ExcelImportService.extractRawRows(bytes: bytes, fileName: file.name);

      if (rows.isEmpty) {
        setState(() {
          _isAnalyzing = false;
          _analyzeStatus = 'Aucune ligne de texte trouvée dans le fichier.';
        });
        return;
      }

      // 2. Normalize with Gemini in batches of 15-20 rows
      final importService = ExcelImportService();
      final List<ImportedWineCandidate> allCandidates = [];
      const batchChunk = 15;
      final totalBatches = (rows.length / batchChunk).ceil().clamp(1, 10); // Cap at 10 batches (150 rows)

      for (int b = 0; b < totalBatches; b++) {
        if (!mounted) break;
        final start = b * batchChunk;
        final end = (start + batchChunk < rows.length) ? start + batchChunk : rows.length;
        final chunk = rows.sublist(start, end);

        setState(() {
          _analyzeProgress = 0.1 + (0.85 * (b / totalBatches));
          _analyzeStatus = 'Analyse sommelier par IA (lot ${b + 1}/$totalBatches)...';
        });

        final batchCandidates = await importService.normalizeWineBatch(chunk);
        allCandidates.addAll(batchCandidates);
      }

      if (mounted) {
        setState(() {
          _candidates = allCandidates;
          _isAnalyzing = false;
          _analyzeProgress = 1.0;
          _analyzeStatus = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ ${_candidates.length} vins identifiés avec succès !'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('EXCEL_IMPORT', 'File pick or analysis error', e);
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analyzeStatus = 'Erreur: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'import : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleSelectAll(bool? selected) {
    setState(() {
      for (final c in _candidates) {
        c.isSelected = selected ?? false;
      }
    });
  }

  Future<void> _executeImport({required bool isFreeBatch}) async {
    final selectedCandidates = _candidates.where((c) => c.isSelected).toList();
    if (selectedCandidates.isEmpty) return;

    final isPremium = ref.read(premiumProvider);
    final limit = (!isPremium && isFreeBatch) ? _freeBatchSize : selectedCandidates.length;
    final batchToImport = selectedCandidates.take(limit).toList();

    setState(() => _isImporting = true);

    try {
      final repo = ref.read(cellarRepositoryProvider);
      int count = 0;

      for (final wine in batchToImport) {
        await repo.addBottle(
          cellarId: widget.cellarId,
          wineName: wine.name,
          producer: wine.producer,
          vintage: wine.vintage,
          wineType: wine.type,
          country: wine.country ?? 'France',
          region: wine.region ?? 'Bordeaux',
          appellation: wine.appellation,
          quantity: wine.quantity,
          purchasePrice: wine.purchasePrice,
          currency: wine.currency,
          bottleSize: wine.bottleSize,
          rack: wine.rack,
          shelf: wine.shelf,
        );
        count += wine.quantity;
      }

      // Remove imported candidates from list
      setState(() {
        _candidates.removeWhere((c) => batchToImport.contains(c));
        _importedCount += count;
        _isImporting = false;
      });

      notifyCellarChanged(ref, widget.cellarId);

      if (!mounted) return;

      if (!isPremium && _candidates.isNotEmpty) {
        // Show real AdMob rewarded ad if available between batches; otherwise proceed directly (no fake ads)
        await AdMobService().showRewardedAd(
          onRewardEarned: () {},
          onAdDismissed: () {},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Lot de $count bouteilles importé ! Prêt pour le lot suivant.'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        }
      } else {
        // Full completion
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 28),
                SizedBox(width: 10),
                Text('Import Terminé !'),
              ],
            ),
            content: Text(
              'Félicitations ! $_importedCount bouteilles ont été intégrées dans votre cave avec tous leurs détails sommelier.',
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
                child: const Text('Voir ma cave'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      AppLogger.error('EXCEL_IMPORT', 'Import execution failed', e);
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPremium = ref.watch(premiumProvider);

    final selectedCount = _candidates.where((c) => c.isSelected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Importer une liste Excel / CSV'),
        actions: [
          if (_candidates.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recommencer l\'import',
              onPressed: _pickFile,
            ),
        ],
      ),
      body: _isAnalyzing
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 48),
                    const SizedBox(height: 20),
                    Text('Analyse sommelier par IA...', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(_analyzeStatus, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _analyzeProgress,
                        minHeight: 8,
                        backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                        color: const Color(0xFF8B1E3F),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _candidates.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                          ),
                          child: const Icon(Icons.table_chart_outlined, size: 64, color: Color(0xFF8B1E3F)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Importez votre cave en quelques secondes',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Compatible avec tous les fichiers Excel (.xlsx), CSV, et listes texte. L\'IA identifie automatiquement les domaines, millésimes, couleurs et formats.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                        ),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          onPressed: _pickFile,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1E3F),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.file_upload_outlined, size: 22),
                          label: const Text('Choisir un fichier (.xlsx ou .csv)', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 16),
                        if (_selectedFileName != null && _candidates.isEmpty)
                          Text(
                            'Dernier fichier sélectionné : $_selectedFileName (0 vin extrait)',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Header Bar: File name & Selection toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      child: Row(
                        children: [
                          Checkbox(
                            value: selectedCount == _candidates.length,
                            tristate: selectedCount > 0 && selectedCount < _candidates.length,
                            onChanged: _toggleSelectAll,
                          ),
                          Text(
                            '$selectedCount / ${_candidates.length} vins sélectionnés',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (!isPremium)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.lock_open, size: 14, color: Color(0xFF9A7B1C)),
                                  SizedBox(width: 4),
                                  Text('Gratuit : 15/lot',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9A7B1C))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Candidates List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _candidates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final wine = _candidates[i];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: wine.isSelected
                                    ? const Color(0xFF8B1E3F).withValues(alpha: 0.5)
                                    : theme.dividerColor.withValues(alpha: 0.3),
                                width: wine.isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: wine.isSelected,
                                    onChanged: (val) {
                                      setState(() => wine.isSelected = val ?? false);
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                wine.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ),
                                            if (wine.vintage != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF8B1E3F).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${wine.vintage}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Color(0xFF8B1E3F),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${wine.producer ?? "Domaine inconnu"} • ${wine.region ?? "France"}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            WineTypeBadge(type: wine.type),
                                            const SizedBox(width: 8),
                                            // Format pill
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                wine.bottleSize,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            // Quantity stepper
                                            IconButton(
                                              visualDensity: VisualDensity.compact,
                                              icon: const Icon(Icons.remove, size: 16),
                                              onPressed: wine.quantity > 1
                                                  ? () => setState(() => wine.quantity--)
                                                  : null,
                                            ),
                                            Text('x${wine.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            IconButton(
                                              visualDensity: VisualDensity.compact,
                                              icon: const Icon(Icons.add, size: 16),
                                              onPressed: () => setState(() => wine.quantity++),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom Action Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isPremium && selectedCount > _freeBatchSize)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 16, color: Color(0xFFD4AF37)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Import gratuit par lot de $_freeBatchSize vins (avec pause vidéo) ou instantané avec Privilège.',
                                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: (_isImporting || selectedCount == 0)
                                        ? null
                                        : () => _executeImport(isFreeBatch: true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B1E3F),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: _isImporting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.download_done, size: 20),
                                    label: Text(
                                      !isPremium && selectedCount > _freeBatchSize
                                          ? 'Importer le 1er lot ($_freeBatchSize vins)'
                                          : 'Importer les $selectedCount vins',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
