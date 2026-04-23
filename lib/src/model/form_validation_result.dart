import 'validation_result.dart';

sealed class FormValidationResult {
  const FormValidationResult();
}

class FormValidationSuccess extends FormValidationResult {
  const FormValidationSuccess();
}

class FormValidationFailure extends FormValidationResult {
  final Map<String, ValidationFailure> errors;

  const FormValidationFailure(this.errors);

  ValidationFailure? call(String field) => errors[field];

  bool hasError(String field) => errors.containsKey(field);

  List<String> get fields => errors.keys.toList();

  String? get firstField => errors.keys.firstOrNull;
}
