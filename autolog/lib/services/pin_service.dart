import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the optional 4-digit app lock PIN.
///
/// The PIN is stored as a SHA-256 hash in [SharedPreferences] — the plaintext
/// PIN is never written to disk or exposed in logs.
class PinService {
  PinService(this._prefs);

  final SharedPreferences _prefs;

  static const String _kPinHash = 'pin_hash';
  static const String _kPinEnabled = 'pin_enabled';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns true if the PIN lock is currently enabled.
  bool isPinEnabled() => _prefs.getBool(_kPinEnabled) ?? false;

  /// Enables the PIN lock and stores the SHA-256 hash of [pin].
  ///
  /// [pin] must be a 4-digit string. The plaintext value is never persisted.
  Future<void> setPin(String pin) async {
    assert(pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin),
        'PIN must be exactly 4 digits');
    final hash = _hash(pin);
    await _prefs.setString(_kPinHash, hash);
    await _prefs.setBool(_kPinEnabled, true);
  }

  /// Returns true if [input] matches the stored PIN hash.
  ///
  /// Returns false if no PIN is set.
  bool verifyPin(String input) {
    if (!isPinEnabled()) return false;
    final stored = _prefs.getString(_kPinHash);
    if (stored == null) return false;
    return _hash(input) == stored;
  }

  /// Disables the PIN lock and removes the stored hash.
  Future<void> clearPin() async {
    await _prefs.remove(_kPinHash);
    await _prefs.setBool(_kPinEnabled, false);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Returns the SHA-256 hex digest of [pin].
  static String _hash(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
