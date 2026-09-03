import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/features/cocktails/data/bar_pantry_service.dart';
import 'package:chatmelier/features/cocktails/domain/bar_pantry_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BarPantryService Tests', () {
    late BarPantryService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = BarPantryService(prefs);
    });

    test('Loads default template when storage is empty', () {
      final items = service.getItems();
      expect(items, isNotEmpty);
      expect(items.any((i) => i.id == 'lime'), isTrue);
      expect(items.any((i) => i.id == 'mint'), isTrue);
      expect(items.any((i) => i.id == 'tonic'), isTrue);
      expect(items.every((i) => i.quantity == 0), isTrue);
    });

    test('updateQuantity increments and decrements correctly with clamping at zero', () async {
      await service.updateQuantity('lime', 1);
      var items = service.getItems();
      var lime = items.firstWhere((i) => i.id == 'lime');
      expect(lime.quantity, 1);
      expect(lime.inStock, isTrue);

      await service.updateQuantity('lime', 2);
      items = service.getItems();
      lime = items.firstWhere((i) => i.id == 'lime');
      expect(lime.quantity, 3);

      await service.updateQuantity('lime', -1);
      items = service.getItems();
      lime = items.firstWhere((i) => i.id == 'lime');
      expect(lime.quantity, 2);

      // Decrement below zero should clamp at zero
      await service.updateQuantity('lime', -10);
      items = service.getItems();
      lime = items.firstWhere((i) => i.id == 'lime');
      expect(lime.quantity, 0);
      expect(lime.inStock, isFalse);
    });

    test('resetAll resets all items to zero', () async {
      await service.updateQuantity('lime', 5);
      await service.updateQuantity('mint', 3);
      await service.updateQuantity('tonic', 6);

      var items = service.getItems();
      expect(items.where((i) => i.inStock).length, 3);

      await service.resetAll();

      items = service.getItems();
      expect(items.every((i) => i.quantity == 0), isTrue);
    });

    test('addCustomItem and removeCustomItem handle user custom ingredients', () async {
      final updated = await service.addCustomItem(
        'Sirop d\'hibiscus maison',
        PantryCategory.syrups,
        unit: 'bouteilles',
        emoji: '🌺',
      );

      expect(updated.any((i) => i.name == 'Sirop d\'hibiscus maison' && i.isCustom), isTrue);

      final customItem = updated.firstWhere((i) => i.name == 'Sirop d\'hibiscus maison');
      expect(customItem.quantity, 1);
      expect(customItem.inStock, isTrue);

      final afterRemoval = await service.removeCustomItem(customItem.id);
      expect(afterRemoval.any((i) => i.id == customItem.id), isFalse);
    });
  });
}
