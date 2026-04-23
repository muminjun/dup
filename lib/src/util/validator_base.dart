import '../model/message_factory.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'validate_locale.dart';

class _ValidatorEntry<T> {
  final int phase;
  final ValidationFailure? Function(T?) fn;
  const _ValidatorEntry(this.phase, this.fn);
}

abstract class BaseValidator<T, V extends BaseValidator<T, V>> {
  final List<_ValidatorEntry<T>> _entries = [];
  final List<Future<ValidationFailure?> Function(T?)> _asyncEntries = [];

  String label = '';

  V setLabel(String text) {
    label = text;
    return this as V;
  }

  bool get hasAsyncValidators => _asyncEntries.isNotEmpty;

  V addPhaseValidator(int phase, ValidationFailure? Function(T?) fn) {
    _entries.add(_ValidatorEntry(phase, fn));
    return this as V;
  }

  V addValidator(ValidationFailure? Function(T?) fn) => addPhaseValidator(3, fn);

  V addAsyncValidator(Future<ValidationFailure?> Function(T?) fn) {
    _asyncEntries.add(fn);
    return this as V;
  }

  V required({MessageFactory? messageFactory}) {
    return addPhaseValidator(0, (value) {
      if (value == null || (value is String && value.isEmpty)) {
        return getFailure(
          messageFactory,
          ValidationCode.required,
          {'name': label},
          '$label is required.',
        );
      }
      return null;
    });
  }

  V equalTo(T target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && value != target) {
        return getFailure(
          messageFactory,
          ValidationCode.equal,
          {'name': label},
          '$label does not match.',
        );
      }
      return null;
    });
  }

  V notEqualTo(T target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && value == target) {
        return getFailure(
          messageFactory,
          ValidationCode.notEqual,
          {'name': label},
          '$label is not allowed.',
        );
      }
      return null;
    });
  }

  V includedIn(List<T> allowedValues, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && !allowedValues.contains(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.oneOf,
          {'name': label, 'options': allowedValues.join(', ')},
          '$label must be one of: ${allowedValues.join(', ')}.',
        );
      }
      return null;
    });
  }

  V excludedFrom(List<T> forbiddenValues, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && forbiddenValues.contains(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.notOneOf,
          {'name': label, 'options': forbiddenValues.join(', ')},
          '$label must not be one of: ${forbiddenValues.join(', ')}.',
        );
      }
      return null;
    });
  }

  V satisfy(bool Function(T?) condition, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value == null) return null;
      if (!condition(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.condition,
          {'name': label},
          '$label does not satisfy the condition.',
        );
      }
      return null;
    });
  }

  ValidationResult validate(T? value) {
    final sorted = List<_ValidatorEntry<T>>.from(_entries)
      ..sort((a, b) => a.phase.compareTo(b.phase));
    for (final entry in sorted) {
      final failure = entry.fn(value);
      if (failure != null) return failure;
    }
    return const ValidationSuccess();
  }

  Future<ValidationResult> validateAsync(T? value) async {
    final syncResult = validate(value);
    if (syncResult is ValidationFailure) return syncResult;
    for (final fn in _asyncEntries) {
      final failure = await fn(value);
      if (failure != null) return failure;
    }
    return const ValidationSuccess();
  }

  /// Returns a sync adapter compatible with Flutter's TextFormField.validator.
  String? Function(T?) toValidator() {
    return (value) {
      final result = validate(value);
      return result is ValidationFailure ? result.message : null;
    };
  }

  /// Returns an async adapter for non-Flutter async contexts.
  /// NOT compatible with TextFormField.validator (which is synchronous).
  Future<String?> Function(T?) toAsyncValidator() {
    return (value) async {
      final result = await validateAsync(value);
      return result is ValidationFailure ? result.message : null;
    };
  }

  ValidationFailure getFailure(
    MessageFactory? customFactory,
    ValidationCode code,
    Map<String, dynamic> context,
    String defaultMessage,
  ) {
    final message = customFactory?.call(label, context) ??
        ValidatorLocale.current?.messages[code]?.call(context) ??
        defaultMessage;
    return ValidationFailure(code: code, message: message, context: context);
  }
}
