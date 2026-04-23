import '../model/locale_message.dart';

class ValidatorLocale {
  static ValidatorLocale? _current;

  final Map<String, LocaleMessage> mixed;
  final Map<String, LocaleMessage> number;
  final Map<String, LocaleMessage> string;
  final Map<String, LocaleMessage> array;
  final Map<String, LocaleMessage> boolMessages;
  final Map<String, LocaleMessage> date;

  ValidatorLocale({
    required this.mixed,
    required this.number,
    required this.string,
    required this.array,
    this.boolMessages = const {},
    this.date = const {},
  });

  static void setLocale(ValidatorLocale locale) => _current = locale;
  static void resetLocale() => _current = null;
  static ValidatorLocale? get current => _current;
}

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

  // number
  static const String numberMin = 'min';
  static const String numberMax = 'max';
  static const String numberInteger = 'integer';
  static const String numberPositive = 'positive';
  static const String numberNegative = 'negative';
  static const String numberNonNegative = 'nonNegative';
  static const String numberNonPositive = 'nonPositive';

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
}
