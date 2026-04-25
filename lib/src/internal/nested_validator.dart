import '../model/validation_code.dart';
import '../model/validation_result.dart';

/// Internal transport type for nested validation results.
/// NOT exported from lib/dup.dart.
class NestedValidationFailure extends ValidationFailure {
  final Map<String, ValidationFailure> nestedErrors;

  NestedValidationFailure(this.nestedErrors)
      : super(
          code: ValidationCode.nestedFailed,
          message: nestedErrors.isEmpty
              ? 'Nested validation failed.'
              : 'Nested validation failed: '
                '${nestedErrors.keys.first} — '
                '${nestedErrors.values.first.message}',
          context: const {},
        );
}

/// Sealed result type returned by [NestedValidator.validateNested].
sealed class NestedValidationResult {}

/// A normal phase validator (e.g. required()) on the outer object failed.
/// DupSchema stores this as a regular field error.
class NestedNormalFailure extends NestedValidationResult {
  final ValidationFailure failure;
  NestedNormalFailure(this.failure);
}

/// The inner schema/map validation failed; errors must be flattened.
/// [separator]: '.' for ValidateObject (dot notation), '' for ValidateMap
/// (keys already include bracket notation, e.g. '[score]').
class NestedInnerFailure extends NestedValidationResult {
  final Map<String, ValidationFailure> errors;
  final String separator;
  NestedInnerFailure(this.errors, {this.separator = '.'});
}

/// Internal interface implemented by ValidateObject and ValidateMap.
/// DupSchema calls validateNested/validateNestedSync instead of the public
/// validateAsync/validate for these validators, enabling dot/bracket flattening.
abstract interface class NestedValidator {
  Future<NestedValidationResult?> validateNested(
    dynamic value, {
    bool skipPresence = false,
  });
  NestedValidationResult? validateNestedSync(
    dynamic value, {
    bool skipPresence = false,
  });
}
