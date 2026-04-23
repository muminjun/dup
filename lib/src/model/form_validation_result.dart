import 'validation_result.dart';

/// Sealed result type for a full schema (form) validation.
///
/// Returned by [DupSchema.validate] and [DupSchema.validateSync].
/// Either [FormValidationSuccess] (all fields passed) or
/// [FormValidationFailure] (one or more fields failed). Sealed so switch
/// exhaustiveness is enforced:
///
/// ```dart
/// final result = await schema.validate(data);
/// switch (result) {
///   FormValidationSuccess() => submitForm(),
///   FormValidationFailure(:final errors) => showErrors(errors),
/// }
/// ```
sealed class FormValidationResult {
  const FormValidationResult();
}

/// Indicates that all fields passed validation.
class FormValidationSuccess extends FormValidationResult {
  const FormValidationSuccess();
}

/// Indicates that one or more fields failed validation.
///
/// [errors] maps each failing field name to its [ValidationFailure].
/// Use the call operator to look up a field's error conveniently.
class FormValidationFailure extends FormValidationResult {
  /// Map of field name → [ValidationFailure]. Keys match the schema field names.
  final Map<String, ValidationFailure> errors;

  const FormValidationFailure(this.errors);

  /// Returns the [ValidationFailure] for [field], or null if the field passed.
  ///
  /// ```dart
  /// final emailError = failure('email'); // ValidationFailure?
  /// ```
  ValidationFailure? call(String field) => errors[field];

  /// Returns true if [field] has a validation error.
  bool hasError(String field) => errors.containsKey(field);

  /// All field names that have errors.
  List<String> get fields => errors.keys.toList();

  /// The first field name that has an error, or null if [errors] is empty.
  String? get firstField => errors.keys.firstOrNull;
}
