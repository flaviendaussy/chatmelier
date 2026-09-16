import '../../../../l10n/app_localizations.dart';

/// Result of a structured post-tasting questionnaire for one person.
class TastingQuestionnaireResult {
  // — Step 1: Impression Générale —
  final int emojiImpression; // 0=😖, 1=😕, 2=😐, 3=😊, 4=😍
  final double noteOutOf10; // 1.0 → 10.0

  // — Step 2: Le Nez (Arômes) —
  final Set<String> perceivedAromas; // IDs from aromaOptions
  final double aromaIntensity; // 0.0 (discret) → 1.0 (explosif)

  // — Step 3: La Bouche (Équilibre) —
  /// 0.0 (mou) → 1.0 (vif/tranchant). **Nul si la bouche n'a pas été mesurée** — c'est le
  /// cas du niveau « Gorgée » de la dégustation hors-cave, qui ne pose que les micro-touches.
  /// Sans cette distinction, une gorgée non mesurée poussait l'axe vers 0,5 et comptait
  /// comme une observation : le modèle gagnait de la confiance sans avoir rien appris.
  final double? acidity;
  final double? tannins; // 0.0 (fondus) → 1.0 (puissants) — only for reds, null for whites/sparkling/rosé
  /// 0.0 (léger) → 1.0 (puissant). Nul si non mesuré — voir [acidity].
  final double? body;
  final double length; // 0.0 (courte) → 1.0 (interminable)
  final double? effervescence; // 0.0 (fine) → 1.0 (vive) — only for sparkling

  // — Step 4: Verdict —
  final String wouldBuyAgain; // 'yes', 'maybe', 'no'
  final String idealMoment; // 'apero', 'repas', 'grand_diner', 'diner_romantique', 'solo'
  final Set<String> whatLikedMost; // IDs from likedOptions
  final Set<String> whatDislikedMost; // IDs from dislikedOptions
  final String? foodPairingSynergy; // 'sublime', 'harmonious', 'neutral', 'clashing'

  // — 3 Emotional Micro-Taps ("Fast-Tasting") —
  final String? mouthfeelTexture; // 'silky_lacy', 'crisp_salivating', 'dense_structured'
  final String? fruitProfile; // 'crunchy_tart', 'deep_ripe', 'spicy_herbal'

  // — Extensions for Purists & Fast Tasters —
  final List<String> customAromas; // Freeform aromas added by user
  final bool isExpressMode; // true if completed in 1-page express mode

  // — Context —
  final String profileId; // Which TasteProfile answered
  final String profileName;

  const TastingQuestionnaireResult({
    required this.emojiImpression,
    required this.noteOutOf10,
    required this.perceivedAromas,
    required this.aromaIntensity,
    this.acidity,
    this.tannins,
    this.body,
    required this.length,
    this.effervescence,
    required this.wouldBuyAgain,
    required this.idealMoment,
    required this.whatLikedMost,
    required this.whatDislikedMost,
    this.foodPairingSynergy,
    this.mouthfeelTexture,
    this.fruitProfile,
    this.customAromas = const [],
    this.isExpressMode = false,
    required this.profileId,
    required this.profileName,
  });

  Map<String, dynamic> toJson() => {
    'emoji_impression': emojiImpression,
    'note': noteOutOf10,
    'aromas': perceivedAromas.toList(),
    'custom_aromas': customAromas,
    'aroma_intensity': aromaIntensity,
    if (acidity != null) 'acidity': acidity,
    if (tannins != null) 'tannins': tannins,
    if (body != null) 'body': body,
    'length': length,
    'effervescence': effervescence,
    'would_buy_again': wouldBuyAgain,
    'ideal_moment': idealMoment,
    'liked_most': whatLikedMost.toList(),
    'disliked_most': whatDislikedMost.toList(),
    if (foodPairingSynergy != null) 'food_pairing_synergy': foodPairingSynergy,
    if (mouthfeelTexture != null) 'mouthfeel_texture': mouthfeelTexture,
    if (fruitProfile != null) 'fruit_profile': fruitProfile,
    'is_express_mode': isExpressMode,
    'profile_id': profileId,
    'profile_name': profileName,
  };

