import '../model/message_factory.dart';
import '../model/validation_code.dart';
import 'validator_base.dart';

class ValidateDateTime extends BaseValidator<DateTime, ValidateDateTime> {
  ValidateDateTime isBefore(DateTime target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (!value.isBefore(target)) {
        return getFailure(messageFactory, ValidationCode.dateBefore,
            {'name': label, 'target': target}, '$label must be before $target.');
      }
      return null;
    });
  }

  ValidateDateTime isAfter(DateTime target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (!value.isAfter(target)) {
        return getFailure(messageFactory, ValidationCode.dateAfter,
            {'name': label, 'target': target}, '$label must be after $target.');
      }
      return null;
    });
  }

  ValidateDateTime min(DateTime min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isBefore(min)) {
        return getFailure(messageFactory, ValidationCode.dateMin,
            {'name': label, 'min': min}, '$label must be on or after $min.');
      }
      return null;
    });
  }

  ValidateDateTime max(DateTime max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isAfter(max)) {
        return getFailure(messageFactory, ValidationCode.dateMax,
            {'name': label, 'max': max}, '$label must be on or before $max.');
      }
      return null;
    });
  }

  ValidateDateTime between(DateTime min, DateTime max,
      {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isBefore(min) || value.isAfter(max)) {
        return getFailure(messageFactory, ValidationCode.dateBetween,
            {'name': label, 'min': min, 'max': max},
            '$label must be between $min and $max.');
      }
      return null;
    });
  }

  ValidateDateTime isInFuture({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (!value.isAfter(DateTime.now())) {
        return getFailure(messageFactory, ValidationCode.dateInFuture,
            {'name': label}, '$label must be in the future.');
      }
      return null;
    });
  }

  ValidateDateTime isInPast({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (!value.isBefore(DateTime.now())) {
        return getFailure(messageFactory, ValidationCode.dateInPast,
            {'name': label}, '$label must be in the past.');
      }
      return null;
    });
  }
}
