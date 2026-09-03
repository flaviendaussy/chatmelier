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
    // 🧊 1. Glace & Glaçons (INDISPENSABLE EN HAUT)
    const BarPantryItem(id: 'ice_cubes', name: 'Glaçons classiques', category: PantryCategory.ice, unit: 'bacs / sacs', emoji: '🧊'),
    const BarPantryItem(id: 'clear_ice', name: 'Gros glaçon transparent (Clear Ice)', category: PantryCategory.ice, unit: 'cubes XXL', emoji: '🧊'),
    const BarPantryItem(id: 'ice_sphere', name: 'Sphère de glace', category: PantryCategory.ice, unit: 'sphères', emoji: '⚪'),
    const BarPantryItem(id: 'crushed_ice', name: 'Glace pilée (Crushed Ice)', category: PantryCategory.ice, unit: 'bacs / sacs', emoji: '❄️'),

    // 🍋 2. Fruits & Agrumes
    const BarPantryItem(id: 'lime', name: 'Citron vert (Lime)', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍋‍🟩'),
    const BarPantryItem(id: 'lemon', name: 'Citron jaune', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍋'),
    const BarPantryItem(id: 'orange', name: 'Orange à jus & zestes', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍊'),
    const BarPantryItem(id: 'grapefruit', name: 'Pamplemousse rose', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍈'),
    const BarPantryItem(id: 'yuzu', name: 'Yuzu / Jus de yuzu', category: PantryCategory.fruits, unit: 'pièces / flacons', emoji: '🍋'),
    const BarPantryItem(id: 'clementine', name: 'Clémentine / Mandarine', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍊'),
    const BarPantryItem(id: 'bergamot', name: 'Bergamote', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍋'),
    const BarPantryItem(id: 'cucumber', name: 'Concombre frais', category: PantryCategory.fruits, unit: 'pièces', emoji: '🥒'),
    const BarPantryItem(id: 'strawberries', name: 'Fraises fraîches', category: PantryCategory.fruits, unit: 'barquettes', emoji: '🍓'),
    const BarPantryItem(id: 'raspberries', name: 'Framboises fraîches', category: PantryCategory.fruits, unit: 'barquettes', emoji: '🫐'),
    const BarPantryItem(id: 'blackberries', name: 'Mûres sauvages', category: PantryCategory.fruits, unit: 'barquettes', emoji: '🫐'),
    const BarPantryItem(id: 'blueberries', name: 'Myrtilles', category: PantryCategory.fruits, unit: 'barquettes', emoji: '🫐'),
    const BarPantryItem(id: 'pineapple', name: 'Ananas frais', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍍'),
    const BarPantryItem(id: 'passion_fruit', name: 'Fruit de la passion (Maracuja)', category: PantryCategory.fruits, unit: 'pièces', emoji: '🟣'),
    const BarPantryItem(id: 'pomegranate', name: 'Grenade fraîche (Arilles)', category: PantryCategory.fruits, unit: 'pièces', emoji: '🔴'),
    const BarPantryItem(id: 'apple', name: 'Pomme verte Granny', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍏'),
    const BarPantryItem(id: 'cherries_fresh', name: 'Cerises fraîches', category: PantryCategory.fruits, unit: 'barquettes', emoji: '🍒'),
    const BarPantryItem(id: 'peach', name: 'Pêche blanche', category: PantryCategory.fruits, unit: 'pièces', emoji: '🍑'),

    // 🌿 3. Herbes & Épices
    const BarPantryItem(id: 'mint', name: 'Menthe fraîche', category: PantryCategory.herbs, unit: 'bottes', emoji: '🌿'),
    const BarPantryItem(id: 'basil', name: 'Basilic frais', category: PantryCategory.herbs, unit: 'bottes', emoji: '🌱'),
    const BarPantryItem(id: 'rosemary', name: 'Romarin frais', category: PantryCategory.herbs, unit: 'branches', emoji: '🌲'),
    const BarPantryItem(id: 'thyme', name: 'Thym frais', category: PantryCategory.herbs, unit: 'branches', emoji: '🌾'),
    const BarPantryItem(id: 'sage', name: 'Sauge fraîche', category: PantryCategory.herbs, unit: 'feuilles', emoji: '🍃'),
    const BarPantryItem(id: 'ginger', name: 'Gingembre frais', category: PantryCategory.herbs, unit: 'racines', emoji: '🫚'),
    const BarPantryItem(id: 'cinnamon', name: 'Cannelle en bâtons', category: PantryCategory.herbs, unit: 'bâtons', emoji: '🪵'),
    const BarPantryItem(id: 'nutmeg', name: 'Noix de muscade', category: PantryCategory.herbs, unit: 'noix', emoji: '🌰'),
    const BarPantryItem(id: 'star_anise', name: 'Badiane (Anis étoilé)', category: PantryCategory.herbs, unit: 'étoiles', emoji: '⭐'),
    const BarPantryItem(id: 'cloves', name: 'Clous de girofle', category: PantryCategory.herbs, unit: 'clous', emoji: '🌱'),
    const BarPantryItem(id: 'chili_espelette', name: 'Piment d\'Espelette', category: PantryCategory.herbs, unit: 'flacons', emoji: '🌶️'),
    const BarPantryItem(id: 'black_pepper', name: 'Poivre noir de Tellicherry', category: PantryCategory.herbs, unit: 'moulins', emoji: '🧂'),
    const BarPantryItem(id: 'cardamom', name: 'Cardamome verte', category: PantryCategory.herbs, unit: 'gousses', emoji: '🌿'),

    // 🥤 4. Soft Drinks, Mixers & Eaux
    const BarPantryItem(id: 'tonic', name: 'Tonic Water classique', category: PantryCategory.mixers, unit: 'bouteilles / canettes', emoji: '🫧'),
    const BarPantryItem(id: 'mediterranean_tonic', name: 'Tonic Water Méditerranéen', category: PantryCategory.mixers, unit: 'bouteilles / canettes', emoji: '🌿'),
    const BarPantryItem(id: 'ginger_beer', name: 'Ginger Beer épicée', category: PantryCategory.mixers, unit: 'bouteilles / canettes', emoji: '🍺'),
    const BarPantryItem(id: 'ginger_ale', name: 'Ginger Ale doux', category: PantryCategory.mixers, unit: 'bouteilles / canettes', emoji: '🥤'),
    const BarPantryItem(id: 'soda_water', name: 'Eau gazeuse / Club Soda', category: PantryCategory.mixers, unit: 'bouteilles', emoji: '💧'),
    const BarPantryItem(id: 'cola', name: 'Cola artisanal', category: PantryCategory.mixers, unit: 'bouteilles / canettes', emoji: '🥤'),
    const BarPantryItem(id: 'lemonade', name: 'Limonade artisanale', category: PantryCategory.mixers, unit: 'bouteilles', emoji: '🍋'),
    const BarPantryItem(id: 'cranberry_juice', name: 'Jus de canneberge (Cranberry)', category: PantryCategory.mixers, unit: 'bouteilles', emoji: '🧃'),
    const BarPantryItem(id: 'pineapple_juice', name: 'Jus d\'ananas 100%', category: PantryCategory.mixers, unit: 'bouteilles', emoji: '🍍'),
    const BarPantryItem(id: 'orange_juice', name: 'Jus d\'orange pur jus', category: PantryCategory.mixers, unit: 'bouteilles', emoji: '🍊'),
    const BarPantryItem(id: 'grapefruit_juice', name: 'Jus de pamplemousse rose', category: PantryCategory.mixers, unit: 'bouteilles', emoji: '🍈'),
    const BarPantryItem(id: 'apple_juice', name: 'Jus de pomme fermier', category: PantryCategory.mixers, unit: 'bouteilles', emoji: '🍏'),
    const BarPantryItem(id: 'tomato_juice', name: 'Jus de tomate', category: PantryCategory.mixers, unit: 'bouteilles', emoji: '🍅'),
    const BarPantryItem(id: 'coconut_water', name: 'Eau de coco', category: PantryCategory.mixers, unit: 'briques', emoji: '🥥'),
    const BarPantryItem(id: 'grapefruit_soda', name: 'Soda pamplemousse rose (Paloma)', category: PantryCategory.mixers, unit: 'canettes', emoji: '🥤'),

    // 🍯 5. Sirops, Sucres, Bitters & Condiments
    const BarPantryItem(id: 'sugar_syrup', name: 'Sirop de sucre simple (1:1)', category: PantryCategory.syrups, unit: 'bouteilles', emoji: '🍯'),
    const BarPantryItem(id: 'rich_demerara_syrup', name: 'Sirop riche de Demerara (2:1)', category: PantryCategory.syrups, unit: 'bouteilles', emoji: '🍯'),
    const BarPantryItem(id: 'agave_syrup', name: 'Sirop d\'agave bio', category: PantryCategory.syrups, unit: 'flacons', emoji: '🌵'),
    const BarPantryItem(id: 'honey', name: 'Miel liquide d\'acacia', category: PantryCategory.syrups, unit: 'pots', emoji: '🍯'),
    const BarPantryItem(id: 'maple_syrup', name: 'Sirop d\'érable pur', category: PantryCategory.syrups, unit: 'bouteilles', emoji: '🍁'),
    const BarPantryItem(id: 'syrup_grenadine', name: 'Sirop de grenadine artisanale', category: PantryCategory.syrups, unit: 'bouteilles', emoji: '🍒'),
    const BarPantryItem(id: 'syrup_orgeat', name: 'Sirop d\'orgeat (amande)', category: PantryCategory.syrups, unit: 'bouteilles', emoji: '🥛'),
    const BarPantryItem(id: 'syrup_vanilla', name: 'Sirop de vanille Bourbon', category: PantryCategory.syrups, unit: 'bouteilles', emoji: '🍦'),
    const BarPantryItem(id: 'honey_ginger_syrup', name: 'Sirop miel-gingembre (Penicillin)', category: PantryCategory.syrups, unit: 'pots', emoji: '🍯'),
    const BarPantryItem(id: 'syrup_passion', name: 'Sirop de fruit de la passion', category: PantryCategory.syrups, unit: 'bouteilles', emoji: '🟣'),
    const BarPantryItem(id: 'syrup_raspberry', name: 'Sirop de framboise', category: PantryCategory.syrups, unit: 'bouteilles', emoji: '🍇'),
    const BarPantryItem(id: 'sugar_cube', name: 'Morceau de sucre blanc', category: PantryCategory.syrups, unit: 'morceaux', emoji: '🧊'),
    const BarPantryItem(id: 'brown_sugar', name: 'Cassonade / Sucre roux', category: PantryCategory.syrups, unit: 'sachets', emoji: '🌾'),
    const BarPantryItem(id: 'angostura', name: 'Angostura Aromatic Bitters', category: PantryCategory.syrups, unit: 'flacons', emoji: '🍶'),
    const BarPantryItem(id: 'orange_bitters', name: 'Orange Bitters', category: PantryCategory.syrups, unit: 'flacons', emoji: '🍊'),
    const BarPantryItem(id: 'peychauds', name: 'Peychaud\'s Bitters', category: PantryCategory.syrups, unit: 'flacons', emoji: '🌸'),
    const BarPantryItem(id: 'chocolate_bitters', name: 'Chocolate / Cocoa Bitters', category: PantryCategory.syrups, unit: 'flacons', emoji: '🍫'),
    const BarPantryItem(id: 'celery_bitters', name: 'Celery Bitters', category: PantryCategory.syrups, unit: 'flacons', emoji: '🥬'),
    const BarPantryItem(id: 'salt', name: 'Fleur de sel de Guérande', category: PantryCategory.syrups, unit: 'pincées', emoji: '🧂'),
    const BarPantryItem(id: 'celery_salt', name: 'Sel de céleri', category: PantryCategory.syrups, unit: 'flacons', emoji: '🧂'),
    const BarPantryItem(id: 'tabasco', name: 'Sauce Tabasco rouge', category: PantryCategory.syrups, unit: 'flacons', emoji: '🌶️'),
    const BarPantryItem(id: 'worcestershire', name: 'Sauce Worcestershire (Lea & Perrins)', category: PantryCategory.syrups, unit: 'flacons', emoji: '🥫'),
    const BarPantryItem(id: 'espresso', name: 'Café Espresso frais', category: PantryCategory.syrups, unit: 'tasses', emoji: '☕'),
    const BarPantryItem(id: 'cream', name: 'Crème liquide entière (30%)', category: PantryCategory.syrups, unit: 'briques', emoji: '🥛'),
    const BarPantryItem(id: 'coconut_cream', name: 'Crème / Lait de coco', category: PantryCategory.syrups, unit: 'briques', emoji: '🥥'),
    const BarPantryItem(id: 'egg_white', name: 'Blanc d\'œuf frais / Aquafaba', category: PantryCategory.syrups, unit: 'œufs', emoji: '🥚'),
    const BarPantryItem(id: 'amarena_cherries', name: 'Cerises amarena au sirop', category: PantryCategory.syrups, unit: 'bocaux', emoji: '🍒'),
    const BarPantryItem(id: 'green_olives', name: 'Olives vertes cocktail', category: PantryCategory.syrups, unit: 'bocaux', emoji: '🫒'),
    const BarPantryItem(id: 'cocktail_onions', name: 'Oignons grelots cocktail', category: PantryCategory.syrups, unit: 'bocaux', emoji: '🧅'),
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
