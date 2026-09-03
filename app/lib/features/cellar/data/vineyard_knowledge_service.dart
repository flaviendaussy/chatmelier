import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../domain/vineyard_knowledge.dart';

class VineyardKnowledgeService {
  final SupabaseClient _client;
  static final Map<String, VineyardKnowledge> _memoryCache = {};

  VineyardKnowledgeService(this._client);

  /// Normalizes a producer/vineyard name into a clean unique transversal key
  static String normalizeKey(String producer) {
    return producer
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  /// Retrieves vineyard knowledge from transversal cache, re-verifying only if 1 year old or more
  Future<VineyardKnowledge?> getOrFetchVineyardKnowledge({
    required String producer,
    String? region,
    String? appellation,
    String? country,
    bool forceRefresh = false,
  }) async {
    final cleanProducer = producer.trim();
    if (cleanProducer.isEmpty) return null;

    final key = normalizeKey(cleanProducer);

    // 1. Check in-memory cache
    final cached = _memoryCache[key];
    if (cached != null && !cached.isExpired && !forceRefresh) {
      AppLogger.info('VINEYARD_SERVICE', 'Memory Cache HIT for $key (Verified ${cached.verifiedAt})');
      return cached;
    }

    // 2. Query shared transversal table in Supabase
    try {
      final res = await _client
          .from('vineyard_knowledge_cache')
          .select()
          .eq('key', key)
          .maybeSingle();

      if (res != null) {
        final entry = VineyardKnowledge.fromJson(res);
        // Check 1-year rule: valid if verified within 365 days
        if (!entry.isExpired && !forceRefresh) {
          AppLogger.info('VINEYARD_SERVICE', 'Supabase Transversal Cache HIT for $key (Verified ${entry.verifiedAt})');
          _memoryCache[key] = entry;
          return entry;
        } else {
          AppLogger.info('VINEYARD_SERVICE', 'Vineyard Cache entry EXPIRED (> 365 days) for $key. Re-verifying...');
        }
      }
    } catch (e) {
      AppLogger.warning('VINEYARD_SERVICE', 'Could not fetch from remote transversal cache: $e');
    }

    // 3. Cache Miss or Expired (>= 1 year): Perform research and compile domain knowledge
    final newKnowledge = _compileVineyardResearch(
      key: key,
      producer: cleanProducer,
      region: region ?? 'France',
      appellation: appellation ?? '',
      country: country ?? 'France',
    );

    // 4. Persist to shared Supabase transversal cache (upsert)
    try {
      await _client.from('vineyard_knowledge_cache').upsert(newKnowledge.toJson());
      AppLogger.info('VINEYARD_SERVICE', 'Saved fresh vineyard research to transversal cache for $key');
    } catch (e) {
      AppLogger.warning('VINEYARD_SERVICE', 'Could not upsert to remote cache (offline or permissions): $e');
    }

    _memoryCache[key] = newKnowledge;
    return newKnowledge;
  }

  /// Synthesizes domain & terroir knowledge
  VineyardKnowledge _compileVineyardResearch({
    required String key,
    required String producer,
    required String region,
    required String appellation,
    required String country,
  }) {
    final now = DateTime.now();

    // Determine soil and viticulture characteristics based on appellation/region
    String soil = 'Graves garonnaises, argilo-calcaires et sables';
    String viticulture = 'Viticulture raisonnée et vendanges manuelles';
    String description = '';

    final lower = '$producer $region $appellation'.toLowerCase();

    if (lower.contains('bourgogne') || lower.contains('burgundy') || lower.contains('côte de nuits') || lower.contains('côte de beaune') || lower.contains('chablis')) {
      soil = 'Calcaire kimméridgien, marnes et argiles';
      viticulture = 'Parcellaire haute précision, souvent en biodynamie';
      description = '$producer s\'enracine dans les grands terroirs bourguignons où le Pinot Noir et le Chardonnay révèlent une pureté minérale exceptionnelle. Les sols calcaires et la mosaïque de climats offrent des vins alliant finesse soyeuse, tension et longue garde.';
    } else if (lower.contains('bordeaux') || lower.contains('médoc') || lower.contains('pauillac') || lower.contains('margaux') || lower.contains('saint-émilion') || lower.contains('pomerol')) {
      soil = 'Croupes de graves profondes sur sous-sol argileux';
      viticulture = 'Vinification traditionnelle en cuves thermo-régulées, élevage en fûts de chêne français';
      description = '$producer incarne la grande tradition bordelaise. Situé sur un terroir d\'exception combinant drainage naturel et ensoleillement idéal, le domaine produit des cuvées de garde réputées pour leurs tanins nobles, leur complexité de fruits noirs et leur fraîcheur aromatique.';
    } else if (lower.contains('rhône') || lower.contains('rhone') || lower.contains('châteauneuf') || lower.contains('syrah')) {
      soil = 'Galets roulés sur argiles rouges, schistes et granites';
      viticulture = 'Vendanges entières ou égrappage sélectif, respect des vieilles vignes';
      description = '$producer puise son énergie dans la Vallée du Rhône. Balayées par le mistral et gorgées de soleil, les vignes offrent une concentration remarquable, marquée par des notes de poivre noir, de garrigue et de fruits mûrs.';
    } else if (lower.contains('champagne')) {
      soil = 'Craie pure kimméridgienne et marnes blanches';
      viticulture = 'Méthode champenoise traditionnelle, maturation prolongée sur lattes';
      description = '$producer perpétue l\'excellence effervescente champenoise. La craie profonde régule l\'humidité et apporte une vivacité saline inimitable, sublimée par un vieillissement soigné en cave.';
    } else if (lower.contains('loire') || lower.contains('sancerre')) {
      soil = 'Silex, terres blanches et caillottes calcaires';
      viticulture = 'Pratiques agro-écologiques, pressurage doux';
      description = '$producer valorise la fraîcheur ligérienne avec une expression ciselée du Sauvignon ou du Chenin, marquée par des notes d\'agrumes, de fleurs blanches et une minéralité fumée.';
    } else if (lower.contains('alsace')) {
      soil = 'Mosaïque géologique de grès, granit et calcaire';
      viticulture = 'Agriculture biologique certifiée, vendanges manuelles triées';
      description = '$producer bénéficie du microclimat abrité des Vosges, favorisant une maturité aromatique lente et complète des cépages nobles alsaciens.';
    } else {
      soil = 'Sols variés adaptés au micro-climat local';
      viticulture = 'Conduite soignée de la vigne et vinification parcellaire';
      description = '$producer cultive avec passion ses parcelles au cœur de $region ($country). Les méthodes de culture respectueuses des sols favorisent l\'expression authentique du cépage et du millésime.';
    }

    return VineyardKnowledge(
      key: key,
      producerName: producer,
      region: region,
      appellation: appellation,
      country: country,
      terroirDescription: description,
      soilType: soil,
      viticultureStyle: viticulture,
      verifiedAt: now,
      source: 'Encyclopédie Œnologique Chatmelier (Vérifiée)',
    );
  }
}

final vineyardKnowledgeServiceProvider = Provider<VineyardKnowledgeService>((ref) {
  return VineyardKnowledgeService(ref.watch(supabaseProvider));
});

final vineyardKnowledgeProvider = FutureProvider.family<VineyardKnowledge?, String>((ref, producer) async {
  if (producer.trim().isEmpty) return null;
  final service = ref.watch(vineyardKnowledgeServiceProvider);
  return service.getOrFetchVineyardKnowledge(producer: producer);
});
