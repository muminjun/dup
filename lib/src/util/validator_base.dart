/// Abstract base class for validators.
abstract class BaseValidator<T, V extends BaseValidator<T, V>> {
  final List<Function(T?)> validators = [];
  String label = 'Field';

  /// Sets the label for error messages.
  V setLabel(String text) {
    label = text;
    return this as V;
  }

  /// Checks if the value is equal to [target].
  V equalTo(T target, [String? message]) {
    return addValidator((value) {
      if (value != null && value != target) {
        return message ?? '$label does not match.';
      }
      return null;
    });
  }

  /// Checks if the value is not equal to [target].
  V notEqualTo(T target, [String? message]) {
    return addValidator((value) {
      if (value != null && value == target) {
        return message ?? '$label must be different from the previous value.';
      }
      return null;
    });
  }

  /// Checks if the value is included in [allowedValues].
  V includedIn(List<T> allowedValues, [String? message]) {
    return addValidator((value) {
      if (value != null && !allowedValues.contains(value)) {
        return message ??
            'You must select one of the allowed values for $label.';
      }
      return null;
    });
  }

  /// Checks if the value is excluded from [forbiddenValues].
  V excludedFrom(List<T> forbiddenValues, [String? message]) {
    return addValidator((value) {
      if (value != null && forbiddenValues.contains(value)) {
        return message ?? 'You cannot use a forbidden value for $label.';
      }
      return null;
    });
  }

  /// Checks if the value satisfies the given [condition].
  V satisfy(bool Function(T?) condition, [String? message]) {
    return addValidator((value) {
      if (!condition(value)) {
        return message ?? '$label does not satisfy the required condition.';
      }
      return null;
    });
  }

  /// Adds a custom validator function.
  V addValidator(Function(T?) validator) {
    validators.add(validator);
    return this as V;
  }

  /// Checks if the value is required (not null or empty).
  V required([String? message]) {
    return addValidator((value) {
      if (value == null || (value is String && value.isEmpty)) {
        return message ?? '$label is required.';
      }
      return null;
    });
  }

  /// Runs all validators and returns the first error message, or null if valid.
  String? validate(T? value) {
    for (var validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}
