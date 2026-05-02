import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autolog/services/pin_service.dart';

void main() {
  late PinService pinService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    pinService = PinService(prefs);
  });

  group('PinService', () {
    test('isPinEnabled returns false by default', () {
      expect(pinService.isPinEnabled(), isFalse);
    });

    test('setPin enables the PIN lock', () async {
      await pinService.setPin('1234');
      expect(pinService.isPinEnabled(), isTrue);
    });

    test('verifyPin returns true for the correct PIN', () async {
      await pinService.setPin('5678');
      expect(pinService.verifyPin('5678'), isTrue);
    });

    test('verifyPin returns false for an incorrect PIN', () async {
      await pinService.setPin('1234');
      expect(pinService.verifyPin('9999'), isFalse);
    });

    test('verifyPin returns false when no PIN is set', () {
      expect(pinService.verifyPin('1234'), isFalse);
    });

    test('clearPin disables the PIN lock', () async {
      await pinService.setPin('1234');
      await pinService.clearPin();
      expect(pinService.isPinEnabled(), isFalse);
    });

    test('verifyPin returns false after clearPin', () async {
      await pinService.setPin('1234');
      await pinService.clearPin();
      expect(pinService.verifyPin('1234'), isFalse);
    });

    test('plaintext PIN is not stored in SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await pinService.setPin('4321');
      // Verify the stored value is not the plaintext PIN
      final storedHash = prefs.getString('pin_hash');
      expect(storedHash, isNotNull);
      expect(storedHash, isNot(equals('4321')),
          reason: 'Plaintext PIN must never be stored');
      // Verify it looks like a SHA-256 hex digest (64 hex chars)
      expect(storedHash!.length, equals(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(storedHash), isTrue,
          reason: 'Stored value must be a SHA-256 hex digest');
    });

    test('same PIN always produces the same hash (deterministic)', () async {
      await pinService.setPin('1111');
      final prefs = await SharedPreferences.getInstance();
      final hash1 = prefs.getString('pin_hash');

      await pinService.clearPin();
      await pinService.setPin('1111');
      final hash2 = prefs.getString('pin_hash');

      expect(hash1, equals(hash2));
    });

    test('different PINs produce different hashes', () async {
      await pinService.setPin('1234');
      final prefs = await SharedPreferences.getInstance();
      final hash1 = prefs.getString('pin_hash');

      await pinService.clearPin();
      await pinService.setPin('5678');
      final hash2 = prefs.getString('pin_hash');

      expect(hash1, isNot(equals(hash2)));
    });

    test('setPin overwrites a previously set PIN', () async {
      await pinService.setPin('1234');
      await pinService.setPin('9876');
      expect(pinService.verifyPin('1234'), isFalse);
      expect(pinService.verifyPin('9876'), isTrue);
    });
  });
}
