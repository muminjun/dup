import '../model/locale_message.dart';
import '../model/validation_code.dart';

class ValidatorLocale {
  static ValidatorLocale? _current;

  final Map<ValidationCode, LocaleMessage> messages;

  const ValidatorLocale(this.messages);

  static void setLocale(ValidatorLocale locale) => _current = locale;
  static void resetLocale() => _current = null;
  static ValidatorLocale? get current => _current;

  // ---------------------------------------------------------------------------
  // Temporary compatibility shims — referenced by validators pending Tasks 4–9.
  // These always return empty maps so locale resolution falls through to the
  // hardcoded defaults, keeping existing tests green until each validator is
  // migrated to the new ValidationCode-keyed API.
  // ---------------------------------------------------------------------------

  /// @deprecated Use [messages] with [ValidationCode] keys instead.
  Map<String, LocaleMessage> get mixed => const {};

  /// @deprecated Use [messages] with [ValidationCode] keys instead.
  Map<String, LocaleMessage> get string => const {};

  /// @deprecated Use [messages] with [ValidationCode] keys instead.
  Map<String, LocaleMessage> get number => const {};

  /// @deprecated Use [messages] with [ValidationCode] keys instead.
  Map<String, LocaleMessage> get array => const {};

  /// @deprecated Use [messages] with [ValidationCode] keys instead.
  Map<String, LocaleMessage> get boolMessages => const {};

  /// @deprecated Use [messages] with [ValidationCode] keys instead.
  Map<String, LocaleMessage> get date => const {};
}

// ---------------------------------------------------------------------------
// ValidatorLocaleKeys — kept temporarily; referenced by validators pending
// Tasks 4–9. Will be deleted once all validators migrate to ValidationCode.
// ---------------------------------------------------------------------------
@Deprecated('Use ValidationCode enum values instead')
abstract class ValidatorLocaleKeys {
  // mixed
  static const String required = 'required';
  static const String equal = 'equal';
  static const String notEqual = 'notEqual';
  static const String oneOf = 'oneOf';
  static const String notOneOf = 'notOneOf';
  static const String condition = 'condition';

  // string
  static const String stringMin = 'min';
  static const String stringMax = 'max';
  static const String stringMatches = 'matches';
  static const String stringEmail = 'emailInvalid';
  static const String stringPassword = 'passwordMin';
  static const String stringEmoji = 'emoji';
  static const String stringMobile = 'mobileInvalid';
  static const String stringPhone = 'phoneInvalid';
  static const String stringBizno = 'biznoInvalid';
  static const String stringUrl = 'url';
  static const String stringUuid = 'uuid';
  static const String stringNotBlank = 'notBlank';
  static const String stringAlpha = 'alpha';
  static const String stringAlphanumeric = 'alphanumeric';
  static const String stringNumeric = 'numeric';

  // number
  static const String numberMin = 'min';
  static const String numberMax = 'max';
  static const String numberInteger = 'integer';
  static const String numberPositive = 'positive';
  static const String numberNegative = 'negative';
  static const String numberNonNegative = 'nonNegative';
  static const String numberNonPositive = 'nonPositive';
  static const String numberBetween = 'between';
  static const String numberEven = 'even';
  static const String numberOdd = 'odd';
  static const String numberMultipleOf = 'multipleOf';

  // array
  static const String arrayNotEmpty = 'notEmpty';
  static const String arrayEmpty = 'empty';
  static const String arrayMin = 'min';
  static const String arrayMax = 'max';
  static const String arrayLengthBetween = 'lengthBetween';
  static const String arrayExactLength = 'exactLength';
  static const String arrayContains = 'contains';
  static const String arrayDoesNotContain = 'doesNotContain';
  static const String arrayAllCondition = 'allCondition';
  static const String arrayAnyCondition = 'anyCondition';
  static const String arrayNoneCondition = 'noneCondition';
  static const String arrayNoDuplicates = 'noDuplicates';
  static const String arrayEachItem = 'eachItem';

  // bool
  static const String boolTrue = 'isTrue';
  static const String boolFalse = 'isFalse';

  // date
  static const String dateMin = 'min';
  static const String dateMax = 'max';
  static const String dateBefore = 'before';
  static const String dateAfter = 'after';
  static const String dateBetween = 'between';
  static const String dateInFuture = 'inFuture';
  static const String dateInPast = 'inPast';
}
