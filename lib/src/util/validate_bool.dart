import 'package:dup/src/util/validate_locale.dart';
import 'package:dup/src/util/validator_base.dart';
import '../model/message_factory.dart';

class ValidateBool extends BaseValidator<bool, ValidateBool> {
  ValidateBool isTrue({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value != true) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.boolMessages['isTrue']
            ?.call({'name': label});
        if (global != null) return global;
        return '$label must be true.';
      }
      return null;
    });
  }

  ValidateBool isFalse({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value != false) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.boolMessages['isFalse']
            ?.call({'name': label});
        if (global != null) return global;
        return '$label must be false.';
      }
      return null;
    });
  }
}
