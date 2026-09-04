import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/utils/app_logger.dart';
import '../../offline/presentation/sync_provider.dart';
import '../domain/cocktail.dart';
import 'cocktail_catalog.dart';

const String _kCustomCocktailsStorageKey = 'chatmelier_custom_cocktails_v1';

class CustomCocktailService {
  final SharedPreferences _prefs;
  final SupabaseClient? _supabase;

  CustomCocktailService(this._prefs, [this._supabase]);

  List<Cocktail> getCustomCocktails() {
    final raw = _prefs.getString(_kCustomCocktailsStorageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final parsed = list.map((e) => Cocktail.fromJson(e as Map<String, dynamic>)).toList();
      final seenIds = <String>{};
      final seenNames = <String>{};
      final unique = <Cocktail>[];
      for (final c in parsed) {
        final nid = c.id.trim().toLowerCase();
        final nname = c.name.trim().toLowerCase();
        if (!seenIds.contains(nid) && !seenNames.contains(nname)) {
          seenIds.add(nid);
          seenNames.add(nname);
          unique.add(c);
        }
      }
      return unique;
    } catch (e) {
      AppLogger.warning('CUSTOM_COCKTAILS', 'Could not parse custom cocktails: $e');
      return [];
    }
  }

  Future<List<Cocktail>> saveCocktail(Cocktail cocktail, {String? preferredName}) async {
    final current = getCustomCocktails();
    
    // If a preferred name is given, update the name
    final finalName = (preferredName != null && preferredName.trim().isNotEmpty)
        ? preferredName.trim()
        : cocktail.name.trim();

    // Check if matching by id or name
    final existingIndex = current.indexWhere((c) =>
        c.id == cocktail.id || c.name.toLowerCase() == finalName.toLowerCase());

    final toSave = cocktail.copyWith(
      id: cocktail.id.startsWith('custom_') ? cocktail.id : 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: finalName,
      isCustom: true,
      category: cocktail.category.contains('Création') ? cocktail.category : 'Création Favorite',
    );

    if (existingIndex >= 0) {
      current[existingIndex] = toSave;
    } else {
      current.insert(0, toSave);
    }

    await _prefs.setString(
      _kCustomCocktailsStorageKey,
      jsonEncode(current.map((c) => c.toJson()).toList()),
    );

    _syncToCloud(current);
    return current;
  }

  Future<List<Cocktail>> deleteCocktail(String id) async {
    final current = getCustomCocktails();
    current.removeWhere((c) => c.id == id);
    await _prefs.setString(
      _kCustomCocktailsStorageKey,
      jsonEncode(current.map((c) => c.toJson()).toList()),
    );
    _syncToCloud(current);
    return current;
  }

  bool isSaved(String nameOrId) {
    final current = getCustomCocktails();
    final target = nameOrId.trim().toLowerCase();
    return current.any((c) => c.id.toLowerCase() == target || c.name.toLowerCase() == target);
  }

  Future<void> _syncToCloud(List<Cocktail> items) async {
    final client = _supabase;
    if (client == null) return;
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      await client.from('user_cocktails').upsert(
        items.map((c) => {
          'user_id': user.id,
          'cocktail_id': c.id,
          'data': c.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        }).toList(),
      );
    } catch (_) {
      // Local-first: ignore cloud errors
    }
  }
}

final customCocktailServiceProvider = Provider<CustomCocktailService>((ref) {
  final prefs = ref.watch(sharedPreferencesInstanceProvider);
  final supabase = ref.watch(supabaseProvider);
  return CustomCocktailService(prefs, supabase);
});

final customCocktailsProvider = StateNotifierProvider<CustomCocktailsNotifier, List<Cocktail>>((ref) {
  final service = ref.watch(customCocktailServiceProvider);
  return CustomCocktailsNotifier(service);
});

class CustomCocktailsNotifier extends StateNotifier<List<Cocktail>> {
  final CustomCocktailService _service;

  CustomCocktailsNotifier(this._service) : super(_service.getCustomCocktails());

  Future<void> saveCocktail(Cocktail cocktail, {String? preferredName}) async {
    state = await _service.saveCocktail(cocktail, preferredName: preferredName);
  }

  Future<void> deleteCocktail(String id) async {
    state = await _service.deleteCocktail(id);
  }

  bool isSaved(String nameOrId) {
    final target = nameOrId.trim().toLowerCase();
    return state.any((c) => c.id.toLowerCase() == target || c.name.toLowerCase() == target);
  }
}

/// Combines user's custom saved cocktails with the static catalogue presets, strictly deduplicated
final allCocktailsProvider = Provider<List<Cocktail>>((ref) {
  final customList = ref.watch(customCocktailsProvider);
  final seenIds = <String>{};
  final seenNames = <String>{};
  final result = <Cocktail>[];

  // 1. Custom cocktails first
  for (final c in customList) {
    final normId = c.id.trim().toLowerCase();
    final normName = c.name.trim().toLowerCase();
    if (!seenIds.contains(normId) && !seenNames.contains(normName)) {
      seenIds.add(normId);
      seenNames.add(normName);
      result.add(c);
    }
  }

  // 2. Preset catalog
  for (final c in CocktailCatalog.all) {
    final normId = c.id.trim().toLowerCase();
    final normName = c.name.trim().toLowerCase();
    if (!seenIds.contains(normId) && !seenNames.contains(normName)) {
      seenIds.add(normId);
      seenNames.add(normName);
      result.add(c);
    }
  }

  return result;
});
