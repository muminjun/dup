import 'package:dup/src/util/validate_locale.dart';
import 'package:dup/src/util/validator_base.dart';

import '../model/message_factory.dart';

/// Validator for numeric values.
class ValidateNumber extends BaseValidator<num, ValidateNumber> {
  /// Checks if the value is greater than or equal to [min].
  ValidateNumber min(num min, {MessageFactory? messageFactory}) {
    addValidator((value) {
      if (value != null && value < min) {
        if (messageFactory != null) {
          return messageFactory(label, {'min': min});
        }
        final global = ValidatorLocale.current?.number['min']?.call({
          'name': label,
          'min': min,
        });
        if (global != null) return global;
        return '$label must be at least $min.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the value is less than or equal to [max].
  ValidateNumber max(num max, {MessageFactory? messageFactory}) {
    addValidator((value) {
      if (value != null && value > max) {
        if (messageFactory != null) {
          return messageFactory(label, {'max': max});
        }
        final global = ValidatorLocale.current?.number['max']?.call({
          'name': label,
          'max': max,
        });
        if (global != null) return global;
        return '$label must be at most $max.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the value is an integer.
  ValidateNumber isInteger({MessageFactory? messageFactory}) {
    addValidator((value) {
      if (value != null && value % 1 != 0) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.number['integer']?.call({
          'name': label,
        });
        if (global != null) return global;
        return '$label must be an integer.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the value is a valid landline phone number.
  ValidateNumber phone({MessageFactory? messageFactory}) {
    const landlineRegex = r'^(0[2-9]{1}\d?)-\d{3,4}-\d{4}$';
    addValidator((value) {
      if (value == null || value.toString().isEmpty) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.number['phoneEmpty']?.call({
          'name': label,
        });
        if (global != null) return global;
        return 'Please enter $label.';
      }
      if (!RegExp(landlineRegex).hasMatch(value.toString())) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.number['phoneInvalid']?.call({
          'name': label,
        });
        if (global != null) return global;
        return '$label is not a valid phone number.';
      }
      return null;
    });
    return this;
  }

  /// Checks if the value is a valid business registration number.
  ValidateNumber bizno({MessageFactory? messageFactory}) {
    const brnRegex = r'^\d{3}-\d{2}-\d{5}$';
    addValidator((value) {
      if (value == null || value.toString().isEmpty) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.number['biznoEmpty']?.call({
          'name': label,
        });
        if (global != null) return global;
        return 'Please enter $label.';
      }
      if (!RegExp(brnRegex).hasMatch(value.toString())) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.number['biznoInvalid']?.call({
          'name': label,
        });
        if (global != null) return global;
        return '$label is not a valid business number.';
      }
      return null;
    });
    return this;
  }
}
