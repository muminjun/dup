import '../model/message_factory.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'validator_base.dart';

/// 리스트([List<T>]) 전용 검증기.
///
/// 모든 검증 메서드는 값이 null이면 자동으로 통과(null-skip)한다.
/// 단, [isNotEmpty]는 null도 실패로 처리한다 (null = "비어 있음"으로 간주).
///
/// [eachItem]으로 리스트 내 개별 아이템을 검증할 수 있다.
///
/// ```dart
/// ValidateList<String>()
///   .setLabel('태그')
///   .minLength(1)
///   .maxLength(5)
///   .eachItem((tag) => tag.length > 20
///       ? ValidationFailure(code: ValidationCode.custom, message: '태그는 20자 이하')
///       : null)
///   .validate(tags);
/// ```
class ValidateList<T> extends BaseValidator<List<T>, ValidateList<T>> {
  /// phase 1: 리스트가 null이거나 비어 있으면 실패한다.
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

  /// phase 1: 리스트에 아이템이 있으면 실패한다 (빈 리스트만 허용).
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

  /// phase 2: 아이템 수가 [min] 미만이면 실패한다.
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

  /// phase 2: 아이템 수가 [max] 초과면 실패한다.
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

  /// phase 2: 아이템 수가 [min] ~ [max] 범위를 벗어나면 실패한다.
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

  /// phase 2: 아이템 수가 정확히 [length]가 아니면 실패한다.
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

  /// phase 2: 리스트에 [item]이 없으면 실패한다. null이면 실패.
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

  /// phase 2: 리스트에 [item]이 있으면 실패한다.
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

  /// phase 2: 모든 아이템이 [predicate]를 만족하지 않으면 실패한다.
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

  /// phase 2: [predicate]를 만족하는 아이템이 하나도 없으면 실패한다.
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

  /// phase 2: [predicate]를 만족하는 아이템이 하나라도 있으면 실패한다.
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

  /// phase 2: 리스트에 중복 아이템이 있으면 실패한다.
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

  /// phase 2: 각 아이템을 [itemValidator]로 검증하고, 첫 번째 실패 아이템에서 중단한다.
  ///
  /// [itemValidator]는 [ValidationFailure]를 반환하거나 통과 시 null을 반환해야 한다.
  /// 실패 시 [ValidationFailure.context]의 `index`에 실패한 아이템의 인덱스가 포함된다.
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
