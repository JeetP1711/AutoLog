/// Field validators for all required form inputs in AutoLog.
///
/// Each validator follows the Flutter [FormField] convention: returns `null`
/// when the value is valid, or a non-null error message string when invalid.
///
/// All validators reject whitespace-only strings (Property 4).
abstract final class Validators {
  // ── Generic helpers ────────────────────────────────────────────────────────

  /// Returns true if [value] is null or composed entirely of whitespace.
  static bool _isBlank(String? value) =>
      value == null || value.trim().isEmpty;

  // ── Vehicle fields ─────────────────────────────────────────────────────────

  /// Validates a vehicle nickname (required, 1–50 chars).
  static String? nickname(String? value) {
    if (_isBlank(value)) return 'Nickname is required';
    if (value!.trim().length > 50) return 'Nickname must be 50 characters or fewer';
    return null;
  }

  /// Validates a vehicle number plate (required, 1–20 chars).
  static String? numberPlate(String? value) {
    if (_isBlank(value)) return 'Number plate is required';
    if (value!.trim().length > 20) return 'Number plate must be 20 characters or fewer';
    return null;
  }

  /// Validates a brand selection (required).
  static String? brand(String? value) {
    if (_isBlank(value)) return 'Brand is required';
    return null;
  }

  /// Validates a model selection (required).
  static String? model(String? value) {
    if (_isBlank(value)) return 'Model is required';
    return null;
  }

  // ── Numeric fields ─────────────────────────────────────────────────────────

  /// Validates an odometer reading (required, non-negative number).
  static String? odometer(String? value) {
    if (_isBlank(value)) return 'Odometer reading is required';
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return 'Odometer cannot be negative';
    return null;
  }

  /// Validates a fuel quantity (required, strictly positive).
  static String? quantity(String? value) {
    if (_isBlank(value)) return 'Quantity is required';
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return 'Quantity must be greater than zero';
    return null;
  }

  /// Validates a price / cost / amount (required, non-negative).
  static String? price(String? value) {
    if (_isBlank(value)) return 'Amount is required';
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid amount';
    if (parsed < 0) return 'Amount cannot be negative';
    return null;
  }

  /// Validates a cost field (alias for [price] with a different label).
  static String? cost(String? value) {
    if (_isBlank(value)) return 'Cost is required';
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid cost';
    if (parsed < 0) return 'Cost cannot be negative';
    return null;
  }

  // ── Date fields ────────────────────────────────────────────────────────────

  /// Validates that a date has been selected (non-null).
  static String? date(DateTime? value) {
    if (value == null) return 'Date is required';
    return null;
  }

  /// Validates that an expiry date has been selected and is in the future.
  static String? expiryDate(DateTime? value) {
    if (value == null) return 'Expiry date is required';
    if (value.isBefore(DateTime.now())) return 'Expiry date must be in the future';
    return null;
  }

  // ── Text fields ────────────────────────────────────────────────────────────

  /// Validates a required text field (non-blank, max 200 chars).
  static String? requiredText(String? value, {String label = 'This field'}) {
    if (_isBlank(value)) return '$label is required';
    if (value!.trim().length > 200) return '$label must be 200 characters or fewer';
    return null;
  }

  /// Validates a service type selection (required).
  static String? serviceType(String? value) {
    if (_isBlank(value)) return 'Service type is required';
    return null;
  }

  /// Validates an expense category selection (required).
  static String? expenseCategory(String? value) {
    if (_isBlank(value)) return 'Category is required';
    return null;
  }

  /// Validates a document type selection (required).
  static String? documentType(String? value) {
    if (_isBlank(value)) return 'Document type is required';
    return null;
  }

  // ── PIN ────────────────────────────────────────────────────────────────────

  /// Validates a 4-digit PIN (required, exactly 4 digits).
  static String? pin(String? value) {
    if (_isBlank(value)) return 'PIN is required';
    final trimmed = value!.trim();
    if (trimmed.length != 4) return 'PIN must be exactly 4 digits';
    if (!RegExp(r'^\d{4}$').hasMatch(trimmed)) return 'PIN must contain only digits';
    return null;
  }

  /// Validates that a confirmation PIN matches the original.
  static String? confirmPin(String? value, String original) {
    final baseError = pin(value);
    if (baseError != null) return baseError;
    if (value!.trim() != original.trim()) return 'PINs do not match';
    return null;
  }
}
