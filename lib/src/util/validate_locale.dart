import '../model/locale_message.dart';
import '../model/validation_code.dart';

/// Global locale for customising validation error messages.
///
/// Holds a flat [ValidationCode] → [LocaleMessage] map. When
/// [BaseValidator.getFailure] resolves a message it checks this locale as
/// the second priority (after a per-call `messageFactory`, before the
/// hardcoded English default).
///
/// Set once at app start and it applies to every validator:
///
/// ```dart
/// ValidatorLocale.setLocale(ValidatorLocale({
///   ValidationCode.required: (p) => '${p['name']} is required.',
///   ValidationCode.emailInvalid: (_) => 'Invalid email address.',
/// }));
/// ```
///
/// In tests, call [resetLocale] in `tearDown` to avoid leaking state across
/// test cases.
class ValidatorLocale {
  /// The currently active locale instance. Null means the hardcoded English
  /// defaults are used for every message.
  static ValidatorLocale? _current;

  /// Message function map keyed by [ValidationCode].
  /// Codes not present in the map fall back to the hardcoded default.
  final Map<ValidationCode, LocaleMessage> messages;

  const ValidatorLocale(this.messages);

  /// Activates [locale] globally. Takes effect immediately for all validators.
  static void setLocale(ValidatorLocale locale) => _current = locale;

  /// Resets the global locale to null, restoring hardcoded English defaults.
  static void resetLocale() => _current = null;

  /// The currently active locale, or null if none has been set.
  static ValidatorLocale? get current => _current;