  factory TastingQuestionnaireResult.fromJson(Map<String, dynamic> json) {
    final rawAromas = json['aromas'] ?? json['perceived_aromas'];
    final rawLiked = json['liked_most'] ?? json['what_liked_most'];
    final rawDisliked = json['disliked_most'] ?? json['what_disliked_most'];
    final rawCustom = json['custom_aromas'];

    return TastingQuestionnaireResult(
      emojiImpression: (json['emoji_impression'] as num?)?.toInt() ?? 2,
      noteOutOf10: (json['note'] ?? json['note_out_of_10'] as num?)?.toDouble() ?? 5.0,
      perceivedAromas: rawAromas != null
          ? Set<String>.from((rawAromas as List).map((e) => e.toString()))
          : const <String>{},
      customAromas: rawCustom != null
          ? List<String>.from((rawCustom as List).map((e) => e.toString()))
          : const <String>[],
      aromaIntensity: (json['aroma_intensity'] as num?)?.toDouble() ?? 0.5,
      acidity: (json['acidity'] as num?)?.toDouble(),
      tannins: (json['tannins'] as num?)?.toDouble(),
      body: (json['body'] as num?)?.toDouble(),
      length: (json['length'] as num?)?.toDouble() ?? 0.5,
      effervescence: (json['effervescence'] as num?)?.toDouble(),
      wouldBuyAgain: (json['would_buy_again'] as String?) ?? 'maybe',
      idealMoment: (json['ideal_moment'] as String?) ?? 'repas',
      whatLikedMost: rawLiked != null
          ? Set<String>.from((rawLiked as List).map((e) => e.toString()))
          : const <String>{},
      whatDislikedMost: rawDisliked != null
          ? Set<String>.from((rawDisliked as List).map((e) => e.toString()))
          : const <String>{},
      foodPairingSynergy: json['food_pairing_synergy'] as String?,
      mouthfeelTexture: json['mouthfeel_texture'] as String?,
      fruitProfile: json['fruit_profile'] as String?,
      isExpressMode: (json['is_express_mode'] as bool?) ?? false,
      profileId: (json['profile_id'] as String?) ?? 'me',
      profileName: (json['profile_name'] as String?) ?? 'Moi',
    );
  }

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

  static const List<TextureOption> textureOptions = [
    TextureOption(id: 'silky_lacy', label: 'Soyeux & Dentelle', emoji: '🪶'),
    TextureOption(id: 'crisp_salivating', label: 'Vif & Salivant', emoji: '⚡'),
    TextureOption(id: 'dense_structured', label: 'Dense & Structuré', emoji: '🏛️'),
  ];

  static const List<FruitProfileOption> fruitProfileOptions = [
    FruitProfileOption(id: 'crunchy_tart', label: 'Croquant & Acidulé', emoji: '🍒'),
    FruitProfileOption(id: 'deep_ripe', label: 'Profond & Mûr', emoji: '🫐'),
    FruitProfileOption(id: 'spicy_herbal', label: 'Épicé & Végétal noble', emoji: '🌿'),
  ];

  static List<String> getEmojiDescriptions(AppLocalizations? l10n) {
    if (l10n == null) return emojiDescriptions;
    return [
      l10n.emojiDisliked,
      l10n.emojiMeh,
      l10n.emojiDecent,
      l10n.emojiVeryGood,
      l10n.emojiLoved,
    ];
  }

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

