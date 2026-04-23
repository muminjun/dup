import '../model/message_factory.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'validator_base.dart';

class ValidateNumber extends BaseValidator<num, ValidateNumber> {
  ValidateNumber min(num min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value < min) {
        return getFailure(messageFactory, ValidationCode.numberMin,
            {'name': label, 'min': min}, '$label must be at least $min.');
      }
      return null;
    });
  }

  ValidateNumber max(num max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value > max) {
        return getFailure(messageFactory, ValidationCode.numberMax,
            {'name': label, 'max': max}, '$label must be at most $max.');
      }
      return null;
    });
  }

  ValidateNumber isInteger({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && value % 1 != 0) {
        return getFailure(messageFactory, ValidationCode.integer,
            {'name': label}, '$label must be an integer.');
      }
      return null;
    });
  }

  ValidateNumber isPositive({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value <= 0) {
        return getFailure(messageFactory, ValidationCode.positive,
            {'name': label}, '$label must be positive.');
      }
      return null;
    });
  }

  ValidateNumber isNegative({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value >= 0) {
        return getFailure(messageFactory, ValidationCode.negative,
            {'name': label}, '$label must be negative.');
      }
      return null;
    });
  }

  ValidateNumber isNonNegative({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value < 0) {
        return getFailure(messageFactory, ValidationCode.nonNegative,
            {'name': label}, '$label must be zero or positive.');
      }
      return null;
    });
  }

  ValidateNumber isNonPositive({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value > 0) {
        return getFailure(messageFactory, ValidationCode.nonPositive,
            {'name': label}, '$label must be zero or negative.');
      }
      return null;
    });
  }

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

  ValidateNumber isEven({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value % 2 != 0) {
        return getFailure(messageFactory, ValidationCode.even,
            {'name': label}, '$label must be an even number.');
      }
      return null;
    });
  }

  ValidateNumber isOdd({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value % 2 == 0) {
        return getFailure(messageFactory, ValidationCode.odd,
            {'name': label}, '$label must be an odd number.');
      }
      return null;
    });
  }

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

  /// Parses a [String?] input to [num] then validates.
  /// Compatible with Flutter's TextFormField.validator.
  /// Returns a parse error if input is non-null, non-empty, and not a valid number.
  @override
  String? Function(dynamic) toValidator({String? parseErrorMessage}) {
    return (dynamic input) {
      if (input == null || input.isEmpty) {
        final result = validate(null);
        return result is ValidationFailure ? result.message : null;
      }
      final parsed = num.tryParse(input as String);
      if (parsed == null) {
        return parseErrorMessage ?? '$label is not a valid number.';
      }
      final result = validate(parsed);
      return result is ValidationFailure ? result.message : null;
    };
  }
}
