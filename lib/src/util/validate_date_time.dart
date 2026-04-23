import '../model/message_factory.dart';
import '../model/validation_code.dart';
import 'validator_base.dart';

/// 날짜/시간([DateTime]) 전용 검증기.
///
/// 모든 검증 메서드는 값이 null이면 자동으로 통과(null-skip)한다.
///
/// ```dart
/// ValidateDateTime()
///   .setLabel('생년월일')
///   .min(DateTime(1900))
///   .isInPast()
///   .required()
///   .validate(birthDate);
/// ```
class ValidateDateTime extends BaseValidator<DateTime, ValidateDateTime> {
  /// phase 1: 값이 [target] 이전이 아니면 실패한다 (즉, [target] 이후이거나 같으면 실패).
  ValidateDateTime isBefore(DateTime target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (!value.isBefore(target)) {
        return getFailure(
          messageFactory,
          ValidationCode.dateBefore,
          {'name': label, 'target': target},
          '$label must be before $target.',
        );
      }
      return null;
    });
  }

  /// phase 1: 값이 [target] 이후가 아니면 실패한다 (즉, [target] 이전이거나 같으면 실패).
  ValidateDateTime isAfter(DateTime target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (!value.isAfter(target)) {
        return getFailure(messageFactory, ValidationCode.dateAfter, {
          'name': label,
          'target': target,
        }, '$label must be after $target.');
      }
      return null;
    });
  }

  /// phase 2: 값이 [min] 이전이면 실패한다 (최소 날짜 이후여야 함).
  ValidateDateTime min(DateTime min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isBefore(min)) {
        return getFailure(
          messageFactory,
          ValidationCode.dateMin,
          {'name': label, 'min': min},
          '$label must be on or after $min.',
        );
      }
      return null;
    });
  }

  /// phase 2: 값이 [max] 이후이면 실패한다 (최대 날짜 이전이어야 함).
  ValidateDateTime max(DateTime max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isAfter(max)) {
        return getFailure(
          messageFactory,
          ValidationCode.dateMax,
          {'name': label, 'max': max},
          '$label must be on or before $max.',
        );
      }
      return null;
    });
  }

  /// phase 2: 값이 [min] ~ [max] 범위를 벗어나면 실패한다 (경계값 포함).
  ValidateDateTime between(
    DateTime min,
    DateTime max, {
    MessageFactory? messageFactory,
  }) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isBefore(min) || value.isAfter(max)) {
        return getFailure(
          messageFactory,
          ValidationCode.dateBetween,
          {'name': label, 'min': min, 'max': max},
          '$label must be between $min and $max.',
        );
      }
      return null;
    });
  }

  /// phase 2: 값이 현재 시각 이전이거나 같으면 실패한다 (미래 날짜만 허용).
  ValidateDateTime isInFuture({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (!value.isAfter(DateTime.now())) {
        return getFailure(
          messageFactory,
          ValidationCode.dateInFuture,
          {'name': label},
          '$label must be in the future.',
        );
      }
      return null;
    });
  }

  /// phase 2: 값이 현재 시각 이후이거나 같으면 실패한다 (과거 날짜만 허용).
  ValidateDateTime isInPast({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (!value.isBefore(DateTime.now())) {
        return getFailure(messageFactory, ValidationCode.dateInPast, {
          'name': label,
        }, '$label must be in the past.');
      }
      return null;
    });
  }
}
