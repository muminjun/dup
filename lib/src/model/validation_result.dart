import 'validation_code.dart';

/// Sealed result type for a single-field validation.
///
/// Returned by [BaseValidator.validate] and [BaseValidator.validateAsync].
/// Either [ValidationSuccess] (all checks passed) or [ValidationFailure]
/// (the first failing check). Sealed so switch exhaustiveness is enforced:
///
/// ```dart
/// final result = ValidateString().email().validate(input);
/// switch (result) {
///   ValidationSuccess() => print('ok'),
///   ValidationFailure(:final message) => print(message),
/// }
/// ```
sealed class ValidationResult {
  const ValidationResult();
}

/// Indicates that validation passed. Immutable; use the const constructor.
class ValidationSuccess extends ValidationResult {
  const ValidationSuccess();
}

/// Indicates that validation failed, carrying the reason code, message, and context.
class ValidationFailure extends ValidationResult {
  /// Code classifying the failure. Also used as the lookup key in [ValidatorLocale].
  final ValidationCode code;

  /// Optional sub-tag for user-defined validators that use [ValidationCode.custom].
  final String? customCode;

  /// Resolved error message — snapshotted at validation time.
  /// Priority: messageFactory → locale → hardcoded default.
  final String message;

  /// Parameters used to build [message] (e.g. `{name: 'Email', min: 3}`).
  /// Passed to the locale [LocaleMessage] function for dynamic interpolation.
  final Map<String, dynamic> context;

  const ValidationFailure({
    required this.code,
    this.customCode,
    required this.message,
    this.context = const {},
  });
}
