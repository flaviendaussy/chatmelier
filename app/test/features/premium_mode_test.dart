import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmelier/shared/providers/premium_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PremiumNotifier Tests', () {
    test('Defaults to false initially', () {
      final notifier = PremiumNotifier();
      expect(notifier.state, isFalse);
    });

    test('Loads persisted true value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'chatmelier_is_premium_mode': true});
      final notifier = PremiumNotifier();
      // Wait for async _loadFromPrefs to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.state, isTrue);
    });

    test('Can toggle premium state and persists it', () async {
      final notifier = PremiumNotifier();
      expect(notifier.state, isFalse);

      await notifier.togglePremium();
      expect(notifier.state, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('chatmelier_is_premium_mode'), isTrue);

      await notifier.togglePremium();
      expect(notifier.state, isFalse);
      expect(prefs.getBool('chatmelier_is_premium_mode'), isFalse);
    });

    test('setPremium directly updates and persists state', () async {
      final notifier = PremiumNotifier();
      await notifier.setPremium(true);
      expect(notifier.state, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('chatmelier_is_premium_mode'), isTrue);

      await notifier.setPremium(false);
      expect(notifier.state, isFalse);
      expect(prefs.getBool('chatmelier_is_premium_mode'), isFalse);
    });
  });
}
