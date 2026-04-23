import '../model/message_factory.dart';
import '../model/validation_code.dart';
import 'validator_base.dart';

/// 불리언([bool]) 전용 검증기.
///
/// null은 자동으로 통과(null-skip)한다.
/// null도 막으려면 [required]를 체이닝한다.
///
/// ```dart
/// ValidateBool()
///   .setLabel('이용약관 동의')
///   .isTrue()
///   .required()
///   .validate(agreed);
/// ```
class ValidateBool extends BaseValidator<bool, ValidateBool> {
  /// phase 1: 값이 true가 아니면 실패한다. null은 통과(null-skip).
  ValidateBool isTrue({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value != true) {
        return getFailure(messageFactory, ValidationCode.boolTrue, {
          'name': label,
        }, '$label must be true.');
      }
      return null;
    });
  }

  /// phase 1: 값이 false가 아니면 실패한다. null은 통과(null-skip).
  ValidateBool isFalse({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value != false) {
        return getFailure(messageFactory, ValidationCode.boolFalse, {
          'name': label,
        }, '$label must be false.');
      }
      return null;
    });
  }
}
