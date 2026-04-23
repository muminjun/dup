import '../model/form_validation_result.dart';
import '../model/validation_result.dart';
import 'validator_base.dart';

/// 여러 필드의 검증기를 하나로 묶어 폼 전체를 검증하는 스키마 클래스.
///
/// [BaseValidatorSchema] + [UiFormService]를 단일 클래스로 통합한 v2 API.
///
/// **기본 사용법:**
/// ```dart
/// final schema = DupSchema({
///   'email': ValidateString().email().required(),
///   'age': ValidateNumber().min(18).required(),
/// });
///
/// final result = await schema.validate(formData);
/// if (result is FormValidationFailure) {
///   print(result('email')?.message);
/// }
/// ```
///
/// **레이블 커스터마이징:**
/// ```dart
/// DupSchema(
///   {'passwordConfirm': ValidateString().required()},
///   labels: {'passwordConfirm': '비밀번호 확인'},
/// )
/// ```
/// labels 맵에 없는 필드는 스키마 키 이름이 레이블로 사용된다.
///
/// **교차 필드 검증(crossValidate):**
/// 모든 필드가 개별 통과한 뒤에만 실행된다. 필드 레벨 에러가 있으면 실행되지 않는다.
class DupSchema {
  /// 필드명 → 검증기 맵. 생성 시 각 검증기에 레이블이 설정된다.
  final Map<String, BaseValidator> _schema;

  /// 모든 필드가 통과한 뒤 실행되는 교차 필드 검증 함수.
  /// null이면 교차 검증 없음. 에러가 없으면 null을 반환해야 한다.
  Map<String, ValidationFailure>? Function(Map<String, dynamic>)?
      _crossValidator;

  /// [schema]: 필드명 → 검증기 맵.
  /// [labels]: 필드명 → 레이블 오버라이드. 없으면 필드명이 레이블로 사용됨.
  DupSchema(
    Map<String, BaseValidator> schema, {
    Map<String, String> labels = const {},
  }) : _schema = Map.from(schema) {
    // 생성 시 각 검증기에 레이블을 주입한다. 에러 메시지의 필드명으로 표시된다.
    for (final entry in _schema.entries) {
      final label = labels[entry.key] ?? entry.key;
      entry.value.setLabel(label);
    }
  }

  /// 스키마 내 어느 필드에라도 async 검증기가 있으면 true.
  /// [validateSync] 호출 전 확인 용도로 사용된다.
  bool get hasAsyncValidators =>
      _schema.values.any((v) => v.hasAsyncValidators);

  /// 교차 필드 검증 함수를 등록하고 자신을 반환한다 (체이닝 지원).
  ///
  /// [fn]은 전체 data 맵을 받아 필드별 에러 맵 또는 null을 반환한다.
  /// 필드 레벨 에러가 하나라도 있으면 [fn]은 호출되지 않는다.
  DupSchema crossValidate(
    Map<String, ValidationFailure>? Function(Map<String, dynamic>) fn,
  ) {
    _crossValidator = fn;
    return this;
  }

  /// 모든 필드를 비동기로 검증하고 [FormValidationResult]를 반환한다.
  ///
  /// 각 필드의 [validateAsync]를 순서대로 실행한다.
  /// 하나라도 실패하면 [FormValidationFailure]를 반환하고 crossValidate는 건너뛴다.
  Future<FormValidationResult> validate(Map<String, dynamic> data) async {
    final errors = <String, ValidationFailure>{};
    for (final field in _schema.keys) {
      final result = await _schema[field]!.validateAsync(data[field]);
      if (result is ValidationFailure) {
        errors[field] = result;
      }
    }
    if (errors.isNotEmpty) return FormValidationFailure(errors);
    if (_crossValidator != null) {
      final crossErrors = _crossValidator!(data);
      if (crossErrors != null && crossErrors.isNotEmpty) {
        return FormValidationFailure(crossErrors);
      }
    }
    return const FormValidationSuccess();
  }

  /// 모든 필드를 동기로 검증하고 [FormValidationResult]를 반환한다.
  ///
  /// async 검증기가 있는 스키마에서 호출하면 debug 모드에서 [AssertionError]가 발생한다.
  /// async 검증기가 있다면 [validate]를 사용해야 한다.
  FormValidationResult validateSync(Map<String, dynamic> data) {
    assert(
      !hasAsyncValidators,
      'validateSync() called on a schema that has async validators. '
      'Use validate() instead.',
    );
    final errors = <String, ValidationFailure>{};
    for (final field in _schema.keys) {
      final result = _schema[field]!.validate(data[field]);
      if (result is ValidationFailure) {
        errors[field] = result;
      }
    }
    if (errors.isNotEmpty) return FormValidationFailure(errors);
    if (_crossValidator != null) {
      final crossErrors = _crossValidator!(data);
      if (crossErrors != null && crossErrors.isNotEmpty) {
        return FormValidationFailure(crossErrors);
      }
    }
    return const FormValidationSuccess();
  }

  /// 특정 필드 하나만 단독으로 검증한다 (예: TextFormField의 onChange 처리).
  ///
  /// [field]가 스키마에 없으면 [ValidationSuccess]를 반환한다.
  Future<ValidationResult> validateField(String field, dynamic value) async {
    final validator = _schema[field];
    if (validator == null) return const ValidationSuccess();
    return validator.validateAsync(value);
  }
}
