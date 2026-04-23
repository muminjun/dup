import '../model/form_validation_result.dart';
import '../model/validation_result.dart';
import 'validator_base.dart';

/// Schema-level validator that groups multiple field validators and runs
/// them together as a form.
///
/// Replaces the v1 `BaseValidatorSchema` + `UiFormService` pair with a single
/// class. Validators are keyed by field name; each validator's label is set
/// to the field name (or the value from [labels]) at construction time.
///
/// **Basic usage:**
/// ```dart
/// final schema = DupSchema({
///   'email': ValidateString().email().required(),
///   'age':   ValidateNumber().min(18).required(),
/// });
///
/// final result = await schema.validate(formData);
/// if (result is FormValidationFailure) {
///   print(result('email')?.message);
/// }
/// ```
///
/// **Custom labels:**
/// ```dart
/// DupSchema(
///   {'passwordConfirm': ValidateString().required()},
///   labels: {'passwordConfirm': 'Password confirmation'},
/// )
/// ```
///
/// **Cross-field validation** runs only when all individual fields pass:
/// ```dart
/// schema.crossValidate((data) {
///   if (data['password'] != data['passwordConfirm']) {
///     return {'passwordConfirm': ValidationFailure(...)};
///   }
///   return null;
/// });
/// ```
class DupSchema {
  /// Field name → validator map. Each validator has its label set in the constructor.
  final Map<String, BaseValidator> _schema;

  /// Optional cross-field validator, set via [crossValidate].
  /// Receives the full data map; returns field-level errors or null if everything passes.
  /// Not called when any individual field has already failed.
  Map<String, ValidationFailure>? Function(Map<String, dynamic>)?
      _crossValidator;

  /// [schema]: field name → validator map.
  /// [labels]: optional overrides for the label assigned to each validator.
  ///           Fields absent from this map use their key name as the label.
  DupSchema(
    Map<String, BaseValidator> schema, {
    Map<String, String> labels = const {},
  }) : _schema = Map.from(schema) {
    // Inject labels now so error messages carry the correct field name.
    for (final entry in _schema.entries) {
      final label = labels[entry.key] ?? entry.key;
      entry.value.setLabel(label);
    }
  }

  /// True when any field validator has at least one async validator registered.
  /// Use this to decide between [validate] and [validateSync].
  bool get hasAsyncValidators =>
      _schema.values.any((v) => v.hasAsyncValidators);

  /// Registers a cross-field validation function and returns [this] for chaining.
  ///
  /// [fn] receives the raw data map and returns a field-error map or null.
  /// It is only called when all individual fields pass their own validators.
  DupSchema crossValidate(
    Map<String, ValidationFailure>? Function(Map<String, dynamic>) fn,
  ) {
    _crossValidator = fn;
    return this;
  }

  /// Validates all fields asynchronously and returns a [FormValidationResult].
  ///
  /// Each field's [BaseValidator.validateAsync] is awaited in schema-key order.
  /// If any field fails, [FormValidationFailure] is returned immediately and
  /// [crossValidate] is skipped.
  Future<FormValidationResult> validate(Map<String, dynamic> data) async {
    final errors = <String, ValidationFailure>{};
    for (final field in _schema.keys) {
      final result = await _schema[field]!.validateAsync(data[field]);
      if (result is ValidationFailure) {
        errors[field] = result;
      }
    }
    if (errors.isNotEmpty) return FormValidationFailure(errors);
    if (_crossValidator != null) {
      final crossErrors = _crossValidator!(data);
      if (crossErrors != null && crossErrors.isNotEmpty) {
        return FormValidationFailure(crossErrors);
      }
    }
    return const FormValidationSuccess();
  }

  /// Validates all fields synchronously and returns a [FormValidationResult].
  ///
  /// Asserts in debug mode that no async validators are registered.
  /// Use [validate] when the schema contains async validators.
  FormValidationResult validateSync(Map<String, dynamic> data) {
    assert(
      !hasAsyncValidators,
      'validateSync() called on a schema that has async validators. '
      'Use validate() instead.',
    );
    final errors = <String, ValidationFailure>{};
    for (final field in _schema.keys) {
      final result = _schema[field]!.validate(data[field]);
      if (result is ValidationFailure) {
        errors[field] = result;
      }
    }
    if (errors.isNotEmpty) return FormValidationFailure(errors);
    if (_crossValidator != null) {
      final crossErrors = _crossValidator!(data);
      if (crossErrors != null && crossErrors.isNotEmpty) {
        return FormValidationFailure(crossErrors);
      }
    }
    return const FormValidationSuccess();
  }

  /// Validates a single field in isolation (e.g. for on-change feedback in a
  /// [TextFormField]).
  ///
  /// Returns [ValidationSuccess] when [field] is not registered in the schema.
  Future<ValidationResult> validateField(String field, dynamic value) async {
    final validator = _schema[field];
    if (validator == null) return const ValidationSuccess();
    return validator.validateAsync(value);
  }
}