  static List<AromaOption> getAromaOptions(AppLocalizations? l10n) {
    if (l10n == null) return aromaOptions;
    return [
      AromaOption(id: 'fruits_rouges', label: l10n.aromaFruitsRouges, emoji: '🍒'),
      AromaOption(id: 'fruits_noirs', label: l10n.aromaFruitsNoirs, emoji: '🫐'),
      AromaOption(id: 'fruits_blancs', label: l10n.aromaFruitsBlancs, emoji: '🍑'),
      AromaOption(id: 'agrumes', label: l10n.aromaAgrumes, emoji: '🍋'),
      AromaOption(id: 'floral', label: l10n.aromaFloral, emoji: '🌸'),
      AromaOption(id: 'vegetal', label: l10n.aromaVegetal, emoji: '🌿'),
      AromaOption(id: 'epices_douces', label: l10n.aromaEpicesDouces, emoji: '🧀'),
      AromaOption(id: 'epices_vives', label: l10n.aromaEpicesVives, emoji: '🌶️'),
      AromaOption(id: 'boise', label: l10n.aromaBoise, emoji: '🪵'),
      AromaOption(id: 'beurre', label: l10n.aromaBeurre, emoji: '🧈'),
      AromaOption(id: 'mineral', label: l10n.aromaMineral, emoji: '⛰️'),
      AromaOption(id: 'miel', label: l10n.aromaMiel, emoji: '🍯'),
      AromaOption(id: 'chocolat', label: l10n.aromaChocolat, emoji: '🍫'),
      AromaOption(id: 'fumee', label: l10n.aromaFumee, emoji: '🔥'),
    ];
  }

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
    LikeOption(id: 'rien_decevant', label: 'Rien / Décevant 😕'),
  ];

  static List<LikeOption> getLikedOptions(AppLocalizations? l10n) {
    if (l10n == null) return likedOptions;
    return [
      LikeOption(id: 'fraicheur', label: l10n.likedFreshness),
      LikeOption(id: 'fruite', label: l10n.likedFruitiness),
      LikeOption(id: 'complexite', label: l10n.likedComplexity),
      LikeOption(id: 'elegance', label: l10n.likedElegance),
      LikeOption(id: 'puissance', label: l10n.likedPower),
      LikeOption(id: 'soyeux', label: l10n.likedSilky),
      LikeOption(id: 'originalite', label: l10n.likedOriginality),
      LikeOption(id: 'accord_plat', label: l10n.likedFoodPairing),
      LikeOption(id: 'minerale', label: l10n.likedMinerality),
      LikeOption(id: 'longueur', label: l10n.likedLength),
      LikeOption(id: 'rien_decevant', label: l10n.likedDisappointing),
    ];
  }

  static int emojiIndexForRating(double rating) {
    if (rating >= 9.0) return 4; // 😍
    if (rating >= 7.5) return 3; // 😊
    if (rating >= 5.5) return 2; // 😐
    if (rating >= 3.5) return 1; // 😕
    return 0; // 😖
  }

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

  static List<LikeOption> getDislikedOptions(AppLocalizations? l10n) {
    if (l10n == null) return dislikedOptions;
    return [
      LikeOption(id: 'trop_acide', label: l10n.dislikedTooAcidic),
      LikeOption(id: 'trop_tannique', label: l10n.dislikedTooTannic),
      LikeOption(id: 'trop_boise', label: l10n.dislikedTooOaked),
      LikeOption(id: 'trop_alcoolise', label: l10n.dislikedTooAlcoholic),
      LikeOption(id: 'trop_leger', label: l10n.dislikedTooThin),
      LikeOption(id: 'manque_fruit', label: l10n.dislikedLacksFruit),
      LikeOption(id: 'trop_sucre', label: l10n.dislikedTooSweet),
      LikeOption(id: 'trop_cher', label: l10n.dislikedTooExpensive),
      LikeOption(id: 'rien', label: l10n.dislikedNothing),
    ];
  }

  static String fastTastingTitle([dynamic lang]) {
    final code = TextureOption._extractLang(lang);
    switch (code) {
      case 'fr': return '⚡ Dégustation Express';
      case 'es': return '⚡ Cata Exprés';
      case 'ca': return '⚡ Tast Exprés';
      case 'it': return '⚡ Degustazione Express';
      case 'de': return '⚡ Express-Verkostung';
      case 'nl': return '⚡ Snelle Proeverij';
      case 'pt': return '⚡ Degustação Expresso';
      case 'ja': return '⚡ エクスプレス・テイスティング';
      case 'ko': return '⚡ 익스프레스 테이스팅';
      case 'zh': return '⚡ 极速微品鉴';
      case 'sv': return '⚡ Snabbprovning';
      case 'la': return '⚡ Degustatio Brevis';
      case 'en':
      default: return '⚡ Express Fast-Tasting';
    }
  }

  static String mouthfeelTitle([dynamic lang]) {
    final code = TextureOption._extractLang(lang);
    switch (code) {
      case 'fr': return '1. Toucher de Bouche';
      case 'es': return '1. Textura en Boca';
      case 'ca': return '1. Textura en Boca';
      case 'it': return '1. Consistenza in Bocca';
      case 'de': return '1. Mundgefühl & Textur';
      case 'nl': return '1. Mondgevoel & Structuur';
      case 'pt': return '1. Sensação na Boca';
      case 'ja': return '1. 口当たり・テクスチャー';
      case 'ko': return '1. 입안에서의 촉감 (마우스필)';
      case 'zh': return '1. 口感质地';
      case 'sv': return '1. Mundkänsla & Struktur';
      case 'la': return '1. Tactio Palati';
      case 'en':
      default: return '1. Mouthfeel Texture';
    }
  }

  static String fruitProfileTitle([dynamic lang]) {
    final code = TextureOption._extractLang(lang);
    switch (code) {
      case 'fr': return '2. Éclat du Fruit';
      case 'es': return '2. Perfil de la Fruta';
      case 'ca': return '2. Perfil de la Fruita';
      case 'it': return '2. Profilo del Frutto';
      case 'de': return '2. Fruchtprofil';
      case 'nl': return '2. Fruitprofiel';
      case 'pt': return '2. Perfil da Fruta';
      case 'ja': return '2. フルーツの表情';
      case 'ko': return '2. 과실의 캐릭터';
      case 'zh': return '2. 果味特征';
      case 'sv': return '2. Fruktprofil';
      case 'la': return '2. Fructus Indoles';
      case 'en':
      default: return '2. Fruit Profile';
    }
  }
}

