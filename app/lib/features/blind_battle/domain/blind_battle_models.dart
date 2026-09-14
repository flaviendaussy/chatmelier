import 'dart:math' as math;
import '../../cellar/domain/wine.dart';

enum BlindSessionStatus {
  waiting,
  tasting,
  revealed,
}

class BlindAromaItem {
  final String id;
  final String label;
  final String category;
  final String emoji;

  const BlindAromaItem({
    required this.id,
    required this.label,
    required this.category,
    required this.emoji,
  });
}

class BlindAromaCatalog {
  static const List<BlindAromaItem> allAromas = [
    // Fruits rouges
    BlindAromaItem(id: 'cerise', label: 'Cerise burlat', category: 'Fruits Rouges', emoji: '🍒'),
    BlindAromaItem(id: 'framboise', label: 'Framboise', category: 'Fruits Rouges', emoji: '🍓'),
    BlindAromaItem(id: 'groseille', label: 'Groseille', category: 'Fruits Rouges', emoji: '🫐'),
    // Fruits noirs
    BlindAromaItem(id: 'mure', label: 'Mûre sauvage', category: 'Fruits Noirs', emoji: '🍇'),
    BlindAromaItem(id: 'cassis', label: 'Cassis intense', category: 'Fruits Noirs', emoji: '🫐'),
    BlindAromaItem(id: 'prune', label: 'Pruneau confit', category: 'Fruits Noirs', emoji: '🟣'),
    // Agrumes & Fruits blancs
    BlindAromaItem(id: 'citron', label: 'Citron & Zeste', category: 'Frais & Minéral', emoji: '🍋'),
    BlindAromaItem(id: 'pomme', label: 'Pomme verte / Poire', category: 'Frais & Minéral', emoji: '🍏'),
    BlindAromaItem(id: 'peche', label: 'Pêche blanche', category: 'Frais & Minéral', emoji: '🍑'),
    BlindAromaItem(id: 'pierre', label: 'Pierre à fusil / Silex', category: 'Frais & Minéral', emoji: '⚡'),
    // Boisé & Élevage
    BlindAromaItem(id: 'vanille', label: 'Vanille bourbon', category: 'Élevage & Bois', emoji: '🪵'),
    BlindAromaItem(id: 'pain_grille', label: 'Pain grillé / Brioche', category: 'Élevage & Bois', emoji: '🍞'),
    BlindAromaItem(id: 'cafe', label: 'Moka / Cacao', category: 'Élevage & Bois', emoji: '☕'),
    // Épices & Végétal
    BlindAromaItem(id: 'poivre', label: 'Poivre noir moulu', category: 'Épices & Terroir', emoji: '🌶️'),
    BlindAromaItem(id: 'reglisse', label: 'Réglisse noire', category: 'Épices & Terroir', emoji: '🌿'),
    BlindAromaItem(id: 'sous_bois', label: 'Sous-bois & Truffe', category: 'Épices & Terroir', emoji: '🍄'),
    BlindAromaItem(id: 'cuir', label: 'Cuir noble', category: 'Épices & Terroir', emoji: '👞'),
    // Floral
    BlindAromaItem(id: 'fleur_blanche', label: 'Fleur blanche / Acacia', category: 'Floral', emoji: '🌼'),
    BlindAromaItem(id: 'violette', label: 'Violette délicate', category: 'Floral', emoji: '🌸'),
  ];
}

class BlindGuess {
  final String color; // Rouge, Blanc, Rosé, Effervescent
  final List<String> selectedAromaIds;
  final String sweetness; // Sec, Demi-sec, Moelleux, Liquoreux
  final String acidity; // Basse, Équilibrée, Tranchante / Vive
  final String tannins; // Nuls (Blanc), Soyeux / Fondus, Puissants / Serrés
  final int caudaliesSeconds; // 2 à 15 secondes
  final String grape;
  final String region;
  final int? vintage;
  final String? personalNote;

  const BlindGuess({
    required this.color,
    this.selectedAromaIds = const [],
    this.sweetness = 'Sec',
    this.acidity = 'Équilibrée',
    this.tannins = 'Soyeux / Fondus',
    this.caudaliesSeconds = 6,
    required this.grape,
    required this.region,
    this.vintage,
    this.personalNote,
  });

