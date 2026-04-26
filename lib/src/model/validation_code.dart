/// Enum identifying every built-in validation rule.
///
/// Used as the key in [ValidatorLocale]'s message map and stored in
/// [ValidationFailure.code] to classify the failure reason.
/// User-defined validators use [custom] and can sub-classify with
/// [ValidationFailure.customCode].
enum ValidationCode {
  // Shared — available on all validator types
  required, // value is null or empty string
  notBlank, // string contains only whitespace
  equal, // equalTo() — value differs from the required target
  notEqual, // notEqualTo() — value equals the forbidden target
  oneOf, // includedIn() — value is not in the allowed list
  notOneOf, // excludedFrom() — value is in the forbidden list
  condition, // satisfy() — custom condition returned false
  custom, // addValidator() and other user-defined validators
  // String (ValidateString)
  stringMin, // min() — too few characters
  stringMax, // max() — too many characters
  matches, // matches() — regex mismatch
  emailInvalid, // email() — invalid email format
  passwordMin, // password() — password too short
  emoji, // emoji() — emoji characters not allowed
  mobileInvalid, // mobile() — invalid mobile number format
  phoneInvalid, // phone() — invalid phone number format
  biznoInvalid, // bizno() — invalid business registration number
  url, // url() — invalid URL format
  uuid, // uuid() — invalid UUID format
  alpha, // alpha() — non-alpha characters present
  alphanumeric, // alphanumeric() — non-alphanumeric characters present
  numeric, // numeric() — non-digit characters present
  // Number (ValidateNumber)
  numberMin, // min() — value below minimum
  numberMax, // max() — value above maximum
  integer, // isInteger() — value has a decimal part
  positive, // isPositive() — value is zero or negative
  negative, // isNegative() — value is zero or positive
  nonNegative, // isNonNegative() — value is negative
  nonPositive, // isNonPositive() — value is positive
  between, // between() — value outside range
  even, // isEven() — value is odd
  odd, // isOdd() — value is even
  multipleOf, // isMultipleOf() — value is not a multiple
  // List (ValidateList)
  listNotEmpty, // isNotEmpty() — list is empty
  listEmpty, // isEmpty() — list is not empty
  listMin, // minLength() — too few items
  listMax, // maxLength() — too many items
  listLengthBetween, // lengthBetween() — item count outside range
  listExactLength, // hasLength() — item count does not match
  contains, // contains() — required item is absent
  doesNotContain, // doesNotContain() — forbidden item is present
  all, // all() — at least one item fails the predicate
  any, // any() — no items satisfy the predicate
  none, // none() — at least one item satisfies the predicate
  noDuplicates, // hasNoDuplicates() — duplicate items found
  eachItem, // eachItem() — an individual item failed validation
  // DateTime (ValidateDateTime)
  dateMin, // min() — date is before the minimum
  dateMax, // max() — date is after the maximum
  dateBefore, // isBefore() — date is not before the target
  dateAfter, // isAfter() — date is not after the target
  dateBetween, // between() — date is outside the range
  dateInFuture, // isInFuture() — date is in the past
  dateInPast, // isInPast() — date is in the future
  // Bool (ValidateBool)
  boolTrue, // isTrue() — value is false
  boolFalse, // isFalse() — value is true
  // String — new in v2
  startsWith, // startsWith() — value does not start with prefix
  endsWith, // endsWith() — value does not end with suffix
  stringContains, // contains() — required substring absent
  ipAddress, // ipAddress() — not a valid IP address
  hexColor, // hexColor() — not a valid hex color
  base64, // base64() — not valid Base64
  json, // json() — not parseable JSON
  creditCard, // creditCard() — Luhn check failed
  koPostalCode, // koPostalCode() — not a valid Korean postal code
  // Number — new in v2
  numberPrecision, // isPrecision() — too many decimal places
  isPort, // isPort() — not a valid port number
  // DateTime — new in v2
  isWeekday, // isWeekday() — not a weekday
  isWeekend, // isWeekend() — not a weekend
  isToday, // isToday() — not today
  isSameDay, // isSameDay() — not the same calendar day
  isWithin, // isWithin() — outside the allowed duration
  // List — new in v2
  listContainsAll, // containsAll() — missing required items
  // Map (ValidateMap) — new in v2
  mapMinSize, // minSize() — too few entries
  mapMaxSize, // maxSize() — too many entries
  mapKeyInvalid, // keyValidator() — key failed, no specific code from inner validator
  mapValueInvalid, // valueValidator() — value failed, no specific code from inner validator
  // Nested (ValidateObject / ValidateMap) — new in v2
  nestedFailed, // inner schema validation failed (direct-call summary)
}
