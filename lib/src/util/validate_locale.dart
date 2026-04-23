import '../model/locale_message.dart';
import '../model/validation_code.dart';

/// 검증 에러 메시지를 전역적으로 커스터마이징하는 로케일 설정.
///
/// [ValidationCode] → [LocaleMessage] 맵을 보유하며, [BaseValidator.getFailure]에서
/// 메시지를 조회할 때 2순위로 사용된다 (1순위: messageFactory, 3순위: 하드코딩 기본값).
///
/// 앱 시작 시 한 번 설정하면 모든 검증기에 적용된다:
///
/// ```dart
/// ValidatorLocale.setLocale(ValidatorLocale({
///   ValidationCode.required: (p) => '${p['name']}은(는) 필수입니다.',
///   ValidationCode.emailInvalid: (_) => '이메일 형식이 올바르지 않습니다.',
/// }));
/// ```
///
/// 테스트에서는 상태 누출을 막기 위해 tearDown에서 [resetLocale]을 호출해야 한다.
class ValidatorLocale {
  /// 현재 활성화된 로케일 인스턴스. null이면 기본 영문 메시지가 사용된다.
  static ValidatorLocale? _current;

  /// [ValidationCode]를 키로 하는 메시지 함수 맵.
  /// 맵에 없는 코드는 자동으로 기본값으로 폴백된다.
  final Map<ValidationCode, LocaleMessage> messages;

  const ValidatorLocale(this.messages);

  /// 전역 로케일을 설정한다. 이후 모든 검증기의 메시지에 적용된다.
  static void setLocale(ValidatorLocale locale) => _current = locale;

  /// 전역 로케일을 초기화한다 (null로). 기본 영문 메시지로 복구된다.
  static void resetLocale() => _current = null;

  /// 현재 설정된 로케일. 설정되지 않았으면 null.
  static ValidatorLocale? get current => _current;
}
