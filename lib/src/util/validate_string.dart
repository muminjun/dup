import 'package:dup/src/util/validator_base.dart';

/// Validator for String values.
class ValidateString extends BaseValidator<String, ValidateString> {
  /// Checks if the string has at least [min] characters.
  ValidateString min(int min, [String? message]) {
    addValidator((value) {
      if (value != null && value.trim().length < min) {
        return message ?? '$label must be at least $min characters long.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the string has at most [max] characters.
  ValidateString max(int max, [String? message]) {
    addValidator((value) {
      if (value != null && value.trim().length > max) {
        return message ?? '$label must be at most $max characters long.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the string matches the given [regex].
  ValidateString matches(RegExp regex, [String? message]) {
    addValidator((value) {
      if (value != null && !regex.hasMatch(value.trim())) {
        return message ?? 'Invalid format.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the string is a valid email address.
  ValidateString email([String? message]) {
    const emailRegex =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    addValidator((value) {
      if (value == null || value.trim().isEmpty) {
        return message ?? 'Please enter an email address.';
      }
      if (!RegExp(emailRegex).hasMatch(value.trim())) {
        return message ?? 'Invalid email format.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the string is a valid password.
  ValidateString password([String? message]) {
    addValidator((value) {
      if (value == null || value.trim().isEmpty) {
        return message ?? 'Please enter a password.';
      }
      if (value.trim().length < 4) {
        return message ?? 'Password must be at least 4 characters long.';
      }
      if (!RegExp(r"^[\u0000-\u007F]+$").hasMatch(value.trim())) {
        return message ??
            'Password must contain only ASCII characters (letters, numbers, special characters).';
      }
      return null;
    });
    return this;
  }

  /// Checks if the string contains any emoji characters.
  ValidateString emoji([String? message]) {
    const emojiRegex = r'[\uD800-\uDBFF][\uDC00-\uDFFF]';
    addValidator((value) {
      if (value != null &&
          value.isNotEmpty &&
          RegExp(emojiRegex).hasMatch(value)) {
        return message ??
            'The text contains unsupported special characters (emojis).';
      }
      return null;
    });
    return this;
  }

  /// Checks if the string is a valid mobile phone number.
  ValidateString mobile([String? message]) {
    const phoneRegex = r'^\d{2,3}-\d{3,4}-\d{4}$';
    addValidator((value) {
      if (value == null || value.toString().isEmpty) {
        return message ?? 'Please enter a mobile phone number.';
      }
      if (!RegExp(phoneRegex).hasMatch(value.toString())) {
        return message ?? 'Invalid mobile phone number format.';
      }
      return null;
    });
    return this;
  }
}