  Map<String, dynamic> toJson() => {
        'color': color,
        'selectedAromaIds': selectedAromaIds,
        'sweetness': sweetness,
        'acidity': acidity,
        'tannins': tannins,
        'caudaliesSeconds': caudaliesSeconds,
        'grape': grape,
        'region': region,
        'vintage': vintage,
        'personalNote': personalNote,
      };

  factory BlindGuess.fromJson(Map<String, dynamic> json) {
    return BlindGuess(
      color: json['color'] as String? ?? 'Rouge',
      selectedAromaIds: (json['selectedAromaIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      sweetness: json['sweetness'] as String? ?? 'Sec',
      acidity: json['acidity'] as String? ?? 'Équilibrée',
      tannins: json['tannins'] as String? ?? 'Soyeux / Fondus',
      caudaliesSeconds: json['caudaliesSeconds'] as int? ?? 6,
      grape: json['grape'] as String? ?? '',
      region: json['region'] as String? ?? '',
      vintage: json['vintage'] as int?,
      personalNote: json['personalNote'] as String?,
    );
  }
}

class BlindBattleScoreBreakdown {
  final int colorScore; // max 20
  final int grapeScore; // max 30
  final int regionScore; // max 25
  final int vintageScore; // max 25
  final int aromasScore; // max 20
  final int palateScore; // max 20
  final List<String> feedbackItems;

  const BlindBattleScoreBreakdown({
    required this.colorScore,
    required this.grapeScore,
    required this.regionScore,
    required this.vintageScore,
    required this.aromasScore,
    required this.palateScore,
    required this.feedbackItems,
  });

  int get totalScore => colorScore + grapeScore + regionScore + vintageScore + aromasScore + palateScore;
}

class BlindParticipant {
  final String id;
  final String pseudo;
  final String? email;
  final bool isHost;
  final DateTime joinedAt;
  final BlindGuess? guess;
  final BlindBattleScoreBreakdown? scoreBreakdown;
  final int totalScore;

  const BlindParticipant({
    required this.id,
    required this.pseudo,
    this.email,
    this.isHost = false,
    required this.joinedAt,
    this.guess,
    this.scoreBreakdown,
    this.totalScore = 0,
  });

  BlindParticipant copyWith({
    String? id,
    String? pseudo,
    String? email,
    bool? isHost,
    DateTime? joinedAt,
    BlindGuess? guess,
    BlindBattleScoreBreakdown? scoreBreakdown,
    int? totalScore,
  }) {
    return BlindParticipant(
      id: id ?? this.id,
      pseudo: pseudo ?? this.pseudo,
      email: email ?? this.email,
      isHost: isHost ?? this.isHost,
      joinedAt: joinedAt ?? this.joinedAt,
      guess: guess ?? this.guess,
      scoreBreakdown: scoreBreakdown ?? this.scoreBreakdown,
      totalScore: totalScore ?? this.totalScore,
    );
  }
}

class BlindBattleSession {
  final String id; // Code de session, ex: "CHAT-408"
  final DateTime createdAt;
  final String hostId;
  final Wine secretWine;
  final BlindSessionStatus status;
  final List<BlindParticipant> participants;

  const BlindBattleSession({
    required this.id,
    required this.createdAt,
    required this.hostId,
    required this.secretWine,
    required this.status,
    required this.participants,
  });

  BlindBattleSession copyWith({
    String? id,
    DateTime? createdAt,
    String? hostId,
    Wine? secretWine,
    BlindSessionStatus? status,
    List<BlindParticipant>? participants,
  }) {
    return BlindBattleSession(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      hostId: hostId ?? this.hostId,
      secretWine: secretWine ?? this.secretWine,
      status: status ?? this.status,
      participants: participants ?? this.participants,
    );
  }
}

class BlindBattleScorer {
  static BlindBattleScoreBreakdown evaluate({
    required BlindGuess guess,
    required Wine secretWine,
  }) {
    final feedback = <String>[];

    // 1. Couleur (20 pts)
    int colorScore = 0;
    final secretType = (secretWine.type ?? '').toLowerCase();
    final guessColor = guess.color.toLowerCase();

    if (secretType.contains('rouge') && guessColor.contains('rouge')) {
      colorScore = 20;
      feedback.add('🎯 Robe rouge parfaitement identifiée (+20 pts)');
    } else if (secretType.contains('blanc') && guessColor.contains('blanc')) {
      colorScore = 20;
      feedback.add('🎯 Robe blanche parfaitement identifiée (+20 pts)');
    } else if (secretType.contains('rosé') && guessColor.contains('rosé')) {
      colorScore = 20;
      feedback.add('🎯 Robe rosée parfaitement identifiée (+20 pts)');
    } else if (secretType.contains('effervescent') || secretType.contains('champagne')) {
      if (guessColor.contains('effervescent') || guessColor.contains('champagne')) {
        colorScore = 20;
        feedback.add('🎯 Effervescence repérée (+20 pts)');
      }
    } else {
      feedback.add('❌ Robe manquée (${secretWine.type ?? "Inconnu"}) (+0 pt)');
    }

    // 2. Cépage (30 pts)
    int grapeScore = 0;
    final secretGrapes = secretWine.grapes.map((g) => g.name.toLowerCase()).toList();
    final guessGrape = guess.grape.trim().toLowerCase();

    if (guessGrape.isNotEmpty) {
      if (secretGrapes.any((g) => g.contains(guessGrape) || guessGrape.contains(g))) {
        grapeScore = 30;
        feedback.add('🍇 Cépage maître "$guessGrape" trouvé en plein dans le mille ! (+30 pts)');
      } else {
        feedback.add('🍇 Cépage proposé : "$guessGrape" (vrai flacon : ${secretGrapes.join(", ")}) (+0 pt)');
      }
    }

    // 3. Région / Appellation (25 pts)
    int regionScore = 0;
    final secretRegion = (secretWine.region ?? '').toLowerCase();
    final secretAppellation = (secretWine.appellation ?? '').toLowerCase();
    final guessRegion = guess.region.trim().toLowerCase();

    if (guessRegion.isNotEmpty) {
      if (secretAppellation.isNotEmpty && (secretAppellation.contains(guessRegion) || guessRegion.contains(secretAppellation))) {
        regionScore = 25;
        feedback.add('📍 Appellation exacte "${secretWine.appellation}" trouvée ! (+25 pts)');
      } else if (secretRegion.isNotEmpty && (secretRegion.contains(guessRegion) || guessRegion.contains(secretRegion))) {
        regionScore = 20;
        feedback.add('📍 Région "${secretWine.region}" bien ciblée ! (+20 pts)');
      } else {
        feedback.add('📍 Terroir manqué (origine : ${secretWine.region ?? secretWine.appellation ?? "Non spécifié"}) (+0 pt)');
      }
    }

    // 4. Millésime (25 pts)
    int vintageScore = 0;
    final actualVintage = secretWine.vintage;
    if (actualVintage != null && guess.vintage != null) {
      final diff = (actualVintage - guess.vintage!).abs();
      if (diff == 0) {
        vintageScore = 25;
        feedback.add('📅 Millésime $actualVintage exact ! Précision d\'orfèvre (+25 pts)');
      } else if (diff == 1) {
        vintageScore = 18;
        feedback.add('📅 À 1 an près ($actualVintage vs ${guess.vintage}) ! Superbe estimation (+18 pts)');
      } else if (diff <= 3) {
        vintageScore = 10;
        feedback.add('📅 Proche du millésime ($actualVintage vs ${guess.vintage}) (+10 pts)');
      } else {
        feedback.add('📅 Millésime $actualVintage (vous aviez proposé ${guess.vintage}) (+0 pt)');
      }
    } else if (actualVintage == null) {
      vintageScore = 15; // Équité si le vin n'a pas de millésime
    }

    // 5. Arômes détectés (20 pts)
    int aromasScore = 0;
    if (guess.selectedAromaIds.isNotEmpty) {
      // Valorise la finesse de détection sensorielle
      aromasScore = math.min(20, guess.selectedAromaIds.length * 5);
      feedback.add('👃 ${guess.selectedAromaIds.length} notes et arômes exprimés avec acuité (+${aromasScore} pts)');
    }

    // 6. Bouche & Caudalies (20 pts)
    int palateScore = 15;
    if (guess.caudaliesSeconds >= 5) {
      palateScore += 5;
      feedback.add('⏱️ Caudalies (${guess.caudaliesSeconds}s) & toucher de bouche évalués (+20 pts)');
    } else {
      feedback.add('⏱️ Analyse de bouche enregistrée (+15 pts)');
    }

    return BlindBattleScoreBreakdown(
      colorScore: colorScore,
      grapeScore: grapeScore,
      regionScore: regionScore,
      vintageScore: vintageScore,
      aromasScore: aromasScore,
      palateScore: palateScore,
      feedbackItems: feedback,
    );
  }
}
