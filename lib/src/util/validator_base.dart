import '../model/message_factory.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'validate_locale.dart';

/// phase 번호와 검증 함수를 쌍으로 묶는 내부 엔트리.
/// phase 값이 낮을수록 먼저 실행된다 (0 = required, 1 = 형식, 2 = 범위, 3 = 커스텀, 4 = 비동기).
class _ValidatorEntry<T> {
  final int phase;
  final ValidationFailure? Function(T?) fn;
  const _ValidatorEntry(this.phase, this.fn);
}

/// 모든 검증기의 공통 기반 클래스.
///
/// F-bounded 다형성(`V extends BaseValidator<T, V>`)으로 서브클래스 메서드가
/// 구체 타입을 반환하므로 체이닝 시 타입 캐스팅이 필요 없다.
///
/// **실행 흐름:**
/// 1. [validate] — 동기 phase 0 ~ 3를 phase 순서로 실행. 첫 실패에서 중단.
/// 2. [validateAsync] — 동기 phase를 먼저 실행한 뒤 async 엔트리를 순서대로 실행.
///
/// **null 계약:** phase 1+ 검증기는 value가 null이면 null(통과)을 반환해야 한다.
/// null 처리는 phase 0 (`required`)의 전담 역할이다.
///
/// **메시지 우선순위:** messageFactory → [ValidatorLocale.current] → 하드코딩 기본값.
abstract class BaseValidator<T, V extends BaseValidator<T, V>> {
  final List<_ValidatorEntry<T>> _entries = [];
  final List<Future<ValidationFailure?> Function(T?)> _asyncEntries = [];

  /// 에러 메시지에 사용되는 필드 레이블. [setLabel]로 설정한다.
  String label = '';

  /// 필드 레이블을 설정하고 자신을 반환해 체이닝을 유지한다.
  V setLabel(String text) {
    label = text;
    return this as V;
  }

  /// async 검증기([addAsyncValidator])가 하나라도 등록되어 있으면 true.
  /// [DupSchema.validateSync]에서 async 검증기 존재 여부를 확인할 때 사용된다.
  bool get hasAsyncValidators => _asyncEntries.isNotEmpty;

  /// 특정 phase에 동기 검증 함수를 등록한다.
  /// phase 번호가 낮을수록 먼저 실행된다. 같은 phase 내 순서는 등록 순서를 따른다.
  V addPhaseValidator(int phase, ValidationFailure? Function(T?) fn) {
    _entries.add(_ValidatorEntry(phase, fn));
    return this as V;
  }

  /// phase 3(커스텀)에 동기 검증 함수를 등록한다.
  /// 반환값이 null이면 통과, [ValidationFailure]면 실패.
  V addValidator(ValidationFailure? Function(T?) fn) =>
      addPhaseValidator(3, fn);

  /// 비동기 검증 함수를 등록한다.
  /// [validateAsync] 호출 시 모든 동기 phase 이후에 순서대로 실행된다.
  V addAsyncValidator(Future<ValidationFailure?> Function(T?) fn) {
    _asyncEntries.add(fn);
    return this as V;
  }

  /// phase 0: 값이 null이거나 빈 문자열이면 실패한다.
  /// 이 검증기가 없으면 null은 자동으로 통과(null-skip)된다.
  V required({MessageFactory? messageFactory}) {
    return addPhaseValidator(0, (value) {
      if (value == null || (value is String && value.isEmpty)) {
        return getFailure(messageFactory, ValidationCode.required, {
          'name': label,
        }, '$label is required.');
      }
      return null;
    });
  }

  /// phase 3: 값이 [target]과 다르면 실패한다.
  V equalTo(T target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && value != target) {
        return getFailure(messageFactory, ValidationCode.equal, {
          'name': label,
        }, '$label does not match.');
      }
      return null;
    });
  }

  /// phase 3: 값이 [target]과 같으면 실패한다.
  V notEqualTo(T target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && value == target) {
        return getFailure(messageFactory, ValidationCode.notEqual, {
          'name': label,
        }, '$label is not allowed.');
      }
      return null;
    });
  }

  /// phase 3: 값이 [allowedValues] 목록에 없으면 실패한다.
  V includedIn(List<T> allowedValues, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && !allowedValues.contains(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.oneOf,
          {'name': label, 'options': allowedValues.join(', ')},
          '$label must be one of: ${allowedValues.join(', ')}.',
        );
      }
      return null;
    });
  }

  /// phase 3: 값이 [forbiddenValues] 목록에 포함되면 실패한다.
  V excludedFrom(List<T> forbiddenValues, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && forbiddenValues.contains(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.notOneOf,
          {'name': label, 'options': forbiddenValues.join(', ')},
          '$label must not be one of: ${forbiddenValues.join(', ')}.',
        );
      }
      return null;
    });
  }

  /// phase 3: [condition]이 false를 반환하면 실패한다. null은 통과(null-skip).
  V satisfy(bool Function(T?) condition, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value == null) return null;
      if (!condition(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.condition,
          {'name': label},
          '$label does not satisfy the condition.',
        );
      }
      return null;
    });
  }

  /// 등록된 모든 동기 검증기를 phase 순서로 실행한다.
  /// 첫 번째 실패([ValidationFailure])에서 즉시 중단하고 반환한다.
  /// 모두 통과하면 [ValidationSuccess]를 반환한다.
  ValidationResult validate(T? value) {
    final sorted = List<_ValidatorEntry<T>>.from(_entries)
      ..sort((a, b) => a.phase.compareTo(b.phase));
    for (final entry in sorted) {
      final failure = entry.fn(value);
      if (failure != null) return failure;
    }
    return const ValidationSuccess();
  }

  /// 동기 검증 → async 검증 순서로 실행한다.
  /// 동기 단계에서 실패하면 async 검증기는 실행되지 않는다.
  Future<ValidationResult> validateAsync(T? value) async {
    final syncResult = validate(value);
    if (syncResult is ValidationFailure) return syncResult;
    for (final fn in _asyncEntries) {
      final failure = await fn(value);
      if (failure != null) return failure;
    }
    return const ValidationSuccess();
  }

  /// Flutter의 [TextFormField.validator]와 호환되는 동기 어댑터를 반환한다.
  /// 성공이면 null, 실패이면 에러 메시지 문자열을 반환한다.
  String? Function(T?) toValidator() {
    return (value) {
      final result = validate(value);
      return result is ValidationFailure ? result.message : null;
    };
  }

  /// 비동기 컨텍스트용 어댑터를 반환한다.
  /// [TextFormField.validator]는 동기만 지원하므로 Flutter 폼에는 사용할 수 없다.
  Future<String?> Function(T?) toAsyncValidator() {
    return (value) async {
      final result = await validateAsync(value);
      return result is ValidationFailure ? result.message : null;
    };
  }

  /// 에러 메시지를 3단계 우선순위로 결정하고 [ValidationFailure]를 생성한다.
  ///
  /// 1. [customFactory] — 해당 검증기 호출 시 직접 전달한 메시지 팩토리
  /// 2. [ValidatorLocale.current] — 전역 로케일에 등록된 메시지
  /// 3. [defaultMessage] — 파일에 하드코딩된 영문 기본값
  ValidationFailure getFailure(
    MessageFactory? customFactory,
    ValidationCode code,
    Map<String, dynamic> context,
    String defaultMessage,
  ) {
    final message =
        customFactory?.call(label, context) ??
        ValidatorLocale.current?.messages[code]?.call(context) ??
        defaultMessage;
    return ValidationFailure(code: code, message: message, context: context);
  }
}
