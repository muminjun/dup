import 'package:dup/src/util/validate_locale.dart';
import '../model/message_factory.dart';

/// Base abstract class for building validation rules with chainable methods.
/// [T] - Type of value being validated
/// [V] - Validator subclass type for method chaining
abstract class BaseValidator<T, V extends BaseValidator<T, V>> {
  /// List of validation functions that return error messages
  final List<String? Function(T? value)> validators = [];

  /// Field label used in error messages
  String label = '';

  /// Sets the display name for the field being validated
  V setLabel(String text) {
    label = text;
    return this as V;
  }

  /// Adds a custom validation function to the validator chain
  V addValidator(String? Function(T? value) validator) {
    validators.add(validator);
    return this as V;
  }

  /// Validates that the value matches the target value
  /// Message resolution order:
  /// 1. Custom message factory → 2. Global locale → 3. Default message
  V equalTo(T target, {MessageFactory? messageFactory}) {
    addValidator((value) {
      if (value != null && value != target) {
        return getErrorMessage(messageFactory, 'equal', {
          'name': label,
        }, '$label does not match.');
      }
      return null;
    });
    return this as V;
  }

  /// Validates that the value does NOT match the target value
  V notEqualTo(T target, {MessageFactory? messageFactory}) {
    addValidator((value) {
      if (value != null && value == target) {
        return getErrorMessage(messageFactory, 'notEqual', {
          'name': label,
        }, '$label is not allowed.');
      }
      return null;
    });
    return this as V;
  }

  /// Validates that the value exists in allowedValues list
  V includedIn(List<T> allowedValues, {MessageFactory? messageFactory}) {
    addValidator((value) {
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
    return this as V;
  }

  /// Validates that the value does NOT exist in forbiddenValues list
  V excludedFrom(List<T> forbiddenValues, {MessageFactory? messageFactory}) {
    addValidator((value) {
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
    return this as V;
  }

  /// Validates using a custom condition function
  V satisfy(bool Function(T?) condition, {MessageFactory? messageFactory}) {
    addValidator((value) {
      if (!condition(value)) {
        return getErrorMessage(messageFactory, 'condition', {
          'name': label,
        }, '$label does not satisfy the condition.');
      }
      return null;
    });
    return this as V;
  }

  /// Validates that the value is not null/empty
  V required({MessageFactory? messageFactory}) {
    addValidator((value) {
      if (value == null || (value is String && value.isEmpty)) {
        return getErrorMessage(messageFactory, 'required', {
          'name': label,
        }, '$label is required.');
      }
      return null;
    });
    return this as V;
  }

  /// Executes all validation rules and returns first error message
  String? validate(T? value) {
    for (var validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  /// Unified error message resolution logic
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
