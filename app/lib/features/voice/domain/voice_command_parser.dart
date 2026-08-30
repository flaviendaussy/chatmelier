enum VoiceActionType {
  checkout,
  add,
  sommelier,
  unknown,
}

class ParsedVoiceCommand {
  final VoiceActionType actionType;
  final String rawText;
  final String? wineName;
  final int? vintage;
  final int quantity;
  final String? wineType; // 'red', 'white', 'rose', 'sparkling'
  final String? location; // rack / shelf
  final String? query;

  const ParsedVoiceCommand({
    required this.actionType,
    required this.rawText,
    this.wineName,
    this.vintage,
    this.quantity = 1,
    this.wineType,
    this.location,
    this.query,
  });
}

class VoiceCommandParser {
  static ParsedVoiceCommand parse(String rawInput) {
    final raw = rawInput.trim();
    if (raw.isEmpty) {
      return ParsedVoiceCommand(
        actionType: VoiceActionType.unknown,
        rawText: raw,
      );
    }

    final lower = raw.toLowerCase();

    // 1. DÉTECTION CHECKOUT (Sortir / Déguster / Boire / Ouvrir)
    final checkoutKeywords = ['sortir', 'déguster', 'deguster', 'bu', 'boire', 'ouvrir', 'consommer', 'prends', 'prendre'];
    if (checkoutKeywords.any((k) => lower.contains(k))) {
      final qty = _extractQuantity(lower);
      final vintage = _extractVintage(lower);
      String clean = _cleanWineName(raw, [
        ...checkoutKeywords,
        'une', 'un', 'des', 'les', 'du', 'de', 'la', 'bouteille', 'bouteilles',
        'ce soir', 'pour ce soir', 'pour dîner', 'pour diner', 'au frais',
      ]);

      return ParsedVoiceCommand(
        actionType: VoiceActionType.checkout,
        rawText: raw,
        wineName: clean.isEmpty ? null : clean,
        vintage: vintage,
        quantity: qty,
      );
    }

    // 2. DÉTECTION AJOUT (Ajouter / Rentrer / Nouveau / Ranger)
    final addKeywords = ['ajouter', 'ajoute', 'rentrer', 'rentre', 'nouveau', 'nouvelle', 'ranger', 'range', 'mets', 'mettre', 'stocker'];
    if (addKeywords.any((k) => lower.contains(k))) {
      final qty = _extractQuantity(lower);
      final vintage = _extractVintage(lower);
      final wineType = _extractWineType(lower);
      final location = _extractLocation(raw);

      String clean = _cleanWineName(raw, [
        ...addKeywords,
        'une', 'un', 'des', 'les', 'du', 'de', 'la', 'bouteille', 'bouteilles',
        'carton', 'cartons', 'caisse', 'caisses', 'lot',
      ]);

      return ParsedVoiceCommand(
        actionType: VoiceActionType.add,
        rawText: raw,
        wineName: clean.isEmpty ? 'Nouveau Vin' : clean,
        vintage: vintage,
        quantity: qty,
        wineType: wineType,
        location: location,
      );
    }

    // 3. REQUÊTE SOMMELIER / ACCORD METS & VINS / CONSEIL
    final sommelierKeywords = ['accord', 'quel vin', 'conseil', 'recommande', 'servir', 'température', 'temperature', 'carafage', 'carafer', 'apogée', 'apogee', 'manger', 'plat'];
    if (sommelierKeywords.any((k) => lower.contains(k)) || lower.endsWith('?')) {
      return ParsedVoiceCommand(
        actionType: VoiceActionType.sommelier,
        rawText: raw,
        query: raw,
      );
    }

    // Par défaut, orienter vers le sommelier
    return ParsedVoiceCommand(
      actionType: VoiceActionType.sommelier,
      rawText: raw,
      query: raw,
    );
  }

