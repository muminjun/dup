import '../model/message_factory.dart';
import '../model/validation_code.dart';
import 'validator_base.dart';

class ValidateBool extends BaseValidator<bool, ValidateBool> {
  ValidateBool isTrue({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value != true) {
        return getFailure(messageFactory, ValidationCode.boolTrue,
            {'name': label}, '$label must be true.');
      }
      return null;
    });
  }

  ValidateBool isFalse({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value != false) {
        return getFailure(messageFactory, ValidationCode.boolFalse,
            {'name': label}, '$label must be false.');
      }
      return null;
    });
  }
}
