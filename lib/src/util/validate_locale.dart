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
}
