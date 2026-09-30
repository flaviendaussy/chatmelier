import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/providers/cellar_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../data/furniture_vision_service.dart';
import '../domain/cellar_furniture.dart';
import '../../../shared/utils/langue.dart';

class FurnitureEditorDialog extends ConsumerStatefulWidget {
  final CellarFurniture? initialFurniture;
  final String cellarId;

  const FurnitureEditorDialog({
    super.key,
    this.initialFurniture,
    required this.cellarId,
  });

  static Future<CellarFurniture?> show(
    BuildContext context, {
    CellarFurniture? initialFurniture,
    required String cellarId,
  }) {
    return showDialog<CellarFurniture>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FurnitureEditorDialog(
        initialFurniture: initialFurniture,
        cellarId: cellarId,
      ),
    );
  }

  @override
  ConsumerState<FurnitureEditorDialog> createState() => _FurnitureEditorDialogState();
}

class _FurnitureEditorDialogState extends ConsumerState<FurnitureEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _shapeType;
  late int _columns;
  late int _rows;
  late List<List<bool>> _slotsMatrix;
  bool _isSaving = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialFurniture;
    _nameController = TextEditingController(text: init?.name ?? 'Casier principal');
    _shapeType = init?.shapeType ?? 'rectangle';
    _columns = init?.columns ?? 6;
    _rows = init?.rows ?? 6;
    if (_shapeType == CellarFurniture.shapeCupboard) {
      _columns = 1;
      _slotsMatrix = CellarFurniture.generateMatrix(
        shapeType: _shapeType,
        columns: 1,
        rows: _rows,
      );
    } else if (init != null) {
      _slotsMatrix = init.slotsMatrix.map((r) => List<bool>.from(r)).toList();
    } else {
      _slotsMatrix = CellarFurniture.generateMatrix(
        shapeType: _shapeType,
        columns: _columns,
        rows: _rows,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyPreset(String shape) {
    setState(() {
      _shapeType = shape;
      if (shape == CellarFurniture.shapeCupboard) {
        _columns = 1;
        _rows = 3;
      }
      _slotsMatrix = CellarFurniture.generateMatrix(
        shapeType: shape,
        columns: _columns,
        rows: _rows,
      );
    });
  }

  void _updateDimensions(int newCols, int newRows) {
    setState(() {
      if (_shapeType == CellarFurniture.shapeCupboard) {
        _columns = 1;
        _rows = newRows.clamp(1, 14);
      } else {
        _columns = newCols.clamp(2, 12);
        _rows = newRows.clamp(2, 14);
      }

      // Re-generate or adapt matrix
      _slotsMatrix = CellarFurniture.generateMatrix(
        shapeType: _shapeType,
        columns: _columns,
        rows: _rows,
      );
    });
  }

  void _toggleSlot(int c, int r) {
    if (r < 0 || r >= _slotsMatrix.length) return;
    if (c < 0 || c >= _slotsMatrix[r].length) return;
    setState(() {
      _slotsMatrix[r][c] = !_slotsMatrix[r][c];
      _shapeType = 'custom';
    });
  }

  Future<void> _scanFurnitureWithCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _isScanning = true);
    try {
      final visionService = FurnitureVisionService();
      final layout = await visionService.analyzeFurnitureImage(imagePath: image.path);

      if (mounted) {
        setState(() {
          _nameController.text = layout.name;
          _columns = layout.columns;
          _rows = layout.rows;
          _shapeType = layout.shapeType;
          _slotsMatrix = layout.slotsMatrix;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('✨ Meuble analysé : {columns}x{rows} ({layout_name})', '✨ Rack analysed: {columns}x{rows} ({layout_name})', {'columns': layout.columns, 'rows': layout.rows, 'layout_name': layout.name})),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('FURNITURE_SCAN', 'Failed to scan furniture', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Impossible d\'analyser la photo du meuble. Ajustez manuellement.', 'Couldn\'t analyse the photo of the rack. Adjust it by hand.')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(cellarRepositoryProvider);
      CellarFurniture result;

      if (_shapeType == CellarFurniture.shapeCupboard) {
        _columns = 1;
        _slotsMatrix = CellarFurniture.generateMatrix(
          shapeType: _shapeType,
          columns: 1,
          rows: _rows,
        );
      }

      if (widget.initialFurniture != null) {
        final updated = widget.initialFurniture!.copyWith(
          name: _nameController.text.trim(),
          shapeType: _shapeType,
          columns: _columns,
          rows: _rows,
          slotsMatrix: _slotsMatrix,
        );
        await repo.updateFurniture(updated);
        result = updated;
      } else {
        result = await repo.createFurniture(
          cellarId: widget.cellarId,
          name: _nameController.text.trim(),
          shapeType: _shapeType,
          columns: _columns,
          rows: _rows,
          slotsMatrix: _slotsMatrix,
        );
      }

      notifyCellarChanged(ref, widget.cellarId);
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      AppLogger.error('FURNITURE_EDITOR', 'Failed to save furniture', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Erreur lors de l\'enregistrement : {e}', 'Couldn\'t save: {e}', {'e': e})),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  int get _activeSlotsCount {
    int count = 0;
    for (final row in _slotsMatrix) {
      for (final cell in row) {
        if (cell) count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.grid_view_rounded, color: Color(0xFF8B1E3F), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.initialFurniture != null ? tr('Modifier le meuble', 'Edit the rack') : tr('Nouveau meuble de cave', 'New cellar rack'),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + Scan Button Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: tr('Nom du meuble *', 'Rack name *'),
                                  hintText: tr('ex: Casier chêne, Étagère A...', 'e.g. Oak rack, Shelf A...'),
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? tr('Requis', 'Required') : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonalIcon(
                              onPressed: _isScanning ? null : _scanFurnitureWithCamera,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              icon: _isScanning
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.photo_camera, size: 18),
                              label: Text(tr('Scanner', 'Scan')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Preset Shapes
                        Text(
                          tr('Disposition / Forme', 'Layout / shape'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ChoiceChip(
                              avatar: const Icon(Icons.table_restaurant_outlined, size: 16),
                              label: Text(tr('Casier Rectangle', 'Rectangular rack')),
                              selected: _shapeType == 'rectangle',
                              onSelected: (s) {
                                if (s) _applyPreset('rectangle');
                              },
                            ),
                            ChoiceChip(
                              avatar: const Icon(Icons.kitchen_outlined, size: 16),
                              label: Text(tr('Placard / Rangement libre', 'Cupboard / free storage')),
                              selected: _shapeType == 'cupboard',
                              onSelected: (s) {
                                if (s) _applyPreset('cupboard');
                              },
                            ),
                            ChoiceChip(
                              avatar: const Icon(Icons.change_history, size: 16),
                              label: Text(tr('Triangle / Pyramide', 'Triangle / pyramid')),
                              selected: _shapeType == 'triangle',
                              onSelected: (s) {
                                if (s) _applyPreset('triangle');
                              },
                            ),
                            ChoiceChip(
                              avatar: const Icon(Icons.view_week_outlined, size: 16),
                              label: Text(tr('Décalé 4+2', 'Staggered 4+2')),
                              selected: _shapeType == 'staggered_4_2',
                              onSelected: (s) {
                                if (s) _applyPreset('staggered_4_2');
                              },
                            ),
                            ChoiceChip(
                              avatar: const Icon(Icons.tune, size: 16),
                              label: Text(tr('Personnalisé', 'Custom')),
                              selected: _shapeType == 'custom',
                              onSelected: (s) {
                                if (s) setState(() => _shapeType = 'custom');
                              },
                            ),
                          ],
                        ),
                        if (_shapeType == 'cupboard') ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.kitchen_outlined, color: Color(0xFFD4AF37), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tr('Placard / Étagère libre : les bouteilles sont disposées librement sans case fixe (placard de cuisine, buffet, étagère en vrac). Vous pouvez ajouter, retirer ou déplacer vos bouteilles à tout moment sans contrainte de coordonnées.', 'Cupboard / open shelf: bottles sit freely with no fixed slot (kitchen cupboard, sideboard, open shelving). Add, remove or move bottles at any time, with no coordinates to respect.'),
                                    style: const TextStyle(fontSize: 12, height: 1.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Dimensions Row (Columns x Rows)
                        if (_shapeType != CellarFurniture.shapeCupboard) ...[
                          Row(
                            children: [
                              // Columns
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tr('Colonnes (A-{v1})', 'Columns (A-{v1})', {'v1': String.fromCharCode(64 + _columns)}),
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: const Icon(Icons.remove, size: 18),
                                            onPressed: _columns > 2 ? () => _updateDimensions(_columns - 1, _rows) : null,
                                          ),
                                          Expanded(
                                            child: Text('$_columns',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          ),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: const Icon(Icons.add, size: 18),
                                            onPressed: _columns < 12 ? () => _updateDimensions(_columns + 1, _rows) : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Rows
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tr('Rangées (1-{rows})', 'Rows (1-{rows})', {'rows': _rows}),
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: const Icon(Icons.remove, size: 18),
                                            onPressed: _rows > 1 ? () => _updateDimensions(_columns, _rows - 1) : null,
                                          ),
                                          Expanded(
                                            child: Text('$_rows',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          ),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: const Icon(Icons.add, size: 18),
                                            onPressed: _rows < 14 ? () => _updateDimensions(_columns, _rows + 1) : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Capacity & Interactive Block Grid Header
                          Row(
                            children: [
                              Text(
                                tr('Modélisation en blocs', 'Block model'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tr('{activeSlotsCount} places actives', '{activeSlotsCount} active slots', {'activeSlotsCount': _activeSlotsCount}),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9A7B1C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('Touchez un bloc pour l\'activer ou le désactiver selon votre meuble réel.', 'Tap a block to turn it on or off to match your actual rack.'),
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),

                          // Interactive 2D Blocks Grid
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F2EB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Column Letters Header (A, B, C...)
                                Row(
                                  children: [
                                    const SizedBox(width: 24),
                                    ...List.generate(_columns, (c) {
                                      return Expanded(
                                        child: Text(
                                          String.fromCharCode(65 + c),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ...List.generate(_rows, (r) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          child: Text(
                                            '${r + 1}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        ...List.generate(_columns, (c) {
                                          final isActive = (r < _slotsMatrix.length && c < _slotsMatrix[r].length)
                                              ? _slotsMatrix[r][c]
                                              : false;
                                          return Expanded(
                                            child: GestureDetector(
                                              onTap: () => _toggleSlot(c, r),
                                              child: Container(
                                                height: 32,
                                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? const Color(0xFF8B1E3F).withValues(alpha: 0.85)
                                                      : (isDark ? Colors.white10 : Colors.grey.shade300),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: isActive
                                                        ? const Color(0xFF6B142F)
                                                        : Colors.transparent,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: isActive
                                                      ? const Icon(Icons.wine_bar, size: 14, color: Colors.white)
                                                      : const Icon(Icons.close, size: 10, color: Colors.black26),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ] else ...[
                          // CUPBOARD MODE: No width, no min/max capacity, only number of shelves
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.table_rows_outlined, size: 18, color: Color(0xFF8B1E3F)),
                                    const SizedBox(width: 8),
                                    Text(
                                      tr('Nombre d\'étagères / niveaux', 'Number of shelves / levels'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        tr('Capacité libre & indéfinie', 'Free, open-ended capacity'),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF9A7B1C),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('Placement totalement libre : chaque étagère accueille vos bouteilles en vrac, sans largeur ni contrainte de nombre.', 'Completely free placement: each shelf holds your bottles loosely, with no width or number limit.'),
                                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    IconButton.filledTonal(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: _rows > 1 ? () => _updateDimensions(1, _rows - 1) : null,
                                    ),
                                    Expanded(
                                      child: Text(
                                        tr('{rows} étagère{v1}', '{rows} shel{v2}', {'rows': _rows, 'v1': _rows > 1 ? "s" : "", 'v2': _rows > 1 ? "ves" : "f"}),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: _rows < 14 ? () => _updateDimensions(1, _rows + 1) : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Cupboard preview without blocks or columns
                          Row(
                            children: [
                              Text(
                                tr('Aperçu du meuble', 'Rack preview'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Spacer(),
                              Text(
                                tr('{rows} étagères ouvertes', '{rows} open shelves', {'rows': _rows}),
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF282522) : const Color(0xFFECE5D8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF8C7355), width: 3),
                            ),
                            child: Column(
                              children: List.generate(_rows, (r) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 5),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Color(0xFF8C7355), width: 4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.table_rows_outlined, size: 16, color: Color(0xFF8C7355)),
                                      const SizedBox(width: 8),
                                      Text(
                                        tr('Étagère {v1}', 'Shelf {v1}', {'v1': r + 1}),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      const Spacer(),
                                      Text(
                                        tr('Rangement libre • Quantité indéfinie', 'Free storage • Any quantity'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(tr('Annuler', 'Cancel')),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E3F),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(tr('Enregistrer le meuble', 'Save the rack')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
