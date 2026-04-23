import 'validation_code.dart';

sealed class ValidationResult {
  const ValidationResult();
}

class ValidationSuccess extends ValidationResult {
  const ValidationSuccess();
}

class ValidationFailure extends ValidationResult {
  final ValidationCode code;

  /// Optional tag for user-defined validators using [ValidationCode.custom].
  final String? customCode;

  /// Resolved message string — snapshot at validation time.
  final String message;

  /// Parameters used to build [message] (e.g. {name: 'Email', min: 3}).
  final Map<String, dynamic> context;

  const ValidationFailure({
    required this.code,
    this.customCode,
    required this.message,
    this.context = const {},
  });
}
