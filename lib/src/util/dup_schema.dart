import '../internal/nested_validator.dart';
import '../model/form_validation_result.dart';
import '../model/validation_result.dart';
import 'validator_base.dart';

class _WhenRule {
  final String field;
  final bool Function(dynamic) condition;
  final Map<String, BaseValidator> then;
  const _WhenRule({
    required this.field,
    required this.condition,
    required this.then,
  });
}

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

  /// Label overrides supplied at construction time; used by [_buildEffective]
  /// to apply the correct label to when-rule then-validators at validation time.
  final Map<String, String> _labels;

  /// Optional cross-field validator, set via [crossValidate].
  /// Receives the full data map; returns field-level errors or null if everything passes.
  /// Not called when any individual field has already failed.
  Map<String, ValidationFailure>? Function(Map<String, dynamic>)?
  _crossValidator;

  bool _isPartial = false;
  final List<_WhenRule> _whenRules = [];

  /// [schema]: field name → validator map.
  /// [labels]: optional overrides for the label assigned to each validator.
  ///           Fields absent from this map use their key name as the label.
  DupSchema(
    Map<String, BaseValidator> schema, {
    Map<String, String> labels = const {},
  }) : _schema = Map.from(schema),
       _labels = Map.from(labels) {
    // Inject labels now so error messages carry the correct field name.
    for (final entry in _schema.entries) {
      final label = labels[entry.key] ?? entry.key;
      entry.value.setLabel(label);
    }
  }

  /// True when any field validator has at least one async validator registered.
  /// Use this to decide between [validate] and [validateSync].
  bool get hasAsyncValidators =>
      _schema.values.any((v) => v.hasAsyncValidators) ||
      _whenRules.any((r) => r.then.values.any((v) => v.hasAsyncValidators));

  /// Registers a cross-field validation function and returns this schema for chaining.
  ///
  /// [fn] receives the raw data map and returns a field-error map or null.
  /// It is only called when all individual fields pass their own validators.
  DupSchema crossValidate(
    Map<String, ValidationFailure>? Function(Map<String, dynamic>) fn,
  ) {
    _crossValidator = fn;
    return this;
  }

  /// Registers a conditional validation rule. [condition] receives the raw input
  /// value of [field]; when true, [then] validators replace base validators for
  /// those fields. Evaluated before any validation runs.
  DupSchema when({
    required String field,
    required bool Function(dynamic) condition,
    required Map<String, BaseValidator> then,
  }) {
    _whenRules.add(_WhenRule(field: field, condition: condition, then: then));
    return this;
  }

  void _applyNestedResult(
    String field,
    NestedValidationResult? result,
    Map<String, ValidationFailure> errors,
  ) {
    if (result is NestedNormalFailure) {
      errors[field] = result.failure;
    } else if (result is NestedInnerFailure) {
      for (final e in result.errors.entries) {
        errors['$field${result.separator}${e.key}'] = e.value;
      }
    }
  }

  Map<String, BaseValidator> _buildEffective(Map<String, dynamic> data) {
    final effective = Map<String, BaseValidator>.from(_schema);
    for (final rule in _whenRules) {
      if (rule.condition(data[rule.field])) {
        for (final e in rule.then.entries) {
          e.value.setLabel(_labels[e.key] ?? e.key);
          effective[e.key] = e.value;
        }
      }
    }
    return effective;
  }

  DupSchema _derive(Map<String, BaseValidator> kept) {
    final derivedLabels = {
      for (final key in kept.keys)
        key:
            _labels[key] ??
            (kept[key]!.label.isNotEmpty ? kept[key]!.label : key),
    };
    final keptRules =
        _whenRules
            .where((r) => kept.containsKey(r.field))
            .map((r) {
              final filteredThen = Map.fromEntries(
                r.then.entries.where((e) => kept.containsKey(e.key)),
              );
              if (filteredThen.isEmpty) return null;
              return _WhenRule(
                field: r.field,
                condition: r.condition,
                then: filteredThen,
              );
            })
            .whereType<_WhenRule>()
            .toList();
    return DupSchema(kept, labels: derivedLabels)
      .._whenRules.addAll(keptRules)
      .._isPartial = _isPartial
      .._crossValidator = _crossValidator;
  }

  /// Returns a new [DupSchema] containing only [fields]. Unknown names ignored.
  DupSchema pick(List<String> fields) {
    final kept = Map.fromEntries(
      _schema.entries.where((e) => fields.contains(e.key)),
    );
    return _derive(kept);
  }

  /// Returns a new [DupSchema] with [fields] removed. Unknown names ignored.
  DupSchema omit(List<String> fields) {
    final kept = Map.fromEntries(
      _schema.entries.where((e) => !fields.contains(e.key)),
    );
    return _derive(kept);
  }

  /// Returns a new [DupSchema] where `required()` presence checks are skipped
  /// at validation time. All other validators (format, constraint, custom) remain
  /// active. Validator instances are shared — no cloning occurs.
  DupSchema partial() {
    return DupSchema(_schema, labels: _labels)
      .._isPartial = true
      .._whenRules.addAll(_whenRules)
      .._crossValidator = _crossValidator;
  }

  /// Validates all fields asynchronously and returns a [FormValidationResult].
  ///
  /// Each field's [BaseValidator.validateAsync] is awaited in schema-key order.
  /// All fields are validated before returning; [FormValidationFailure] contains
  /// errors for every field that failed. [crossValidate] is only called when
  /// all individual fields pass.
  Future<FormValidationResult> validate(
    Map<String, dynamic> data, {
    bool skipPresence = false,
  }) async {
    final effectiveSkip = _isPartial || skipPresence;
    final effective = _buildEffective(data);
    final errors = <String, ValidationFailure>{};
    for (final field in effective.keys) {
      final validator = effective[field]!;
      if (validator is NestedValidator) {
        final result = await (validator as NestedValidator).validateNested(
          data[field],
          skipPresence: effectiveSkip,
        );
        _applyNestedResult(field, result, errors);
      } else {
        final result = await validator.validateAsync(
          data[field],
          skipPresence: effectiveSkip,
        );
        if (result is ValidationFailure) errors[field] = result;
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
  FormValidationResult validateSync(
    Map<String, dynamic> data, {
    bool skipPresence = false,
  }) {
    if (hasAsyncValidators) {
      throw StateError(
        'validateSync() called on a schema that has async validators. '
        'Use validate() instead.',
      );
    }
    final effectiveSkip = _isPartial || skipPresence;
    final effective = _buildEffective(data);
    final errors = <String, ValidationFailure>{};
    for (final field in effective.keys) {
      final validator = effective[field]!;
      if (validator is NestedValidator) {
        final result = (validator as NestedValidator).validateNestedSync(
          data[field],
          skipPresence: effectiveSkip,
        );
        _applyNestedResult(field, result, errors);
      } else {
        final result = validator.validate(
          data[field],
          skipPresence: effectiveSkip,
        );
        if (result is ValidationFailure) errors[field] = result;
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
  /// `TextFormField`).
  ///
  /// Returns [ValidationSuccess] when [field] is not registered in the schema.
  ///
  /// Provide [data] (the full form data map) to apply [when] conditional rules.
  /// Without [data], only the base schema validator for the field is used.
  Future<ValidationResult> validateField(
    String field,
    dynamic value, {
    Map<String, dynamic>? data,
  }) async {
    final effective = data != null ? _buildEffective(data) : _schema;
    final validator = effective[field];
    if (validator == null) return const ValidationSuccess();
    return validator.validateAsync(value, skipPresence: _isPartial);
  }
}
