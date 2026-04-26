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
  ValidateMap<V> keyValidator(ValidateString validator) {
    _keyValidator = validator;
    return this;
  }

  /// Phase 1: applies [validator] to every map value.
  ValidateMap<V> valueValidator(BaseValidator<V, dynamic> validator) {
    _valueValidator = validator;
    return this;
  }

  @override
  ValidationResult validate(
    Map<String, V>? value, {
    bool skipPresence = false,
  }) {
    final chainResult = runPhaseChain(value, skipPresence: skipPresence);
    if (chainResult is ValidationFailure) return chainResult;
    if (value == null) return const ValidationSuccess();
    final entryErrors = _validateEntriesSync(value, skipPresence: skipPresence);
    if (entryErrors.isNotEmpty) return _entrySummary(entryErrors);
    return const ValidationSuccess();
  }

  @override
  Future<ValidationResult> validateAsync(
    Map<String, V>? value, {
    bool skipPresence = false,
  }) async {
    final chainResult = runPhaseChain(value, skipPresence: skipPresence);
    if (chainResult is ValidationFailure) return chainResult;
    final asyncFailure = await runAsyncChain(value);
    if (asyncFailure != null) return asyncFailure;
    if (value == null) return const ValidationSuccess();
    final entryErrors = await _validateEntries(
      value,
      skipPresence: skipPresence,
    );
    if (entryErrors.isNotEmpty) return _entrySummary(entryErrors);
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
  Future<NestedValidationResult?> validateNested(
    dynamic value, {
    bool skipPresence = false,
  }) async {
    final chainResult = runPhaseChain(
      value as Map<String, V>?,
      skipPresence: skipPresence,
    );
    if (chainResult is ValidationFailure) {
      return NestedNormalFailure(chainResult);
    }
    final asyncFailure = await runAsyncChain(value);
    if (asyncFailure != null) return NestedNormalFailure(asyncFailure);
    if (value == null) return null;
    final entryErrors = await _validateEntries(
      value,
      skipPresence: skipPresence,
    );
    if (entryErrors.isNotEmpty) {
      return NestedInnerFailure(entryErrors, separator: '');
    }
    return null;
  }

  @override
  NestedValidationResult? validateNestedSync(
    dynamic value, {
    bool skipPresence = false,
  }) {
    final chainResult = runPhaseChain(
      value as Map<String, V>?,
      skipPresence: skipPresence,
    );
    if (chainResult is ValidationFailure) {
      return NestedNormalFailure(chainResult);
    }
    if (value == null) return null;
    final entryErrors = _validateEntriesSync(value, skipPresence: skipPresence);
    if (entryErrors.isNotEmpty) {
      return NestedInnerFailure(entryErrors, separator: '');
    }
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
        final kr = await _keyValidator!.validateAsync(entry.key);
        _keyValidator!.setLabel(savedLabel);
        if (kr is ValidationFailure) {
          errors['[${entry.key}]'] = kr;
          continue;
        }
      }
      if (_valueValidator != null) {
        final savedLabel = _valueValidator!.label;
        _valueValidator!.setLabel(entry.key);
        final vr = await _valueValidator!.validateAsync(
          entry.value,
          skipPresence: skipPresence,
        );
        _valueValidator!.setLabel(savedLabel);
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
        final kr = _keyValidator!.validate(entry.key);
        _keyValidator!.setLabel(savedLabel);
        if (kr is ValidationFailure) {
          errors['[${entry.key}]'] = kr;
          continue;
        }
      }
      if (_valueValidator != null) {
        final savedLabel = _valueValidator!.label;
        _valueValidator!.setLabel(entry.key);
        final vr = _valueValidator!.validate(
          entry.value,
          skipPresence: skipPresence,
        );
        _valueValidator!.setLabel(savedLabel);
        if (vr is ValidationFailure) {
          errors['[${entry.key}]'] = vr;
        }
      }
    }
    return errors;
  }
}
