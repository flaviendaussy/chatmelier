import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../shared/utils/app_logger.dart';
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
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const List<String> _candidateModels = [
    'gemini-3.1-flash-lite',
    'gemini-3.5-flash',
    'gemini-flash-latest',
  ];

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

    final systemPrompt = '''Tu es le sommelier IA de Chatmelier.
L'utilisateur te transmet une retranscription vocale ou des notes libres de dégustation saisies à table :
"$spokenText"

Le vin dégusté est : "$wineName" (Type : $cleanWineType).
Les dégustateurs présents sont : ${tasterNames.join(', ')}.

TÂCHE :
Analyse le texte et extrait pour chaque personne mentionnée (ou pour le dégustateur principal si une seule personne est évoquée) les valeurs suivantes :
1. "profile_name" : Nom du dégustateur (doit correspondre au mieux à l'un des noms fournis : ${tasterNames.join(', ')}).
2. "note" : Note sur 10 (flottant entre 1.0 et 10.0). Si non mentionné explicitement, déduis-le du sentiment (ex. "adoré" -> 8.5, "correct" -> 6.5, "moyen" -> 5.0).
3. "emoji_impression" : Entier entre 0 et 4 (0=😖, 1=😕, 2=😐, 3=😊, 4=😍).
4. "aromas" : Tableau d'IDs d'arômes détectés parmi UNIQUEMENT : ${jsonEncode(validAromaIds)}.
5. "acidity" : Flottant 0.0 (mou) à 1.0 (vif/tranchant). Défaut 0.5.
6. ${isRed ? '"tannins" : Flottant 0.0 (soyeux/fondus) à 1.0 (très tannique/râpeux). Défaut 0.5.' : '"mineralite" : Flottant 0.0 à 1.0 (minéralité et tension). Défaut 0.5.'}
7. "body" : Flottant 0.0 (léger) à 1.0 (puissant). Défaut 0.5.
8. "length" : Flottant 0.0 (court) à 1.0 (persistant). Défaut 0.5.
9. "raw_comment" : Brève synthèse en 1 phrase du commentaire de cette personne.

Fournis aussi un "summary" global de 1 phrase résumant l'impression générale.

Réponds STRICTEMENT sous forme d'un objet JSON :
{
  "summary": "...",
  "tasters": [
    {
      "profile_name": "...",
      "note": 8.5,
      "emoji_impression": 3,
      "aromas": ["fruits_noirs", "boise"],
      "acidity": 0.5,
      ${isRed ? '"tannins": 0.6,' : '"mineralite": 0.7,'}
      "body": 0.6,
      "length": 0.7,
      "raw_comment": "..."
    }
  ]
}''';

    try {
      final jsonResponse = await _callGeminiJson(systemPrompt);
      if (jsonResponse != null && jsonResponse['tasters'] is List) {
        final Map<String, TastingParsedProfile> profiles = {};
        final summary = jsonResponse['summary']?.toString() ?? 'Notes de dégustation extraites avec succès.';

        for (final item in jsonResponse['tasters']) {
          if (item is Map<String, dynamic>) {
            final name = item['profile_name']?.toString() ?? (tasterNames.isNotEmpty ? tasterNames.first : 'Moi');
            final note = (item['note'] as num?)?.toDouble().clamp(1.0, 10.0) ?? 7.0;
            final emoji = (item['emoji_impression'] as num?)?.toInt().clamp(0, 4) ?? (note >= 8.5 ? 4 : (note >= 7.0 ? 3 : 2));
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
    final prompt = '''Tu es un sommelier érudit et conteur passionné.
Pour le vin suivant servi à table :
- Vin : $wineName
- Domaine / Producteur : ${producer ?? "Inconnu"}
- Millésime : ${vintage ?? "Non millésimé"}
- Région / Appellation : ${region ?? ""} ${appellation ?? ""}
- Cépages : ${grapes?.join(', ') ?? "Non spécifiés"}
- Type : ${wineType ?? "Rouge"}

Génère 3 courtes anecdotes captivantes et élégantes en français, parfaites pour le maître de maison qui souhaite raconter l'histoire de la bouteille à ses invités :
1. "terroir_and_grape" : Le terroir et la typicité des cépages (1 à 2 phrases percutantes).
2. "vintage_climate" : Le millésime et son contexte climatique marquant (1 à 2 phrases).
3. "sommelier_tip" : Le conseil du sommelier pour apprécier pleinement le vin à table.
4. "fun_fact" : Une anecdote historique ou insolite sur le domaine, la région ou ce style de vin.

Réponds STRICTEMENT sous forme d'un objet JSON :
{
  "terroir_and_grape": "...",
  "vintage_climate": "...",
  "sommelier_tip": "...",
  "fun_fact": "..."
}''';

    try {
      final res = await _callGeminiJson(prompt);
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

    final summaryItems = results.map((r) {
      final aromas = r.perceivedAromas.join(', ');
      return '${r.profileName}: ${r.noteOutOf10}/10, émoji: ${TastingQuestionnaireResult.emojiLabels[r.emojiImpression]}, arômes: [$aromas], avis: ${r.wouldBuyAgain}';
    }).join('; ');

    final prompt = '''Tu es un sommelier qui anime une table d'amis.
Voici les avis enregistrés pour la dégustation de "$wineName" :
$summaryItems

Rédige en français la "Synthèse du Conclave" en 1 ou 2 phrases vivantes et élégantes :
- Indique si le vin a fait l'unanimité ou a créé un débat passionné.
- Mets en lumière les accords ou les contrastes de perception (ex: notes, fraîcheur, arômes).
- Donne la note moyenne de la table.
Reste concis, chaleureux et convivial. Pas de puces, pas de JSON, juste le texte fluide.''';

    try {
      final text = await _callGeminiText(prompt);
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

  Future<Map<String, dynamic>?> _callGeminiJson(String prompt) async {
    for (final model in _candidateModels) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
        );

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'role': 'user',
                    'parts': [{'text': prompt}],
                  }
                ],
                'generationConfig': {
                  'responseMimeType': 'application/json',
                }
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text is String && text.isNotEmpty) {
            return jsonDecode(text) as Map<String, dynamic>;
          }
        }
      } catch (_) {
        // Try next candidate model
      }
    }
    return null;
  }

  Future<String?> _callGeminiText(String prompt) async {
    for (final model in _candidateModels) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
        );

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'role': 'user',
                    'parts': [{'text': prompt}],
                  }
                ],
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text is String && text.isNotEmpty) {
            return text;
          }
        }
      } catch (_) {
        // Try next candidate model
      }
    }
    return null;
  }

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
      emojiImpression: note >= 8.5 ? 4 : (note >= 7.0 ? 3 : 2),
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
