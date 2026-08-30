/// Result of a structured post-tasting questionnaire for one person.
class TastingQuestionnaireResult {
  // — Step 1: Impression Générale —
  final int emojiImpression; // 0=😖, 1=😕, 2=😐, 3=😊, 4=😍
  final double noteOutOf10; // 1.0 → 10.0

  // — Step 2: Le Nez (Arômes) —
  final Set<String> perceivedAromas; // IDs from aromaOptions
  final double aromaIntensity; // 0.0 (discret) → 1.0 (explosif)

  // — Step 3: La Bouche (Équilibre) —
  final double acidity; // 0.0 (mou) → 1.0 (vif/tranchant)
  final double tannins; // 0.0 (fondus) → 1.0 (puissants) — only for reds
  final double body; // 0.0 (léger) → 1.0 (puissant)
  final double length; // 0.0 (courte) → 1.0 (interminable)
  final double? effervescence; // 0.0 (fine) → 1.0 (vive) — only for sparkling

  // — Step 4: Verdict —
  final String wouldBuyAgain; // 'yes', 'maybe', 'no'
  final String idealMoment; // 'apero', 'repas', 'grand_diner', 'solo'
  final Set<String> whatLikedMost; // IDs from likedOptions
  final Set<String> whatDislikedMost; // IDs from dislikedOptions

  // — Context —
  final String profileId; // Which TasteProfile answered
  final String profileName;

  const TastingQuestionnaireResult({
    required this.emojiImpression,
    required this.noteOutOf10,
    required this.perceivedAromas,
    required this.aromaIntensity,
    required this.acidity,
    required this.tannins,
    required this.body,
    required this.length,
    this.effervescence,
    required this.wouldBuyAgain,
    required this.idealMoment,
    required this.whatLikedMost,
    required this.whatDislikedMost,
    required this.profileId,
    required this.profileName,
  });

  Map<String, dynamic> toJson() => {
    'emoji_impression': emojiImpression,
    'note': noteOutOf10,
    'aromas': perceivedAromas.toList(),
    'aroma_intensity': aromaIntensity,
    'acidity': acidity,
    'tannins': tannins,
    'body': body,
    'length': length,
    'effervescence': effervescence,
    'would_buy_again': wouldBuyAgain,
    'ideal_moment': idealMoment,
    'liked_most': whatLikedMost.toList(),
    'disliked_most': whatDislikedMost.toList(),
    'profile_id': profileId,
    'profile_name': profileName,
  };

  // =========================================================================
  // Static reference data for the questionnaire UI
  // =========================================================================

  static const List<String> emojiLabels = ['😖', '😕', '😐', '😊', '😍'];
  static const List<String> emojiDescriptions = [
    'Pas aimé',
    'Bof',
    'Correct',
    'Très bien',
    'Coup de cœur',
  ];

  static const List<AromaOption> aromaOptions = [
    AromaOption(id: 'fruits_rouges', label: 'Fruits rouges', emoji: '🍒'),
    AromaOption(id: 'fruits_noirs', label: 'Fruits noirs', emoji: '🫐'),
    AromaOption(id: 'fruits_blancs', label: 'Fruits blancs/jaunes', emoji: '🍑'),
    AromaOption(id: 'agrumes', label: 'Agrumes', emoji: '🍋'),
    AromaOption(id: 'floral', label: 'Floral', emoji: '🌸'),
    AromaOption(id: 'vegetal', label: 'Végétal / Herbes', emoji: '🌿'),
    AromaOption(id: 'epices_douces', label: 'Épices douces', emoji: '🧀'),
    AromaOption(id: 'epices_vives', label: 'Épices vives / Poivre', emoji: '🌶️'),
    AromaOption(id: 'boise', label: 'Boisé / Vanille', emoji: '🪵'),
    AromaOption(id: 'beurre', label: 'Beurré / Brioche', emoji: '🧈'),
    AromaOption(id: 'mineral', label: 'Minéral / Pierre', emoji: '⛰️'),
    AromaOption(id: 'miel', label: 'Miel / Confiture', emoji: '🍯'),
    AromaOption(id: 'chocolat', label: 'Chocolat / Café', emoji: '🍫'),
    AromaOption(id: 'fumee', label: 'Fumé / Grillé', emoji: '🔥'),
  ];

  static const List<LikeOption> likedOptions = [
    LikeOption(id: 'fraicheur', label: 'La fraîcheur'),
    LikeOption(id: 'fruite', label: 'Le fruité'),
    LikeOption(id: 'complexite', label: 'La complexité'),
    LikeOption(id: 'elegance', label: 'L\'élégance'),
    LikeOption(id: 'puissance', label: 'La puissance'),
    LikeOption(id: 'soyeux', label: 'Le côté soyeux'),
    LikeOption(id: 'originalite', label: 'L\'originalité'),
    LikeOption(id: 'accord_plat', label: 'L\'accord avec le plat'),
    LikeOption(id: 'minerale', label: 'La minéralité'),
    LikeOption(id: 'longueur', label: 'La longueur en bouche'),
  ];

  static const List<LikeOption> dislikedOptions = [
    LikeOption(id: 'trop_acide', label: 'Trop acide'),
    LikeOption(id: 'trop_tannique', label: 'Trop tannique'),
    LikeOption(id: 'trop_boise', label: 'Trop boisé / vanillé'),
    LikeOption(id: 'trop_alcoolise', label: 'Trop alcoolisé / chaud'),
    LikeOption(id: 'trop_leger', label: 'Trop léger / dilué'),
    LikeOption(id: 'manque_fruit', label: 'Manque de fruit'),
    LikeOption(id: 'trop_sucre', label: 'Trop sucré'),
    LikeOption(id: 'trop_cher', label: 'Trop cher pour la qualité'),
    LikeOption(id: 'rien', label: 'Rien, c\'était parfait !'),
  ];
}

class AromaOption {
  final String id;
  final String label;
  final String emoji;
  const AromaOption({required this.id, required this.label, required this.emoji});
}

class LikeOption {
  final String id;
  final String label;
  const LikeOption({required this.id, required this.label});
}