  /// The built-in English defaults as a locale instance.
  /// Use as a base for partial overrides via [merge].
  static final ValidatorLocale base = ValidatorLocale({
    ValidationCode.custom: (p) => '${p['name']} is invalid.',
    ValidationCode.required: (p) => '${p['name']} is required.',
    ValidationCode.notBlank: (p) => '${p['name']} cannot be blank.',
    ValidationCode.equal: (p) => '${p['name']} does not match.',
    ValidationCode.notEqual: (p) => '${p['name']} is not allowed.',
    ValidationCode.oneOf:
        (p) => '${p['name']} must be one of: ${p['options']}.',
    ValidationCode.notOneOf:
        (p) => '${p['name']} must not be one of: ${p['options']}.',
    ValidationCode.condition:
        (p) => '${p['name']} does not satisfy the condition.',
    ValidationCode.stringMin:
        (p) => '${p['name']} must be at least ${p['min']} characters.',
    ValidationCode.stringMax:
        (p) => '${p['name']} must be at most ${p['max']} characters.',
    ValidationCode.matches:
        (p) => '${p['name']} does not match the required format.',
    ValidationCode.emailInvalid:
        (p) => '${p['name']} is not a valid email address.',
    ValidationCode.passwordMin:
        (p) => '${p['name']} must be at least ${p['minLength']} characters.',
    ValidationCode.emoji: (p) => '${p['name']} cannot contain emoji.',
    ValidationCode.mobileInvalid:
        (p) => '${p['name']} is not a valid mobile number.',
    ValidationCode.phoneInvalid:
        (p) => '${p['name']} is not a valid phone number.',
    ValidationCode.biznoInvalid:
        (p) => '${p['name']} is not a valid business registration number.',
    ValidationCode.url: (p) => '${p['name']} is not a valid URL.',
    ValidationCode.uuid: (p) => '${p['name']} is not a valid UUID.',
    ValidationCode.alpha: (p) => '${p['name']} must contain only letters.',
    ValidationCode.alphanumeric:
        (p) => '${p['name']} must contain only letters and numbers.',
    ValidationCode.numeric: (p) => '${p['name']} must contain only digits.',
    ValidationCode.numberMin:
        (p) => '${p['name']} must be at least ${p['min']}.',
    ValidationCode.numberMax:
        (p) => '${p['name']} must be at most ${p['max']}.',
    ValidationCode.integer: (p) => '${p['name']} must be an integer.',
    ValidationCode.positive: (p) => '${p['name']} must be positive.',
    ValidationCode.negative: (p) => '${p['name']} must be negative.',
    ValidationCode.nonNegative: (p) => '${p['name']} must be non-negative.',
    ValidationCode.nonPositive: (p) => '${p['name']} must be non-positive.',
    ValidationCode.between:
        (p) => '${p['name']} must be between ${p['min']} and ${p['max']}.',
    ValidationCode.even: (p) => '${p['name']} must be even.',
    ValidationCode.odd: (p) => '${p['name']} must be odd.',
    ValidationCode.multipleOf:
        (p) => '${p['name']} must be a multiple of ${p['factor']}.',
    ValidationCode.listNotEmpty: (p) => '${p['name']} cannot be empty.',
    ValidationCode.listEmpty: (p) => '${p['name']} must be empty.',
    ValidationCode.listMin:
        (p) => '${p['name']} must have at least ${p['min']} items.',
    ValidationCode.listMax:
        (p) => '${p['name']} cannot have more than ${p['max']} items.',
    ValidationCode.listLengthBetween:
        (p) =>
            '${p['name']} length must be between ${p['min']} and ${p['max']}.',
    ValidationCode.listExactLength:
        (p) => '${p['name']} must have exactly ${p['length']} items.',
    ValidationCode.contains: (p) => '${p['name']} must contain ${p['item']}.',
    ValidationCode.doesNotContain:
        (p) => '${p['name']} must not contain ${p['item']}.',
    ValidationCode.all:
        (p) => 'All items in ${p['name']} must satisfy the condition.',
    ValidationCode.any:
        (p) => 'At least one item in ${p['name']} must satisfy the condition.',
    ValidationCode.none:
        (p) => '${p['name']} must not contain any items matching the condition.',
    ValidationCode.noDuplicates:
        (p) => '${p['name']} must not contain duplicate items.',
    ValidationCode.eachItem:
        (p) => 'Item at index ${p['index']} in ${p['name']}: ${p['error']}',
    ValidationCode.dateMin:
        (p) => '${p['name']} must be on or after ${p['min']}.',
    ValidationCode.dateMax:
        (p) => '${p['name']} must be on or before ${p['max']}.',
    ValidationCode.dateBefore:
        (p) => '${p['name']} must be before ${p['target']}.',
    ValidationCode.dateAfter:
        (p) => '${p['name']} must be after ${p['target']}.',
    ValidationCode.dateBetween:
        (p) => '${p['name']} must be between ${p['min']} and ${p['max']}.',
    ValidationCode.dateInFuture: (p) => '${p['name']} must be in the future.',
    ValidationCode.dateInPast: (p) => '${p['name']} must be in the past.',
    ValidationCode.boolTrue: (p) => '${p['name']} must be true.',
    ValidationCode.boolFalse: (p) => '${p['name']} must be false.',
    // v2 string validators
    ValidationCode.startsWith:
        (p) => '${p['name']} must start with "${p['prefix']}".',
    ValidationCode.endsWith:
        (p) => '${p['name']} must end with "${p['suffix']}".',
    ValidationCode.stringContains:
        (p) => '${p['name']} must contain "${p['substring']}".',
    ValidationCode.ipAddress: (p) => '${p['name']} is not a valid IP address.',
    ValidationCode.hexColor: (p) => '${p['name']} is not a valid hex color.',
    ValidationCode.base64: (p) => '${p['name']} is not valid Base64.',
    ValidationCode.json: (p) => '${p['name']} is not valid JSON.',
    ValidationCode.creditCard:
        (p) => '${p['name']} is not a valid credit card number.',
    ValidationCode.koPostalCode:
        (p) => '${p['name']} is not a valid Korean postal code.',
    // v2 number validators
    ValidationCode.numberPrecision:
        (p) => '${p['name']} must have at most ${p['digits']} decimal places.',
    ValidationCode.portNumber: (p) => '${p['name']} is not a valid port number.',
    // v2 date validators
    ValidationCode.isWeekday: (p) => '${p['name']} must be a weekday.',
    ValidationCode.isWeekend: (p) => '${p['name']} must be a weekend day.',
    ValidationCode.isToday: (p) => '${p['name']} must be today.',
    ValidationCode.isSameDay:
        (p) => '${p['name']} must be the same day as ${p['targetFormatted']}.',
    ValidationCode.isWithin:
        (p) => '${p['name']} must be within ${p['duration']}.',
    // v2 list validators
    ValidationCode.listContainsAll:
        (p) =>
            '${p['name']} must contain all required items. Missing: ${(p['missing'] as List?)?.join(', ') ?? ''}.',
    // v2 map validators
    ValidationCode.mapMinSize:
        (p) => '${p['name']} must have at least ${p['min']} entries.',
    ValidationCode.mapMaxSize:
        (p) => '${p['name']} must have at most ${p['max']} entries.',
    // v2 nested validators
    ValidationCode.nestedFailed:
        (p) => '${p['name']} has nested validation errors.',
  });

  /// Returns a new [ValidatorLocale] with [overrides] applied on top of this
  /// locale's messages (overlay semantics: [overrides] wins on conflict).
  /// The receiver is not mutated.
  ValidatorLocale merge(Map<ValidationCode, LocaleMessage> overrides) {
    return ValidatorLocale({...messages, ...overrides});
  }
}
