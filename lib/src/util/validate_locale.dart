import '../model/locale_message.dart';
import '../model/validation_code.dart';

class ValidatorLocale {
  static ValidatorLocale? _current;

  final Map<ValidationCode, LocaleMessage> messages;

  const ValidatorLocale(this.messages);

  static void setLocale(ValidatorLocale locale) => _current = locale;
  static void resetLocale() => _current = null;
  static ValidatorLocale? get current => _current;
}
