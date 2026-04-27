import 'package:meta/meta.dart';

import '../internal/nested_validator.dart';
import '../model/message_factory.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'validate_string.dart';
import 'validator_base.dart';

/// Validator for [Map<String, V>] values.
///
/// Keys are always [String]. Use [keyValidator] and [valueValidator] to apply
/// per-entry validation. When used inside a [DupSchema], key/value errors are
/// flattened with bracket notation: `result('field[key]')`.
class ValidateMap<V> extends BaseValidator<Map<String, V>, ValidateMap<V>>
    implements NestedValidator {
  ValidateString? _keyValidator;
  BaseValidator<V, dynamic>? _valueValidator;

  @override
  bool get hasAsyncValidators =>
      super.hasAsyncValidators ||
      (_keyValidator?.hasAsyncValidators ?? false) ||
      (_valueValidator?.hasAsyncValidators ?? false);

  /// Phase 2: fails when the map has fewer than [min] entries.
  ValidateMap<V> minSize(int min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.length < min) {
        return getFailure(
          messageFactory,
          ValidationCode.mapMinSize,
          {'name': label, 'min': min},
          '$label must have at least $min entries.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when the map has more than [max] entries.
  ValidateMap<V> maxSize(int max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.length > max) {
        return getFailure(
          messageFactory,
          ValidationCode.mapMaxSize,
          {'name': label, 'max': max},
          '$label must have at most $max entries.',
        );
      }
      return null;
    });
  }

  /// Phase 1: applies [validator] to every map key.
  ///
  /// When a key fails validation, the value for that entry is not checked —
  /// only one error per entry (either a key error or a value error) is recorded.
  ///
  /// **Concurrency warning:** the validator's label is temporarily mutated to
  /// the current entry key during validation and then restored. Do not share
  /// the same [ValidateMap] instance across concurrent [validateAsync] calls
  /// (i.e. two simultaneous `await`s on the same instance), as the label may
  /// be overwritten mid-validation.
  ValidateMap<V> keyValidator(ValidateString validator) {
    _keyValidator = validator;
    return this;
  }

  /// Phase 1: applies [validator] to every map value.
  ///
  /// **Concurrency warning:** same label-mutation caveat as [keyValidator] —
  /// do not share the same [ValidateMap] instance across concurrent
  /// [validateAsync] calls.
  ValidateMap<V> valueValidator(BaseValidator<V, dynamic> validator) {
    _valueValidator = validator;
    return this;
  }

  @override
  ValidationResult validate(
    Map<String, V>? value, {
    bool skipPresence = false,
  }) {
    // Phase 0–1 first (required + format checks including keyValidator/valueValidator).
    final phase01 = runPhaseChain(value, skipPresence: skipPresence, toPhase: 1);
    if (phase01 is ValidationFailure) return phase01;
    if (value != null) {
      final entryErrors = _validateEntriesSync(value, skipPresence: skipPresence);
      if (entryErrors.isNotEmpty) return _entrySummary(entryErrors);
    }
    // Phase 2+ (size constraints) run after entry validation.
    final phase2 = runPhaseChain(value, skipPresence: skipPresence, fromPhase: 2);
    if (phase2 is ValidationFailure) return phase2;
    return const ValidationSuccess();
  }

  @override
  Future<ValidationResult> validateAsync(
    Map<String, V>? value, {
    bool skipPresence = false,
  }) async {
    // Phase 0–1 first (required + format checks including keyValidator/valueValidator).
    final phase01 = runPhaseChain(value, skipPresence: skipPresence, toPhase: 1);
    if (phase01 is ValidationFailure) return phase01;
    if (value != null) {
      final entryErrors = await _validateEntries(value, skipPresence: skipPresence);
      if (entryErrors.isNotEmpty) return _entrySummary(entryErrors);
    }
    // Phase 2+ (size constraints) run after entry validation.
    final phase2 = runPhaseChain(value, skipPresence: skipPresence, fromPhase: 2);
    if (phase2 is ValidationFailure) return phase2;
    final asyncFailure = await runAsyncChain(value);
    if (asyncFailure != null) return asyncFailure;
    return const ValidationSuccess();
  }

  ValidationFailure _entrySummary(Map<String, ValidationFailure> errors) {
    final firstKey = errors.keys.first;
    return ValidationFailure(
      code: ValidationCode.nestedFailed,
      message:
          'Map validation failed: $firstKey — ${errors[firstKey]!.message}',
      context: {'name': label, 'firstField': firstKey},
    );
  }

  @override
  @internal
  Future<NestedValidationResult?> validateNested(
    dynamic value, {
    bool skipPresence = false,
  }) async {
    if (value != null && value is! Map<String, V>) {
      return NestedNormalFailure(ValidationFailure(
        code: ValidationCode.nestedFailed,
        message: '$label must be a map.',
        context: {'name': label},
      ));
    }
    // Phase 0–1 first (required + format checks including keyValidator/valueValidator).
    final phase01 = runPhaseChain(
      value as Map<String, V>?,
      skipPresence: skipPresence,
      toPhase: 1,
    );
    if (phase01 is ValidationFailure) return NestedNormalFailure(phase01);
    if (value != null) {
      final entryErrors = await _validateEntries(value, skipPresence: skipPresence);
      if (entryErrors.isNotEmpty) {
        return NestedInnerFailure(entryErrors, separator: '');
      }
    }
    // Phase 2+ (size constraints) run after entry validation.
    final phase2 = runPhaseChain(value, skipPresence: skipPresence, fromPhase: 2);
    if (phase2 is ValidationFailure) return NestedNormalFailure(phase2);
    final asyncFailure = await runAsyncChain(value);
    if (asyncFailure != null) return NestedNormalFailure(asyncFailure);
    return null;
  }

  @override
  @internal
  NestedValidationResult? validateNestedSync(
    dynamic value, {
    bool skipPresence = false,
  }) {
    if (value != null && value is! Map<String, V>) {
      return NestedNormalFailure(ValidationFailure(
        code: ValidationCode.nestedFailed,
        message: '$label must be a map.',
        context: {'name': label},
      ));
    }
    // Phase 0–1 first (required + format checks including keyValidator/valueValidator).
    final phase01 = runPhaseChain(
      value as Map<String, V>?,
      skipPresence: skipPresence,
      toPhase: 1,
    );
    if (phase01 is ValidationFailure) return NestedNormalFailure(phase01);
    if (value != null) {
      final entryErrors = _validateEntriesSync(value, skipPresence: skipPresence);
      if (entryErrors.isNotEmpty) {
        return NestedInnerFailure(entryErrors, separator: '');
      }
    }
    // Phase 2+ (size constraints) run after entry validation.
    final phase2 = runPhaseChain(value, skipPresence: skipPresence, fromPhase: 2);
    if (phase2 is ValidationFailure) return NestedNormalFailure(phase2);
    return null;
  }

  Future<Map<String, ValidationFailure>> _validateEntries(
    Map<String, V> map, {
    bool skipPresence = false,
  }) async {
    final errors = <String, ValidationFailure>{};
    for (final entry in map.entries) {
      if (_keyValidator != null) {
        final savedLabel = _keyValidator!.label;
        _keyValidator!.setLabel(entry.key);
        final ValidationResult kr;
        try {
          kr = await _keyValidator!.validateAsync(entry.key);
        } finally {
          _keyValidator!.setLabel(savedLabel);
        }
        if (kr is ValidationFailure) {
          errors['[${entry.key}]'] = kr;
          continue;
        }
      }
      if (_valueValidator != null) {
        final savedLabel = _valueValidator!.label;
        _valueValidator!.setLabel(entry.key);
        final ValidationResult vr;
        try {
          vr = await _valueValidator!.validateAsync(
            entry.value,
            skipPresence: skipPresence,
          );
        } finally {
          _valueValidator!.setLabel(savedLabel);
        }
        if (vr is ValidationFailure) {
          errors['[${entry.key}]'] = vr;
        }
      }
    }
    return errors;
  }

  Map<String, ValidationFailure> _validateEntriesSync(
    Map<String, V> map, {
    bool skipPresence = false,
  }) {
    final errors = <String, ValidationFailure>{};
    for (final entry in map.entries) {
      if (_keyValidator != null) {
        final savedLabel = _keyValidator!.label;
        _keyValidator!.setLabel(entry.key);
        final ValidationResult kr;
        try {
          kr = _keyValidator!.validate(entry.key);
        } finally {
          _keyValidator!.setLabel(savedLabel);
        }
        if (kr is ValidationFailure) {
          errors['[${entry.key}]'] = kr;
          continue;
        }
      }
      if (_valueValidator != null) {
        final savedLabel = _valueValidator!.label;
        _valueValidator!.setLabel(entry.key);
        final ValidationResult vr;
        try {
          vr = _valueValidator!.validate(
            entry.value,
            skipPresence: skipPresence,
          );
        } finally {
          _valueValidator!.setLabel(savedLabel);
        }
        if (vr is ValidationFailure) {
          errors['[${entry.key}]'] = vr;
        }
      }
    }
    return errors;
  }
}
