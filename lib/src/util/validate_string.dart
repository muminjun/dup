import '../model/message_factory.dart';
import '../model/validation_code.dart';
import 'validator_base.dart';

/// Validator for [String] values.
///
/// All methods null-skip: they return null (pass) when the value is null.
/// Add [required] to the chain if null should be rejected.
///
/// ```dart
/// ValidateString()
///   .setLabel('Email')
///   .email()
///   .required()
///   .validate(value);
/// ```
class ValidateString extends BaseValidator<String, ValidateString> {
  /// Phase 2: fails when the trimmed length is less than [min].
  ValidateString min(int min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.trim().length < min) {
        return getFailure(
          messageFactory,
          ValidationCode.stringMin,
          {'name': label, 'min': min},
          '$label must be at least $min characters.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when the trimmed length exceeds [max].
  ValidateString max(int max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.trim().length > max) {
        return getFailure(
          messageFactory,
          ValidationCode.stringMax,
          {'name': label, 'max': max},
          '$label must be at most $max characters.',
        );
      }
      return null;
    });
  }

  /// Phase 1: fails when the trimmed value does not match [regex].
  ValidateString matches(RegExp regex, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && !regex.hasMatch(value.trim())) {
        return getFailure(
          messageFactory,
          ValidationCode.matches,
          {'name': label},
          '$label does not match the required format.',
        );
      }
      return null;
    });
  }

  /// Phase 1: fails when the value is not a valid email address.
  /// Null and empty string pass (null-skip).
  ValidateString email({MessageFactory? messageFactory}) {
    const emailRegex =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@'
        r'((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|'
        r'(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(emailRegex).hasMatch(value.trim())) {
        return getFailure(
          messageFactory,
          ValidationCode.emailInvalid,
          {'name': label},
          '$label is not a valid email address.',
        );
      }
      return null;
    });
  }

  /// Phase 1: fails when the trimmed length is less than [minLength].
  /// Default minimum length is 4. Null and empty string pass (null-skip).
  ValidateString password({int minLength = 4, MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (value.trim().length < minLength) {
        return getFailure(
          messageFactory,
          ValidationCode.passwordMin,
          {'name': label, 'minLength': minLength},
          '$label must be at least $minLength characters.',
        );
      }
      return null;
    });
  }

  /// Phase 1: fails when the value contains emoji characters.
  ValidateString emoji({MessageFactory? messageFactory}) {
    final emojiRegex = RegExp(r'\p{Emoji_Presentation}', unicode: true);
    return addPhaseValidator(1, (value) {
      if (value != null && value.isNotEmpty && emojiRegex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.emoji, {
          'name': label,
        }, '$label cannot contain emoji.');
      }
      return null;
    });
  }

  /// Phase 0: fails when the value consists entirely of whitespace.
  /// Null passes (null-skip). Combine with [required] to also reject null.
  ValidateString notBlank({MessageFactory? messageFactory}) {
    return addPhaseValidator(0, (value) {
      if (value != null && value.trim().isEmpty) {
        return getFailure(messageFactory, ValidationCode.notBlank, {
          'name': label,
        }, '$label cannot be blank.');
      }
      return null;
    });
  }

  /// Phase 1: fails when the value contains any non-alpha characters (a–z, A–Z).
  ValidateString alpha({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value.trim())) {
        return getFailure(messageFactory, ValidationCode.alpha, {
          'name': label,
        }, '$label must contain only letters.');
      }
      return null;
    });
  }

  /// Phase 1: fails when the value contains characters other than a–z, A–Z, 0–9.
  ValidateString alphanumeric({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
        return getFailure(
          messageFactory,
          ValidationCode.alphanumeric,
          {'name': label},
          '$label must contain only letters and numbers.',
        );
      }
      return null;
    });
  }

  /// Phase 1: fails when the value contains characters other than 0–9.
  ValidateString numeric({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
        return getFailure(
          messageFactory,
          ValidationCode.numeric,
          {'name': label},
          '$label must contain only digits.',
        );
      }
      return null;
    });
  }

  /// Phase 1: validates mobile phone number format.
  /// Default pattern: `010-1234-5678`. Override with [customRegex].
  ValidateString mobile({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^\d{2,3}-\d{3,4}-\d{4}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.mobileInvalid,
          {'name': label},
          '$label is not a valid mobile number.',
        );
      }
      return null;
    });
  }

  /// Phase 1: validates landline phone number format.
  /// Default pattern: `02-1234-5678`. Override with [customRegex].
  ValidateString phone({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^(0[2-9]{1}\d?)-\d{3,4}-\d{4}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.phoneInvalid,
          {'name': label},
          '$label is not a valid phone number.',
        );
      }
      return null;
    });
  }

  /// Phase 1: validates Korean business registration number format.
  /// Default pattern: `123-45-67890`. Override with [customRegex].
  ValidateString bizno({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^\d{3}-\d{2}-\d{5}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.biznoInvalid,
          {'name': label},
          '$label is not a valid business registration number.',
        );
      }
      return null;
    });
  }

  /// Phase 1: fails when the value is not a valid HTTP/HTTPS URL.
  ValidateString url({MessageFactory? messageFactory}) {
    final regex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.url, {
          'name': label,
        }, '$label is not a valid URL.');
      }
      return null;
    });
  }

  /// Phase 1: fails when the value is not a valid UUID v4 (case-insensitive).
  ValidateString uuid({MessageFactory? messageFactory}) {
    final regex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.uuid, {
          'name': label,
        }, '$label is not a valid UUID.');
      }
      return null;
    });
  }
}
