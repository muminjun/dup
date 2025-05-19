import '../model/locale_message.dart';

/// The ValidatorLocale class manages validation messages
/// for different data types in multiple languages.
class ValidatorLocale {
  /// Singleton instance to hold the current ValidatorLocale.
  static ValidatorLocale? _current;

  /// Map of messages for mixed types (e.g., general validation).
  final Map<String, LocaleMessage> mixed;

  /// Map of messages for number type validations.
  final Map<String, LocaleMessage> number;

  /// Map of messages for string type validations.
  final Map<String, LocaleMessage> string;

  /// Map of messages for array type validations.
  final Map<String, LocaleMessage> array;

  /// Constructor: Requires message maps for each type.
  ValidatorLocale({
    required this.mixed,
    required this.number,
    required this.string,
    required this.array,
  });

  /// Sets the current ValidatorLocale instance.
  /// [locale]: The ValidatorLocale to set as current.
  static void setLocale(ValidatorLocale locale) {
    _current = locale;
  }

  /// Returns the currently set ValidatorLocale instance.
  static ValidatorLocale? get current => _current;
}
