import 'package:dup/src/util/validator_base.dart';

/// Validator for numeric values.
class ValidateNumber extends BaseValidator<num, ValidateNumber> {
  /// Checks if the value is greater than or equal to [min].
  ValidateNumber min(num min, [String? message]) {
    addValidator((value) {
      if (value != null && value < min) {
        return message ?? '$label must be at least $min.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the value is less than or equal to [max].
  ValidateNumber max(num max, [String? message]) {
    addValidator((value) {
      if (value != null && value > max) {
        return message ?? '$label must be at most $max.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the value is an integer.
  ValidateNumber isInteger([String? message]) {
    addValidator((value) {
      if (value != null && value % 1 != 0) {
        return message ?? '$label must be an integer.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the value is a valid landline phone number.
  ValidateNumber phone([String? message]) {
    const landlineRegex = r'^(0[2-9]{1}\d?)-\d{3,4}-\d{4}$';
    addValidator((value) {
      if (value == null || value.toString().isEmpty) {
        return message ?? 'Please enter a phone number.';
      }
      if (!RegExp(landlineRegex).hasMatch(value.toString())) {
        return message ?? 'Invalid phone number format.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the value is a valid business registration number.
  ValidateNumber bizno([String? message]) {
    const brnRegex = r'^\d{3}-\d{2}-\d{5}$';
    addValidator((value) {
      if (value == null || value.toString().isEmpty) {
        return message ?? 'Please enter a business registration number.';
      }
      if (!RegExp(brnRegex).hasMatch(value.toString())) {
        return message ?? 'Invalid business registration number format.';
      }
      return null;
    });
    return this;
  }
}
