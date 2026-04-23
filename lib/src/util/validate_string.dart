import 'package:dup/src/util/validate_locale.dart';
import 'package:dup/src/util/validator_base.dart';
import '../model/message_factory.dart';

class ValidateString extends BaseValidator<String, ValidateString> {
  ValidateString min(int min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.trim().length < min) {
        if (messageFactory != null) return messageFactory(label, {'min': min});
        final global = ValidatorLocale.current?.string['min']
            ?.call({'name': label, 'min': min});
        if (global != null) return global;
        return '$label must be at least $min characters.';
      }
      return null;
    });
  }

  ValidateString max(int max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.trim().length > max) {
        if (messageFactory != null) return messageFactory(label, {'max': max});
        final global = ValidatorLocale.current?.string['max']
            ?.call({'name': label, 'max': max});
        if (global != null) return global;
        return '$label must be at most $max characters.';
      }
      return null;
    });
  }

  ValidateString matches(RegExp regex, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && !regex.hasMatch(value.trim())) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['matches']
            ?.call({'name': label});
        if (global != null) return global;
        return '$label does not match the required format.';
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
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['emailInvalid']
            ?.call({'name': label});
        if (global != null) return global;
        return '$label is not a valid email address.';
      }
      return null;
    });
  }

  ValidateString password({int minLength = 4, MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (value.trim().length < minLength) {
        if (messageFactory != null) {
          return messageFactory(label, {'minLength': minLength});
        }
        final global = ValidatorLocale.current?.string['passwordMin']
            ?.call({'name': label, 'minLength': minLength});
        if (global != null) return global;
        return '$label must be at least $minLength characters.';
      }
      return null;
    });
  }

  ValidateString emoji({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && value.isNotEmpty) {
        if (RegExp(r'\p{Emoji}', unicode: true).hasMatch(value)) {
          if (messageFactory != null) return messageFactory(label, {});
          final global = ValidatorLocale.current?.string['emoji']
              ?.call({'name': label});
          if (global != null) return global;
          return '$label cannot contain emoji.';
        }
      }
      return null;
    });
  }

  ValidateString mobile({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^\d{2,3}-\d{3,4}-\d{4}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['mobileInvalid']
            ?.call({'name': label});
        if (global != null) return global;
        return '$label is not a valid mobile number.';
      }
      return null;
    });
  }

  ValidateString phone({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^(0[2-9]{1}\d?)-\d{3,4}-\d{4}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['phoneInvalid']
            ?.call({'name': label});
        if (global != null) return global;
        return '$label is not a valid phone number.';
      }
      return null;
    });
  }

  ValidateString bizno({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^\d{3}-\d{2}-\d{5}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['biznoInvalid']
            ?.call({'name': label});
        if (global != null) return global;
        return '$label is not a valid business registration number.';
      }
      return null;
    });
  }

  ValidateString url({MessageFactory? messageFactory}) {
    final regex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['url']
            ?.call({'name': label});
        if (global != null) return global;
        return '$label is not a valid URL.';
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
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['uuid']
            ?.call({'name': label});
        if (global != null) return global;
        return '$label is not a valid UUID.';
      }
      return null;
    });
  }
}
