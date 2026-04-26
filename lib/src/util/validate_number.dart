import '../model/message_factory.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'validator_base.dart';

/// Validator for [num] values (int and double).
///
/// All methods null-skip: they return null (pass) when the value is null.
///
/// For Flutter [TextFormField] integration use [toValidator], which parses
/// a string input to [num] before running validation:
///
/// ```dart
/// TextFormField(
///   validator: ValidateNumber().setLabel('Age').min(18).toValidator(),
/// )
/// ```
class ValidateNumber extends BaseValidator<num, ValidateNumber> {
  /// Phase 2: fails when value is less than [min].
  ValidateNumber min(num min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value < min) {
        return getFailure(messageFactory, ValidationCode.numberMin,
            {'name': label, 'min': min}, '$label must be at least $min.');
      }
      return null;
    });
  }

  /// Phase 2: fails when value exceeds [max].
  ValidateNumber max(num max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value > max) {
        return getFailure(messageFactory, ValidationCode.numberMax,
            {'name': label, 'max': max}, '$label must be at most $max.');
      }
      return null;
    });
  }

  /// Phase 1: fails when value has a fractional part (i.e. is not a whole number).
  ValidateNumber isInteger({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && value % 1 != 0) {
        return getFailure(messageFactory, ValidationCode.integer,
            {'name': label}, '$label must be an integer.');
      }
      return null;
    });
  }

  /// Phase 2: fails when value is zero or negative.
  ValidateNumber isPositive({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value <= 0) {
        return getFailure(messageFactory, ValidationCode.positive,
            {'name': label}, '$label must be positive.');
      }
      return null;
    });
  }

  /// Phase 2: fails when value is zero or positive.
  ValidateNumber isNegative({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value >= 0) {
        return getFailure(messageFactory, ValidationCode.negative,
            {'name': label}, '$label must be negative.');
      }
      return null;
    });
  }

  /// Phase 2: fails when value is negative (zero is allowed).
  ValidateNumber isNonNegative({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value < 0) {
        return getFailure(messageFactory, ValidationCode.nonNegative,
            {'name': label}, '$label must be zero or positive.');
      }
      return null;
    });
  }

  /// Phase 2: fails when value is positive (zero is allowed).
  ValidateNumber isNonPositive({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value > 0) {
        return getFailure(messageFactory, ValidationCode.nonPositive,
            {'name': label}, '$label must be zero or negative.');
      }
      return null;
    });
  }

  /// Phase 2: fails when value is outside the inclusive range [[min], [max]].
  ValidateNumber between(num min, num max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && (value < min || value > max)) {
        return getFailure(messageFactory, ValidationCode.between,
            {'name': label, 'min': min, 'max': max},
            '$label must be between $min and $max.');
      }
      return null;
    });
  }

  /// Phase 2: fails when value is odd or not an integer.
  ValidateNumber isEven({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && (value % 1 != 0 || value % 2 != 0)) {
        return getFailure(messageFactory, ValidationCode.even,
            {'name': label}, '$label must be an even number.');
      }
      return null;
    });
  }

  /// Phase 2: fails when value is even or not an integer.
  ValidateNumber isOdd({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && (value % 1 != 0 || value % 2 == 0)) {
        return getFailure(messageFactory, ValidationCode.odd,
            {'name': label}, '$label must be an odd number.');
      }
      return null;
    });
  }

  /// Phase 2: fails when value is not a multiple of [factor].
  ValidateNumber isMultipleOf(num factor, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value % factor != 0) {
        return getFailure(messageFactory, ValidationCode.multipleOf,
            {'name': label, 'factor': factor},
            '$label must be a multiple of $factor.');
      }
      return null;
    });
  }

  /// Returns a [TextFormField]-compatible adapter that parses string input to
  /// [num] before running validation.
  ///
  /// - null / empty string → runs `required` check (if registered)
  /// - non-numeric string → returns [parseErrorMessage] or a default parse error
  /// - valid number string → runs the full numeric validation chain
  ///
  // Return type is `dynamic` rather than `String?` because Dart does not allow
  // overriding `String? Function(num?)` with `String? Function(String?)` —
  // function types are contravariant in parameters.
  @override
  String? Function(dynamic) toValidator({String? parseErrorMessage}) {
    return (dynamic input) {
      if (input == null || (input is String && input.isEmpty)) {
        final result = validate(null);
        return result is ValidationFailure ? result.message : null;
      }
      final parsed = num.tryParse(input.toString());
      if (parsed == null) {
        return parseErrorMessage ?? '$label is not a valid number.';
      }
      final result = validate(parsed);
      return result is ValidationFailure ? result.message : null;
    };
  }

  /// Phase 1: fails when the value has more than [digits] decimal places.
  ValidateNumber isPrecision(int digits, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      final s = value.toString();
      final dotIndex = s.indexOf('.');
      final actualDigits = dotIndex < 0 ? 0 : s.length - dotIndex - 1;
      if (actualDigits > digits) {
        return getFailure(
          messageFactory,
          ValidationCode.numberPrecision,
          {'name': label, 'digits': digits},
          '$label must have at most $digits decimal places.',
        );
      }
      return null;
    });
  }

  /// Phase 1: fails when value is not an integer in range 0–65535.
  /// Non-integer values (e.g. 80.5) also fail.
  ValidateNumber isPort({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value != value.truncate() || value < 0 || value > 65535) {
        return getFailure(
          messageFactory,
          ValidationCode.isPort,
          {'name': label},
          '$label must be a valid port number (0–65535).',
        );
      }
      return null;
    });
  }
}
