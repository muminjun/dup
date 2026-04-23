import 'validation_result.dart';

/// 폼(스키마) 전체 검증 결과를 나타내는 sealed 클래스.
///
/// [DupSchema.validate] / [DupSchema.validateSync]의 반환 타입.
/// 성공이면 [FormValidationSuccess], 하나 이상의 필드가 실패하면 [FormValidationFailure].
///
/// ```dart
/// final result = await schema.validate(data);
/// switch (result) {
///   FormValidationSuccess() => submitForm(),
///   FormValidationFailure(:final errors) => showErrors(errors),
/// }
/// ```
sealed class FormValidationResult {
  const FormValidationResult();
}

/// 모든 필드가 검증을 통과했음을 나타낸다.
class FormValidationSuccess extends FormValidationResult {
  const FormValidationSuccess();
}

/// 하나 이상의 필드가 검증에 실패했음을 나타낸다.
///
/// [errors]는 필드명 → [ValidationFailure] 맵이다.
/// call() 연산자로 특정 필드의 에러를 조회할 수 있다.
class FormValidationFailure extends FormValidationResult {
  /// 필드별 실패 정보. 키는 스키마에서 사용한 필드명.
  final Map<String, ValidationFailure> errors;

  const FormValidationFailure(this.errors);

  /// 특정 필드의 [ValidationFailure]를 반환한다. 해당 필드가 없으면 null.
  ///
  /// ```dart
  /// final emailError = failure('email'); // ValidationFailure?
  /// ```
  ValidationFailure? call(String field) => errors[field];

  /// 특정 필드에 에러가 있는지 확인한다.
  bool hasError(String field) => errors.containsKey(field);

  /// 에러가 있는 모든 필드 이름 목록.
  List<String> get fields => errors.keys.toList();

  /// 에러가 있는 첫 번째 필드 이름. 에러가 없으면 null (정상적으로는 발생 안 함).
  String? get firstField => errors.keys.firstOrNull;
}
