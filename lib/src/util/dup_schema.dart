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
/// **Cross-field validation** runs only when all individual fields pass.
/// The cross-validator receives a map containing only the schema's own fields.
/// When a schema is derived via [pick] or [omit], the cross-validator is
/// carried over and will only see the fields that remain in the derived schema:
/// ```dart
/// schema.crossValidate((data) {
///   if (data['password'] != data['passwordConfirm']) {
///     return {'passwordConfirm': ValidationFailure(...)};
///   }
///   return null;
/// });
/// ```
///
/// **Shared validator instances:** validator objects passed to the schema are
/// used directly — they are not cloned. [pick], [omit], and [partial] return
/// new [DupSchema] instances that share the same underlying validator objects.
/// This means calling [BaseValidator.setLabel] (done internally during validation) on a
/// shared instance affects all schemas that reference it. Do not share a single
/// validator instance across concurrent [validate] / [BaseValidator.validateAsync] calls on
/// different schemas.
///
/// **Label mutation at construction:** the constructor calls [BaseValidator.setLabel] on each
/// validator immediately. If the same validator instance is passed to two schemas
/// with different [labels] overrides, the label will reflect whichever schema was
/// constructed last. Use a fresh validator instance per schema when different
/// labels are needed for the same field.
class DupSchema {
  /// Field name → validator map. Each validator has its label set in the constructor.
  final Map<String, BaseValidator> _schema;

  /// Label overrides supplied at construction time; used by [_buildEffective]
  /// to apply the correct label to when-rule then-validators at validation time.
  final Map<String, String> _labels;

  /// Optional cross-field validator, set via [crossValidate].
  /// Receives a data map filtered to only the fields present in this schema.
  /// Not called when any individual field has already failed.
  Map<String, ValidationFailure>? Function(Map<String, dynamic>)?
  _crossValidator;

  /// Keys present in this schema. Used to filter the data map before passing
  /// it to [_crossValidator], so derived schemas (pick/omit) never expose
  /// removed fields to the cross-validator.
  Set<String>? _schemaKeys;

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
  /// [fn] receives a data map containing only the fields present in this
  /// schema (not the full raw input). It returns a field-error map or null.
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
  ///
  /// Warning: [then] validator instances must not be shared across multiple
  /// [when] rules or reused as base schema validators. Labels are mutated on
  /// these instances at validation time, which is non-deterministic if the same
  /// instance appears in multiple rules.
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

  /// Returns a view of [data] containing only the keys present in this schema.
  /// Passed to [_crossValidator] so derived schemas (pick/omit) never expose
  /// removed fields to the cross-validator.
  Map<String, dynamic> _filterData(Map<String, dynamic> data) {
    final keys = _schemaKeys ?? _schema.keys.toSet();
    return {for (final k in keys) k: data[k]};
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
      .._crossValidator = _crossValidator
      .._schemaKeys = kept.keys.toSet();
  }

  /// Returns a new [DupSchema] containing only [fields]. Unknown names ignored.
  ///
  /// The [crossValidate] function is carried over to the derived schema.
  /// The cross-validator receives a data map filtered to the schema's own
  /// fields — fields not included in [fields] will appear as `null` even if
  /// the caller supplies them in the data map.
  DupSchema pick(List<String> fields) {
    final kept = Map.fromEntries(
      _schema.entries.where((e) => fields.contains(e.key)),
    );
    return _derive(kept);
  }

  /// Returns a new [DupSchema] with [fields] removed. Unknown names ignored.
  ///
  /// The [crossValidate] function is carried over to the derived schema.
  /// The cross-validator receives a data map filtered to the schema's own
  /// fields — removed fields will appear as `null` even if the caller
  /// supplies them in the data map.
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
    // All fields are kept, so when-rules need no filtering (unlike _derive).
    return DupSchema(_schema, labels: _labels)
      .._isPartial = true
      .._whenRules.addAll(_whenRules)
      .._crossValidator = _crossValidator;
  }

  /// Validates all fields asynchronously and returns a [FormValidationResult].
  ///
  /// Fields are validated **sequentially** in schema-key insertion order.
  /// All fields are validated before returning; [FormValidationFailure] contains
  /// errors for every field that failed. [crossValidate] is only called when
  /// all individual fields pass.
  ///
  /// When the schema contains multiple I/O-bound async validators (e.g.
  /// uniqueness checks), consider [validateParallel] to run all fields
  /// concurrently instead.
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
      final crossErrors = _crossValidator!(_filterData(data));
      if (crossErrors != null && crossErrors.isNotEmpty) {
        return FormValidationFailure(crossErrors);
      }
    }
    return const FormValidationSuccess();
  }

  /// Validates all fields **concurrently** and returns a [FormValidationResult].
  ///
  /// All field validators are launched at the same time via [Future.wait],
  /// reducing total latency when multiple fields have I/O-bound async
  /// validators (e.g. database uniqueness checks). Unlike [validate], field
  /// execution order is not guaranteed.
  ///
  /// [crossValidate] is only called when all individual fields pass.
  Future<FormValidationResult> validateParallel(
    Map<String, dynamic> data, {
    bool skipPresence = false,
  }) async {
    final effectiveSkip = _isPartial || skipPresence;
    final effective = _buildEffective(data);
    final fields = effective.keys.toList();

    // Run every field validator concurrently. Each future resolves to a
    // Map<String, ValidationFailure> (possibly empty) for that field.
    final perFieldErrors = await Future.wait(
      fields.map((field) async {
        final partial = <String, ValidationFailure>{};
        final validator = effective[field]!;
        if (validator is NestedValidator) {
          final result = await (validator as NestedValidator).validateNested(
            data[field],
            skipPresence: effectiveSkip,
          );
          _applyNestedResult(field, result, partial);
        } else {
          final result = await validator.validateAsync(
            data[field],
            skipPresence: effectiveSkip,
          );
          if (result is ValidationFailure) partial[field] = result;
        }
        return partial;
      }),
    );

    final errors = <String, ValidationFailure>{
      for (final m in perFieldErrors) ...m,
    };
    if (errors.isNotEmpty) return FormValidationFailure(errors);
    if (_crossValidator != null) {
      final crossErrors = _crossValidator!(_filterData(data));
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
      final crossErrors = _crossValidator!(_filterData(data));
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
  ///
  /// Set [skipPresence] to `true` to suppress `required` checks — useful for
  /// live on-change validation before the user has finished filling the form.
  ///
  /// **Nested fields:** when [field] maps to a [ValidateObject] or [ValidateMap],
  /// this method dispatches through [NestedValidator.validateNested] and returns
  /// the first sub-field failure (with its flattened key as the message context),
  /// matching the behaviour of [validate].
  Future<ValidationResult> validateField(
    String field,
    dynamic value, {
    Map<String, dynamic>? data,
    bool skipPresence = false,
  }) async {
    final effectiveSkip = _isPartial || skipPresence;
    final effective = data != null ? _buildEffective(data) : _schema;
    final validator = effective[field];
    if (validator == null) return const ValidationSuccess();
    if (validator is NestedValidator) {
      final nested = await (validator as NestedValidator).validateNested(
        value,
        skipPresence: effectiveSkip,
      );
      if (nested == null) return const ValidationSuccess();
      if (nested is NestedNormalFailure) return nested.failure;
      if (nested is NestedInnerFailure) {
        return nested.errors.values.first;
      }
    }
    return validator.validateAsync(value, skipPresence: effectiveSkip);
  }
}
