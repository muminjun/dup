import 'package:dup/src/util/validator_base.dart';
import '../model/base_validator_schema.dart';
import 'form_validate_exception.dart';

class UiFormService {
  /// Validates the given [request] against the provided [schema].
  /// Throws [FormValidationException] if validation fails.
  /// If [abortEarly] is true, stops at the first encountered error.
  Future<void> validate<T>(
      BaseValidatorSchema schema,
      Map<String, dynamic> request, {
        bool abortEarly = false,
      }) async {
    final errors = <String, String?>{};

    for (final field in schema.schema.keys) {
      final BaseValidator validator = schema.schema[field]!;
      final value = request[field];
      final String? error = validator.validate(value);

      if (error != null) {
        errors[field] = error;
        if (abortEarly) break;
      }
    }

    // Throw exception if any validation errors are found
    if (errors.isNotEmpty) {
      throw FormValidationException(errors);
    }
  }

  /// Returns true if the given [path] has an error in [error].
  bool hasError(String path, FormValidationException? error) {
    if (error == null) return false;
    return error.errors.containsKey(path);
  }
}

/// Global instance for convenient access.
final useUiForm = UiFormService();
