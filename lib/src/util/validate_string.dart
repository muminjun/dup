import '../model/message_factory.dart';
import '../model/validation_code.dart';
import 'validator_base.dart';

class ValidateString extends BaseValidator<String, ValidateString> {
  ValidateString min(int min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.trim().length < min) {
        return getFailure(messageFactory, ValidationCode.stringMin,
            {'name': label, 'min': min}, '$label must be at least $min characters.');
      }
      return null;
    });
  }

  ValidateString max(int max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.trim().length > max) {
        return getFailure(messageFactory, ValidationCode.stringMax,
            {'name': label, 'max': max}, '$label must be at most $max characters.');
      }
      return null;
    });
  }

  ValidateString matches(RegExp regex, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && !regex.hasMatch(value.trim())) {
        return getFailure(messageFactory, ValidationCode.matches,
            {'name': label}, '$label does not match the required format.');
      }
      return null;
    });
  }

  ValidateString email({MessageFactory? messageFactory}) {
    const emailRegex =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@'
        r'((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|'
        r'(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(emailRegex).hasMatch(value.trim())) {
        return getFailure(messageFactory, ValidationCode.emailInvalid,
            {'name': label}, '$label is not a valid email address.');
      }
      return null;
    });
  }

  ValidateString password({int minLength = 4, MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (value.trim().length < minLength) {
        return getFailure(messageFactory, ValidationCode.passwordMin,
            {'name': label, 'minLength': minLength},
            '$label must be at least $minLength characters.');
      }
      return null;
    });
  }

  ValidateString emoji({MessageFactory? messageFactory}) {
    final emojiRegex = RegExp(r'\p{Emoji_Presentation}', unicode: true);
    return addPhaseValidator(1, (value) {
      if (value != null && value.isNotEmpty && emojiRegex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.emoji,
            {'name': label}, '$label cannot contain emoji.');
      }
      return null;
    });
  }

  ValidateString notBlank({MessageFactory? messageFactory}) {
    return addPhaseValidator(0, (value) {
      if (value != null && value.trim().isEmpty) {
        return getFailure(messageFactory, ValidationCode.notBlank,
            {'name': label}, '$label cannot be blank.');
      }
      return null;
    });
  }

  ValidateString alpha({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value.trim())) {
        return getFailure(messageFactory, ValidationCode.alpha,
            {'name': label}, '$label must contain only letters.');
      }
      return null;
    });
  }

  ValidateString alphanumeric({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
        return getFailure(messageFactory, ValidationCode.alphanumeric,
            {'name': label}, '$label must contain only letters and numbers.');
      }
      return null;
    });
  }

  ValidateString numeric({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
        return getFailure(messageFactory, ValidationCode.numeric,
            {'name': label}, '$label must contain only digits.');
      }
      return null;
    });
  }

  ValidateString mobile({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^\d{2,3}-\d{3,4}-\d{4}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.mobileInvalid,
            {'name': label}, '$label is not a valid mobile number.');
      }
      return null;
    });
  }

  ValidateString phone({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^(0[2-9]{1}\d?)-\d{3,4}-\d{4}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.phoneInvalid,
            {'name': label}, '$label is not a valid phone number.');
      }
      return null;
    });
  }

  ValidateString bizno({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^\d{3}-\d{2}-\d{5}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.biznoInvalid,
            {'name': label}, '$label is not a valid business registration number.');
      }
      return null;
    });
  }

  ValidateString url({MessageFactory? messageFactory}) {
    final regex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.url,
            {'name': label}, '$label is not a valid URL.');
      }
      return null;
    });
  }

  ValidateString uuid({MessageFactory? messageFactory}) {
    final regex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.uuid,
            {'name': label}, '$label is not a valid UUID.');
      }
      return null;
    });
  }
}