class AromaOption {
  final String id;
  final String label;
  final String emoji;
  const AromaOption({required this.id, required this.label, required this.emoji});

  String localizedLabel(AppLocalizations? l10n) {
    if (l10n == null) return label;
    switch (id) {
      case 'fruits_rouges': return l10n.aromaFruitsRouges;
      case 'fruits_noirs': return l10n.aromaFruitsNoirs;
      case 'fruits_blancs': return l10n.aromaFruitsBlancs;
      case 'agrumes': return l10n.aromaAgrumes;
      case 'floral': return l10n.aromaFloral;
      case 'vegetal': return l10n.aromaVegetal;
      case 'epices_douces': return l10n.aromaEpicesDouces;
      case 'epices_vives': return l10n.aromaEpicesVives;
      case 'boise': return l10n.aromaBoise;
      case 'beurre': return l10n.aromaBeurre;
      case 'mineral': return l10n.aromaMineral;
      case 'miel': return l10n.aromaMiel;
      case 'chocolat': return l10n.aromaChocolat;
      case 'fumee': return l10n.aromaFumee;
      default: return label;
    }
  }
}

class LikeOption {
  final String id;
  final String label;
  const LikeOption({required this.id, required this.label});

  String localizedLabel(AppLocalizations? l10n) {
    if (l10n == null) return label;
    switch (id) {
      case 'fraicheur': return l10n.likedFreshness;
      case 'fruite': return l10n.likedFruitiness;
      case 'complexite': return l10n.likedComplexity;
      case 'elegance': return l10n.likedElegance;
      case 'puissance': return l10n.likedPower;
      case 'soyeux': return l10n.likedSilky;
      case 'originalite': return l10n.likedOriginality;
      case 'accord_plat': return l10n.likedFoodPairing;
      case 'minerale': return l10n.likedMinerality;
      case 'longueur': return l10n.likedLength;
      case 'rien_decevant': return l10n.likedDisappointing;
      case 'trop_acide': return l10n.dislikedTooAcidic;
      case 'trop_tannique': return l10n.dislikedTooTannic;
      case 'trop_boise': return l10n.dislikedTooOaked;
      case 'trop_alcoolise': return l10n.dislikedTooAlcoholic;
      case 'trop_leger': return l10n.dislikedTooThin;
      case 'manque_fruit': return l10n.dislikedLacksFruit;
      case 'trop_sucre': return l10n.dislikedTooSweet;
      case 'trop_cher': return l10n.dislikedTooExpensive;
      case 'rien': return l10n.dislikedNothing;
      default: return label;
    }
  }
}

class TextureOption {
  final String id;
  final String label;
  final String emoji;
  const TextureOption({required this.id, required this.label, required this.emoji});

