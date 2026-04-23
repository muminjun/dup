enum ValidationCode {
  // shared
  required, notBlank, equal, notEqual, oneOf, notOneOf, condition, custom,

  // string
  stringMin, stringMax, matches, emailInvalid, passwordMin, emoji,
  mobileInvalid, phoneInvalid, biznoInvalid, url, uuid,
  alpha, alphanumeric, numeric,

  // number
  numberMin, numberMax, integer, positive, negative,
  nonNegative, nonPositive, between, even, odd, multipleOf,

  // list
  listNotEmpty, listEmpty, listMin, listMax, listLengthBetween,
  listExactLength, contains, doesNotContain, all, any, none,
  noDuplicates, eachItem,

  // datetime
  dateMin, dateMax, dateBefore, dateAfter, dateBetween,
  dateInFuture, dateInPast,

  // bool
  boolTrue, boolFalse,
}
