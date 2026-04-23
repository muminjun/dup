import '../model/message_factory.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'validator_base.dart';

/// Validator for [List<T>] values.
///
/// All methods null-skip (return null / pass when value is null), except
/// [isNotEmpty] which treats null as empty and fails.
///
/// Use [eachItem] to validate individual list elements:
///
/// ```dart
/// ValidateList<String>()
///   .setLabel('Tags')
///   .minLength(1)
///   .maxLength(5)
///   .eachItem((tag) => tag.length > 20
///       ? const ValidationFailure(code: ValidationCode.custom, message: 'Tag too long')
///       : null)
///   .validate(tags);
/// ```
class ValidateList<T> extends BaseValidator<List<T>, ValidateList<T>> {
  /// Phase 1: fails when the list is null or empty.
  ValidateList<T> isNotEmpty({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && value.isEmpty) {
        return getFailure(messageFactory, ValidationCode.listNotEmpty, {
          'name': label,
        }, '$label cannot be empty.');
      }
      return null;
    });
  }

  /// Phase 1: fails when the list contains any items (only an empty list passes).
  ValidateList<T> isEmpty({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && value.isNotEmpty) {
        return getFailure(messageFactory, ValidationCode.listEmpty, {
          'name': label,
        }, '$label must be empty.');
      }
      return null;
    });
  }

  /// Phase 2: fails when the item count is less than [min].
  ValidateList<T> minLength(int min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.length < min) {
        return getFailure(
          messageFactory,
          ValidationCode.listMin,
          {'name': label, 'min': min},
          '$label must have at least $min items.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when the item count exceeds [max].
  ValidateList<T> maxLength(int max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.length > max) {
        return getFailure(
          messageFactory,
          ValidationCode.listMax,
          {'name': label, 'max': max},
          '$label cannot have more than $max items.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when the item count is outside the inclusive range [[min], [max]].
  ValidateList<T> lengthBetween(
    int min,
    int max, {
    MessageFactory? messageFactory,
  }) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.length < min || value.length > max) {
        return getFailure(
          messageFactory,
          ValidationCode.listLengthBetween,
          {'name': label, 'min': min, 'max': max},
          '$label length must be between $min and $max.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when the item count is not exactly [length].
  ValidateList<T> hasLength(int length, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.length != length) {
        return getFailure(
          messageFactory,
          ValidationCode.listExactLength,
          {'name': label, 'length': length},
          '$label must have exactly $length items.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when [item] is not present in the list. Null fails.
  ValidateList<T> contains(T item, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && !value.contains(item)) {
        return getFailure(messageFactory, ValidationCode.contains, {
          'name': label,
          'item': item,
        }, '$label must contain $item.');
      }
      return null;
    });
  }

  /// Phase 2: fails when [item] is present in the list.
  ValidateList<T> doesNotContain(T item, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.contains(item)) {
        return getFailure(
          messageFactory,
          ValidationCode.doesNotContain,
          {'name': label, 'item': item},
          '$label must not contain $item.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when any item does not satisfy [predicate].
  ValidateList<T> all(
    bool Function(T) predicate, {
    MessageFactory? messageFactory,
  }) {
    return addPhaseValidator(2, (value) {
      if (value != null && !value.every(predicate)) {
        return getFailure(
          messageFactory,
          ValidationCode.all,
          {'name': label},
          'All items in $label must satisfy the condition.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when no items satisfy [predicate].
  ValidateList<T> any(
    bool Function(T) predicate, {
    MessageFactory? messageFactory,
  }) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (!value.any(predicate)) {
        return getFailure(
          messageFactory,
          ValidationCode.any,
          {'name': label},
          'At least one item in $label must satisfy the condition.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when any item satisfies [predicate].
  ValidateList<T> none(
    bool Function(T) predicate, {
    MessageFactory? messageFactory,
  }) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.any(predicate)) {
        return getFailure(
          messageFactory,
          ValidationCode.none,
          {'name': label},
          'No items in $label must satisfy the condition.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when the list contains duplicate items.
  ValidateList<T> hasNoDuplicates({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.toSet().length != value.length) {
        return getFailure(
          messageFactory,
          ValidationCode.noDuplicates,
          {'name': label},
          '$label must not contain duplicate items.',
        );
      }
      return null;
    });
  }

  /// Phase 2: validates each item with [itemValidator], stopping at the first failure.
  ///
  /// [itemValidator] must return [ValidationFailure] on failure or null to pass.
  /// The resulting failure includes `context['index']` with the failing item's index.
  ValidateList<T> eachItem(
    ValidationFailure? Function(T) itemValidator, {
    MessageFactory? messageFactory,
  }) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      for (int i = 0; i < value.length; i++) {
        final failure = itemValidator(value[i]);
        if (failure != null) {
          final msg =
              messageFactory?.call(label, {
                'index': i,
                'error': failure.message,
              }) ??
              getFailure(
                null,
                ValidationCode.eachItem,
                {'name': label, 'index': i, 'error': failure.message},
                'Item at index $i in $label: ${failure.message}',
              ).message;
          return ValidationFailure(
            code: ValidationCode.eachItem,
            message: msg,
            context: {'name': label, 'index': i, 'innerFailure': failure},
          );
        }
      }
      return null;
    });
  }
}
