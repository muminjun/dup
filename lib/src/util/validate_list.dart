import 'package:dup/src/util/validate_locale.dart';
import 'package:dup/src/util/validator_base.dart';
import '../model/message_factory.dart';

/// Validator for lists of type [T].
class ValidateList<T> extends BaseValidator<List<T>, ValidateList<T>> {
  /// Validates that the list is not empty.
  ValidateList<T> isNotEmpty({MessageFactory? messageFactory}) {
    return addValidator((value) {
      if (value == null || value.isEmpty) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.array['notEmpty']?.call({
          'name': label,
        });
        if (global != null) return global;
        return '$label cannot be empty';
      }
      return null;
    });
  }

  /// Validates that the list is empty.
  ValidateList<T> isEmpty({MessageFactory? messageFactory}) {
    return addValidator((value) {
      if (value != null && value.isNotEmpty) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.array['empty']?.call({
          'name': label,
        });
        if (global != null) return global;
        return '$label must be empty';
      }
      return null;
    });
  }

  /// Validates that the list has a minimum length.
  ValidateList<T> minLength(int min, {MessageFactory? messageFactory}) {
    return addValidator((value) {
      if (value == null || value.length < min) {
        if (messageFactory != null) {
          return messageFactory(label, {'min': min});
        }
        final global = ValidatorLocale.current?.array['min']?.call({
          'name': label,
          'min': min,
        });
        if (global != null) return global;
        return '$label must have at least $min items';
      }
      return null;
    });
  }

  /// Validates that the list has a maximum length.
  ValidateList<T> maxLength(int max, {MessageFactory? messageFactory}) {
    return addValidator((value) {
      if (value != null && value.length > max) {
        if (messageFactory != null) {
          return messageFactory(label, {'max': max});
        }
        final global = ValidatorLocale.current?.array['max']?.call({
          'name': label,
          'max': max,
        });
        if (global != null) return global;
        return '$label cannot have more than $max items';
      }
      return null;
    });
  }

  /// Validates that the list length is within a range.
  ValidateList<T> lengthBetween(int min, int max, {MessageFactory? messageFactory}) {
    return addValidator((value) {
      if (value == null || value.length < min || value.length > max) {
        if (messageFactory != null) {
          return messageFactory(label, {'min': min, 'max': max});
        }
        final global = ValidatorLocale.current?.array['lengthBetween']?.call({
          'name': label,
          'min': min,
          'max': max,
        });
        if (global != null) return global;
        return '$label length must be between $min and $max';
      }
      return null;
    });
  }

  /// Validates that the list has an exact length.
  ValidateList<T> hasLength(int length, {MessageFactory? messageFactory}) {
    return addValidator((value) {
      if (value == null || value.length != length) {
        if (messageFactory != null) {
          return messageFactory(label, {'length': length});
        }
        final global = ValidatorLocale.current?.array['exactLength']?.call({
          'name': label,
          'length': length,
        });
        if (global != null) return global;
        return '$label must have exactly $length items';
      }
      return null;
    });
  }

  /// Validates that the list contains a specific item.
  ValidateList<T> contains(T item, {MessageFactory? messageFactory}) {
    return addValidator((value) {
      if (value == null || !value.contains(item)) {
        if (messageFactory != null) {
          return messageFactory(label, {'item': item});
        }
        final global = ValidatorLocale.current?.array['contains']?.call({
          'name': label,
          'item': item,
        });
        if (global != null) return global;
        return '$label must contain $item';
      }
      return null;
    });
  }

  /// Validates that the list does not contain a specific item.
  ValidateList<T> doesNotContain(T item, {MessageFactory? messageFactory}) {
    return addValidator((value) {
      if (value != null && value.contains(item)) {
        if (messageFactory != null) {
          return messageFactory(label, {'item': item});
        }
        final global = ValidatorLocale.current?.array['doesNotContain']?.call({
          'name': label,
          'item': item,
        });
        if (global != null) return global;
        return '$label must not contain $item';
      }
      return null;
    });
  }

  /// Validates that all items in the list satisfy a condition.
  ValidateList<T> all(bool Function(T) predicate, {MessageFactory? messageFactory}) {
    return addValidator((value) {
      if (value != null && !value.every(predicate)) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.array['allCondition']?.call({
          'name': label,
        });
        if (global != null) return global;
        return 'All items in $label must satisfy the condition';
      }
      return null;
    });
  }

  /// Validates that at least one item in the list satisfies a condition.
  ValidateList<T> any(bool Function(T) predicate, {MessageFactory? messageFactory}) {
    return addValidator((value) {
      if (value == null || !value.any(predicate)) {
        if (messageFactory != null) {
          return messageFactory(label, {});
        }
        final global = ValidatorLocale.current?.array['anyCondition']?.call({
          'name': label,
        });
        if (global != null) return global;
        return 'At least one item in $label must satisfy the condition';
      }
      return null;
    });
  }

  /// Validates that the list has no duplicate items.
  ValidateList<T> hasNoDuplicates({MessageFactory? messageFactory}) {
    return addValidator((value) {
      if (value != null) {
        final Set<T> uniqueItems = value.toSet();
        if (uniqueItems.length != value.length) {
          if (messageFactory != null) {
            return messageFactory(label, {});
          }
          final global = ValidatorLocale.current?.array['noDuplicates']?.call({
            'name': label,
          });
          if (global != null) return global;
          return '$label must not contain duplicate items';
        }
      }
      return null;
    });
  }

  /// Validates that each item in the list passes a custom validator.
  ValidateList<T> eachItem(String? Function(T) validator, {MessageFactory? messageFactory}) {
    return addValidator((value) {
      if (value != null) {
        for (int i = 0; i < value.length; i++) {
          final itemError = validator(value[i]);
          if (itemError != null) {
            if (messageFactory != null) {
              return messageFactory(label, {'index': i, 'error': itemError});
            }
            final global = ValidatorLocale.current?.array['eachItem']?.call({
              'name': label,
              'index': i,
              'error': itemError,
            });
            if (global != null) return global;
            return 'Item at index $i in $label: $itemError';
          }
        }
      }
      return null;
    });
  }
}
