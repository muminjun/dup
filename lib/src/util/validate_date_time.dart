import 'package:dup/src/util/validate_locale.dart';
import 'package:dup/src/util/validator_base.dart';
import '../model/message_factory.dart';

class ValidateDateTime extends BaseValidator<DateTime, ValidateDateTime> {
  ValidateDateTime isBefore(DateTime target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (!value.isBefore(target)) {
        if (messageFactory != null) {
          return messageFactory(label, {'target': target});
        }
        final global = ValidatorLocale.current?.date['before']
            ?.call({'name': label, 'target': target});
        if (global != null) return global;
        return '$label must be before $target.';
      }
      return null;
    });
  }

  ValidateDateTime isAfter(DateTime target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (!value.isAfter(target)) {
        if (messageFactory != null) {
          return messageFactory(label, {'target': target});
        }
        final global = ValidatorLocale.current?.date['after']
            ?.call({'name': label, 'target': target});
        if (global != null) return global;
        return '$label must be after $target.';
      }
      return null;
    });
  }

  ValidateDateTime min(DateTime min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isBefore(min)) {
        if (messageFactory != null) return messageFactory(label, {'min': min});
        final global = ValidatorLocale.current?.date['min']
            ?.call({'name': label, 'min': min});
        if (global != null) return global;
        return '$label must be on or after $min.';
      }
      return null;
    });
  }

  ValidateDateTime max(DateTime max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isAfter(max)) {
        if (messageFactory != null) return messageFactory(label, {'max': max});
        final global = ValidatorLocale.current?.date['max']
            ?.call({'name': label, 'max': max});
        if (global != null) return global;
        return '$label must be on or before $max.';
      }
      return null;
    });
  }

  ValidateDateTime between(
    DateTime min,
    DateTime max, {
    MessageFactory? messageFactory,
  }) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isBefore(min) || value.isAfter(max)) {
        if (messageFactory != null) {
          return messageFactory(label, {'min': min, 'max': max});
        }
        final global = ValidatorLocale.current?.date['between']
            ?.call({'name': label, 'min': min, 'max': max});
        if (global != null) return global;
        return '$label must be between $min and $max.';
      }
      return null;
    });
  }
}
