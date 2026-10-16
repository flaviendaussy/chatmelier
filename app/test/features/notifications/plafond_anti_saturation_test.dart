import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatmelier/features/notifications/data/notification_preferences_service.dart';
import 'package:chatmelier/features/notifications/domain/notification_anti_spam_policy.dart';
import 'package:chatmelier/features/notifications/presentation/notification_settings_sheet.dart';

/// 11/10 : « fais en sorte que le plafond anti saturation ne soit qu'une option (pré
/// sélectionnée sur true) ». Ce n'était qu'un texte, sans réglage ni effet.
void main() {
  test('le plafond est coché d\'office, et se garde décoché', () async {
    SharedPreferences.setMockInitialValues({});
    final service = NotificationPreferencesService(await SharedPreferences.getInstance());
    expect(service.loadPreferences().plafondAntiSaturation, isTrue);
    await service.savePreferences(service.loadPreferences().copyWith(plafondAntiSaturation: false));
    expect(service.loadPreferences().plafondAntiSaturation, isFalse);
  });

  test('coché : une alerte de Chatmelier par jour ; décoché : aucune limite', () {
    final maintenant = DateTime(2026, 10, 16, 18);
    final hier = maintenant.subtract(const Duration(hours: 20));
    expect(NotificationAntiSpamPolicy.canSendProactiveAlert(now: maintenant, lastAlertSentAt: hier, alertsSentToday: 0), isTrue);
    expect(NotificationAntiSpamPolicy.canSendProactiveAlert(now: maintenant, lastAlertSentAt: hier, alertsSentToday: 1), isFalse);
    expect(
      NotificationAntiSpamPolicy.canSendProactiveAlert(
          now: maintenant, lastAlertSentAt: maintenant, alertsSentToday: 5, plafond: false),
      isTrue,
    );
  });

  testWidgets('les réglages le montrent comme un interrupteur, coché', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: Scaffold(body: NotificationSettingsSheet())),
    ));
    await tester.pumpAndSettle();
    final ligne = find.ancestor(of: find.text('Plafond anti-saturation'), matching: find.byType(Row)).first;
    final interrupteur = find.descendant(of: ligne, matching: find.byType(Switch));
    expect(interrupteur, findsOneWidget);
    expect(tester.widget<Switch>(interrupteur).value, isTrue);
    await tester.tap(interrupteur);
    await tester.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getBool(NotificationPreferencesService.keyPlafond), isFalse);
  });
}
