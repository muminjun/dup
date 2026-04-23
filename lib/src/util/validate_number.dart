import '../model/message_factory.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'validator_base.dart';

/// 숫자([num]) 전용 검증기.
///
/// 모든 검증 메서드는 값이 null이면 자동으로 통과(null-skip)한다.
///
/// Flutter TextFormField와 연동할 때는 [toValidator]를 사용한다.
/// 이 메서드는 문자열 입력을 [num]으로 파싱한 뒤 검증하므로
/// 텍스트 필드의 문자열 입력을 그대로 전달할 수 있다.
///
/// ```dart
/// TextFormField(
///   validator: ValidateNumber().setLabel('나이').min(18).toValidator(),
/// )
/// ```
class ValidateNumber extends BaseValidator<num, ValidateNumber> {
  /// phase 2: 값이 [min] 미만이면 실패한다.
  ValidateNumber min(num min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value < min) {
        return getFailure(messageFactory, ValidationCode.numberMin,
            {'name': label, 'min': min}, '$label must be at least $min.');
      }
      return null;
    });
  }

  /// phase 2: 값이 [max] 초과면 실패한다.
  ValidateNumber max(num max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value > max) {
        return getFailure(messageFactory, ValidationCode.numberMax,
            {'name': label, 'max': max}, '$label must be at most $max.');
      }
      return null;
    });
  }

  /// phase 1: 소수점이 있으면 실패한다 (정수 여부 확인).
  ValidateNumber isInteger({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && value % 1 != 0) {
        return getFailure(messageFactory, ValidationCode.integer,
            {'name': label}, '$label must be an integer.');
      }
      return null;
    });
  }

  /// phase 2: 값이 0 이하이면 실패한다 (양수 여부 확인).
  ValidateNumber isPositive({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value <= 0) {
        return getFailure(messageFactory, ValidationCode.positive,
            {'name': label}, '$label must be positive.');
      }
      return null;
    });
  }

  /// phase 2: 값이 0 이상이면 실패한다 (음수 여부 확인).
  ValidateNumber isNegative({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value >= 0) {
        return getFailure(messageFactory, ValidationCode.negative,
            {'name': label}, '$label must be negative.');
      }
      return null;
    });
  }

  /// phase 2: 값이 0 미만이면 실패한다 (0 포함 양수 허용).
  ValidateNumber isNonNegative({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value < 0) {
        return getFailure(messageFactory, ValidationCode.nonNegative,
            {'name': label}, '$label must be zero or positive.');
      }
      return null;
    });
  }

  /// phase 2: 값이 0 초과면 실패한다 (0 포함 음수 허용).
  ValidateNumber isNonPositive({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value > 0) {
        return getFailure(messageFactory, ValidationCode.nonPositive,
            {'name': label}, '$label must be zero or negative.');
      }
      return null;
    });
  }

  /// phase 2: 값이 [min] ~ [max] 범위를 벗어나면 실패한다 (경계값 포함).
  ValidateNumber between(num min, num max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && (value < min || value > max)) {
        return getFailure(messageFactory, ValidationCode.between,
            {'name': label, 'min': min, 'max': max},
            '$label must be between $min and $max.');
      }
      return null;
    });
  }

  /// phase 2: 홀수이면 실패한다.
  ValidateNumber isEven({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value % 2 != 0) {
        return getFailure(messageFactory, ValidationCode.even,
            {'name': label}, '$label must be an even number.');
      }
      return null;
    });
  }

  /// phase 2: 짝수이면 실패한다.
  ValidateNumber isOdd({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value % 2 == 0) {
        return getFailure(messageFactory, ValidationCode.odd,
            {'name': label}, '$label must be an odd number.');
      }
      return null;
    });
  }

  /// phase 2: [factor]의 배수가 아니면 실패한다.
  ValidateNumber isMultipleOf(num factor, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value % factor != 0) {
        return getFailure(messageFactory, ValidationCode.multipleOf,
            {'name': label, 'factor': factor},
            '$label must be a multiple of $factor.');
      }
      return null;
    });
  }

  /// 문자열 입력을 [num]으로 파싱한 뒤 검증하는 TextFormField 호환 어댑터.
  ///
  /// - null 또는 빈 문자열: required 검증만 실행 (설정된 경우)
  /// - 숫자로 파싱 불가: [parseErrorMessage] 또는 기본 파싱 에러 반환
  /// - 파싱 성공: 숫자 검증 실행
  ///
  // Return type은 dynamic (String? 아님). Dart 타입 시스템 상 String? Function(String?)는
  // base class의 String? Function(num?) override로 허용되지 않기 때문.
  @override
  String? Function(dynamic) toValidator({String? parseErrorMessage}) {
    return (dynamic input) {
      if (input == null || (input is String && input.isEmpty)) {
        final result = validate(null);
        return result is ValidationFailure ? result.message : null;
      }
      final parsed = num.tryParse(input.toString());
      if (parsed == null) {
        return parseErrorMessage ?? '$label is not a valid number.';
      }
      final result = validate(parsed);
      return result is ValidationFailure ? result.message : null;
    };
  }
}
