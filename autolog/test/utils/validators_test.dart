// Feature: autolog-vehicle-manager
// Property 4: Whitespace-only inputs are rejected
//
// For any string composed entirely of whitespace characters (spaces, tabs,
// newlines), every field validator returns invalid (non-null error message).
//
// Validates: Requirements 5.2, 7.1, 8.1, 9.1

import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';

import 'package:autolog/utils/validators.dart';

// Generates strings composed entirely of whitespace characters.
Arbitrary<String> get _whitespaceString => integer(min: 1, max: 30).map(
      (len) => List.generate(len, (i) {
        const chars = [' ', '\t', '\n', '\r', ' ', ' '];
        return chars[i % chars.length];
      }).join(),
    );

void main() {
  group('Validators — Property 4: whitespace-only inputs are rejected', () {
    // ── Property-based tests ────────────────────────────────────────────────

    test('nickname rejects whitespace-only strings', () async {
      property(
        forAll(_whitespaceString),
        (ws) {
          expect(Validators.nickname(ws), isNotNull,
              reason: 'Whitespace-only nickname "$ws" must be rejected');
        },
      );
    });

    test('numberPlate rejects whitespace-only strings', () async {
      property(
        forAll(_whitespaceString),
        (ws) {
          expect(Validators.numberPlate(ws), isNotNull,
              reason: 'Whitespace-only number plate "$ws" must be rejected');
        },
      );
    });

    test('odometer rejects whitespace-only strings', () async {
      property(
        forAll(_whitespaceString),
        (ws) {
          expect(Validators.odometer(ws), isNotNull,
              reason: 'Whitespace-only odometer "$ws" must be rejected');
        },
      );
    });

    test('quantity rejects whitespace-only strings', () async {
      property(
        forAll(_whitespaceString),
        (ws) {
          expect(Validators.quantity(ws), isNotNull,
              reason: 'Whitespace-only quantity "$ws" must be rejected');
        },
      );
    });

    test('price rejects whitespace-only strings', () async {
      property(
        forAll(_whitespaceString),
        (ws) {
          expect(Validators.price(ws), isNotNull,
              reason: 'Whitespace-only price "$ws" must be rejected');
        },
      );
    });

    test('cost rejects whitespace-only strings', () async {
      property(
        forAll(_whitespaceString),
        (ws) {
          expect(Validators.cost(ws), isNotNull,
              reason: 'Whitespace-only cost "$ws" must be rejected');
        },
      );
    });

    test('serviceType rejects whitespace-only strings', () async {
      property(
        forAll(_whitespaceString),
        (ws) {
          expect(Validators.serviceType(ws), isNotNull,
              reason: 'Whitespace-only service type "$ws" must be rejected');
        },
      );
    });

    test('expenseCategory rejects whitespace-only strings', () async {
      property(
        forAll(_whitespaceString),
        (ws) {
          expect(Validators.expenseCategory(ws), isNotNull,
              reason: 'Whitespace-only category "$ws" must be rejected');
        },
      );
    });

    // ── Null rejection ──────────────────────────────────────────────────────

    test('all validators reject null', () {
      expect(Validators.nickname(null), isNotNull);
      expect(Validators.numberPlate(null), isNotNull);
      expect(Validators.odometer(null), isNotNull);
      expect(Validators.quantity(null), isNotNull);
      expect(Validators.price(null), isNotNull);
      expect(Validators.cost(null), isNotNull);
      expect(Validators.serviceType(null), isNotNull);
      expect(Validators.expenseCategory(null), isNotNull);
      expect(Validators.documentType(null), isNotNull);
      expect(Validators.pin(null), isNotNull);
    });

    // ── Valid input acceptance ──────────────────────────────────────────────

    test('nickname accepts valid non-blank string', () {
      expect(Validators.nickname('My Car'), isNull);
    });

    test('numberPlate accepts valid plate', () {
      expect(Validators.numberPlate('MH12AB1234'), isNull);
    });

    test('odometer accepts valid number', () {
      expect(Validators.odometer('12500'), isNull);
      expect(Validators.odometer('0'), isNull);
    });

    test('quantity accepts positive number', () {
      expect(Validators.quantity('40.5'), isNull);
    });

    test('quantity rejects zero', () {
      expect(Validators.quantity('0'), isNotNull);
    });

    test('price accepts zero', () {
      expect(Validators.price('0'), isNull);
    });

    test('odometer rejects negative', () {
      expect(Validators.odometer('-100'), isNotNull);
    });

    test('pin accepts exactly 4 digits', () {
      expect(Validators.pin('1234'), isNull);
    });

    test('pin rejects 3 digits', () {
      expect(Validators.pin('123'), isNotNull);
    });

    test('pin rejects 5 digits', () {
      expect(Validators.pin('12345'), isNotNull);
    });

    test('pin rejects non-digit characters', () {
      expect(Validators.pin('12ab'), isNotNull);
    });

    test('confirmPin accepts matching PINs', () {
      expect(Validators.confirmPin('1234', '1234'), isNull);
    });

    test('confirmPin rejects non-matching PINs', () {
      expect(Validators.confirmPin('1234', '5678'), isNotNull);
    });

    test('date accepts non-null DateTime', () {
      expect(Validators.date(DateTime.now()), isNull);
    });

    test('date rejects null', () {
      expect(Validators.date(null), isNotNull);
    });
  });
}
