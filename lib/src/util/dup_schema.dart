import '../model/form_validation_result.dart';
import '../model/validation_result.dart';
import 'validator_base.dart';

class DupSchema {
  final Map<String, BaseValidator> _schema;
  Map<String, ValidationFailure>? Function(Map<String, dynamic>)?
      _crossValidator;

  DupSchema(
    Map<String, BaseValidator> schema, {
    Map<String, String> labels = const {},
  }) : _schema = Map.from(schema) {
    for (final entry in _schema.entries) {
      final label = labels[entry.key] ?? entry.key;
      entry.value.setLabel(label);
    }
  }

  bool get hasAsyncValidators =>
      _schema.values.any((v) => v.hasAsyncValidators);

  DupSchema crossValidate(
    Map<String, ValidationFailure>? Function(Map<String, dynamic>) fn,
  ) {
    _crossValidator = fn;
    return this;
  }

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

  Future<ValidationResult> validateField(String field, dynamic value) async {
    final validator = _schema[field];
    if (validator == null) return const ValidationSuccess();
    return validator.validateAsync(value);
  }
}
