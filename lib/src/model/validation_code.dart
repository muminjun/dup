/// 모든 내장 검증 규칙을 식별하는 코드 열거형.
///
/// [ValidatorLocale]의 메시지 맵 키로 사용되며,
/// [ValidationFailure.code]에 저장되어 실패 원인을 분류한다.
/// 사용자 정의 검증기는 [custom]을 사용하고 [ValidationFailure.customCode]로 세부 분류한다.
enum ValidationCode {
  // 공통 — 모든 타입에서 사용 가능
  required, // 값이 null이거나 빈 문자열일 때
  notBlank, // 공백만 있는 문자열일 때
  equal, // equalTo() — 특정 값과 달라야 할 때
  notEqual, // notEqualTo() — 특정 값과 같으면 안 될 때
  oneOf, // includedIn() — 허용 목록에 없을 때
  notOneOf, // excludedFrom() — 금지 목록에 포함될 때
  condition, // satisfy() — 커스텀 조건을 통과하지 못할 때
  custom, // addValidator() 등 사용자 정의 검증기

  // 문자열 (ValidateString)
  stringMin, // min() — 최소 글자 수 미달
  stringMax, // max() — 최대 글자 수 초과
  matches, // matches() — 정규식 불일치
  emailInvalid, // email() — 이메일 형식 오류
  passwordMin, // password() — 비밀번호 최소 길이 미달
  emoji, // emoji() — 이모지 포함 금지
  mobileInvalid, // mobile() — 휴대폰 번호 형식 오류
  phoneInvalid, // phone() — 전화번호 형식 오류
  biznoInvalid, // bizno() — 사업자등록번호 형식 오류
  url, // url() — URL 형식 오류
  uuid, // uuid() — UUID 형식 오류
  alpha, // alpha() — 영문자 이외 포함
  alphanumeric, // alphanumeric() — 영숫자 이외 포함
  numeric, // numeric() — 숫자 이외 포함

  // 숫자 (ValidateNumber)
  numberMin, // min() — 최솟값 미달
  numberMax, // max() — 최댓값 초과
  integer, // isInteger() — 소수점 포함
  positive, // isPositive() — 0 이하
  negative, // isNegative() — 0 이상
  nonNegative, // isNonNegative() — 음수
  nonPositive, // isNonPositive() — 양수
  between, // between() — 범위 이탈
  even, // isEven() — 홀수
  odd, // isOdd() — 짝수
  multipleOf, // isMultipleOf() — 배수 아님

  // 리스트 (ValidateList)
  listNotEmpty, // isNotEmpty() — 빈 리스트
  listEmpty, // isEmpty() — 비어 있지 않은 리스트
  listMin, // minLength() — 최소 아이템 수 미달
  listMax, // maxLength() — 최대 아이템 수 초과
  listLengthBetween, // lengthBetween() — 길이 범위 이탈
  listExactLength, // hasLength() — 정확한 길이 불일치
  contains, // contains() — 특정 아이템 없음
  doesNotContain, // doesNotContain() — 금지 아이템 포함
  all, // all() — 일부 아이템이 조건 불만족
  any, // any() — 모든 아이템이 조건 불만족
  none, // none() — 조건 만족 아이템 존재
  noDuplicates, // hasNoDuplicates() — 중복 아이템 존재
  eachItem, // eachItem() — 개별 아이템 검증 실패

  // 날짜/시간 (ValidateDateTime)
  dateMin, // min() — 최소 날짜 이전
  dateMax, // max() — 최대 날짜 이후
  dateBefore, // isBefore() — 기준 날짜 이후
  dateAfter, // isAfter() — 기준 날짜 이전
  dateBetween, // between() — 날짜 범위 이탈
  dateInFuture, // isInFuture() — 과거 날짜
  dateInPast, // isInPast() — 미래 날짜

  // 불리언 (ValidateBool)
  boolTrue, // isTrue() — false일 때
  boolFalse, // isFalse() — true일 때
}
