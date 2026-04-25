import '../internal/nested_validator.dart';
import '../model/form_validation_result.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'dup_schema.dart';
import 'validator_base.dart';

/// Wraps a [DupSchema] as a single-field validator, enabling nested object
/// validation within a parent [DupSchema].
///
/// When used inside a [DupSchema], failing sub-fields are flattened into the
/// parent [FormValidationFailure] with dot notation:
/// `result('address.street')?.message`
///
/// When called directly via [validate]/[validateAsync], inner failures are
/// summarised as a single [ValidationCode.nestedFailed] failure.
class ValidateObject extends BaseValidator<Map<String, dynamic>, ValidateObject>
    implements NestedValidator {
  final DupSchema _innerSchema;

  ValidateObject(this._innerSchema);

  @override
  bool get hasAsyncValidators =>
      super.hasAsyncValidators || _innerSchema.hasAsyncValidators;

  @override
  ValidationResult validate(
    Map<String, dynamic>? value, {
    bool skipPresence = false,
  }) {
    final chainResult = runPhaseChain(value, skipPresence: skipPresence);
    if (chainResult is ValidationFailure) return chainResult;
    if (value == null) return const ValidationSuccess();
    final innerResult = _innerSchema.validateSync(value);
    if (innerResult is FormValidationFailure) {
      return _innerSummary(innerResult);
    }
    return const ValidationSuccess();
  }

  @override
  Future<ValidationResult> validateAsync(
    Map<String, dynamic>? value, {
    bool skipPresence = false,
  }) async {
    final chainResult = runPhaseChain(value, skipPresence: skipPresence);
    if (chainResult is ValidationFailure) return chainResult;
    final asyncFailure = await runAsyncChain(value);
    if (asyncFailure != null) return asyncFailure;
    if (value == null) return const ValidationSuccess();
    final innerResult = await _innerSchema.validate(value);
    if (innerResult is FormValidationFailure) {
      return _innerSummary(innerResult);
    }
    return const ValidationSuccess();
  }

  @override
  Future<NestedValidationResult?> validateNested(
    dynamic value, {
    bool skipPresence = false,
  }) async {
    final chainResult = runPhaseChain(
      value as Map<String, dynamic>?,
      skipPresence: skipPresence,
    );
    if (chainResult is ValidationFailure) return NestedNormalFailure(chainResult);
    final asyncFailure = await runAsyncChain(value);
    if (asyncFailure != null) return NestedNormalFailure(asyncFailure);
    if (value == null) return null;
    final innerResult = await _innerSchema.validate(value);
    if (innerResult is FormValidationFailure) {
      return NestedInnerFailure(innerResult.errors);
    }
    return null;
  }

  @override
  NestedValidationResult? validateNestedSync(
    dynamic value, {
    bool skipPresence = false,
  }) {
    final chainResult = runPhaseChain(
      value as Map<String, dynamic>?,
      skipPresence: skipPresence,
    );
    if (chainResult is ValidationFailure) return NestedNormalFailure(chainResult);
    if (value == null) return null;
    final innerResult = _innerSchema.validateSync(value);
    if (innerResult is FormValidationFailure) {
      return NestedInnerFailure(innerResult.errors);
    }
    return null;
  }

  ValidationFailure _innerSummary(FormValidationFailure innerResult) {
    final firstField = innerResult.firstField ?? '(unknown)';
    return ValidationFailure(
      code: ValidationCode.nestedFailed,
      message: 'Nested validation failed: $firstField — '
          '${innerResult(firstField)?.message ?? ''}',
      context: {'name': label, 'firstField': firstField},
    );
  }
}
