/// Represents a physical wine furniture unit (étagère, casier, meuble) in a cellar.
class CellarFurniture {
  static const String shapeRectangle = 'rectangle';
  static const String shapeCupboard = 'cupboard';
  static const String shapeTriangle = 'triangle';
  static const String shapeStaggered = 'staggered_4_2';
  static const String shapeCustom = 'custom';

  final String id;
  final String cellarId;
  final String name;
  final String shapeType; // 'rectangle', 'cupboard', 'triangle', 'staggered_4_2', 'custom'
  final int columns;
  final int rows;
  final List<List<bool>> slotsMatrix; // [row][col] is true if active slot
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CellarFurniture({
    required this.id,
    required this.cellarId,
    required this.name,
    this.shapeType = 'rectangle',
    required this.columns,
    required this.rows,
    required this.slotsMatrix,
    this.createdAt,
    this.updatedAt,
  });

  /// Indicates if this furniture is a loose/bulk cupboard or shelf where bottles
  /// don't have rigid coordinates and can be moved freely without slot tracking.
  bool get isCupboard => shapeType == 'cupboard' || shapeType == 'bulk' || shapeType == 'free_shelf';

  /// Human-readable French label for this furniture shape.
  String get shapeTypeName {
    switch (shapeType) {
      case 'cupboard':
      case 'bulk':
      case 'free_shelf':
        return 'Placard / Rangement libre';
      case 'triangle':
        return 'Casier triangulaire (Pyramide)';
      case 'staggered_4_2':
        return 'Casier décalé 4+2';
      case 'custom':
        return 'Meuble personnalisé';
      case 'rectangle':
      default:
        return 'Casier rectangulaire';
    }
  }

  /// Converts 0-indexed column and row into a sommelier coordinate string.
  /// Example: col 0, row 6 -> 'A7' (Col A, 7th row)
  static String slotCode(int colIndex, int rowIndex) {
    final colLetter = String.fromCharCode(65 + colIndex);
    return '$colLetter${rowIndex + 1}';
  }

  /// Parses a coordinate string like 'A7' into 0-indexed column and row.
  static ({int col, int row})? parseSlotCode(String code) {
    final trimmed = code.trim().toUpperCase();
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(trimmed);
    if (match == null) return null;

    final letters = match.group(1)!;
    final rowNum = int.tryParse(match.group(2)!);
    if (rowNum == null || rowNum < 1) return null;

    // For single letter 'A'..'Z'
    int colIndex = 0;
    for (int i = 0; i < letters.length; i++) {
      colIndex = colIndex * 26 + (letters.codeUnitAt(i) - 64);
    }
    colIndex -= 1; // 0-indexed

    return (col: colIndex, row: rowNum - 1);
  }

  /// Describes slot code in plain French/sommelier wording.
  /// Example: 'A7' -> 'A7 (1ère colonne, 7e rangée)'
  /// Or: 'Étagère 2' / 'Placard' -> 'Étagère 2'
  static String describeSlotCode(String code) {
    final lower = code.trim().toLowerCase();
    if (lower == 'placard' || lower == 'vrac' || lower == 'libre') {
      return 'Rangement libre (sans case fixe)';
    }
    if (lower.startsWith('etagere') || lower.startsWith('étagère') || lower.startsWith('niveau')) {
      return code.trim();
    }
    final parsed = parseSlotCode(code);
    if (parsed == null) return code;
    final colNum = parsed.col + 1;
    final rowNum = parsed.row + 1;
    final colLetter = String.fromCharCode(65 + parsed.col);
    final colDesc = colNum == 1 ? '1ère colonne' : '${colNum}e colonne';
    final rowDesc = rowNum == 1 ? '1ère rangée' : '${rowNum}e rangée';
    return '$colLetter$rowNum ($colDesc, $rowDesc)';
  }

