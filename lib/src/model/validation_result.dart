import 'validation_code.dart';

/// 단일 필드 검증 결과를 나타내는 sealed 클래스.
///
/// [validate] / [validateAsync]의 반환 타입으로, 검증이 성공이면 [ValidationSuccess],
/// 실패이면 [ValidationFailure]가 반환된다. sealed이므로 switch 문에서 exhaustive 처리 가능.
///
/// ```dart
/// final result = ValidateString().email().validate(input);
/// switch (result) {
///   ValidationSuccess() => print('ok'),
///   ValidationFailure(:final message) => print(message),
/// }
/// ```
sealed class ValidationResult {
  const ValidationResult();
}

/// 검증 성공을 나타낸다. 값이 없는 불변 객체로, const 생성자로 재사용된다.
class ValidationSuccess extends ValidationResult {
  const ValidationSuccess();
}

/// 검증 실패를 나타낸다. 실패 원인 코드, 메시지, 컨텍스트를 포함한다.
class ValidationFailure extends ValidationResult {
  /// 실패 원인을 분류하는 코드. [ValidatorLocale] 메시지 조회 키로도 사용된다.
  final ValidationCode code;

  /// [ValidationCode.custom] 사용 시 세부 분류를 위한 선택적 태그.
  final String? customCode;

  /// 검증 시점에 확정된 에러 메시지 스냅샷.
  /// messageFactory → locale → 기본값 우선순위로 결정된다.
  final String message;

  /// 메시지 생성에 사용된 파라미터 (예: {name: 'Email', min: 3}).
  /// locale messageFactory에서 동적 메시지를 만들 때 전달된다.
  final Map<String, dynamic> context;

  const ValidationFailure({
    required this.code,
    this.customCode,
    required this.message,
    this.context = const {},
  });
}
