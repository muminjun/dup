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

  /// Phase 1: fails when the date falls on a weekend (Saturday or Sunday).
  ValidateDateTime isWeekday({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value.weekday >= DateTime.saturday) {
        return getFailure(messageFactory, ValidationCode.isWeekday, {
          'name': label,
        }, '$label must be a weekday.');
      }
      return null;
    });
  }

  /// Phase 1: fails when the date falls on a weekday (Monday–Friday).
  ValidateDateTime isWeekend({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value.weekday < DateTime.saturday) {
        return getFailure(messageFactory, ValidationCode.isWeekend, {
          'name': label,
        }, '$label must be a weekend day.');
      }
      return null;
    });
  }

  /// Phase 1: fails when the date is not the same calendar day as [target].
  ValidateDateTime isSameDay(
    DateTime target, {
    MessageFactory? messageFactory,
  }) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value.year != target.year ||
          value.month != target.month ||
          value.day != target.day) {
        return getFailure(messageFactory, ValidationCode.isSameDay, {
          'name': label,
          'target': target,
        }, '$label must be on ${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}.');
      }
      return null;
    });
  }

  /// Phase 2: fails when the date is not the same calendar day as [DateTime.now()].
  ValidateDateTime isToday({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      final now = DateTime.now();
      if (value.year != now.year ||
          value.month != now.month ||
          value.day != now.day) {
        return getFailure(messageFactory, ValidationCode.isToday, {
          'name': label,
        }, '$label must be today.');
      }
      return null;
    });
  }

  /// Phase 2: fails when the absolute difference between [value] and [from]
  /// exceeds [duration]. [from] defaults to [DateTime.now()].
  ValidateDateTime isWithin(
    Duration duration, {
    DateTime? from,
    MessageFactory? messageFactory,
  }) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      final anchor = from ?? DateTime.now();
      final diff = value.difference(anchor).abs();
      if (diff > duration) {
        return getFailure(
          messageFactory,
          ValidationCode.isWithin,
          {'name': label, 'duration': duration, 'from': anchor},
          '$label must be within $duration of $anchor.',
        );
      }
      return null;
    });
  }
}
