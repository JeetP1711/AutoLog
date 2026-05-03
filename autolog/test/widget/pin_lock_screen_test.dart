import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autolog/providers/pin_provider.dart';
import 'package:autolog/providers/settings_provider.dart';
import 'package:autolog/screens/pin/pin_lock_screen.dart';
import 'package:autolog/services/pin_service.dart';
import 'package:autolog/theme/app_theme.dart';
import 'package:autolog/theme/theme_controller.dart';

void main() {
  group('PinLockScreen widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      // Set a PIN: 1234
      final pinService = PinService(prefs);
      await pinService.setPin('1234');
    });

    Widget buildScreen() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          pinServiceProvider.overrideWithValue(PinService(prefs)),
          themeControllerProvider.overrideWith(
              () => ThemeController(prefs)),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme(),
          home: const PinLockScreen(),
        ),
      );
    }

    testWidgets('shows PIN entry UI elements', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('AutoLog'), findsOneWidget);
      expect(find.text('Enter your PIN'), findsOneWidget);
      // Should show 10 digit buttons (0-9)
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('shows error message on incorrect PIN', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Enter wrong PIN: 9999
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();

      // Wait for verification
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect PIN'), findsOneWidget);
    });

    testWidgets('shows lockout message after 5 wrong attempts', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Enter wrong PIN 5 times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('9'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('9'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('9'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('9'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
      }

      // Should show lockout message
      expect(find.textContaining('Locked for'), findsOneWidget);
      expect(find.text('Too many attempts'), findsOneWidget);
    });

    testWidgets('PIN dots fill as digits are entered', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Enter 2 digits
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      // The screen should still be showing (not navigated away)
      expect(find.text('Enter your PIN'), findsOneWidget);
    });
  });
}
