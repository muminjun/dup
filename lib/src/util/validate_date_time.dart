import '../model/message_factory.dart';
import '../model/validation_code.dart';
import 'validator_base.dart';

/// Validator for [DateTime] values.
///
/// All methods null-skip: they return null (pass) when the value is null.
///
/// ```dart
/// ValidateDateTime()
///   .setLabel('Date of birth')
///   .min(DateTime(1900))
///   .isInPast()
///   .required()
///   .validate(birthDate);
/// ```
class ValidateDateTime extends BaseValidator<DateTime, ValidateDateTime> {
  /// Phase 1: fails when value is not strictly before [target].
  ValidateDateTime isBefore(DateTime target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (!value.isBefore(target)) {
        return getFailure(
          messageFactory,
          ValidationCode.dateBefore,
          {'name': label, 'target': target},
          '$label must be before $target.',
        );
      }
      return null;
    });
  }

  /// Phase 1: fails when value is not strictly after [target].
  ValidateDateTime isAfter(DateTime target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (!value.isAfter(target)) {
        return getFailure(messageFactory, ValidationCode.dateAfter, {
          'name': label,
          'target': target,
        }, '$label must be after $target.');
      }
      return null;
    });
  }

  /// Phase 2: fails when value is before [min] (i.e. value must be on or after [min]).
  ValidateDateTime min(DateTime min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isBefore(min)) {
        return getFailure(
          messageFactory,
          ValidationCode.dateMin,
          {'name': label, 'min': min},
          '$label must be on or after $min.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when value is after [max] (i.e. value must be on or before [max]).
  ValidateDateTime max(DateTime max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isAfter(max)) {
        return getFailure(
          messageFactory,
          ValidationCode.dateMax,
          {'name': label, 'max': max},
          '$label must be on or before $max.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when value is outside the inclusive range [[min], [max]].
  ValidateDateTime between(
    DateTime min,
    DateTime max, {
    MessageFactory? messageFactory,
  }) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isBefore(min) || value.isAfter(max)) {
        return getFailure(
          messageFactory,
          ValidationCode.dateBetween,
          {'name': label, 'min': min, 'max': max},
          '$label must be between $min and $max.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when value is not strictly after [DateTime.now].
  ValidateDateTime isInFuture({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (!value.isAfter(DateTime.now())) {
        return getFailure(
          messageFactory,
          ValidationCode.dateInFuture,
          {'name': label},
          '$label must be in the future.',
        );
      }
      return null;
    });
  }

  /// Phase 2: fails when value is not strictly before [DateTime.now].
  ValidateDateTime isInPast({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (!value.isBefore(DateTime.now())) {
        return getFailure(messageFactory, ValidationCode.dateInPast, {
          'name': label,
        }, '$label must be in the past.');
      }
      return null;
    });
  }
}
