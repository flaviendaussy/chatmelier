import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../offline/presentation/sync_provider.dart';
import '../domain/bar_pantry_item.dart';

const String _kBarPantryStorageKey = 'chatmelier_bar_pantry_items_v1';

class BarPantryService {
  final SharedPreferences _prefs;
  final SupabaseClient? _supabase;

  BarPantryService(this._prefs, [this._supabase]);

  static final List<BarPantryItem> defaultTemplate = [
    // 🍋 Fruits & Agrumes
    const BarPantryItem(id: 'lime', name: 'Citron vert (Lime)', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍋‍🟩'),
    const BarPantryItem(id: 'lemon', name: 'Citron jaune', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍋'),
    const BarPantryItem(id: 'orange', name: 'Orange', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍊'),
    const BarPantryItem(id: 'grapefruit', name: 'Pamplemousse rose', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍈'),
    const BarPantryItem(id: 'cucumber', name: 'Concombre', category: PantryCategory.fruits, unit: 'pièces', emoji: '🥒'),
    const BarPantryItem(id: 'strawberries', name: 'Fraises / Fruits rouges', category: PantryCategory.fruits, unit: 'barquettes', emoji: '🍓'),
    const BarPantryItem(id: 'pineapple', name: 'Ananas', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍍'),
    const BarPantryItem(id: 'apple', name: 'Pomme', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍎'),

    // 🌿 Herbes & Aromates
    const BarPantryItem(id: 'mint', name: 'Menthe fraîche', category: PantryCategory.herbs, unit: 'bottes', emoji: '🌿'),
    const BarPantryItem(id: 'basil', name: 'Basilic frais', category: PantryCategory.herbs, unit: 'bottes', emoji: '🌱'),
    const BarPantryItem(id: 'rosemary', name: 'Romarin frais', category: PantryCategory.herbs, unit: 'branches', emoji: '🌲'),
    const BarPantryItem(id: 'thyme', name: 'Thym frais', category: PantryCategory.herbs, unit: 'branches', emoji: '🌾'),
    const BarPantryItem(id: 'ginger', name: 'Gingembre frais', category: PantryCategory.herbs, unit: 'morceaux', emoji: '🫚'),

    // 🥤 Soft Drinks & Mixers
    const BarPantryItem(id: 'tonic', name: 'Tonic Water', category: PantryCategory.mixers, unit: 'canettes / btl', emoji: '🫧'),
    const BarPantryItem(id: 'ginger_beer', name: 'Ginger Beer', category: PantryCategory.mixers, unit: 'canettes / btl', emoji: '🍺'),
    const BarPantryItem(id: 'ginger_ale', name: 'Ginger Ale', category: PantryCategory.mixers, unit: 'canettes / btl', emoji: '🥤'),
    const BarPantryItem(id: 'soda_water', name: 'Eau gazeuse / Soda', category: PantryCategory.mixers, unit: 'bouteilles', emoji: '💧'),
    const BarPantryItem(id: 'cola', name: 'Cola', category: PantryCategory.mixers, unit: 'canettes / btl', emoji: '🥤'),
    const BarPantryItem(id: 'cranberry_juice', name: 'Jus de canneberge (Cranberry)', category: PantryCategory.mixers, unit: 'bouteilles', emoji: '🧃'),
    const BarPantryItem(id: 'pineapple_juice', name: 'Jus d\'ananas', category: PantryCategory.mixers, unit: 'bouteilles', emoji: '🍍'),
    const BarPantryItem(id: 'orange_juice', name: 'Jus d\'orange', category: PantryCategory.mixers, unit: 'bouteilles', emoji: '🍊'),
    const BarPantryItem(id: 'tomato_juice', name: 'Jus de tomate', category: PantryCategory.mixers, unit: 'bouteilles', emoji: '🍅'),
    const BarPantryItem(id: 'grapefruit_soda', name: 'Soda pamplemousse rose', category: PantryCategory.mixers, unit: 'canettes', emoji: '🥤'),

    // 🍯 Sirops, Sucres & Bitters
    const BarPantryItem(id: 'sugar_syrup', name: 'Sirop de sucre simple', category: PantryCategory.syrups, unit: 'bouteilles', emoji: '🍯'),
    const BarPantryItem(id: 'agave_syrup', name: 'Sirop d\'agave', category: PantryCategory.syrups, unit: 'flacons', emoji: '🌵'),
    const BarPantryItem(id: 'syrup_grenadine', name: 'Sirop de grenadine', category: PantryCategory.syrups, unit: 'bouteilles', emoji: '🍒'),
    const BarPantryItem(id: 'syrup_orgeat', name: 'Sirop d\'orgeat (amande)', category: PantryCategory.syrups, unit: 'bouteilles', emoji: '🥛'),
    const BarPantryItem(id: 'syrup_raspberry', name: 'Sirop de framboise', category: PantryCategory.syrups, unit: 'bouteilles', emoji: '🍇'),
    const BarPantryItem(id: 'honey', name: 'Miel liquide', category: PantryCategory.syrups, unit: 'pots', emoji: '🍯'),
    const BarPantryItem(id: 'honey_ginger_syrup', name: 'Sirop miel-gingembre', category: PantryCategory.syrups, unit: 'pots', emoji: '🍯'),
    const BarPantryItem(id: 'angostura', name: 'Angostura Bitters', category: PantryCategory.syrups, unit: 'flacons', emoji: '🍶'),
    const BarPantryItem(id: 'salt', name: 'Sel marin / Fleur de sel', category: PantryCategory.syrups, unit: 'pincées', emoji: '🧂'),
    const BarPantryItem(id: 'tabasco', name: 'Sauce Tabasco', category: PantryCategory.syrups, unit: 'flacons', emoji: '🌶️'),
    const BarPantryItem(id: 'worcestershire', name: 'Sauce Worcestershire', category: PantryCategory.syrups, unit: 'flacons', emoji: '🥫'),
    const BarPantryItem(id: 'espresso', name: 'Café Espresso', category: PantryCategory.syrups, unit: 'tasses', emoji: '☕'),
    const BarPantryItem(id: 'cream', name: 'Crème liquide entière', category: PantryCategory.syrups, unit: 'briques', emoji: '🥛'),
    const BarPantryItem(id: 'coconut_cream', name: 'Crème / Lait de coco', category: PantryCategory.syrups, unit: 'briques', emoji: '🥥'),
    const BarPantryItem(id: 'egg_white', name: 'Blanc d\'œuf', category: PantryCategory.syrups, unit: 'œufs', emoji: '🥚'),

    // 🧊 Glace
    const BarPantryItem(id: 'ice_cubes', name: 'Glaçons entiers', category: PantryCategory.ice, unit: 'bacs / sacs', emoji: '🧊'),
    const BarPantryItem(id: 'crushed_ice', name: 'Glace pilée', category: PantryCategory.ice, unit: 'bacs / sacs', emoji: '❄️'),
  ];

  List<BarPantryItem> getItems() {
    final raw = _prefs.getString(_kBarPantryStorageKey);
    if (raw == null || raw.isEmpty) {
      return List<BarPantryItem>.from(defaultTemplate);
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      final savedItems = decoded.map((e) => BarPantryItem.fromJson(e as Map<String, dynamic>)).toList();
      
      // Merge saved quantities with default template in case new items were added
      final Map<String, BarPantryItem> savedMap = {for (final item in savedItems) item.id: item};
      final List<BarPantryItem> result = [];
      
      for (final t in defaultTemplate) {
        if (savedMap.containsKey(t.id)) {
          final saved = savedMap.remove(t.id)!;
          result.add(t.copyWith(quantity: saved.quantity));
        } else {
          result.add(t);
        }
      }
      // Add custom items
      result.addAll(savedMap.values.where((item) => item.isCustom));
      return result;
    } catch (e) {
      AppLogger.warning('BAR_PANTRY', 'Could not parse local pantry: $e');
      return List<BarPantryItem>.from(defaultTemplate);
    }
  }

  Future<void> saveItems(List<BarPantryItem> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_kBarPantryStorageKey, encoded);

    // Sync to Supabase in background if user is logged in
    final user = _supabase?.auth.currentUser;
    if (user != null && _supabase != null) {
      try {
        await _supabase
            .from('bar_pantry')
            .upsert({
              'user_id': user.id,
              'items': items.where((i) => i.quantity > 0 || i.isCustom).map((e) => e.toJson()).toList(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      } catch (e) {
        AppLogger.warning('BAR_PANTRY', 'Background cloud sync failed: $e');
      }
    }
  }

  Future<List<BarPantryItem>> updateQuantity(String id, int delta) async {
    HapticFeedback.lightImpact();
    final items = getItems();
    final index = items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final current = items[index];
      final newQty = (current.quantity + delta).clamp(0, 999);
      items[index] = current.copyWith(quantity: newQty);
      await saveItems(items);
    }
    return items;
  }

  Future<List<BarPantryItem>> setQuantity(String id, int quantity) async {
    final items = getItems();
    final index = items.indexWhere((e) => e.id == id);
    if (index != -1) {
      final current = items[index];
      items[index] = current.copyWith(quantity: quantity.clamp(0, 999));
      await saveItems(items);
    }
    return items;
  }

  Future<List<BarPantryItem>> resetAll() async {
    HapticFeedback.mediumImpact();
    final items = getItems();
    for (int i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(quantity: 0);
    }
    await saveItems(items);
    return items;
  }

  Future<List<BarPantryItem>> addCustomItem(String name, PantryCategory category, {String unit = 'unités', String emoji = '🍹'}) async {
    final items = getItems();
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = BarPantryItem(
      id: id,
      name: name.trim(),
      category: category,
      quantity: 1,
      unit: unit,
      emoji: emoji,
      isCustom: true,
    );
    items.add(newItem);
    await saveItems(items);
    return items;
  }

  Future<List<BarPantryItem>> removeCustomItem(String id) async {
    final items = getItems();
    items.removeWhere((e) => e.id == id && e.isCustom);
    await saveItems(items);
    return items;
  }
}

// Riverpod Provider
class BarPantryNotifier extends StateNotifier<List<BarPantryItem>> {
  final BarPantryService _service;

  BarPantryNotifier(this._service) : super(_service.getItems());

  Future<void> increment(String id) async {
    state = await _service.updateQuantity(id, 1);
  }

  Future<void> decrement(String id) async {
    state = await _service.updateQuantity(id, -1);
  }

  Future<void> setQuantity(String id, int qty) async {
    state = await _service.setQuantity(id, qty);
  }

  Future<void> resetAll() async {
    state = await _service.resetAll();
  }

  Future<void> addCustomItem(String name, PantryCategory category, {String unit = 'unités', String emoji = '🍹'}) async {
    state = await _service.addCustomItem(name, category, unit: unit, emoji: emoji);
  }

  Future<void> removeCustomItem(String id) async {
    state = await _service.removeCustomItem(id);
  }
}

final barPantryServiceProvider = Provider<BarPantryService>((ref) {
  final prefs = ref.watch(sharedPreferencesInstanceProvider);
  final supabase = ref.watch(supabaseProvider);
  return BarPantryService(prefs, supabase);
});

final barPantryProvider = StateNotifierProvider<BarPantryNotifier, List<BarPantryItem>>((ref) {
  final service = ref.watch(barPantryServiceProvider);
  return BarPantryNotifier(service);
});
