import '../model/message_factory.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'validate_locale.dart';

/// Internal pairing of a phase number and a validator function.
/// Lower phase numbers execute first (0 = required, 1 = format, 2 = range,
/// 3 = custom, 4 = async).
class _ValidatorEntry<T> {
  final int phase;
  final int sortIndex;
  final ValidationFailure? Function(T?) fn;
  final bool isPresence;
  const _ValidatorEntry(
    this.phase,
    this.sortIndex,
    this.fn, {
    this.isPresence = false,
  });
}

/// Base class for all validators.
///
/// Uses F-bounded polymorphism (`V extends BaseValidator<T, V>`) so subclass
/// methods return the concrete subclass type, enabling fluent chaining without
/// manual casts.
///
/// **Execution order:**
/// 1. [validate] — runs sync phases 0–3 in phase order; stops at first failure.
/// 2. [validateAsync] — runs all sync phases first, then async entries in order.
///
/// **Null contract:** Phase 1+ validators must return null (pass) when value is
/// null. Null handling is the sole responsibility of phase 0 (`required`).
///
/// **Message priority:** messageFactory → [ValidatorLocale.current] → hardcoded default.
abstract class BaseValidator<T, V extends BaseValidator<T, V>> {
  final List<_ValidatorEntry<T>> _entries = [];
  final List<Future<ValidationFailure?> Function(T?)> _asyncEntries = [];
  // Safe after construction; not concurrent-safe if addPhaseValidator is called
  // while another isolate is running the phase chain.
  bool _sorted = false;

  /// Display label used in error messages. Set via [setLabel].
  String label = '';

  /// Sets the field label and returns the validator for chaining.
  V setLabel(String text) {
    label = text;
    return this as V;
  }

  /// True if at least one async validator has been registered via
  /// [addAsyncValidator]. Used by [DupSchema.validateSync] to guard against
  /// skipped async checks.
  bool get hasAsyncValidators => _asyncEntries.isNotEmpty;

  /// Registers a sync validator at the given [phase].
  /// Lower phase numbers run first; within the same phase, registration order
  /// is preserved.
  V addPhaseValidator(
    int phase,
    ValidationFailure? Function(T?) fn, {
    bool isPresence = false,
  }) {
    _entries.add(
      _ValidatorEntry(phase, _entries.length, fn, isPresence: isPresence),
    );
    _sorted = false;
    return this as V;
  }

  /// Registers a sync validator at phase 3 (custom).
  /// Return null to pass, [ValidationFailure] to fail.
  V addValidator(ValidationFailure? Function(T?) fn) =>
      addPhaseValidator(3, fn);

  /// Registers an async validator. Runs after all sync phases in [validateAsync].
  V addAsyncValidator(Future<ValidationFailure?> Function(T?) fn) {
    _asyncEntries.add(fn);
    return this as V;
  }

  /// Runs sync phase entries only. When [skipPresence] is true, entries
  /// registered with isPresence:true (i.e. required()) are skipped.
  ///
  /// Use [fromPhase] and [toPhase] to run only a subset of phases (inclusive).
  /// This allows callers to interleave entry validation between phase bands
  /// (e.g. run phases 0–1 first, then entry checks, then phases 2+).
  ValidationResult runPhaseChain(
    T? value, {
    bool skipPresence = false,
    int fromPhase = 0,
    int toPhase = 999,
  }) {
    if (!_sorted) {
      _entries.sort((a, b) {
        final c = a.phase.compareTo(b.phase);
        return c != 0 ? c : a.sortIndex.compareTo(b.sortIndex);
      });
      _sorted = true;
    }
    for (final entry in _entries) {
      if (entry.phase < fromPhase || entry.phase > toPhase) continue;
      if (skipPresence && entry.isPresence) continue;
      final failure = entry.fn(value);
      if (failure != null) return failure;
    }
    return const ValidationSuccess();
  }

  /// Runs async entries only. Returns the first failure or null.
  Future<ValidationFailure?> runAsyncChain(T? value) async {
    for (final fn in _asyncEntries) {
      final failure = await fn(value);
      if (failure != null) return failure;
    }
    return null;
  }

  /// Phase 0: fails when value is null or an empty string.
  /// Without this, null values silently pass all other phases.
  V required({MessageFactory? messageFactory}) {
    return addPhaseValidator(0, (value) {
      if (value == null || (value is String && value.isEmpty)) {
        return getFailure(messageFactory, ValidationCode.required, {
          'name': label,
        }, '$label is required.');
      }
      return null;
    }, isPresence: true);
  }

  /// Phase 3: fails when value does not equal [target].
  V equalTo(T target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && value != target) {
        return getFailure(messageFactory, ValidationCode.equal, {
          'name': label,
        }, '$label does not match.');
      }
      return null;
    });
  }

  /// Phase 3: fails when value equals [target].
  V notEqualTo(T target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && value == target) {
        return getFailure(messageFactory, ValidationCode.notEqual, {
          'name': label,
        }, '$label is not allowed.');
      }
      return null;
    });
  }

  /// Phase 3: fails when value is not in [allowedValues].
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

  /// Phase 3: fails when value is in [forbiddenValues].
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

  /// Phase 3: fails when [condition] returns false. Null values pass (null-skip).
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

  /// Runs all registered sync validators in phase order.
  /// Stops at the first [ValidationFailure] and returns it immediately.
  /// Returns [ValidationSuccess] if all pass.
  ValidationResult validate(T? value, {bool skipPresence = false}) {
    return runPhaseChain(value, skipPresence: skipPresence);
  }

  /// Runs sync phases first, then async validators in registration order.
  /// Short-circuits: if any sync phase fails the async entries are not executed.
  Future<ValidationResult> validateAsync(
    T? value, {
    bool skipPresence = false,
  }) async {
    final syncResult = runPhaseChain(value, skipPresence: skipPresence);
    if (syncResult is ValidationFailure) return syncResult;
    final asyncFailure = await runAsyncChain(value);
    return asyncFailure ?? const ValidationSuccess();
  }

  /// Returns a sync adapter compatible with Flutter's `TextFormField.validator`.
  /// Returns null on success, the error message string on failure.
  String? Function(T?) toValidator() {
    return (value) {
      final result = validate(value);
      return result is ValidationFailure ? result.message : null;
    };
  }

  /// Returns an async adapter for non-Flutter async contexts.
  /// NOT compatible with `TextFormField.validator` (which is synchronous).
  Future<String?> Function(T?) toAsyncValidator() {
    return (value) async {
      final result = await validateAsync(value);
      return result is ValidationFailure ? result.message : null;
    };
  }

  /// Resolves the error message using 3-level priority and builds a
  /// [ValidationFailure].
  ///
  /// Priority:
  /// 1. [customFactory] — messageFactory argument on the specific call
  /// 2. [ValidatorLocale.current] — global locale map lookup by [code]
  /// 3. [defaultMessage] — hardcoded English fallback in the validator body
  ValidationFailure getFailure(
    MessageFactory? customFactory,
    ValidationCode code,
    Map<String, dynamic> context,
    String defaultMessage,
  ) {
    final message =
        customFactory?.call(label, context) ??
        ValidatorLocale.current?.messages[code]?.call(context) ??
        defaultMessage;
    return ValidationFailure(code: code, message: message, context: context);
  }
}
