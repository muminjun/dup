import '../model/message_factory.dart';
import '../model/validation_code.dart';
import 'validator_base.dart';

/// Validator for [bool] values.
///
/// Both methods null-skip (null passes). Add [required] to also reject null.
///
/// ```dart
/// ValidateBool()
///   .setLabel('Terms accepted')
///   .isTrue()
///   .required()
///   .validate(accepted);
/// ```
class ValidateBool extends BaseValidator<bool, ValidateBool> {
  /// Phase 1: fails when value is not true. Null passes (null-skip).
  ValidateBool isTrue({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value != true) {
        return getFailure(
            messageFactory,
            ValidationCode.boolTrue,
            {
              'name': label,
            },
            '$label must be true.');
      }
      return null;
    });
  }

  /// Phase 1: fails when value is not false. Null passes (null-skip).
  ValidateBool isFalse({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value != false) {
        return getFailure(
            messageFactory,
            ValidationCode.boolFalse,
            {
              'name': label,
            },
            '$label must be false.');
      }
      return null;
    });
  }
}
