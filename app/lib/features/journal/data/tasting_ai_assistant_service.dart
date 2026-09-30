import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/fonctions_ia.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/langue.dart';
import '../domain/tasting_questionnaire_result.dart';

final tastingAiAssistantServiceProvider = Provider<TastingAiAssistantService>((ref) {
  return TastingAiAssistantService();
});

class TastingParsedProfile {
  final String profileName;
  final double noteOutOf10;
  final int emojiImpression;
  final Set<String> perceivedAromas;
  final double acidity;
  final double? tannins;
  final double? mineralite;
  final double body;
  final double length;
  final String? rawComment;

  const TastingParsedProfile({
    required this.profileName,
    required this.noteOutOf10,
    required this.emojiImpression,
    required this.perceivedAromas,
    required this.acidity,
    this.tannins,
    this.mineralite,
    required this.body,
    required this.length,
    this.rawComment,
  });
}

class TastingNaturalParsedResult {
  final Map<String, TastingParsedProfile> profiles;
  final String summary;

  const TastingNaturalParsedResult({
    required this.profiles,
    required this.summary,
  });
}

class WineStorytellingData {
  final String terroirAndGrape;
  final String vintageClimate;
  final String sommelierTip;
  final String funFact;

  const WineStorytellingData({
    required this.terroirAndGrape,
    required this.vintageClimate,
    required this.sommelierTip,
    required this.funFact,
  });

  static WineStorytellingData fallback({
    required String wineName,
    int? vintage,
    String? region,
    String? grape,
  }) {
    final vStr = vintage != null ? '$vintage' : 'ce millésime';
    final regStr = region != null && region.isNotEmpty ? region : 'son terroir d\'origine';
    return WineStorytellingData(
      terroirAndGrape: '$wineName puise son élégance dans $regStr. Un assemblage soigné qui reflète la typicité géologique de son appellation.',
      vintageClimate: 'L\'année $vStr a offert des conditions équilibrées entre ensoleillement généreux et fraîcheur nocturne, préservant la fraîcheur aromatique.',
      sommelierTip: 'Servez dans des verres amples et laissez respirer quelques minutes dans le verre pour libérer toute sa palette aromatique.',
      funFact: 'À table, ce vin brille par sa capacité à créer du lien et à stimuler le débat entre amateurs éclairés.',
    );
  }
}

class BlindQuizData {
  final List<String> regionChoices;
  final String correctRegion;
  final List<String> grapeChoices;
  final String correctGrape;
  final List<String> vintageBrackets;
  final String correctVintageBracket;
  final List<String> priceBrackets;
  final String estimatedPriceBracket;

  const BlindQuizData({
    required this.regionChoices,
    required this.correctRegion,
    required this.grapeChoices,
    required this.correctGrape,
    required this.vintageBrackets,
    required this.correctVintageBracket,
    required this.priceBrackets,
    required this.estimatedPriceBracket,
  });
}

/// AI Assistant for guided tastings, speech dictation, blind tastings, and table storytelling.
class TastingAiAssistantService {
  /// Depuis la V2.3, ces tâches passent par la fonction `taches-ia` : l'app n'a plus de clé.
  /// Sans serveur (hors ligne, Supabase non initialisé dans un essai), les replis locaux
  /// prennent le relais, comme avant.
  TastingAiAssistantService({FonctionsIa? ia}) : _iaInjecte = ia;

  final FonctionsIa? _iaInjecte;

  FonctionsIa? get _ia {
    if (_iaInjecte != null) return _iaInjecte;
    try {
      return FonctionsIa(Supabase.instance.client);
    } catch (_) {
      return null;
    }
  }

  /// Le résultat d'une tâche du serveur, ou `null` si elle n'a pas abouti.
  Future<dynamic> _tache(String tache, Map<String, dynamic> entrees) async {
    final ia = _ia;
    if (ia == null) return null;
    final r = await ia.appeler('taches-ia', {'tache': tache, 'langue': tr('fr', 'en'), ...entrees},
        delai: const Duration(seconds: 40));
    if (!r.ok) {
      AppLogger.info('TASTING_AI', '$tache sans le sommelier (${r.erreur}) : repli local');
      return null;
    }
    return r.donnees!['resultat'];
  }