  static int _extractQuantity(String text) {
    // 1. Détection caisse (12) ou carton (6)
    if (RegExp(r'\b(caisse|caisses)\b').hasMatch(text)) {
      final match = RegExp(r'\b(\d+)\s+caisse').firstMatch(text);
      if (match != null) {
        final count = int.tryParse(match.group(1)!) ?? 1;
        return count * 12;
      }
      return 12;
    }
    if (RegExp(r'\b(carton|cartons)\b').hasMatch(text)) {
      final match = RegExp(r'\b(\d+)\s+carton').firstMatch(text);
      if (match != null) {
        final count = int.tryParse(match.group(1)!) ?? 1;
        return count * 6;
      }
      return 6;
    }

    // 2. Chiffre explicite (ex: "3 bouteilles", "sortir 2 margaux")
    final match = RegExp(r'\b(\d+)\s*(bouteilles?|flacons?|cols?)?\b').firstMatch(text);
    if (match != null) {
      final numStr = match.group(1);
      final val = int.tryParse(numStr ?? '');
      if (val != null && val > 0 && val < 1000) {
        // Éviter de confondre avec un millésime
        if (val < 1900 || val > 2100) {
          return val;
        }
      }
    }

    // 3. Nombres en lettres
    if (RegExp(r'\b(deux)\b').hasMatch(text)) return 2;
    if (RegExp(r'\b(trois)\b').hasMatch(text)) return 3;
    if (RegExp(r'\b(quatre)\b').hasMatch(text)) return 4;
    if (RegExp(r'\b(cinq)\b').hasMatch(text)) return 5;
    if (RegExp(r'\b(six)\b').hasMatch(text)) return 6;
    if (RegExp(r'\b(douze)\b').hasMatch(text)) return 12;

    return 1;
  }

  static int? _extractVintage(String text) {
    final match = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(0)!);
    }
    return null;
  }

  static String? _extractWineType(String text) {
    if (text.contains('champagne') || text.contains('effervescent') || text.contains('crémant') || text.contains('cremant') || text.contains('bulle')) {
      return 'sparkling';
    }
    if (text.contains('blanc') || text.contains('white')) return 'white';
    if (text.contains('rosé') || text.contains('rose')) return 'rose';
    if (text.contains('rouge') || text.contains('red')) return 'red';
    return null;
  }

  static String? _extractLocation(String text) {
    final match = RegExp(r'\b(casier|étagère|etagere|rang|colonne|zone)\s+([a-zA-Z0-9\-\_]+)\b', caseSensitive: false).firstMatch(text);
    if (match != null) {
      final prefix = match.group(1)!.toLowerCase();
      final code = match.group(2)!.toUpperCase();
      return '$prefix $code';
    }
    return null;
  }

  static String _cleanWineName(String raw, List<String> stopWords) {
    String cleaned = raw;
    // Retirer le millésime
    cleaned = cleaned.replaceAll(RegExp(r'\b(19\d\d|20\d\d)\b'), ' ');
    // Retirer la quantité explicite (ex: "6 bouteilles")
    cleaned = cleaned.replaceAll(RegExp(r'\b\d+\s*(bouteilles?|cartons?|caisses?)?\b', caseSensitive: false), ' ');
    // Retirer l'emplacement (ex: "casier B3")
    cleaned = cleaned.replaceAll(RegExp(r'\b(casier|étagère|etagere|rang|colonne)\s+[a-zA-Z0-9\-\_]+\b', caseSensitive: false), ' ');

    // Retirer les mots d'arrêt au début
    final words = cleaned.split(RegExp(r'\s+'));
    final filtered = <String>[];
    for (final w in words) {
      final lw = w.toLowerCase().replaceAll(RegExp(r'[^\w\u00C0-\u017F]'), '');
      if (!stopWords.contains(lw) && lw.isNotEmpty) {
        filtered.add(w);
      }
    }

    return filtered.join(' ').trim();
  }
}
