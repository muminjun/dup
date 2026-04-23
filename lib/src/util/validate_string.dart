import '../model/message_factory.dart';
import '../model/validation_code.dart';
import 'validator_base.dart';

/// 문자열([String]) 전용 검증기.
///
/// 모든 검증 메서드는 값이 null이면 자동으로 통과(null-skip)한다.
/// null 체크가 필요하면 [required]를 체이닝한다.
///
/// ```dart
/// ValidateString()
///   .setLabel('이메일')
///   .email()
///   .required()
///   .validate(value);
/// ```
class ValidateString extends BaseValidator<String, ValidateString> {
  /// phase 2: 문자열 길이(공백 제거 후)가 [min] 미만이면 실패한다.
  ValidateString min(int min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.trim().length < min) {
        return getFailure(
          messageFactory,
          ValidationCode.stringMin,
          {'name': label, 'min': min},
          '$label must be at least $min characters.',
        );
      }
      return null;
    });
  }

  /// phase 2: 문자열 길이(공백 제거 후)가 [max] 초과면 실패한다.
  ValidateString max(int max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.trim().length > max) {
        return getFailure(
          messageFactory,
          ValidationCode.stringMax,
          {'name': label, 'max': max},
          '$label must be at most $max characters.',
        );
      }
      return null;
    });
  }

  /// phase 1: 값이 [regex]와 일치하지 않으면 실패한다. 공백 제거 후 검사.
  ValidateString matches(RegExp regex, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && !regex.hasMatch(value.trim())) {
        return getFailure(
          messageFactory,
          ValidationCode.matches,
          {'name': label},
          '$label does not match the required format.',
        );
      }
      return null;
    });
  }

  /// phase 1: 이메일 형식 검증. null이거나 빈 값이면 통과(null-skip).
  ValidateString email({MessageFactory? messageFactory}) {
    const emailRegex =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@'
        r'((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|'
        r'(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(emailRegex).hasMatch(value.trim())) {
        return getFailure(
          messageFactory,
          ValidationCode.emailInvalid,
          {'name': label},
          '$label is not a valid email address.',
        );
      }
      return null;
    });
  }

  /// phase 1: 비밀번호 최소 길이 검증. 기본 최소 길이는 4자.
  ValidateString password({int minLength = 4, MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (value.trim().length < minLength) {
        return getFailure(
          messageFactory,
          ValidationCode.passwordMin,
          {'name': label, 'minLength': minLength},
          '$label must be at least $minLength characters.',
        );
      }
      return null;
    });
  }

  /// phase 1: 이모지 문자가 포함되면 실패한다.
  ValidateString emoji({MessageFactory? messageFactory}) {
    final emojiRegex = RegExp(r'\p{Emoji_Presentation}', unicode: true);
    return addPhaseValidator(1, (value) {
      if (value != null && value.isNotEmpty && emojiRegex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.emoji, {
          'name': label,
        }, '$label cannot contain emoji.');
      }
      return null;
    });
  }

  /// phase 0: 값이 공백만으로 구성되면 실패한다. null은 통과.
  /// [required]와 함께 사용하면 null도 막을 수 있다.
  ValidateString notBlank({MessageFactory? messageFactory}) {
    return addPhaseValidator(0, (value) {
      if (value != null && value.trim().isEmpty) {
        return getFailure(messageFactory, ValidationCode.notBlank, {
          'name': label,
        }, '$label cannot be blank.');
      }
      return null;
    });
  }

  /// phase 1: 영문자(a-z, A-Z)만 허용한다. 숫자, 공백, 특수문자 포함 시 실패.
  ValidateString alpha({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value.trim())) {
        return getFailure(messageFactory, ValidationCode.alpha, {
          'name': label,
        }, '$label must contain only letters.');
      }
      return null;
    });
  }

  /// phase 1: 영문자와 숫자(a-z, A-Z, 0-9)만 허용한다.
  ValidateString alphanumeric({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
        return getFailure(
          messageFactory,
          ValidationCode.alphanumeric,
          {'name': label},
          '$label must contain only letters and numbers.',
        );
      }
      return null;
    });
  }

  /// phase 1: 숫자(0-9)만 허용한다. 소수점, 부호 포함 시 실패.
  ValidateString numeric({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
        return getFailure(
          messageFactory,
          ValidationCode.numeric,
          {'name': label},
          '$label must contain only digits.',
        );
      }
      return null;
    });
  }

  /// phase 1: 휴대폰 번호 형식 검증. 기본 패턴: `010-1234-5678`.
  /// [customRegex]로 패턴을 교체할 수 있다.
  ValidateString mobile({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^\d{2,3}-\d{3,4}-\d{4}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.mobileInvalid,
          {'name': label},
          '$label is not a valid mobile number.',
        );
      }
      return null;
    });
  }

  /// phase 1: 일반 전화번호 형식 검증. 기본 패턴: `02-1234-5678`.
  /// [customRegex]로 패턴을 교체할 수 있다.
  ValidateString phone({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^(0[2-9]{1}\d?)-\d{3,4}-\d{4}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.phoneInvalid,
          {'name': label},
          '$label is not a valid phone number.',
        );
      }
      return null;
    });
  }

  /// phase 1: 사업자등록번호 형식 검증. 기본 패턴: `123-45-67890`.
  /// [customRegex]로 패턴을 교체할 수 있다.
  ValidateString bizno({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^\d{3}-\d{2}-\d{5}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.biznoInvalid,
          {'name': label},
          '$label is not a valid business registration number.',
        );
      }
      return null;
    });
  }

  /// phase 1: HTTP/HTTPS URL 형식 검증.
  ValidateString url({MessageFactory? messageFactory}) {
    final regex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.url, {
          'name': label,
        }, '$label is not a valid URL.');
      }
      return null;
    });
  }

  /// phase 1: UUID v4 형식 검증 (대소문자 무관).
  ValidateString uuid({MessageFactory? messageFactory}) {
    final regex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.uuid, {
          'name': label,
        }, '$label is not a valid UUID.');
      }
      return null;
    });
  }
}
