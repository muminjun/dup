import 'package:dup/src/util/validate_locale.dart';
import 'package:dup/src/util/validator_base.dart';
import '../model/message_factory.dart';

class ValidateList<T> extends BaseValidator<List<T>, ValidateList<T>> {
  ValidateList<T> isNotEmpty({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.array['notEmpty']
            ?.call({'name': label});
        if (global != null) return global;
        return '$label cannot be empty.';
      }
      return null;
    });
  }

  ValidateList<T> isEmpty({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && value.isNotEmpty) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.array['empty']
            ?.call({'name': label});
        if (global != null) return global;
        return '$label must be empty.';
      }
      return null;
    });
  }

  ValidateList<T> minLength(int min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.length < min) {
        if (messageFactory != null) return messageFactory(label, {'min': min});
        final global = ValidatorLocale.current?.array['min']
            ?.call({'name': label, 'min': min});
        if (global != null) return global;
        return '$label must have at least $min items.';
      }
      return null;
    });
  }

  ValidateList<T> maxLength(int max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.length > max) {
        if (messageFactory != null) return messageFactory(label, {'max': max});
        final global = ValidatorLocale.current?.array['max']
            ?.call({'name': label, 'max': max});
        if (global != null) return global;
        return '$label cannot have more than $max items.';
      }
      return null;
    });
  }

  ValidateList<T> lengthBetween(int min, int max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null || value.length < min || value.length > max) {
        if (messageFactory != null) {
          return messageFactory(label, {'min': min, 'max': max});
        }
        final global = ValidatorLocale.current?.array['lengthBetween']
            ?.call({'name': label, 'min': min, 'max': max});
        if (global != null) return global;
        return '$label length must be between $min and $max.';
      }
      return null;
    });
  }

  ValidateList<T> hasLength(int length, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.length != length) {
        if (messageFactory != null) {
          return messageFactory(label, {'length': length});
        }
        final global = ValidatorLocale.current?.array['exactLength']
            ?.call({'name': label, 'length': length});
        if (global != null) return global;
        return '$label must have exactly $length items.';
      }
      return null;
    });
  }

  ValidateList<T> contains(T item, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null || !value.contains(item)) {
        if (messageFactory != null) return messageFactory(label, {'item': item});
        final global = ValidatorLocale.current?.array['contains']
            ?.call({'name': label, 'item': item});
        if (global != null) return global;
        return '$label must contain $item.';
      }
      return null;
    });
  }

  ValidateList<T> doesNotContain(T item, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.contains(item)) {
        if (messageFactory != null) return messageFactory(label, {'item': item});
        final global = ValidatorLocale.current?.array['doesNotContain']
            ?.call({'name': label, 'item': item});
        if (global != null) return global;
        return '$label must not contain $item.';
      }
      return null;
    });
  }

  ValidateList<T> all(bool Function(T) predicate, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && !value.every(predicate)) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.array['allCondition']
            ?.call({'name': label});
        if (global != null) return global;
        return 'All items in $label must satisfy the condition.';
      }
      return null;
    });
  }

  ValidateList<T> any(bool Function(T) predicate, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (!value.any(predicate)) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.array['anyCondition']
            ?.call({'name': label});
        if (global != null) return global;
        return 'At least one item in $label must satisfy the condition.';
      }
      return null;
    });
  }

  ValidateList<T> hasNoDuplicates({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.toSet().length != value.length) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.array['noDuplicates']
            ?.call({'name': label});
        if (global != null) return global;
        return '$label must not contain duplicate items.';
      }
      return null;
    });
  }

  ValidateList<T> eachItem(
    String? Function(T) validator, {
    MessageFactory? messageFactory,
  }) {
    return addPhaseValidator(2, (value) {
      if (value != null) {
        for (int i = 0; i < value.length; i++) {
          final itemError = validator(value[i]);
          if (itemError != null) {
            if (messageFactory != null) {
              return messageFactory(label, {'index': i, 'error': itemError});
            }
            final global = ValidatorLocale.current?.array['eachItem']
                ?.call({'name': label, 'index': i, 'error': itemError});
            if (global != null) return global;
            return 'Item at index $i in $label: $itemError';
          }
        }
      }
      return null;
    });
  }
}