  String localizedLabel([dynamic lang]) {
    final code = _extractLang(lang);
    switch (id) {
      case 'silky_lacy':
        switch (code) {
          case 'en': return 'Silky & Delicate';
          case 'es': return 'Sedoso y Delicado';
          case 'ca': return 'Sedós i Delicat';
          case 'la': return 'Sericeum ac Lene';
          case 'it': return 'Setoso & Delicato';
          case 'de': return 'Seidig & Zart';
          case 'nl': return 'Zijdeachtig & Fijn';
          case 'pt': return 'Sedoso & Delicado';
          case 'ja': return 'シルキーで繊細';
          case 'ko': return '실키하고 섬세함';
          case 'zh': return '丝滑与细腻';
          case 'sv': return 'Silkeslen & Subtil';
          case 'fr':
          default: return 'Soyeux & Dentelle';
        }
      case 'crisp_salivating':
        switch (code) {
          case 'en': return 'Crisp & Salivating';
          case 'es': return 'Vivo y Salivante';
          case 'ca': return 'Viu i Salivant';
          case 'la': return 'Recens ac Salivans';
          case 'it': return 'Vivace & Salivante';
          case 'de': return 'Lebendig & Saftig';
          case 'nl': return 'Levendig & Sappig';
          case 'pt': return 'Vivo & Salivante';
          case 'ja': return 'キレがあり唾液を誘う';
          case 'ko': return '생동감 있고 군침 도는';
          case 'zh': return '活泼与生津';
          case 'sv': return 'Pigg & Fräsch';
          case 'fr':
          default: return 'Vif & Salivant';
        }
      case 'dense_structured':
      default:
        switch (code) {
          case 'en': return 'Dense & Structured';
          case 'es': return 'Denso y Estructurado';
          case 'ca': return 'Dens i Estructurat';
          case 'la': return 'Spissum ac Firmatum';
          case 'it': return 'Denso & Strutturato';
          case 'de': return 'Dicht & Strukturiert';
          case 'nl': return 'Vol & Gestructureerd';
          case 'pt': return 'Denso & Estruturado';
          case 'ja': return '濃厚で骨格がある';
          case 'ko': return '농밀하고 탄탄한 구조';
          case 'zh': return '浓郁与紧实';
          case 'sv': return 'Fyllig & Strukturerad';
          case 'fr':
          default: return 'Dense & Structuré';
        }
    }
  }

  static String _extractLang(dynamic lang) {
    if (lang == null) return 'en';
    if (lang is String) {
      final s = lang.trim().toLowerCase();
      if (s.contains('-')) return s.split('-').first;
      if (s.contains('_')) return s.split('_').first;
      return s;
    }
    if (lang is AppLocalizations) {
      return lang.localeName.toLowerCase().split('_').first;
    }
    return 'en';
  }
}

class FruitProfileOption {
  final String id;
  final String label;
  final String emoji;
  const FruitProfileOption({required this.id, required this.label, required this.emoji});

  String localizedLabel([dynamic lang]) {
    final code = TextureOption._extractLang(lang);
    switch (id) {
      case 'crunchy_tart':
        switch (code) {
          case 'en': return 'Crunchy & Tart';
          case 'es': return 'Crujiente y Acidulado';
          case 'ca': return 'Cruixent i Acidulat';
          case 'la': return 'Crispans ac Acidulum';
          case 'it': return 'Croccante & Acidulo';
          case 'de': return 'Knackig & Säuerlich';
          case 'nl': return 'Knapperig & Friszuur';
          case 'pt': return 'Crocante & Fresco';
          case 'ja': return 'フレッシュで甘酸っぱい';
          case 'ko': return '아삭하고 새콤한 과실';
          case 'zh': return '爽脆与微酸';
          case 'sv': return 'Krispig & Syrlig';
          case 'fr':
          default: return 'Croquant & Acidulé';
        }
      case 'deep_ripe':
        switch (code) {
          case 'en': return 'Deep & Ripe';
          case 'es': return 'Profundo y Maduro';
          case 'ca': return 'Profund i Madur';
          case 'la': return 'Profundum ac Maturum';
          case 'it': return 'Profondo & Maturo';
          case 'de': return 'Tief & Vollreif';
          case 'nl': return 'Diep & Rijp';
          case 'pt': return 'Profundo & Maduro';
          case 'ja': return '深みのある熟した果実';
          case 'ko': return '깊고 잘 익은 과실';
          case 'zh': return '深沉与成熟';
          case 'sv': return 'Djup & Mogen';
          case 'fr':
          default: return 'Profond & Mûr';
        }
      case 'spicy_herbal':
      default:
        switch (code) {
          case 'en': return 'Spicy & Herbal';
          case 'es': return 'Especiado y Balsámico';
          case 'ca': return 'Especiat i Balsàmic';
          case 'la': return 'Conditum ac Herbaceum';
          case 'it': return 'Speziato & Erbaceo nobile';
          case 'de': return 'Würzig & Kräuterig';
          case 'nl': return 'Kruidig & Verfijnd groen';
          case 'pt': return 'Especiado & Vegetal nobre';
          case 'ja': return 'スパイシーでハーブの香り';
          case 'ko': return '스파이시하고 고급스러운 허브';
          case 'zh': return '香料与草本芬芳';
          case 'sv': return 'Kryddig & Örtig';
          case 'fr':
          default: return 'Épicé & Végétal noble';
        }
    }
  }
}
