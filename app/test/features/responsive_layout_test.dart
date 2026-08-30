import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatmelier/shared/utils/responsive_layout.dart';

void main() {
  group('Responsive Layout Breakpoints Tests', () {
    testWidgets('Detects Mobile for width < 700', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(Responsive.isMobile(context), isTrue);
              expect(Responsive.isTablet(context), isFalse);
              expect(Responsive.isDesktop(context), isFalse);
              expect(Responsive.formFactor(context), FormFactor.mobile);
              return const Scaffold(body: Text('Mobile View'));
            },
          ),
        ),
      );
    });

    testWidgets('Detects Tablet for 700 <= width < 1100', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(Responsive.isMobile(context), isFalse);
              expect(Responsive.isTablet(context), isTrue);
              expect(Responsive.isDesktop(context), isFalse);
              expect(Responsive.formFactor(context), FormFactor.tablet);
              return const Scaffold(body: Text('Tablet View'));
            },
          ),
        ),
      );
    });

    testWidgets('Detects Desktop for width >= 1100', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(Responsive.isMobile(context), isFalse);
              expect(Responsive.isTablet(context), isFalse);
              expect(Responsive.isDesktop(context), isTrue);
              expect(Responsive.formFactor(context), FormFactor.desktop);
              return const Scaffold(body: Text('Desktop View'));
            },
          ),
        ),
      );
    });

    testWidgets('ResponsiveLayout displays correct widget depending on screen size', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Widget buildTestable() {
        return const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Rendered Mobile'),
            tablet: Text('Rendered Tablet'),
            desktop: Text('Rendered Desktop'),
          ),
        );
      }

      // Mobile
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpWidget(buildTestable());
      expect(find.text('Rendered Mobile'), findsOneWidget);
      expect(find.text('Rendered Tablet'), findsNothing);
      expect(find.text('Rendered Desktop'), findsNothing);

      // Tablet
      tester.view.physicalSize = const Size(900, 1000);
      await tester.pumpWidget(buildTestable());
      expect(find.text('Rendered Mobile'), findsNothing);
      expect(find.text('Rendered Tablet'), findsOneWidget);
      expect(find.text('Rendered Desktop'), findsNothing);

      // Desktop
      tester.view.physicalSize = const Size(1400, 900);
      await tester.pumpWidget(buildTestable());
      expect(find.text('Rendered Mobile'), findsNothing);
      expect(find.text('Rendered Tablet'), findsNothing);
      expect(find.text('Rendered Desktop'), findsOneWidget);
    });
  });
}
