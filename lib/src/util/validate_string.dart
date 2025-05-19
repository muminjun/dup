import 'package:dup/src/util/validate_locale.dart';
import 'package:dup/src/util/validator_base.dart';

import '../model/message_factory.dart';

/// Validator for String values.
class ValidateString extends BaseValidator<String, ValidateString> {
  /// Checks if the string has at least [min] characters.
  ValidateString min(int min, {MessageFactory? messageFactory}) {
    addValidator((value) {
      if (value != null && value.trim().length < min) {
        if (messageFactory != null) {
          return messageFactory(label, {'min': min});
        }
        final global = ValidatorLocale.current?.string['min']?.call({
          'name': label,
          'min': min,
        });
        if (global != null) return global;
        return '$label must be at least $min characters.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the string has at most [max] characters.
  ValidateString max(int max, {MessageFactory? messageFactory}) {
    addValidator((value) {
      if (value != null && value.trim().length > max) {
        if (messageFactory != null) {
          return messageFactory(label, {'max': max});
        }
        final global = ValidatorLocale.current?.string['max']?.call({
          'name': label,
          'max': max,
        });
        if (global != null) return global;
        return '$label must be at most $max characters.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the string matches the given [regex].
  ValidateString matches(RegExp regex, {MessageFactory? messageFactory}) {
    addValidator((value) {
      if (value != null && !regex.hasMatch(value.trim())) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.string['matches']?.call({
          'name': label,
        });
        if (global != null) return global;
        return '$label does not match the required format.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the string is a valid email address.
  ValidateString email({MessageFactory? messageFactory}) {
    const emailRegex =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    addValidator((value) {
      if (value == null || value.trim().isEmpty) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.string['emailEmpty']?.call({
          'name': label,
        });
        if (global != null) return global;
        return 'Please enter $label.';
      }
      if (!RegExp(emailRegex).hasMatch(value.trim())) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.string['emailInvalid']?.call({
          'name': label,
        });
        if (global != null) return global;
        return '$label is not a valid email address.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the string is a valid password.
  ValidateString password({MessageFactory? messageFactory}) {
    addValidator((value) {
      if (value == null || value.trim().isEmpty) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.string['passwordEmpty']?.call({
          'name': label,
        });
        if (global != null) return global;
        return 'Please enter $label.';
      }
      if (value.trim().length < 4) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.string['passwordMin']?.call({
          'name': label,
        });
        if (global != null) return global;
        return '$label must be at least 4 characters.';
      }
      if (!RegExp("^[\u0000-\u007F]+\$").hasMatch(value.trim())) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.string['passwordAscii']?.call({
          'name': label,
        });
        if (global != null) return global;
        return '$label must contain only ASCII characters.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the string contains any emoji characters.
  ValidateString emoji({MessageFactory? messageFactory}) {
    const emojiRegex = r'[\uD800-\uDBFF][\uDC00-\uDFFF]';
    addValidator((value) {
      if (value != null &&
          value.isNotEmpty &&
          RegExp(emojiRegex).hasMatch(value)) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.string['emoji']?.call({
          'name': label,
        });
        if (global != null) return global;
        return '$label cannot contain emoji.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the string is a valid mobile phone number.
  ValidateString mobile({MessageFactory? messageFactory}) {
    const phoneRegex = r'^\d{2,3}-\d{3,4}-\d{4}$';
    addValidator((value) {
      if (value == null || value.toString().isEmpty) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.string['mobileEmpty']?.call({
          'name': label,
        });
        if (global != null) return global;
        return 'Please enter $label.';
      }
      if (!RegExp(phoneRegex).hasMatch(value.toString())) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.string['mobileInvalid']?.call({
          'name': label,
        });
        if (global != null) return global;
        return '$label is not a valid mobile number.';
      }
      return null;
    });
    return this;
  }
}