  /// Checks if a slot at (col, row) is active and can hold a bottle.
  bool isSlotActive(int colIndex, int rowIndex) {
    if (rowIndex < 0 || rowIndex >= rows) return false;
    if (colIndex < 0 || colIndex >= columns) return false;
    if (rowIndex >= slotsMatrix.length) return false;
    final rowList = slotsMatrix[rowIndex];
    if (colIndex >= rowList.length) return false;
    return rowList[colIndex];
  }

  /// Total capacity of active bottle slots in this furniture unit.
  int get totalCapacity {
    int count = 0;
    for (final row in slotsMatrix) {
      for (final cell in row) {
        if (cell) count++;
      }
    }
    return count;
  }

  /// Generates a preset slot matrix for given dimensions and shape type.
  static List<List<bool>> generateMatrix({
    required String shapeType,
    required int columns,
    required int rows,
  }) {
    final matrix = List.generate(
      rows,
      (_) => List.generate(columns, (_) => true),
    );

    switch (shapeType) {
      case 'cupboard':
      case 'bulk':
        // Placard / rangement libre: rows represents shelves/levels, all active
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < columns; c++) {
            matrix[r][c] = true;
          }
        }
        break;

      case 'triangle':
        // Pyramid / triangle rack:
        // Top row has fewer slots, widening towards the bottom.
        // For row r in 0..rows-1, width is roughly proportional.
        for (int r = 0; r < rows; r++) {
          final activeCount = ((r + 1) * columns / rows).round().clamp(1, columns);
          final startCol = ((columns - activeCount) / 2).floor();
          final endCol = startCol + activeCount;
          for (int c = 0; c < columns; c++) {
            matrix[r][c] = c >= startCol && c < endCol;
          }
        }
        break;

      case 'staggered_4_2':
        // Alternating row rack:
        // Even rows have full width, odd rows have 2 slots centered.
        for (int r = 0; r < rows; r++) {
          if (r % 2 == 1) {
            final startCol = ((columns - 2) / 2).floor().clamp(0, columns - 1);
            final endCol = (startCol + 2).clamp(1, columns);
            for (int c = 0; c < columns; c++) {
              matrix[r][c] = c >= startCol && c < endCol;
            }
          }
        }
        break;

      case 'rectangle':
      case 'custom':
      default:
        // All active by default
        break;
    }

    return matrix;
  }

  factory CellarFurniture.fromJson(Map<String, dynamic> json) {
    final cols = (json['columns'] as num?)?.toInt() ?? 6;
    final rows = (json['rows'] as num?)?.toInt() ?? 6;
    final shape = json['shape_type'] as String? ?? 'rectangle';

    List<List<bool>> matrix = [];
    final rawMatrix = json['slots_matrix'];
    if (rawMatrix is List) {
      for (final rawRow in rawMatrix) {
        if (rawRow is List) {
          matrix.add(rawRow.map((c) => c == true).toList());
        }
      }
    }

    // Fallback if matrix is empty or dimensional mismatch
    if (matrix.isEmpty || matrix.length != rows || (matrix.isNotEmpty && matrix[0].length != cols)) {
      matrix = generateMatrix(shapeType: shape, columns: cols, rows: rows);
    }

    return CellarFurniture(
      id: json['id'] as String,
      cellarId: json['cellar_id'] as String,
      name: json['name'] as String? ?? 'Casier de rangement',
      shapeType: shape,
      columns: cols,
      rows: rows,
      slotsMatrix: matrix,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cellar_id': cellarId,
      'name': name,
      'shape_type': shapeType,
      'columns': columns,
      'rows': rows,
      'slots_matrix': slotsMatrix,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  CellarFurniture copyWith({
    String? id,
    String? cellarId,
    String? name,
    String? shapeType,
    int? columns,
    int? rows,
    List<List<bool>>? slotsMatrix,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CellarFurniture(
      id: id ?? this.id,
      cellarId: cellarId ?? this.cellarId,
      name: name ?? this.name,
      shapeType: shapeType ?? this.shapeType,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      slotsMatrix: slotsMatrix ?? this.slotsMatrix,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