  /// 🎙️ Parse spoken or natural language tasting notes into structured questionnaire results.
  /// Example input: "Bernard a adoré, 8.5/10 avec des arômes de mûre et de sous-bois. Caro lui met 7/10 en trouvant qu'il manque un peu de fraîcheur."
  Future<TastingNaturalParsedResult> parseNaturalLanguageNotes({
    required String spokenText,
    required List<String> tasterNames,
    required String wineType,
    required String wineName,
  }) async {
    final cleanWineType = wineType.toLowerCase();
    final isRed = cleanWineType.contains('rouge') || cleanWineType.contains('red');
    final validAromaIds = TastingQuestionnaireResult.aromaOptions.map((a) => a.id).toList();

    try {
      final brut = await _tache('notes_degustation', {
        'texte': spokenText,
        'degustateurs': tasterNames,
        'type_vin': wineType,
        'nom_vin': wineName,
        'aromes': validAromaIds,
      });
      final jsonResponse = brut is Map ? Map<String, dynamic>.from(brut) : null;
      if (jsonResponse != null && jsonResponse['tasters'] is List) {
        final Map<String, TastingParsedProfile> profiles = {};
        final summary = jsonResponse['summary']?.toString() ?? 'Notes de dégustation extraites avec succès.';

        for (final item in jsonResponse['tasters']) {
          if (item is Map<String, dynamic>) {
            final name = item['profile_name']?.toString() ?? (tasterNames.isNotEmpty ? tasterNames.first : 'Moi');
            final note = (item['note'] as num?)?.toDouble().clamp(1.0, 10.0) ?? 7.0;
            // Même correspondance que le curseur du questionnaire. Il en existait une
            // seconde ici, avec d'autres seuils (7,0 au lieu de 7,5 pour 😊), si bien que
            // deux personnes ayant mis 7,0/10 se voyaient attribuer des émojis différents
            // selon qu'elles avaient bougé le curseur ou dicté leur commentaire.
            // Remonté par un utilisateur le 2026-09-08.
            final emoji = (item['emoji_impression'] as num?)?.toInt().clamp(0, 4) ??
                TastingQuestionnaireResult.emojiIndexForRating(note);
            final rawAromas = item['aromas'] as List?;
            final Set<String> aromas = {};
            if (rawAromas != null) {
              for (final a in rawAromas) {
                final aStr = a.toString();
                if (validAromaIds.contains(aStr)) {
                  aromas.add(aStr);
                }
              }
            }

            profiles[name] = TastingParsedProfile(
              profileName: name,
              noteOutOf10: note,
              emojiImpression: emoji,
              perceivedAromas: aromas,
              acidity: (item['acidity'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.5,
              tannins: isRed ? (item['tannins'] as num?)?.toDouble().clamp(0.0, 1.0) : null,
              mineralite: !isRed ? (item['mineralite'] as num?)?.toDouble().clamp(0.0, 1.0) : null,
              body: (item['body'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.5,
              length: (item['length'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.5,
              rawComment: item['raw_comment']?.toString(),
            );
          }
        }

        if (profiles.isNotEmpty) {
          return TastingNaturalParsedResult(profiles: profiles, summary: summary);
        }
      }
    } catch (e) {
      AppLogger.warning('TASTING_AI', 'Failed to parse natural language notes: $e');
    }

    // Heuristic fallback if offline or API unavailable
    return _fallbackParseNotes(spokenText, tasterNames, isRed);
  }

  /// 📖 Generate storytelling anecdotes for the host to tell around the dinner table.
  Future<WineStorytellingData> generateWineStorytelling({
    required String wineName,
    int? vintage,
    String? producer,
    String? region,
    String? appellation,
    String? wineType,
    List<String>? grapes,
  }) async {
    try {
      final brut = await _tache('recit', {
        'nom': wineName,
        if (vintage != null) 'millesime': vintage,
        if (producer != null) 'producteur': producer,
        if (region != null) 'region': region,
        if (appellation != null) 'appellation': appellation,
        if (wineType != null) 'type': wineType,
        'cepages': grapes ?? const <String>[],
      });
      final res = brut is Map ? Map<String, dynamic>.from(brut) : null;
      if (res != null) {
        return WineStorytellingData(
          terroirAndGrape: res['terroir_and_grape']?.toString() ?? 'Un vin issu d\'un terroir remarquable.',
          vintageClimate: res['vintage_climate']?.toString() ?? 'Un millésime qui a révélé toute la finesse du domaine.',
          sommelierTip: res['sommelier_tip']?.toString() ?? 'À savourer lentement pour laisser le vin s\'épanouir.',
          funFact: res['fun_fact']?.toString() ?? 'Ce vin est le reflet d\'une longue tradition vigneronne.',
        );
      }
    } catch (e) {
      AppLogger.warning('TASTING_AI', 'Storytelling generation failed: $e');
    }

    return WineStorytellingData.fallback(
      wineName: wineName,
      vintage: vintage,
      region: region ?? appellation,
      grape: grapes?.isNotEmpty == true ? grapes!.first : null,
    );
  }

  /// 🍷 Generate the "Synthèse du Conclave" / table consensus after group tasting.
  Future<String> generateTastingConsensus({
    required String wineName,
    required List<TastingQuestionnaireResult> results,
  }) async {
    if (results.isEmpty) return 'Dégustation terminée avec succès.';
    if (results.length == 1) {
      final r = results.first;
      return '${r.profileName} lui attribue la note de ${r.noteOutOf10.toStringAsFixed(1)}/10 (${TastingQuestionnaireResult.emojiLabels[r.emojiImpression]}).';
    }

    final avis = results.map((r) {
      final aromas = r.perceivedAromas.join(', ');
      return '${r.profileName}: ${r.noteOutOf10}/10, émoji: ${TastingQuestionnaireResult.emojiLabels[r.emojiImpression]}, arômes: [$aromas], avis: ${r.wouldBuyAgain}';
    }).toList();

    try {
      final brut = await _tache('synthese_table', {'nom_vin': wineName, 'avis': avis});
      final text = brut is String ? brut : null;
      if (text != null && text.trim().isNotEmpty) {
        return text.trim();
      }
    } catch (e) {
      AppLogger.warning('TASTING_AI', 'Consensus generation failed: $e');
    }

    // Heuristic fallback
    final avg = results.map((r) => r.noteOutOf10).reduce((a, b) => a + b) / results.length;
    final highest = results.reduce((a, b) => a.noteOutOf10 >= b.noteOutOf10 ? a : b);
    final lowest = results.reduce((a, b) => a.noteOutOf10 <= b.noteOutOf10 ? a : b);

    if ((highest.noteOutOf10 - lowest.noteOutOf10) <= 1.0) {
      return 'Ce vin a fait l\'unanimité autour de la table avec une note moyenne harmonieuse de ${avg.toStringAsFixed(1)}/10 ✨';
    } else {
      return 'Ce vin a suscité un beau débat à table : plébiscité par ${highest.profileName} (${highest.noteOutOf10.toStringAsFixed(1)}/10), tandis que ${lowest.profileName} l\'a trouvé plus réservé (${lowest.noteOutOf10.toStringAsFixed(1)}/10). Moyenne : ${avg.toStringAsFixed(1)}/10 🍷';
    }
  }

  /// 🙈 Generate blind tasting quiz options (credible regions and grapes tailored to the real wine).
  BlindQuizData generateBlindQuizOptions({
    required String wineName,
    required String wineType,
    int? vintage,
    String? region,
    String? appellation,
    List<String>? grapes,
    double? price,
  }) {
    final cleanType = wineType.toLowerCase();
    final isWhite = cleanType.contains('blanc') || cleanType.contains('white');
    final isRose = cleanType.contains('ros') || cleanType.contains('rose');
    final isSparkling = cleanType.contains('effervescent') || cleanType.contains('champ');

    // 1. Regions
    final targetRegion = (appellation != null && appellation.isNotEmpty)
        ? appellation
        : (region != null && region.isNotEmpty ? region : 'Bordeaux');

    final candidateRegions = isSparkling
        ? ['Champagne', 'Crémant d\'Alsace', 'Val de Loire', 'Franciacorta (Italie)']
        : (isWhite
            ? ['Bourgogne (Chablis / Beaune)', 'Vallée de la Loire (Sancerre)', 'Alsace', 'Bordeaux Blanc']
            : (isRose
                ? ['Côtes de Provence', 'Bandol', 'Tavel (Rhône)', 'Languedoc-Roussillon']
                : ['Bordeaux (Médoc / Saint-Émilion)', 'Vallée du Rhône', 'Bourgogne', 'Languedoc']));

    final Set<String> regionSet = {targetRegion};
    for (final r in candidateRegions) {
      if (regionSet.length < 4) regionSet.add(r);
    }
    final regionChoices = regionSet.toList()..shuffle();

    // 2. Grapes
    final targetGrape = grapes != null && grapes.isNotEmpty ? grapes.first : (isWhite ? 'Chardonnay' : 'Pinot Noir');
    final candidateGrapes = isSparkling
        ? ['Chardonnay', 'Pinot Noir', 'Pinot Meunier', 'Chenin Blanc']
        : (isWhite
            ? ['Chardonnay', 'Sauvignon Blanc', 'Riesling', 'Chenin Blanc']
            : (isRose
                ? ['Grenache', 'Cinsault', 'Syrah', 'Mourvèdre']
                : ['Cabernet Sauvignon', 'Pinot Noir', 'Syrah', 'Merlot']));

    final Set<String> grapeSet = {targetGrape};
    for (final g in candidateGrapes) {
      if (grapeSet.length < 4) grapeSet.add(g);
    }
    final grapeChoices = grapeSet.toList()..shuffle();

    // 3. Vintage brackets
    final nowYear = DateTime.now().year;
    final age = vintage != null ? (nowYear - vintage) : 3;
    String correctBracket;
    if (age <= 2) {
      correctBracket = 'Très jeune (1 - 2 ans)';
    } else if (age <= 6) {
      correctBracket = 'En pleine jeunesse (3 - 6 ans)';
    } else if (age <= 12) {
      correctBracket = 'À parfaite maturité (7 - 12 ans)';
    } else {
      correctBracket = 'Grand vin de garde (> 12 ans)';
    }

    final vintageBrackets = [
      'Très jeune (1 - 2 ans)',
      'En pleine jeunesse (3 - 6 ans)',
      'À parfaite maturité (7 - 12 ans)',
      'Grand vin de garde (> 12 ans)',
    ];

    // 4. Price brackets
    final p = price ?? 22.0;
    String priceBracket;
    if (p < 15) {
      priceBracket = 'Moins de 15 € (Plaisir immédiat)';
    } else if (p < 30) {
      priceBracket = '15 € - 30 € (Belle découverte)';
    } else if (p < 60) {
      priceBracket = '30 € - 60 € (Grande cuvée)';
    } else {
      priceBracket = 'Plus de 60 € (Flacon d\'exception)';
    }

    final priceBrackets = [
      'Moins de 15 € (Plaisir immédiat)',
      '15 € - 30 € (Belle découverte)',
      '30 € - 60 € (Grande cuvée)',
      'Plus de 60 € (Flacon d\'exception)',
    ];

    return BlindQuizData(
      regionChoices: regionChoices,
      correctRegion: targetRegion,
      grapeChoices: grapeChoices,
      correctGrape: targetGrape,
      vintageBrackets: vintageBrackets,
      correctVintageBracket: correctBracket,
      priceBrackets: priceBrackets,
      estimatedPriceBracket: priceBracket,
    );
  }

  // =========================================================================
  // Internal Helpers
  // =========================================================================


  TastingNaturalParsedResult _fallbackParseNotes(String text, List<String> tasterNames, bool isRed) {
    final lower = text.toLowerCase();
    final primaryName = tasterNames.isNotEmpty ? tasterNames.first : 'Moi';

    double note = 7.0;
    final scoreMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:/|sur)\s*10', caseSensitive: false).firstMatch(lower);
    if (scoreMatch != null) {
      final parsed = double.tryParse(scoreMatch.group(1)!.replaceAll(',', '.'));
      if (parsed != null) {
        note = parsed.clamp(1.0, 10.0);
      }
    } else if (lower.contains('adoré') || lower.contains('régal') || lower.contains('excellent') || lower.contains('coup de coeur') || lower.contains('incroyable')) {
      note = 9.0;
    } else if (lower.contains('très bon') || lower.contains('super') || lower.contains('remarquable')) {
      note = 8.0;
    } else if (lower.contains('bof') || lower.contains('moyen') || lower.contains('déçu')) {
      note = 5.0;
    } else if (lower.contains('mauvais') || lower.contains('bouchonné') || lower.contains('pas bon')) {
      note = 3.0;
    }

    final Set<String> detectedAromas = {};
    if (lower.contains('mûre') || lower.contains('cassis') || lower.contains('noir')) detectedAromas.add('fruits_noirs');
    if (lower.contains('fraise') || lower.contains('framboise') || lower.contains('cerise') || lower.contains('rouge')) detectedAromas.add('fruits_rouges');
    if (lower.contains('pomme') || lower.contains('poire') || lower.contains('pêche')) detectedAromas.add('fruits_blancs');
    if (lower.contains('citron') || lower.contains('pamplemousse') || lower.contains('agrume')) detectedAromas.add('agrumes');
    if (lower.contains('vanille') || lower.contains('boisé') || lower.contains('chêne')) detectedAromas.add('boise');
    if (lower.contains('minéral') || lower.contains('caillou') || lower.contains('craie') || lower.contains('silex')) detectedAromas.add('mineral');
    if (lower.contains('fumé') || lower.contains('grillé')) detectedAromas.add('fumee');
    if (lower.contains('poivre') || lower.contains('épicé')) detectedAromas.add('epices_vives');

    final profile = TastingParsedProfile(
      profileName: primaryName,
      noteOutOf10: note,
      // Voir plus haut : une seule correspondance note → émoji dans toute l'app.
      emojiImpression: TastingQuestionnaireResult.emojiIndexForRating(note),
      perceivedAromas: detectedAromas,
      acidity: lower.contains('acide') || lower.contains('vif') ? 0.75 : 0.5,
      tannins: isRed ? (lower.contains('tannique') || lower.contains('râpeux') ? 0.8 : 0.5) : null,
      mineralite: !isRed ? (lower.contains('minéral') || lower.contains('frais') ? 0.8 : 0.5) : null,
      body: lower.contains('puissant') || lower.contains('lourd') ? 0.8 : 0.5,
      length: lower.contains('long') ? 0.8 : 0.5,
      rawComment: text,
    );

    return TastingNaturalParsedResult(
      profiles: {primaryName: profile},
      summary: 'Commentaire analysé : note de ${note.toStringAsFixed(1)}/10.',
    );
  }
}
