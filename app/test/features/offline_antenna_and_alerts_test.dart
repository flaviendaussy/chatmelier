import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/features/offline/presentation/chatmelier_offline_antenna_widget.dart';

void main() {
  testWidgets('ChatmelierOfflineAntennaWidget renders properly with title and message', (tester) async {
    bool retryClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatmelierOfflineAntennaWidget(
            title: 'Recherche de réseau...',
            message: 'Chatmelier tend le goulot de sa bouteille façon antenne',
            onRetry: () {
              retryClicked = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Recherche de réseau...'), findsOneWidget);
    expect(find.text('Chatmelier tend le goulot de sa bouteille façon antenne'), findsOneWidget);
    expect(find.text('Tester la connexion'), findsOneWidget);

    // Tap retry button
    await tester.tap(find.text('Tester la connexion'));
    expect(retryClicked, isTrue);

    // Let animation advance smoothly
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1000));
  });
}
