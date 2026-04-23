import 'package:dup/src/util/validate_locale.dart';
import '../model/message_factory.dart';

class _ValidatorEntry<T> {
  final int phase;
  final String? Function(T?) fn;
  const _ValidatorEntry(this.phase, this.fn);
}

abstract class BaseValidator<T, V extends BaseValidator<T, V>> {
  final List<_ValidatorEntry<T>> _entries = [];
  final List<Future<String?> Function(T?)> _asyncEntries = [];

  String label = '';

  V setLabel(String text) {
    label = text;
    return this as V;
  }

  V addPhaseValidator(int phase, String? Function(T?) fn) {
    _entries.add(_ValidatorEntry(phase, fn));
    return this as V;
  }

  V addValidator(String? Function(T?) fn) => addPhaseValidator(3, fn);

  V addAsyncValidator(Future<String?> Function(T?) fn) {
    _asyncEntries.add(fn);
    return this as V;
  }

  V required({MessageFactory? messageFactory}) {
    return addPhaseValidator(0, (value) {
      if (value == null || (value is String && value.isEmpty)) {
        return getErrorMessage(
          messageFactory, 'required', {'name': label}, '$label is required.',
        );
      }
      return null;
    });
  }

  V equalTo(T target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && value != target) {
        return getErrorMessage(
          messageFactory, 'equal', {'name': label}, '$label does not match.',
        );
      }
      return null;
    });
  }

  V notEqualTo(T target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && value == target) {
        return getErrorMessage(
          messageFactory, 'notEqual', {'name': label}, '$label is not allowed.',
        );
      }
      return null;
    });
  }

  V includedIn(List<T> allowedValues, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && !allowedValues.contains(value)) {
        return getErrorMessage(
          messageFactory,
          'oneOf',
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
        return getErrorMessage(
          messageFactory,
          'notOneOf',
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
        return getErrorMessage(
          messageFactory, 'condition', {'name': label}, '$label does not satisfy the condition.',
        );
      }
      return null;
    });
  }

  String? validate(T? value) {
    final sorted = List<_ValidatorEntry<T>>.from(_entries)
      ..sort((a, b) => a.phase.compareTo(b.phase));
    for (final entry in sorted) {
      final error = entry.fn(value);
      if (error != null) return error;
    }
    return null;
  }

  Future<String?> validateAsync(T? value) async {
    final syncError = validate(value);
    if (syncError != null) return syncError;
    for (final fn in _asyncEntries) {
      final error = await fn(value);
      if (error != null) return error;
    }
    return null;
  }

  String? getErrorMessage(
    MessageFactory? customFactory,
    String messageKey,
    Map<String, dynamic> params,
    String defaultMessage,
  ) {
    return customFactory?.call(label, params) ??
        ValidatorLocale.current?.mixed[messageKey]?.call(params) ??
        defaultMessage;
  }
}
